# Smart Khata Manager

Offline-first Flutter ledger app with hybrid OCR/AI, double-entry accounting, and Firebase sync.

## Architecture

```
lib/
├── app/                    # App shell (routes, bindings, theme entry)
├── core/                   # Shared config, services, theme, utils
│   ├── config/
│   ├── services/           # Firebase, Gemini, Network, Notifications
│   └── theme/
└── features/               # Feature-first modules
    ├── dashboard/
    ├── ledger/
    ├── ocr/
    ├── reminders/
    └── splash/
```

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.27)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli)

## Setup

### 1. Create Flutter project scaffold (if not done)

```bash
flutter create . --org com.smartkhata --project-name smart_khata_manager
flutter pub get
```

### 2. Configure Firebase

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

This replaces `lib/firebase_options.dart` with your real project credentials and adds platform config files.

Enable **Cloud Firestore** in the [Firebase Console](https://console.firebase.google.com/).

### 3. Configure Gemini API Key

```bash
cp .env.example .env
```

Edit `.env` and add your free-tier key from [Google AI Studio](https://aistudio.google.com/apikey).

### 4. Android permissions (add to `AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

### 5. Run

```bash
flutter run
```

## Live Web App (GitHub Pages)

Source code on GitHub is **not** the runnable website. Each push to `main` builds Flutter web and deploys it automatically.

**Live URL:** [https://nelamnelamjaan-arch.github.io/khata/](https://nelamnelamjaan-arch.github.io/khata/)

**One-time setup (repo owner):**

1. GitHub repo → **Settings** → **Pages**
2. **Build and deployment** → Source: **GitHub Actions**
3. Wait for the [Deploy workflow](https://github.com/nelamnelamjaan-arch/khata/actions) to finish after push

If you see **404** on assets like `flutter_bootstrap.js`, you are opening the repo root instead of the deployed Pages URL above.

## Offline-First Behavior

Firestore persistence is enabled in `FirebaseService`:

- Writes save to local cache **immediately**
- Pending writes sync automatically when internet returns
- Use the cloud icon on the dashboard to see online/offline status

## Hybrid OCR/AI

| Mode    | Engine              | Capability                          |
|---------|---------------------|-------------------------------------|
| Offline | Google ML Kit       | Raw text extraction from images     |
| Online  | Google Gemini Flash | Structured parsing (date, amount, party) |

## Ledger Colors

| Type       | Urdu         | Color  |
|------------|--------------|--------|
| Receivable | Lenay hain   | Green  |
| Payable    | Denay hain   | Red    |

## Next Steps

- [ ] Ledger CRUD with double-entry Firestore models
- [ ] OCR scan UI with camera/gallery picker
- [ ] Reminder scheduling UI
- [ ] Vercel web dashboard (future)
