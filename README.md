# AliveShot

AliveShot is a social and competitive recreation app. It encourages people to share healthy, creative, and recreational activities while challenging others in short, friendly competitions. The goal is to move users from passive scrolling into active participation by creating, joining, and voting on challenges around exercise, dance, or music practice.

## What This Project Is About

- A community-first social experience focused on healthy habits and creative hobbies.
- A challenge system where users post a task, accept opponents, and let the community vote.
- A profile progression system with streaks, wins, and activity focus areas.

This project is based on the vision described in the proposal document and is intended as a formal portfolio project for recruiters and academic review.

## Key Features

- Public feed with stories and posts centered on productive activities.
- Challenge creation and head-to-head competition (24-hour deadline).
- Community voting on challenge results.
- Streaks and score history to motivate long-term participation.

## Tech Stack

- Flutter (mobile app)
- Firebase (authentication, storage, notifications)
- Node.js + Express (API)
- PostgreSQL (challenge and user data)

## Quick Start (Local Development)

1. Install Flutter (stable channel) and Android Studio.
2. From the repo root:

```bash
flutter pub get
flutter run
```

This launches the app on an Android emulator or a connected Android device. iOS is not supported in this version.

## Quick Start (Demo APK)

If you want to try the current build without setting up Flutter, use the prebuilt APK:

1. Open the file at `build/app/outputs/apk/release/app-release.apk`.
2. Transfer it to your Android phone.
3. On the phone, enable installation from unknown sources.
4. Open the APK and complete the installation.

Note: If you are generating the APK yourself, run:

```bash
flutter build apk --release
```

## Requirements

### PC (Development)

- Flutter SDK (stable channel)
- Android SDK + Platform Tools (via Android Studio)
- Java (JDK installed for Android builds)
- Git

### Android Phone (Demo)

- Android device with available storage for the APK
- Permission to install apps from unknown sources

## How To Use The App

1. Sign in and complete your profile.
2. Browse the feed and stories to explore activities.
3. Create a challenge with a clear goal and category.
4. Accept or request challenges from other users.
5. Vote on competitions and track your streaks and results.

Full walkthrough demo:
https://www.youtube.com/watch?v=14_FbkaN48U

## Backend (Optional Overview)

The API lives in `backend/` and is cloud-deployed for the current demo. If you want to run it locally:

```bash
cd backend
npm install
npm run start
```

Environment variables required by the API:

- `DB_HOST`
- `DB_PORT` (default: 5432)
- `DB_USER`
- `DB_PASSWORD`
- `DB_NAME`

The Firebase Admin SDK is initialized using a service account JSON file at `backend/src/config/firebase-service-account.json`. Replace it with your own credentials for any public deployment.

### Firebase App Configuration

This repo uses templates so secrets do not get committed. To run the app locally:

1. Generate Firebase configs with the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

2. Place the generated files:
	- `android/app/google-services.json`
	- `lib/firebase_options.dart`

The template file `android/app/google-services.example.json` shows the expected structure.

## CI/CD Practices (Recommended)

This repository does not include CI yet, but the following workflow is recommended for production quality:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Suggested GitHub Actions steps:

- Run `flutter analyze` and `flutter test` on every pull request.
- Build a release APK on `main` after passing checks.
- Use branch protection (required reviews, status checks).
- Rotate Firebase credentials and never commit private keys.

## Project Structure

- `lib/` Flutter application source
- `assets/` static assets
- `backend/` Node.js API
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` platform targets

## License

This project is for academic and portfolio purposes. If you want to reuse or extend it, please contact the author.
