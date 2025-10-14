# Contributing to Cosmic Havoc

Thank you for your interest in contributing to Cosmic Havoc! 🚀

## � Project Overview

Cosmic Havoc is a 2D space shooter game built with Flutter and the Flame game engine.

```
lib/
├── main.dart              # Entry point
├── my_game.dart           # Main game class
├── components/            # Game components (player, asteroids, weapons, etc.)
├── overlays/              # UI overlays (menus, HUD)
└── managers/              # Game managers (audio, etc.)
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.24.0+)
- Dart SDK (3.6.0+)
- Android Studio or VS Code
- Git

### Setup

1. Fork this repository
2. Clone your fork:
    ```bash
    git clone https://github.com/YOUR_USERNAME/cosmic_havoc.git
    cd cosmic_havoc
    ```
3. Install dependencies:
    ```bash
    flutter pub get
    ```
4. Run the game:
    ```bash
    flutter run
    ```

## 📋 Development Workflow

### 1. Create a New Branch

```bash
git checkout develop
git checkout -b feature/your-feature-name
```

### Branch Naming Convention

- `feature/feature-name` - New features
- `fix/bug-description` - Bug fixes
- `refactor/component-name` - Code refactoring
- `docs/description` - Documentation updates

### 2. Development

- Follow Flame game engine best practices
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Write clear, commented code
- Run `flutter analyze` and fix warnings
- Run `dart format .` to format code

### 3. Testing

```bash
# Run all tests
flutter test

# Run on specific platform
flutter run -d android
flutter run -d chrome
flutter run -d windows
```

### 4. Commit Guidelines

Use clear commit messages:

```
feat: add new power-up type
fix: resolve collision detection issue
docs: update README with new controls
refactor: improve laser shooting logic
```

### 5. Pull Request Process

1. Push branch to your fork
2. Create Pull Request to main repository
3. Fill out PR template completely
4. Wait for code review
5. Address feedback if any
6. Merge after approval

## 🎮 Game Development Guidelines

### Adding New Components

When adding new game components (enemies, weapons, power-ups):

```dart
// components/new_component.dart
import 'package:flame/components.dart';

class NewComponent extends SpriteComponent 
    with HasGameReference<MyGame>, CollisionCallbacks {
  
  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('new_component.png');
    size = Vector2(50, 50);
    // Add collision detection, etc.
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    // Update logic
  }
}
```

### Testing Your Changes

Test your game changes thoroughly:

- Start game and play through
- Test all controls (touch, keyboard)
- Check collision detection
- Verify audio plays correctly
- Test on multiple platforms if possible
- Check for performance issues
- Ensure no crashes or errors

## 💻 Coding Standards

### Dart Style Guide

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart):

```dart
// ✅ GOOD
class Player extends SpriteAnimationComponent {
  final double speed;
  int _health = 100;
  
  Player({required this.speed});
  
  void takeDamage(int damage) {
    _health -= damage;
  }
}

// ❌ BAD
class player {
  var Speed;
  int health = 100;
}
```

### Naming Conventions

- **Classes**: `PascalCase` (e.g., `PlayerShip`)
- **Files**: `snake_case` (e.g., `player_ship.dart`)
- **Variables/Functions**: `camelCase` (e.g., `playerSpeed`)
- **Constants**: `lowerCamelCase` (e.g., `maxHealth`)
- **Private members**: prefix with `_` (e.g., `_health`)

### Comments

```dart
// ✅ GOOD - Explains "why", not "what"
// Increase speed by 50% on power-up to create powerful feeling
player.speed *= 1.5;

// ❌ BAD - Just repeats the code
// Multiply speed by 1.5
player.speed *= 1.5;

```

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flame Engine Documentation](https://docs.flame-engine.org/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

## � Reporting Bugs

Use the Bug Report template in Issues:
- Clear description
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/videos
- Platform and version info

## 💡 Suggesting Features

Use the Feature Request template:
- Clear description of feature
- Problem it solves
- How it would work
- Any design mockups

## ❓ Questions

If you have questions:
- Check existing [Issues](https://github.com/tutaki304/cosmic_havoc/issues)
- Create a new [Discussion](https://github.com/tutaki304/cosmic_havoc/discussions)
- Ask in Pull Request comments

## 📜 Code of Conduct

Be respectful and constructive. We want a welcoming community.

## 🙏 Thank You

Thank you for contributing to Cosmic Havoc! Every contribution helps make the game better. 🚀


### Author Checklist

-   [ ] Feature is fully implemented
-   [ ] All tests pass locally
-   [ ] `flutter analyze` returns no issues
-   [ ] Code is properly formatted
-   [ ] PR description is complete
-   [ ] Breaking changes are documented

## 🆘 Getting Help

### Resources

-   [Flutter Documentation](https://flutter.dev/docs)
-   [Dart Language Tour](https://dart.dev/guides/language/language-tour)
-   [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

### Community

-   GitHub Issues - Bug reports và feature requests
-   GitHub Discussions - General questions và ideas
-   Code Reviews - Learning opportunities

```

## � Recognition

Contributors will be recognized in:
- README.md
- Release notes  
- Credits in game

Thank you for contributing! 🙏

