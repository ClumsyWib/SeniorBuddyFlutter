# SeniorBuddy (Flutter)

This is the Flutter frontend application for the Senior Care app.

## Prerequisites
- **Flutter SDK**: Make sure Flutter is installed and added to your system path. [Install Flutter here](https://docs.flutter.dev/get-started/install).
- **Backend Running**: Make sure the Django backend is running before testing the app.

## Setup & Running the Project

Follow the instructions for your operating system.

### 🍎 macOS / 🐧 Linux

1. **Open your terminal**.
2. **Navigate to the project folder:**
   ```bash
   cd "path/to/seniorbuddy1 (Copy)"
   ```
3. **Get dependencies:**
   ```bash
   flutter pub get
   ```
4. **Run the application:**
   You must provide the Backend API URL when running the app so it connects to Django.
   - If running on a **Web Browser** or **Desktop App**, use `127.0.0.1`:
     ```bash
     flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
     ```
   - If running on an **Android Emulator**, use `10.0.2.2` (the emulator's localhost loopback):
     ```bash
     flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
     ```
   - If testing on a **Physical Device (Phone)**, use the local network IP address of the machine running the backend (e.g., `192.168.1.100`):
     ```bash
     flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000/api
     ```

### 🪟 Windows

1. **Open Command Prompt or PowerShell**.
2. **Navigate to the project folder:**
   ```cmd
   cd "path\to\seniorbuddy1 (Copy)"
   ```
3. **Get dependencies:**
   ```cmd
   flutter pub get
   ```
4. **Run the application:**
   You must provide the Backend API URL so it knows where to connect.
   - If running on a **Web Browser** or **Windows Desktop**, use `127.0.0.1`:
     ```cmd
     flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
     ```
   - If running on an **Android Emulator**, use `10.0.2.2`:
     ```cmd
     flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
     ```
   - If testing on a **Physical Device (Phone)**, use your computer's local network IP address (e.g., `192.168.1.100`):
     ```cmd
     flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000/api
     ```

---

## Build for Production
To build a web release:
```bash
flutter build web --dart-define=API_BASE_URL=http://your-production-backend.com/api
```

## Analyze / Lint
Check for code issues:
```bash
flutter analyze
```
