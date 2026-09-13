import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_game_state.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/providers/cube_game_provider.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/widgets/cube_browse_view.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/widgets/cube_face_board.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/widgets/cube_geometry.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/widgets/cube_number_pad.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/widgets/cube_pause_sheet.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/widgets/cube_progress_indicator.dart';
import 'package:m6_sudoku/features/settings/presentation/providers/settings_provider.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/game_provider.dart'
    show showPencilMarksProvider;
import 'package:m6_sudoku/shared/widgets/glass/glass_surface.dart';
import 'package:m6_sudoku/shared/widgets/pausable_blur.dart';

/// Which of the two 3D-mode surfaces is showing right now — mutually
/// exclusive with the mid-transition state (`_isMorphing`), which
/// briefly replaces both while one face grows from cube-thumbnail size to
/// full screen (or shrinks back).
enum _CubeMode { play, browse }

/// The 3D Sudoku game screen. Three presentations share one controller:
///
///  * **Play View** — one face, full-screen, fully legible and tappable.
///    The default: this is the only surface a player is ever actually
///    solving a puzzle on.
///  * **Browse View** — the cube as a real 3D object, shown at a fixed,
///    always-angled "product shot" camera so two or three faces are
///    visible at once (see [CubeBrowseView]). Purely for orienting
///    yourself and picking a face — nothing on it is tappable at the cell
///    level, which is exactly what frees it to be as densely detailed and
///    steeply angled as it likes without hurting legibility.
///  * **the morph between them** — pinching out on Browse View's
///    front-most face (or tapping it) grows that face from its spot on
///    the cube to fill the screen, landing in Play View; pinching in on
///    Play View shrinks it back onto the cube.
///
///  A third, independent flat carousel (plain swipeable `PageView`, no
///  cube object at all) remains available via the top bar's mode toggle,
///  and is what reduced-motion/screen-reader sessions get automatically
///  regardless of that toggle — see [show3DCubeProvider].
class CubeGameScreen extends ConsumerStatefulWidget {
  const CubeGameScreen({super.key});

  @override
  ConsumerState<CubeGameScreen> createState() => _CubeGameScreenState();
}

