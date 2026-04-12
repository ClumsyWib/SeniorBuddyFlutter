# SeniorBuddy (Flutter)

Flutter frontend for the Senior Care app.

## Setup
```bash
cd "seniorbuddy1"
flutter pub get
```

## Configure Backend URL (important)
The app reads the backend base URL at build time:

`--dart-define=API_BASE_URL=http://127.0.0.1:8000/api`

Example (web build):
```bash
flutter build web --debug --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

## Analyze / Lint
```bash
flutter analyze
```

## Build / Run
Build (web):
```bash
flutter build web --debug --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

