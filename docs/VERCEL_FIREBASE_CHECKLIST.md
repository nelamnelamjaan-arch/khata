# Vercel + Firebase checklist (no custom domain)

Use this when hosting only on **Vercel** (`*.vercel.app`) — no own domain required.

## 1. Firebase Console → Authorized domains

**Path:** [Firebase Console](https://console.firebase.google.com/) → project **khata-manager-ccf3a** → **Build** → **Authentication** → **Settings** → **Authorized domains**

Add these (check each box):

| Domain | Why |
|--------|-----|
| `localhost` | Local `flutter run -d chrome` |
| `khata-manager-ccf3a.firebaseapp.com` | Default Firebase host |
| `khata-manager-ccf3a.web.app` | Firebase web app host |
| **Your exact Vercel URL** | e.g. `khata-abc123.vercel.app` |

**How to find your Vercel URL**

1. [Vercel Dashboard](https://vercel.com/dashboard) → your project → **Domains**
2. Copy the **Production** domain (ends with `.vercel.app`)
3. Paste that full hostname into Authorized domains (no `https://`, no path)

You do **not** need a custom domain. Each preview deployment (`*.vercel.app`) may need its preview hostname added if you test preview URLs on mobile.

## 2. Vercel environment variables (optional)

**Path:** Vercel → Project → **Settings** → **Environment Variables**

| Variable | Required? | Purpose |
|----------|-----------|---------|
| `GEMINI_API_KEY` | Only for receipt AI | Gemini scan |
| `FIREBASE_*` | No | Override keys; default = `firebase_options.dart` |

If you skip all `FIREBASE_*` vars, the build uses committed FlutterFire web config (normal for client apps).

## 3. Deploy flow (automatic)

Every `git push` to `main`:

1. `scripts/vercel-build.sh` runs
2. `flutter build web --release --base-href /`
3. Output in `build/web` → Vercel CDN

## 4. Mobile browser verification

1. Open production `https://YOUR-PROJECT.vercel.app` in **normal** Safari/Chrome (not private).
2. On dashboard, check **Build** label (git SHA) — confirms latest deploy loaded.
3. Tap **Test Firebase (mobile check)** → snackbar should say **Firebase OK**.
4. If old version stuck: close tab → clear site data for that URL → reopen, or hard refresh.

## 5. Firestore rules

```powershell
firebase deploy --only firestore:rules
```

Rules file: `firestore.rules` (open read/write for dev).
