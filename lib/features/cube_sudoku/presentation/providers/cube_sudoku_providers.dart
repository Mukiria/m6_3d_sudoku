import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m6_sudoku/features/cube_sudoku/data/datasources/cube_game_local_datasource.dart';
import 'package:m6_sudoku/features/cube_sudoku/data/repositories/cube_game_repository_impl.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/repositories/cube_game_repository.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/usecases/cube_achievement_usecases.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/usecases/cube_game_usecases.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart'
    show
        puzzleBankSourceProvider,
        puzzleGeneratorProvider,
        storageServiceProvider;

// Shares the regular game's storage service, puzzle generator and puzzle
// bank instances
// (see sudoku_providers.dart) rather than standing up its own — a cube
// session is a second, independently-keyed save (see
// CubeGameLocalDataSource), not a second storage backend.
final cubeGameLocalDataSourceProvider = Provider<CubeGameLocalDataSource>((
  ref,
) {
  final storage = ref.read(storageServiceProvider);
  final generator = ref.read(puzzleGeneratorProvider);
  final bank = ref.read(puzzleBankSourceProvider);
  return CubeGameLocalDataSource(storage, generator, bank);
});

final cubeGameRepositoryProvider = Provider<CubeGameRepository>((ref) {
  final dataSource = ref.read(cubeGameLocalDataSourceProvider);
  return CubeGameRepositoryImpl(dataSource);
});

final generateCubePuzzlesUseCaseProvider = Provider<GenerateCubePuzzlesUseCase>(
  (ref) {
    final repo = ref.read(cubeGameRepositoryProvider);
    return GenerateCubePuzzlesUseCase(repo);
  },
);

final getCubeGameStateUseCaseProvider = Provider<GetCubeGameStateUseCase>((
  ref,
) {
  final repo = ref.read(cubeGameRepositoryProvider);
  return GetCubeGameStateUseCase(repo);
});

final saveCubeGameStateUseCaseProvider = Provider<SaveCubeGameStateUseCase>((
  ref,
) {
  final repo = ref.read(cubeGameRepositoryProvider);
  return SaveCubeGameStateUseCase(repo);
});

final clearCubeGameStateUseCaseProvider = Provider<ClearCubeGameStateUseCase>((
  ref,
) {
  final repo = ref.read(cubeGameRepositoryProvider);
  return ClearCubeGameStateUseCase(repo);
});

final evaluateCubeAchievementDeltasUseCaseProvider =
    Provider<EvaluateCubeAchievementDeltasUseCase>((ref) {
      return EvaluateCubeAchievementDeltasUseCase();
    });
