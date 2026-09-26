# M6 Sudoku

A production-ready Flutter Sudoku application built with Clean Architecture, Feature-first architecture, Riverpod, and GoRouter.

## Features

- **Clean Architecture**: Separation of concerns with Domain, Data, and Presentation layers
- **Feature-first Structure**: Modular feature-based organization
- **Riverpod**: Modern state management with code generation
- **GoRouter**: Declarative routing with deep linking support
- **Material 3**: Latest Material Design with dynamic theming
- **Light & Dark Themes**: Full theme support with system preference
- **Shared Preferences**: Local data persistence
- **Responsive Layout**: Works on phones, tablets, and web
- **Animations**: Smooth animations with flutter_animate
- **Null Safety**: Full null safety compliance
- **No Deprecated APIs**: Uses latest Flutter 3.24+ APIs
- **Daily Challenges**: New puzzle every day
- **Achievements**: Unlock achievements as you play
- **Statistics**: Track your progress and performance
- **Hints System**: Multiple hint types with explanations
- **Undo/Redo**: Full move history support
- **Auto-save**: Never lose your progress

## Screenshots

| Light Theme | Dark Theme |
|-------------|------------|
| ![Light](docs/screenshots/light.png) | ![Dark](docs/screenshots/dark.png) |

## Download

- **Android**: [Google Play Store](https://play.google.com/store/apps/details?id=com.msixv.m6sudoku)
- **Web**: [Play Online](https://m6-sudoku.web.app)

## Architecture

```
lib/
├── core/
│   ├── constants/      # App constants
│   ├── di/             # Dependency injection
│   ├── errors/         # Failures and exceptions
│   ├── extensions/     # Dart extensions
│   ├── routing/        # GoRouter configuration
│   ├── services/       # Core services (storage)
│   ├── theme/          # Theme configuration
│   └── utils/          # Utility classes
├── features/
│   ├── home/           # Home screen
│   ├── sudoku/         # Main game feature
│   │   ├── data/       # Data layer
│   │   ├── domain/     # Domain layer
│   │   └── presentation/  # UI layer
│   ├── settings/       # Settings feature
│   └── statistics/     # Statistics feature
├── shared/
│   └── widgets/        # Shared UI components
└── main.dart           # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK 3.24+
- Dart SDK 3.3+
- Android Studio / VS Code

### Installation

```bash
# Clone the repository
git clone https://github.com/Mukiria/m6_sudoku.git

# Navigate to project
cd m6_sudoku

# Get dependencies
flutter pub get

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

## Commands

```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Build release APK
flutter build apk --release

# Build release iOS
flutter build ios --release

# Build release web
flutter build web --release

# Generate code (after changes)
dart run build_runner build --delete-conflicting-outputs

# Generate app icons
dart run flutter_launcher_icons

# Generate splash screen
dart run flutter_native_splash:create
```

## Project Structure

### Core Layer
- **Constants**: App-wide constants
- **DI**: Dependency injection setup
- **Errors**: Failure and exception classes
- **Extensions**: Dart extension methods
- **Routing**: GoRouter configuration
- **Services**: Shared services (Storage)
- **Theme**: Material 3 theme with custom extensions
- **Utils**: Utility classes (Either, Equatable)

### Features
Each feature follows Clean Architecture:
- **Domain**: Entities, Repository interfaces, Use cases
- **Data**: Repository implementations, Data sources
- **Presentation**: Providers, Widgets, Screens

### Shared
Reusable widgets, components, and utilities.

## Dependencies

### Production
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `shared_preferences` - Local storage
- `freezed_annotation` - Immutable data classes
- `json_annotation` - JSON serialization
- `equatable` - Value equality
- `dartz` - Functional programming (Either)
- `google_fonts` - Custom fonts
- `flutter_animate` - Animations
- `fl_chart` - Charts for statistics

### Development
- `flutter_lints` - Linting rules
- `riverpod_generator` - Riverpod code generation
- `custom_lint` - Custom lint rules
- `riverpod_lint` - Riverpod specific lints
- `build_runner` - Code generation
- `freezed` - Freezed code generation
- `json_serializable` - JSON serialization generation
- `mockito` - Mocking for tests
- `flutter_launcher_icons` - App icon generation
- `flutter_native_splash` - Splash screen generation

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG](CHANGELOG.md) for version history.

## Release Notes

See [RELEASE_NOTES](RELEASE_NOTES.md) for the latest release details.