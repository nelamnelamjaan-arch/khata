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

## Vercel + mobile browsers

Firebase **web** config is compiled from `lib/firebase_options.dart` (not Vercel env vars). You do **not** need `FIREBASE_*` environment variables on Vercel for Firestore.

**Required (Firebase Console):**

1. [Firebase Console](https://console.firebase.google.com/) → project **khata-manager-ccf3a**
2. **Authentication** → **Settings** → **Authorized domains**
3. Add every host users open on phones:
   - `your-app.vercel.app` (your real Vercel subdomain)
   - Any custom domain (e.g. `khata.example.com`)
   - `localhost` (local dev)

**Mobile Safari / Chrome tips:**

- Avoid **Private Browsing** (blocks IndexedDB / Firestore cache).
- Allow **site data** / cookies for your Vercel URL.
- If splash shows “Firebase connection failed”, tap **Retry** after checking network.

**Redeploy after code changes:**

```powershell
git push origin main
```

Vercel rebuilds with `scripts/vercel-build.sh` (`flutter build web --release --base-href /`).

---

## If `firebase login` fails

1. Install Node.js from https://nodejs.org
2. Run: `npm install -g firebase-tools`
3. Run: `dart pub global activate flutterfire_cli`
4. Try `firebase login` again

## Manual alternative (no CLI)

Firebase Console → Project Settings → Your Web App → copy `firebaseConfig` values into `lib/firebase_options.dart` (replace `YOUR_WEB_API_KEY`, etc.).
