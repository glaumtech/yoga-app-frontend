# yoga_champ

Yoga competition application frontend (Flutter).

## Getting Started

Install dependencies:

```bash
flutter pub get
```

Run the app with a profile entrypoint:

```bash
flutter run -t lib/main_qa.dart
```

## Web Build Profiles

This project uses separate entrypoints to set environment configuration:

- `lib/main_qa.dart` -> QA (`https://ghopon.com/yogatest`)
- `lib/main_prod.dart` -> Production (`https://ghopon.com/school`)

Build web for QA deployment:

```bash
flutter build web --release -t lib/main_qa.dart
```

If QA is hosted under a subpath, set the base href accordingly:

```bash
flutter build web --release -t lib/main_qa.dart --base-href /yogatest/
```

Build web for production:

```bash
flutter build web --release -t lib/main_prod.dart
```

Build output is generated in `build/web/`.
