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

## Web deployment (CloudFront / S3)

This app uses **hash URLs** by default (for example `/#/admin/participants`) so browser refresh and direct links work on static hosting without extra server configuration.

If you prefer clean path URLs (for example `/admin/participants`) and your host is **CloudFront + S3**, add custom error responses so missing paths serve `index.html`:

1. CloudFront distribution → **Error pages** → **Create custom error response**
2. **403 Forbidden** → response path `/index.html`, response code **200**
3. Repeat for **404 Not Found** → `/index.html`, response code **200**
4. Invalidate the CloudFront cache after deploying a new build

Then you can re-enable path URLs in `main.dart`, `main_qa.dart`, and `main_prod.dart`:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';

if (kIsWeb) {
  usePathUrlStrategy();
}
```

Without that CloudFront configuration, refreshing a path URL returns S3 `AccessDenied` XML instead of the app.
