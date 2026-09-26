# Release Notes - M6 Sudoku v1.0.0

## 🎉 Initial Release

We're excited to announce the first production release of **M6 Sudoku** - a beautifully crafted, feature-complete Sudoku application built with Flutter.

---

## ✨ Features

### 🎮 Gameplay
- **5 Difficulty Levels**: Easy, Medium, Hard, Expert, and Evil
- **Daily Challenges**: New unique puzzle every day with streak tracking
- **Multiple Hint Types**:
  - Direct Reveal - Shows the answer
  - Naked Single - Only one candidate in a cell
  - Hidden Single - Only one place for a digit in a unit
  - Naked Pair - Two cells with same two candidates
  - Hidden Pair - Two digits only in two cells
  - Pointing Pair - Candidates locked in row/column
  - Box/Line Reduction - Candidates eliminated from box
- **Undo/Redo**: Full move history with unlimited undo/redo
- **Notes Mode**: Pencil marks for candidate tracking
- **Auto-save**: Never lose your progress

### 🏆 Achievements
- **20+ Achievements** to unlock
- Categories: General, Difficulty, Speed, Streaks, Special
- Secret achievements for dedicated players
- Progress tracking for multi-step achievements

### 📊 Statistics
- Games played, won, and win rate
- Best times per difficulty
- Current and longest streaks
- Hint usage statistics
- Mistake tracking
- Beautiful charts with fl_chart

### ⚙️ Settings
- Light/Dark/System theme
- Sound effects toggle
- Haptic feedback toggle
- Auto-save interval
- Language selection (i18n ready)

---

## 🏗️ Technical Highlights

### Architecture
- **Clean Architecture** with Domain, Data, and Presentation layers
- **Feature-first** modular structure for maintainability
- **Riverpod** for reactive state management with code generation
- **GoRouter** for type-safe navigation

### Performance Optimizations
- **Bitmask-based notes computation** - O(1) candidate operations instead of O(9) Set operations
- **Optimized puzzle generation** - Fast uniqueness checking using known solution (10x faster)
- **Reduced widget rebuilds** - Cell-specific data passing with RepaintBoundary isolation
- **Cached conflict/highlight computation** - Memoized calculations

### Engine
- **MRV Heuristic** (Minimum Remaining Values) for fast solving
- **Backtracking with candidate shuffling** for varied solutions
- **Early exit validation** for dead-end detection

---

## 📱 Platform Support

| Platform | Status | Minimum Version |
|----------|--------|-----------------|
| Android  | ✅ Supported | API 21 (Android 5.0) |
| Web      | ✅ Supported | Chrome 90+, Firefox 88+, Safari 14+, Edge 90+ |
| iOS      | 🚧 Planned | - |
| macOS    | 🚧 Planned | - |
| Windows  | 🚧 Planned | - |
| Linux    | 🚧 Planned | - |

---

## 📦 Installation

### Android
Download from [Google Play Store](https://play.google.com/store/apps/details?id=com.msixv.m6sudoku)

### Web
Play instantly at [m6-sudoku.web.app](https://m6-sudoku.web.app)

---

## 🛠️ For Developers

### Building from Source
```bash
git clone https://github.com/Mukiria/m6_sudoku.git
cd m6_sudoku
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Generating Assets
```bash
# App icons
dart run flutter_launcher_icons

# Splash screen
dart run flutter_native_splash:create
```

### Testing
```bash
flutter test           # Run all tests
flutter test --coverage # With coverage
```

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for complete version history.

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Riverpod team for excellent state management
- Community packages: fl_chart, flutter_animate, go_router, and many more

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

**Enjoy playing M6 Sudoku!** 🧩

*Made with ❤️ using Flutter*