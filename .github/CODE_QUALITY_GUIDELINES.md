# Code Quality Guidelines for Memory Match Game

## 🏗️ Architecture Guidelines

### Clean Architecture Structure

Project phải tuân thủ cấu trúc Clean Architecture với các layers:

```
lib/
├── main.dart                # Entry point
├── app.dart                 # App configuration
├── core/                    # Shared utilities
│   ├── constants/           # App constants
│   ├── utils/               # Utility functions
│   ├── error/               # Error handling
│   └── theme/               # App themes
├── data/                    # Data layer
│   ├── models/              # Data models
│   ├── datasources/         # Data sources
│   └── repositories_impl/   # Repository implementations
├── domain/                  # Business logic layer
│   ├── entities/            # Business entities
│   ├── repositories/        # Repository interfaces
│   └── usecases/            # Use cases
├── presentation/            # UI layer
│   ├── screens/             # App screens
│   ├── widgets/             # Reusable widgets
│   ├── providers/           # State management
│   └── routes/              # App routing
└── services/                # External services
```

### Architecture Rules

1. **Domain layer** không được import Flutter hoặc external packages
2. **Data layer** implements interfaces từ domain layer
3. **Presentation layer** chỉ chứa UI logic và state management
4. **Core layer** chứa utilities dùng chung cho toàn app

## 📝 Coding Standards

### Naming Conventions

-   **Files**: `snake_case.dart`
-   **Classes**: `PascalCase`
-   **Variables/Functions**: `camelCase`
-   **Constants**: `SCREAMING_SNAKE_CASE`
-   **Private members**: `_leadingUnderscore`

### File Organization

```dart
// Order of imports
1. Dart core libraries
2. Flutter libraries
3. Third-party packages
4. Project imports (relative)

// Order of class members
1. Static constants
2. Instance variables
3. Constructors
4. Static methods
5. Instance methods
6. Overridden methods
```

### Documentation

-   Public APIs phải có documentation comments
-   Complex business logic phải có inline comments
-   README.md phải được cập nhật khi có thay đổi architecture

## 🧪 Testing Requirements

### Test Coverage

-   Unit tests: >= 80% coverage cho business logic
-   Widget tests: Critical UI components
-   Integration tests: Key user flows

### Test Organization

```
test/
├── unit/
│   ├── core/
│   ├── data/
│   ├── domain/
│   └── services/
├── widget/
│   └── presentation/
└── integration/
```

## 🚀 Performance Guidelines

### Widget Performance

-   Sử dụng `const` constructors khi có thể
-   Tránh rebuild không cần thiết
-   Sử dụng `ListView.builder` cho long lists
-   Optimize images (format, size, caching)

### Memory Management

-   Dispose controllers và streams properly
-   Avoid memory leaks từ listeners
-   Use weak references khi appropriate

## 🔒 Security Guidelines

### Data Protection

-   Không hardcode API keys hoặc sensitive data
-   Sử dụng environment variables
-   Validate user inputs
-   Sanitize data trước khi display

### API Security

-   Implement proper error handling
-   Use HTTPS cho network calls
-   Implement request timeouts
-   Handle network failures gracefully

## 📱 Platform Guidelines

### Cross-platform Compatibility

-   Test trên cả Android và iOS
-   Handle platform-specific behaviors
-   Use responsive design
-   Test multiple screen sizes

### Accessibility

-   Provide semantic labels
-   Support screen readers
-   Ensure proper contrast ratios
-   Test với accessibility tools

## 🔄 Git Workflow

### Branch Naming

-   `feature/feature-name`
-   `fix/bug-description`
-   `hotfix/critical-fix`
-   `refactor/component-name`

### Commit Messages

```
type(scope): description

Types: feat, fix, docs, style, refactor, test, chore
Scope: component/feature being changed
Description: Brief description of changes
```

### Pull Request Process

1. Create feature branch từ `develop`
2. Implement changes với tests
3. Run `flutter analyze` và fix warnings
4. Run `dart format` để format code
5. Create PR với detailed description
6. Code review và approval
7. Merge vào `develop`

## 🛠️ Development Tools

### Required Tools

-   Flutter SDK (latest stable)
-   Dart SDK
-   Android Studio / VS Code
-   Flutter Inspector
-   Dart DevTools

### Recommended Extensions

-   Flutter
-   Dart
-   Flutter Widget Snippets
-   Bracket Pair Colorizer
-   GitLens

## ✅ Pre-commit Checklist

### Before Every Commit

-   [ ] Code compiles without errors
-   [ ] All tests pass
-   [ ] `flutter analyze` returns no issues
-   [ ] Code is properly formatted
-   [ ] No debug prints or TODO comments
-   [ ] Documentation is updated

### Before Every PR

-   [ ] Feature is fully implemented
-   [ ] Tests are written và pass
-   [ ] Code follows architecture guidelines
-   [ ] Performance is acceptable
-   [ ] Security concerns are addressed
-   [ ] Cross-platform compatibility verified

## 📊 Code Quality Metrics

### Thresholds

-   Test coverage: >= 80%
-   Cyclomatic complexity: <= 10 per method
-   File length: <= 300 lines
-   Method length: <= 50 lines
-   Parameter count: <= 5 per method

### Monitoring

-   Sử dụng GitHub Actions để track metrics
-   Regular code quality reviews
-   Refactor khi metrics vượt thresholds

## 🎯 Best Practices

### State Management

-   Sử dụng Provider/Riverpod cho app state
-   Avoid global state khi có thể
-   Implement proper error states
-   Handle loading states consistently

### Error Handling

-   Use proper exception types
-   Provide meaningful error messages
-   Log errors appropriately
-   Implement fallback UI states

### Localization

-   Prepare cho multi-language support
-   Use localization keys instead of hardcoded strings
-   Test với different languages

---

## 📚 Resources

-   [Flutter Style Guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)
-   [Effective Dart](https://dart.dev/guides/language/effective-dart)
-   [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
-   [Flutter Best Practices](https://flutter.dev/docs/development/best-practices)
