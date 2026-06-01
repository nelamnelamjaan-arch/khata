# Firebase Setup — khata-manager-ccf3a

## Quick setup (2 commands)

Open **PowerShell** in project folder and run:

```powershell
$env:Path = "$env:APPDATA\npm;C:\Users\AL FATEH\flutter\bin;C:\pub-cache\bin;" + $env:Path
cd "C:\Users\AL FATEH\Desktop\khaaty"

firebase login
flutterfire configure --project=khata-manager-ccf3a --platforms=web --yes --overwrite-firebase-options
firebase deploy --only firestore:rules
```

Or double-click: `scripts\setup_firebase.bat`

---

## What each step does

| Step | Command | Result |
|------|---------|--------|
| 1 | `firebase login` | Browser opens → sign in with Google account that owns the Firebase project |
| 2 | `flutterfire configure ...` | Updates `lib/firebase_options.dart` with **real** API keys |
| 3 | `firebase deploy --only firestore:rules` | Fixes Firestore **permission-denied** errors |

---

## After setup

```powershell
flutter run -d edge --web-port=7360
```

Hard refresh browser: **Ctrl + Shift + R**

Orange Firebase warning on dashboard should disappear.

---

## If `firebase login` fails

1. Install Node.js from https://nodejs.org
2. Run: `npm install -g firebase-tools`
3. Run: `dart pub global activate flutterfire_cli`
4. Try `firebase login` again

## Manual alternative (no CLI)

Firebase Console → Project Settings → Your Web App → copy `firebaseConfig` values into `lib/firebase_options.dart` (replace `YOUR_WEB_API_KEY`, etc.).
