# Google Play Store Listing — M6 3D Sudoku

Reference copy for the Play Console store listing form. Paste directly; nothing here needs editing unless the copy itself changes.

## Assets

All verified against Play Console's requirements (dimensions, format, no alpha on the icon).

| Asset | Path | Spec | Verified |
|---|---|---|---|
| Hi-res icon | `store_listing/images/m6_sudoku_logo.png` | 512×512, 32-bit PNG, no alpha | 512×512 PNG, no alpha ✓ |
| Feature graphic | `store_listing/images/m6-sudoku-feature-graphic.jpg` | 1024×500 JPG/PNG | 1024×500 ✓ |
| Screenshot 1 — 3D cube | `store_listing/images/Screenshot_3d_cube.jpg` | 16:9–9:16, 320–3840px | 1080×1920 ✓ |
| Screenshot 2 — 3D cube, front face | `store_listing/images/Screenshot_3d_cube-2.jpg` | 16:9–9:16, 320–3840px | 1080×1920 ✓ |
| Screenshot 3 — solving a face | `store_listing/images/Screenshot_game_play.jpg` | 16:9–9:16, 320–3840px | 1080×1920 ✓ |
| Screenshot 4 — home (dark mode) | `store_listing/images/Screenshot_homescreen_dark_mode.jpg` | 16:9–9:16, 320–3840px | 1080×1920 ✓ |
| Screenshot 5 — daily challenge | `store_listing/images/Screenshot_daily-challenge.jpg` | 16:9–9:16, 320–3840px | 1080×1920 ✓ |
| Screenshot 6 — statistics | `store_listing/images/Screenshot_statistics.jpg` | 16:9–9:16, 320–3840px | 1080×1920 ✓ |

Upload in this order: Play shows the first two or three in search results
and on the listing, so the cube leads. Store artwork lives in
`store_listing/images/`, outside `assets/`, so none of it is bundled into
the app. The older `m6-sudoku-*.jpg` screenshots there show the
pre-rebrand UI and are no longer used.

**Before uploading:**

- **Retake screenshot 6.** It was captured before the statistics tiles
  were fixed, and every label and value is truncated ("Ga…", "Cub…",
  "1…").
- **Screenshot 2 shows the phone's status bar** (clock, a WhatsApp
  notification icon, signal, 71% battery). Not a policy issue, but it
  looks unpolished next to screenshot 1; crop the top ~110px or retake
  with notifications cleared.
- ~~Feature graphic~~ redone 2026-09-26: "M6 3D Sudoku" logotype, cube,
  daily challenge and dark home screen.

## App name

(30 characters max — this one is 26)

```
M6 3D Sudoku: Cube Puzzles
```

The launcher label on the device is "M6 3D Sudoku"; the store title adds
"Cube Puzzles" for search. Play policy forbids words like "best", "#1",
"free" or "new" in the title.

## Short description

(80 characters max — this one is 78)

```
Classic Sudoku plus a 3D cube of six puzzles. Daily challenges, hints & stats.
```

## Full description

(4,000 characters max — this one is 1,953)

```
Sudoku, now in three dimensions.

M6 3D Sudoku gives you everything you expect from a great Sudoku game, plus something you won't find anywhere else: 3D Cube Sudoku, where six puzzles wrap around a cube you can spin in your hand.

3D CUBE SUDOKU
• Six 9×9 puzzles, one on each face of a rotatable 3D cube
• Drag to orbit the cube, twist with two fingers to spin it
• Tap a face to bring it forward and solve it full-screen
• Set a different difficulty for each face and build your own challenge
• Finish a face and the next one is ready to go
• Solve all six to complete the cube

CLASSIC SUDOKU
• Traditional 9×9 puzzles with a guaranteed single solution
• Five difficulty levels: Easy, Medium, Hard, Expert and Evil
• Notes mode for pencilling in candidates
• Undo and erase whenever you change your mind
• Highlighting for the selected row, column and box, and for mistakes

HINTS THAT TEACH
Stuck? A hint doesn't just fill in a number. It points to the next logical move and names the technique behind it, like Naked Single or Hidden Single, so you get better with every puzzle.

DAILY CHALLENGE
A fresh puzzle every day. Keep your streak going and make Sudoku part of your routine.

ACHIEVEMENTS & STATISTICS
Unlock achievements as you play, from your first win to conquering every difficulty. Track your best times, win rate, streaks and progress over time with detailed statistics and charts.

DESIGNED FOR FOCUS
• Clean, modern design with light and dark themes
• Sound effects that play alongside your own music
• Haptic feedback, with every option adjustable in Settings
• Pause at any time, and your game is saved automatically
• Close the app and pick up exactly where you left off

PLAY ANYWHERE
No account and no sign-up. Your games and progress are stored on your device, so you can play offline, anytime.

Exercise your mind with logic, pattern recognition and concentration, one cell at a time.

Download M6 3D Sudoku and start solving.
```

Claims were checked against the code (five difficulties incl. Evil,
per-face cube difficulty, drag/twist gestures, technique-naming hints,
auto-save/resume, stats incl. win rate and best times). It deliberately
says nothing about ads, so it stays accurate once AdMob is added — at
that point only the "Contains ads" declaration needs changing.

## Category and contact

- **App category:** Game › Puzzle
- **Tags:** Sudoku, Logic, Brain games (pick from Play's list)
- **Privacy policy:** https://msixv.com/games/m6-3d-sudoku/privacy-policy/
- **Email:** required — use a support address, it's shown publicly

## Still outstanding for submission

Data safety form, content rating questionnaire, target audience (13+),
and the internal testing upload — see docs/DEPLOYMENT.md §8.