class _CubeGameScreenState extends ConsumerState<CubeGameScreen>
    with TickerProviderStateMixin {
  /// The natural layout size `_buildFaceContent` is designed at — Browse
  /// and the morph both render it inside a `FittedBox` scaled to whatever
  /// on-screen size they need, rather than reflowing the header/board
  /// layout itself at every size.
  static const double _kContentDesignSize = 340;

  /// Browse View's default camera — angled enough that two or three
  /// faces read as a single 3D object at rest, the way a physical cube
  /// sitting on a table would.
  static const double _kDefaultBrowseYaw = -0.68;
  static const double _kDefaultBrowsePitch = -0.46;

  PageController? _pageController;
  bool _hasNavigatedToCompletion = false;
  int _selectionEpoch = 0;
  bool _showingCubeExperience = true;

  /// Drives [PausableBlur] around the puzzle content while [_showPauseSheet]
  /// is up — set via setState there, unlike the regular game's board which
  /// gets the same treatment, so it actually triggers a rebuild.
  bool _isPaused = false;

  /// Mirrors `build`'s own `forceFlat` local so [_handleFaceCompleted] —
  /// triggered from `ref.listen`, not from inside the widget tree it
  /// builds — can tell a reduced-motion/screen-reader session apart from
  /// an ordinary voluntary flat-mode toggle without recomputing
  /// `MediaQuery.of(context)` outside a build.
  bool _forceFlat = false;

  _CubeMode _mode = _CubeMode.play;
  double _browseYaw = _kDefaultBrowseYaw;
  double _browsePitch = _kDefaultBrowsePitch;

  /// Spin around the camera axis, driven by a two-finger twist — see
  /// [CubeBrowseView.roll]. `ScaleUpdateDetails.rotation` is cumulative
  /// since the current gesture started, not a per-frame delta, so
  /// [_rollAtGestureStart] snapshots [_browseRoll] at `onScaleStart` and
  /// every update simply adds that gesture's rotation-so-far on top of it —
  /// which is also what lets roll persist correctly across separate
  /// two-finger gestures instead of resetting each time.
  double _browseRoll = 0;
  double _rollAtGestureStart = 0;

  /// Set once a Browse gesture ever sees a second pointer — guards the
  /// "near-zero movement counts as a tap" heuristic in
  /// [_onBrowseScaleEnd], which would otherwise misfire when a two-finger
  /// twist happens to keep its focal point nearly still (fingers rotating
  /// symmetrically about a shared center) and read as a tap-to-open.
  bool _multiTouchUsed = false;

  late final AnimationController _morphController;
  CubeFace? _morphFace;
  bool _morphToPlay = true;
  bool _isMorphing = false;
  bool _pinchTriggered = false;

  /// Drives the camera swing between [_beginMorphToBrowse]'s shrink and
  /// [_beginMorphToPlay]'s expand in the completed-face auto-advance
  /// sequence (see [_handleFaceCompleted]) — a plain field tween rather
  /// than reusing [_morphController], since that controller's value
  /// already means "how grown/shrunk is the morphing face" and pressing
  /// it into double duty as "how far through the rotation" would fight
  /// itself the moment the two phases needed different durations/curves.
  late final AnimationController _autoRotateController;
  double _rotateStartYaw = 0;
  double _rotateStartPitch = 0;
  double _rotateTargetYaw = 0;
  double _rotateTargetPitch = 0;

  /// Which face [_beginMorphToBrowse] should automatically rotate to and
  /// re-expand into once its shrink finishes — null for an ordinary
  /// user-initiated pinch-to-browse, which just idles in Browse View
  /// instead. Set immediately before that shrink starts and consumed by
  /// [_onMorphStatusChanged].
  CubeFace? _autoAdvanceTarget;

  /// True for the whole shrink → rotate → expand sequence, not just one
  /// leg of it — gates gesture/button entry points that would otherwise
  /// fight an in-flight automatic advance the same way [_isMorphing]
  /// already gates them against a second manual morph.
  bool _isAutoAdvancing = false;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener(_onMorphStatusChanged);
    _autoRotateController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 650),
          )
          ..addListener(_onAutoRotateTick)
          ..addStatusListener(_onAutoRotateStatusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cubeTimerControllerProvider).start();
      final cubeState = ref.read(cubeGameControllerProvider);
      if (cubeState != null) {
        _browseYaw = _kDefaultBrowseYaw;
        _browsePitch = _kDefaultBrowsePitch;
        if (cubeState.isComplete) _navigateToCompletion();
      }
    });
  }

  @override
  void dispose() {
    _morphController.dispose();
    _autoRotateController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  PageController _flatController(CubeFace currentFace) {
    return _pageController ??= PageController(
      initialPage: CubeFace.values.indexOf(currentFace),
    );
  }

  void _onMorphStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final face = _morphFace;
    final autoAdvanceTo = _autoAdvanceTarget;
    _autoAdvanceTarget = null;
    setState(() {
      _mode = _morphToPlay ? _CubeMode.play : _CubeMode.browse;
      _isMorphing = false;
    });
    // Deliberately not resetting _morphController.value here: doing so
    // used to call notifyListeners() reentrantly from inside this very
    // status callback, rebuilding the AnimatedBuilder above with the mode
    // flip not yet applied to the tree. Neither trigger needs the
    // controller pre-zeroed anyway: both call `.forward(from: 0)`, which
    // resets from whatever value is already there.
    if (_morphToPlay && face != null) {
      ref.read(cubeGameControllerProvider.notifier).setActiveFace(face);
      setState(() => _selectionEpoch++);
      // Lands the shrink→rotate→expand sequence from _handleFaceCompleted:
      // this is the "expand" leg completing, so the whole thing is done.
      if (_isAutoAdvancing) setState(() => _isAutoAdvancing = false);
    } else if (!_morphToPlay && autoAdvanceTo != null) {
      // The "shrink" leg of an automatic advance just finished landing in
      // Browse View — continue straight into rotating toward the next
      // open face instead of waiting for a user gesture the way an
      // ordinary manual pinch-to-browse would.
      _beginAutoRotateTo(autoAdvanceTo);
    }
  }

  void _beginMorphToPlay(CubeFace face) {
    if (_isMorphing) return;
    setState(() {
      _morphFace = face;
      _morphToPlay = true;
      _isMorphing = true;
    });
    _morphController.forward(from: 0);
  }

  /// [autoAdvanceTo] is set only by [_handleFaceCompleted]'s automatic
  /// sequence — an ordinary user-triggered pinch/tap-to-browse (the toggle
  /// button, [_onPlayScaleUpdate]) always calls this with no argument, and
  /// just idles in Browse View once the shrink finishes.
  void _beginMorphToBrowse({CubeFace? autoAdvanceTo}) {
    if (_isMorphing) return;
    final cubeState = ref.read(cubeGameControllerProvider);
    if (cubeState == null) return;
    _autoAdvanceTarget = autoAdvanceTo;
    setState(() {
      _morphFace = cubeState.activeFace;
      _morphToPlay = false;
      _isMorphing = true;
    });
    _morphController.forward(from: 0);
  }

  /// The "rotate" leg between [_beginMorphToBrowse]'s shrink and
  /// [_beginMorphToPlay]'s expand: animates the Browse camera from
  /// wherever it already is on to [face]'s canonical orientation, the
  /// same target [_jumpToFace] snaps to instantly for a manual tap — this
  /// is the same destination, just eased in over a beat so the player can
  /// actually see the cube turn to the next open face instead of it
  /// popping there.
  /// The face [_onAutoRotateStatusChanged] should expand once the rotation
  /// lands — tracked explicitly rather than re-derived from the camera
  /// angle at that point (e.g. via [CubeGeometry.mostFacingCamera]) so a
  /// razor-thin floating-point overshoot right at a canonical angle can
  /// never resolve to a different face than the one this rotation was
  /// actually aimed at.
  CubeFace? _pendingExpandFace;

  void _beginAutoRotateTo(CubeFace face) {
    final target = CubeGeometry.canonicalOrientation(face);
    _rotateStartYaw = _browseYaw;
    _rotateStartPitch = _browsePitch;
    _rotateTargetYaw = CubeGeometry.unwrappedTarget(_browseYaw, target.yaw);
    _rotateTargetPitch = CubeGeometry.unwrappedTarget(
      _browsePitch,
      target.pitch,
    );
    _pendingExpandFace = face;
    _autoRotateController.forward(from: 0);
  }

  void _onAutoRotateTick() {
    final t = Curves.easeInOutCubic.transform(_autoRotateController.value);
    setState(() {
      _browseYaw = lerpDouble(_rotateStartYaw, _rotateTargetYaw, t)!;
      _browsePitch = lerpDouble(_rotateStartPitch, _rotateTargetPitch, t)!;
    });
  }

  void _onAutoRotateStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final face = _pendingExpandFace;
    _pendingExpandFace = null;
    // The rotation landed exactly on the target face's canonical angle, so
    // this expand's own camera interpolation (see _buildMorphContent) has
    // nothing left to do but grow in place — no further turning.
    if (face != null) _beginMorphToPlay(face);
  }

  /// The next face after [after] (cycling through [CubeFace.values], the
  /// same fixed order the progress dots use) that isn't solved yet — the
  /// auto-advance destination once [after] itself is completed. Null only
  /// if every other face is already done too, in which case
  /// `cubeState.isComplete` is true and the completion screen (see the
  /// `ref.listen` in [build]) takes over instead of this ever running.
  CubeFace? _nextIncompleteFace(
    CubeGameState cubeState, {
    required CubeFace after,
  }) {
    const values = CubeFace.values;
    final startIndex = values.indexOf(after);
    for (var i = 1; i <= values.length; i++) {
      final candidate = values[(startIndex + i) % values.length];
      if (cubeState.faceState(candidate).status != GameStatus.completed) {
        return candidate;
      }
    }
    return null;
  }

  /// Reacts to [completedFace] just being solved while the cube itself
  /// isn't (that overall-completion case is handled separately by
  /// [_navigateToCompletion]): moves the player on to the next open face
  /// automatically, so they never have to manually back out to Browse
  /// View and pick one themselves.
  ///
  /// In the 3D cube experience this is the shrink → rotate → expand
  /// sequence described on [CubeGameScreen]'s own doc comment. Outside it
  /// — the flat carousel, or `forceFlat` for reduced-motion/screen-reader
  /// sessions — there's no cube to animate, so it's just a plain page
  /// switch after a short pause to let the completed board register.
  void _handleFaceCompleted(CubeFace completedFace, CubeGameState cubeState) {
    final next = _nextIncompleteFace(cubeState, after: completedFace);
    if (next == null) return;

    if (!_showingCubeExperience) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        ref.read(cubeGameControllerProvider.notifier).setActiveFace(next);
        final controller = _pageController;
        if (controller == null) return;
        if (_forceFlat) {
          controller.jumpToPage(CubeFace.values.indexOf(next));
        } else {
          controller.animateToPage(
            CubeFace.values.indexOf(next),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
      return;
    }

    if (_isMorphing || _isAutoAdvancing || _mode != _CubeMode.play) return;
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      if (_isMorphing || _isAutoAdvancing || _mode != _CubeMode.play) return;
      setState(() => _isAutoAdvancing = true);
      _beginMorphToBrowse(autoAdvanceTo: next);
    });
  }

  double get _morphProgress {
    if (!_isMorphing) return _mode == _CubeMode.play ? 1.0 : 0.0;
    final eased = Curves.easeInOutCubic.transform(_morphController.value);
    return _morphToPlay ? eased : 1 - eased;
  }

  // Selecting a face is detected from *within* the scale gesture's own
  // lifecycle (near-zero total movement + release) rather than a sibling
  // `onTap` on the same GestureDetector — combining a tap recognizer and a
  // scale/pan recognizer on one detector is a known-flaky pairing in
  // Flutter (the scale recognizer tends to claim the pointer before the
  // tap recognizer gets a chance to), whereas tracking movement inside
  // the gesture that already owns the pointer is unambiguous.
  double _browseGestureMovement = 0;

  /// True for the duration of a Browse drag — [_buildBrowseContent] shrinks
  /// the cube while this is set (see the doc there) so a face's
  /// perspective enlargement (see [CubeGeometry.perspective]) can never
  /// carry it past the edges of the screen while it's actively being spun,
  /// even though nothing clips it anymore.
  bool _isRotating = false;

  void _onBrowseScaleStart(ScaleStartDetails details) {
    if (_isAutoAdvancing) return;
    _pinchTriggered = false;
    _multiTouchUsed = false;
    _browseGestureMovement = 0;
    _rollAtGestureStart = _browseRoll;
    setState(() => _isRotating = true);
  }

  void _onBrowseScaleUpdate(ScaleUpdateDetails details) {
    if (_isMorphing || _isAutoAdvancing) return;
    _browseGestureMovement += details.focalPointDelta.distance;
    if (details.pointerCount >= 2) {
      _multiTouchUsed = true;
      if (!_pinchTriggered && details.scale > 1.18) {
        _pinchTriggered = true;
        _beginMorphToPlay(
          CubeGeometry.mostFacingCamera(_browseYaw, _browsePitch),
        );
        return;
      }
      setState(() {
        _browseRoll = _rollAtGestureStart + details.rotation;
      });
      return;
    }
    setState(() {
      _browseYaw += details.focalPointDelta.dx * 0.006;
      _browsePitch = (_browsePitch - details.focalPointDelta.dy * 0.006).clamp(
        -math.pi / 2,
        math.pi / 2,
      );
    });
  }

  void _onBrowseScaleEnd(ScaleEndDetails details) {
    setState(() => _isRotating = false);
    if (_isMorphing || _isAutoAdvancing || _pinchTriggered || _multiTouchUsed) {
      return;
    }
    if (_browseGestureMovement < 8) {
      _beginMorphToPlay(
        CubeGeometry.mostFacingCamera(_browseYaw, _browsePitch),
      );
    }
  }

  void _onPlayScaleStart(ScaleStartDetails details) {
    _pinchTriggered = false;
  }

  void _onPlayScaleUpdate(ScaleUpdateDetails details) {
    if (_isMorphing || _isAutoAdvancing) return;
    if (details.pointerCount >= 2 && !_pinchTriggered && details.scale < 0.82) {
      _pinchTriggered = true;
      _beginMorphToBrowse();
    }
  }

  void _onPageChanged(int index) {
    final face = CubeFace.values[index];
    ref.read(cubeGameControllerProvider.notifier).setActiveFace(face);
    setState(() => _selectionEpoch++);
    // The flat carousel is what screen-reader/reduced-motion sessions get
    // instead of the gesture-driven 3D Browse View (see forceFlat above) —
    // swiping between pages is otherwise a silent visual change with
    // nothing to tell a screen-reader user which face they landed on.
    SemanticsService.announce('${face.displayName} face', TextDirection.ltr);
  }

  /// Which face the status bar (and the progress dots' active marker)
  /// currently describes: whichever face is being morphed, whichever is
  /// front-most while browsing, or otherwise the controller's own active
  /// face — the same face a player is actually looking at in every mode.
  CubeFace _statusFace(WidgetRef ref) {
    if (_isMorphing && _morphFace != null) return _morphFace!;
    if (_showingCubeExperience && _mode == _CubeMode.browse) {
      return CubeGeometry.mostFacingCamera(_browseYaw, _browsePitch);
    }
    return ref.watch(cubeGameControllerProvider.select((s) => s!.activeFace));
  }

  /// The progress dots' "jump to this face" action — behavior depends on
  /// which surface is currently showing: an instant face switch in Play
  /// or the flat carousel, an instant look-at in Browse (no need to
  /// morph just to glance at a different face).
  void _jumpToFace(CubeFace face) {
    if (!_showingCubeExperience) {
      ref.read(cubeGameControllerProvider.notifier).setActiveFace(face);
      _pageController?.animateToPage(
        CubeFace.values.indexOf(face),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (_isMorphing || _isAutoAdvancing) return;
    if (_mode == _CubeMode.browse) {
      final target = CubeGeometry.canonicalOrientation(face);
      setState(() {
        _browseYaw = CubeGeometry.unwrappedTarget(_browseYaw, target.yaw);
        _browsePitch = CubeGeometry.unwrappedTarget(_browsePitch, target.pitch);
      });
    } else {
      ref.read(cubeGameControllerProvider.notifier).setActiveFace(face);
      setState(() => _selectionEpoch++);
    }
  }

  /// Pauses the cube timer and blurs/shrinks whatever puzzle content is
  /// currently showing (Play, Browse, or the flat carousel — see
  /// [_isPaused]'s use in `build`) while the pause sheet is up. Doesn't
  /// interrupt an in-flight morph/auto-advance rather than fight it for the
  /// same content; those are quick (well under a second) and the pause
  /// button/back-gesture remain available the instant they finish.
  void _showPauseSheet() {
    if (_isMorphing || _isAutoAdvancing) return;
    setState(() => _isPaused = true);
    ref.read(cubeTimerControllerProvider).pause();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // CubePauseSheet draws its own drag handle as part of its glass sheet
      // — see the identical fix (and why it's needed) on the regular
      // game's _showPauseOverlay in game_screen.dart.
      showDragHandle: false,
      builder: (context) => const CubePauseSheet(),
    ).whenComplete(() {
      if (!mounted) return;
      setState(() => _isPaused = false);
      ref.read(cubeTimerControllerProvider).resume();
    });
  }

  // Same top-bar shortcuts as the regular single-puzzle screen's
  // GameTopBar — duplicated rather than reused because that widget pauses
  // and resumes the single-puzzle timerControllerProvider, not this
  // screen's separate cubeTimerControllerProvider.
  Future<void> _visit(BuildContext context, WidgetRef ref, String route) async {
    ref.read(cubeTimerControllerProvider).pause();
    await context.push(route);
    if (mounted) ref.read(cubeTimerControllerProvider).resume();
  }

  void _cycleTheme(BuildContext context, WidgetRef ref) {
    const order = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
    final current = ref.read(settingsProvider).themeMode;
    final next = order[(order.indexOf(current) + 1) % order.length];
    ref.read(settingsProvider.notifier).updateThemeMode(next);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme: ${next.name.capitalize()}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _navigateToCompletion() {
    if (_hasNavigatedToCompletion) return;
    _hasNavigatedToCompletion = true;
    ref.read(cubeTimerControllerProvider).pause();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(AppRoutes.cubeCompletion);
    });
  }

  /// Just the board — no header. The face name/difficulty/mistakes live in
  /// one persistent, screen-aligned status bar above the cube instead (see
  /// `_StatusBar`), never inside this 3D-transformed content: baking that
  /// text into the rotated/scaled cube-face widget is exactly what made it
  /// tilt and shrink into illegibility in Browse View, the same way a real
  /// product's on-screen HUD is never part of the 3D scene it's overlaid
  /// on.
  Widget _buildFaceContent(
    BuildContext context,
    CubeFace face, {
    required bool isInteractive,
  }) {
    return Consumer(
      builder: (context, ref, _) {
        final faceState = ref.watch(
          cubeGameControllerProvider.select((s) => s!.faceState(face)),
        );
        final showPencilMarks = ref.watch(showPencilMarksProvider);
        // IgnorePointer, not just a no-op onCellTap: every cell has its
        // own live InkWell regardless of isInteractive, and a tap almost
        // always lands directly on one. Left to just no-op the callback,
        // that InkWell still wins the gesture arena over the ancestor
        // GestureDetector's onScale* (the one this exists to let through
        // — see _onBrowseScaleEnd's tap-to-open-face detection), so the
        // tap gets silently swallowed instead of ever opening the face.
        // Excluding the whole board from hit-testing is what actually
        // lets the ancestor see it.
        return IgnorePointer(
          ignoring: !isInteractive,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingSm,
            ),
            child: CubeFaceBoard(
              face: face,
              gameState: faceState,
              showPencilMarks: showPencilMarks,
              selectionEpoch: _selectionEpoch,
              onCellTap: (row, col) {
                ref
                    .read(cubeGameControllerProvider.notifier)
                    .selectCell(face, row, col);
              },
              onCellLongPress: (row, col) {},
              onRetry:
                  () => ref
                      .read(cubeGameControllerProvider.notifier)
                      .retryFace(face),
            ),
          ),
        );
      },
    );
  }

  /// [_buildFaceContent] laid out at [_kContentDesignSize], given an
  /// opaque fill behind it, and scaled to whatever box it's given — what
  /// Browse View and the morph both use so a face reads correctly shrunk
  /// onto the cube instead of reflowing its header/board layout at
  /// arbitrary small sizes.
  ///
  /// [backgroundColor] filling the *entire* design square (not just the
  /// board itself) is what makes the assembled cube read as gapless:
  /// every face is the same solid color edge-to-edge, so the margin left
  /// by the board's own inset padding — and the shared edge between two
  /// adjacent faces — both come out looking continuous instead of
  /// revealing whatever sits behind the cube. The morph fades this to
  /// transparent as a face grows into Play View, which never paints a
  /// background of its own here.
  Widget _scaledFaceContent(
    BuildContext context,
    CubeFace face, {
    required bool isInteractive,
    required Color backgroundColor,
  }) {
    return FittedBox(
      fit: BoxFit.contain,
      child: Container(
        width: _kContentDesignSize,
        height: _kContentDesignSize,
        color: backgroundColor,
        child: _buildFaceContent(context, face, isInteractive: isInteractive),
      ),
    );
  }

  double _browseCubeSize(BoxConstraints constraints) {
    final available = math.min(constraints.maxWidth, constraints.maxHeight);
    return (available * 0.66).clamp(160.0, 380.0);
  }

  double _playContentSize(BoxConstraints constraints) {
    return math.min(constraints.maxWidth, constraints.maxHeight);
  }

  @override
  Widget build(BuildContext context) {
    final hasSession = ref.watch(
      cubeGameControllerProvider.select((s) => s != null),
    );

    ref.listen<CubeGameState?>(cubeGameControllerProvider, (previous, next) {
      if (next == null) return;
      if (next.isComplete && previous?.isComplete != true) {
        _navigateToCompletion();
      } else if (previous != null && !next.isComplete) {
        // Only one face can transition to completed per update — the
        // active face is the only one gameplay ever mutates — but this
        // scans all six rather than assuming it's `next.activeFace`,
        // since retryFace/undo elsewhere in this file can also change a
        // face's status without it being the active one.
        for (final face in CubeFace.values) {
          final wasCompleted =
              previous.faceState(face).status == GameStatus.completed;
          final isCompleted =
              next.faceState(face).status == GameStatus.completed;
          if (!wasCompleted && isCompleted) {
            _handleFaceCompleted(face, next);
            break;
          }
        }
      }
      // Restarts the blue selection highlight's fade-in (see
      // SudokuBoard's doc on selectionEpoch) every time a tap actually
      // changes which cell is selected — not just when the active face
      // itself changes (the three explicit `_selectionEpoch++` calls
      // elsewhere in this file). Without this, a cell tapped more than a
      // few seconds after its face was opened landed on a board whose
      // per-cell fade timers — running ever since that face last got a
      // fresh selectionEpoch — had already decayed to nothing, so the
      // newly selected cell never visibly highlighted.
      if (next.activeFaceState.selectedCell !=
          previous?.activeFaceState.selectedCell) {
        setState(() => _selectionEpoch++);
      }
    });

    if (!hasSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final forceFlat =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
    _forceFlat = forceFlat;
    final manualShow3D = ref.watch(show3DCubeProvider);
    final showingCube = !forceFlat && manualShow3D;

    if (_showingCubeExperience && !showingCube) {
      _pageController?.dispose();
      _pageController = null;
    }
    _showingCubeExperience = showingCube;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showPauseSheet();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerHighest,
        body: SafeArea(
          child: Column(
            children: [
              GlassSurface(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                  vertical: AppConstants.spacingSm,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                  vertical: AppConstants.spacingSm,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _DockIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Pause',
                          onTap: _showPauseSheet,
                        ),
                        if (!forceFlat) ...[
                          const SizedBox(width: AppConstants.spacingSm),
                          _DockIconButton(
                            icon:
                                showingCube
                                    ? Icons.view_agenda_rounded
                                    : Icons.view_in_ar_rounded,
                            tooltip:
                                showingCube
                                    ? 'Switch to flat view'
                                    : 'Switch to 3D cube',
                            onTap:
                                () =>
                                    ref
                                        .read(show3DCubeProvider.notifier)
                                        .state = !manualShow3D,
                          ),
                          if (showingCube) ...[
                            const SizedBox(width: AppConstants.spacingSm),
                            _DockIconButton(
                              icon:
                                  _mode == _CubeMode.play
                                      ? Icons.view_in_ar_outlined
                                      : Icons.grid_on_rounded,
                              tooltip:
                                  _mode == _CubeMode.play
                                      ? 'View the cube'
                                      : 'Back to puzzle',
                              onTap:
                                  _isMorphing || _isAutoAdvancing
                                      ? () {}
                                      : (_mode == _CubeMode.play
                                          ? _beginMorphToBrowse
                                          : () => _beginMorphToPlay(
                                            CubeGeometry.mostFacingCamera(
                                              _browseYaw,
                                              _browsePitch,
                                            ),
                                          )),
                            ),
                          ],
                        ],
                        const Spacer(),
                        _DockIconButton(
                          icon: Icons.palette_outlined,
                          tooltip: 'Theme',
                          onTap: () => _cycleTheme(context, ref),
                        ),
                        _DockIconButton(
                          icon: Icons.leaderboard_rounded,
                          tooltip: 'Statistics',
                          onTap:
                              () => _visit(context, ref, AppRoutes.statistics),
                        ),
                        _DockIconButton(
                          icon: Icons.settings_rounded,
                          tooltip: 'Settings',
                          onTap: () => _visit(context, ref, AppRoutes.settings),
                        ),
                      ],
                    ),
                    Divider(
                      height: AppConstants.spacingMd,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final progress = ref.watch(
                          cubeGameControllerProvider.select(
                            (s) => (
                              activeFace:
                                  _showingCubeExperience &&
                                          _mode == _CubeMode.browse
                                      ? CubeGeometry.mostFacingCamera(
                                        _browseYaw,
                                        _browsePitch,
                                      )
                                      : s!.activeFace,
                              statuses: {
                                for (final f in CubeFace.values)
                                  f: s!.faceState(f).status,
                              },
                            ),
                          ),
                        );
                        return CubeProgressIndicator(
                          faceStatuses: progress.statuses,
                          activeFace: progress.activeFace,
                          onFaceTap: _jumpToFace,
                        );
                      },
                    ),
                    Divider(
                      height: AppConstants.spacingMd,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final statusFace = _statusFace(ref);
                        final status = ref.watch(
                          cubeGameControllerProvider.select(
                            (s) => (
                              faceState: s!.faceState(statusFace),
                              timeElapsed: s.timeElapsed,
                            ),
                          ),
                        );
                        return _StatusBar(
                          face: statusFace,
                          faceState: status.faceState,
                          timeElapsed: status.timeElapsed,
                          onPause: _showPauseSheet,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Expanded(
                child: PausableBlur(
                  paused: _isPaused,
                  child:
                      !showingCube
                          ? Consumer(
                            builder: (context, ref, _) {
                              final activeFace = ref.watch(
                                cubeGameControllerProvider.select(
                                  (s) => s!.activeFace,
                                ),
                              );
                              return PageView.builder(
                                controller: _flatController(activeFace),
                                onPageChanged: _onPageChanged,
                                itemCount: CubeFace.values.length,
                                itemBuilder: (context, index) {
                                  final face = CubeFace.values[index];
                                  return Semantics(
                                    container: true,
                                    label: '${face.displayName} face',
                                    child: _buildFaceContent(
                                      context,
                                      face,
                                      isInteractive: true,
                                    ),
                                  );
                                },
                              );
                            },
                          )
                          : AnimatedBuilder(
                            animation: _morphController,
                            builder: (context, _) {
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  if (_isMorphing) {
                                    return _buildMorphContent(
                                      context,
                                      constraints,
                                    );
                                  }
                                  if (_mode == _CubeMode.browse) {
                                    return _buildBrowseContent(
                                      context,
                                      constraints,
                                    );
                                  }
                                  return _buildPlayContent(context);
                                },
                              );
                            },
                          ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              if (showingCube)
                Opacity(
                  opacity: _morphProgress,
                  child: IgnorePointer(
                    ignoring: _morphProgress < 0.98,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingSm,
                      ),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final activeFace = ref.watch(
                            cubeGameControllerProvider.select(
                              (s) => s!.activeFace,
                            ),
                          );
                          return CubeNumberPad(face: activeFace);
                        },
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSm,
                  ),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final activeFace = ref.watch(
                        cubeGameControllerProvider.select((s) => s!.activeFace),
                      );
                      return CubeNumberPad(face: activeFace);
                    },
                  ),
                ),
              const SizedBox(height: AppConstants.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayContent(BuildContext context) {
    return GestureDetector(
      onScaleStart: _onPlayScaleStart,
      onScaleUpdate: _onPlayScaleUpdate,
      child: Consumer(
        builder: (context, ref, _) {
          final activeFace = ref.watch(
            cubeGameControllerProvider.select((s) => s!.activeFace),
          );
          return _buildFaceContent(context, activeFace, isInteractive: true);
        },
      ),
    );
  }

  Widget _buildBrowseContent(BuildContext context, BoxConstraints constraints) {
    final gridColor =
        Theme.of(context).extension<AppThemeExtension>()!.gridBackgroundColor;
    return GestureDetector(
      onScaleStart: _onBrowseScaleStart,
      onScaleUpdate: _onBrowseScaleUpdate,
      onScaleEnd: _onBrowseScaleEnd,
      // Shrinking here, as a flat post-transform scale on the whole
      // already-rendered cube, is what actually guarantees it stays on
      // screen while being dragged — nothing in here clips anymore (see
      // CubeBrowseView's doc on Stack's default clipBehavior), and a face
      // near dead-on can paint well past its own nominal cubeSize (see
      // CubeGeometry.perspective), so shrinking cubeSize itself would
      // still need to guess how much enlargement to budget for at every
      // possible angle. Scaling the finished result down instead reins
      // in that enlargement too, by construction, however large it gets.
      child: AnimatedScale(
        scale: _isRotating ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: CubeBrowseView(
          yaw: _browseYaw,
          pitch: _browsePitch,
          roll: _browseRoll,
          cubeSize: _browseCubeSize(constraints),
          faceBuilder:
              (context, face) => _scaledFaceContent(
                context,
                face,
                isInteractive: false,
                backgroundColor: gridColor,
              ),
        ),
      ),
    );
  }

  Widget _buildMorphContent(BuildContext context, BoxConstraints constraints) {
    final face = _morphFace!;
    final progress = _morphProgress;
    final target = CubeGeometry.canonicalOrientation(face);
    final yaw =
        lerpDouble(
          _browseYaw,
          CubeGeometry.unwrappedTarget(_browseYaw, target.yaw),
          progress,
        )!;
    final pitch =
        lerpDouble(
          _browsePitch,
          CubeGeometry.unwrappedTarget(_browsePitch, target.pitch),
          progress,
        )!;
    final perspective = lerpDouble(CubeGeometry.perspective, 0.0, progress)!;
    final browseSize = _browseCubeSize(constraints);
    final playSize = _playContentSize(constraints);
    final size = lerpDouble(browseSize, playSize, progress)!;
    // The morphing face's own opaque fill fades out as it grows into Play
    // View, which paints no background of its own here — a hard cut would
    // pop, so this fades in step with everything else about the morph.
    final gridColor =
        Theme.of(context).extension<AppThemeExtension>()!.gridBackgroundColor;
    final morphingFaceBackground =
        Color.lerp(gridColor, gridColor.withValues(alpha: 0), progress)!;

    // No ClipRect and no Stack clipBehavior here either — see the doc on
    // CubeBrowseView.build for why Stack's default hard-edge clip crops a
    // near-dead-on face's perspective-enlarged paint and reads as a mask,
    // regardless of how the layout box around it is sized.
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        for (final other in CubeFace.values.where((f) => f != face))
          if (CubeGeometry.worldNormal(other, _browseYaw, _browsePitch).z >
              CubeGeometry.cullThreshold)
            _buildStillFace(context, other, browseSize, 1 - progress),
        Transform(
          alignment: Alignment.center,
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, perspective)
                ..rotateY(yaw)
                ..rotateX(pitch)
                ..multiply(CubeGeometry.fixedRotationMatrix4(face))
                ..translate(0.0, 0.0, size / 2),
          child: SizedBox(
            width: size,
            height: size,
            child: _scaledFaceContent(
              context,
              face,
              isInteractive: progress > 0.98,
              backgroundColor: morphingFaceBackground,
            ),
          ),
        ),
      ],
    );
  }

  /// A non-morphing face during the transition — stays fixed at the
  /// browse camera's angle throughout, only its opacity animating (fading
  /// out toward Play, in toward Browse) as the selected face grows or
  /// shrinks in front of it.
  Widget _buildStillFace(
    BuildContext context,
    CubeFace face,
    double browseSize,
    double opacityFactor,
  ) {
    final normalZ = CubeGeometry.worldNormal(face, _browseYaw, _browsePitch).z;
    final baseOpacity = ((normalZ + 1) / 2).clamp(0.4, 1.0);
    final gridColor =
        Theme.of(context).extension<AppThemeExtension>()!.gridBackgroundColor;

    return Opacity(
      opacity: baseOpacity * opacityFactor,
      child: Transform(
        alignment: Alignment.center,
        transform:
            Matrix4.identity()
              ..setEntry(3, 2, CubeGeometry.perspective)
              ..rotateY(_browseYaw)
              ..rotateX(_browsePitch)
              ..multiply(CubeGeometry.fixedRotationMatrix4(face))
              ..translate(0.0, 0.0, browseSize / 2),
        child: SizedBox(
          width: browseSize,
          height: browseSize,
          child: _scaledFaceContent(
            context,
            face,
            isInteractive: false,
            backgroundColor: gridColor,
          ),
        ),
      ),
    );
  }
}

String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

/// A plain icon sitting directly on the merged glass dock's own material —
/// the dock is already one floating glass surface, so a second layer of
/// per-icon circular chips would just be redundant chrome (see the
/// regular game's identical `_DockIconButton` in `game_top_bar.dart`).
class _DockIconButton extends StatelessWidget {
  const _DockIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 22, color: colorScheme.onSurfaceVariant),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// The face name/difficulty/mistakes/timer readout — always flat and
/// screen-aligned, sitting above the cube/board area rather than inside
/// it. Shown for whichever face is currently relevant: the active face in
/// Play or the flat carousel, or whichever face is front-most in Browse
/// View (see `_statusFace`), updating live as the player drags. Laid out
/// the same way as the single-puzzle screen's GameHeader — difficulty,
/// mistakes, timer, then pause.
///
/// Content only, deliberately — it renders inside the same `GlassSurface`
/// dock as the top icon row and `CubeProgressIndicator` (see
/// `CubeGameScreen`), so it no longer owns its own card decoration.
class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.face,
    required this.faceState,
    required this.timeElapsed,
    required this.onPause,
  });

  final CubeFace face;
  final GameState faceState;
  final int timeElapsed;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Text(
          '${face.displayName} · ${faceState.difficulty.displayName}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          'Mistakes: ${faceState.mistakes}/3',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color:
                faceState.status == GameStatus.failed
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          _formatTime(timeElapsed),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        IconButton(
          onPressed: onPause,
          icon: const Icon(Icons.pause_rounded),
          tooltip: 'Pause',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

extension _ThemeModeCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
