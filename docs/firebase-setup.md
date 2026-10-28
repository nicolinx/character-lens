# Firebase setup (optional)

The AI explanation uses Gemini through Firebase AI Logic. The app works without it: with no Firebase settings it starts as usual and the AI section is simply unavailable. Nothing with a key is in the repo.

## 1. Create the Firebase project

In the [Firebase console](https://console.firebase.google.com):

1. Create a project, or pick one. Google Analytics is not needed.
2. Go to **AI Services**, then **AI Logic**, and click **Get started**.
3. Choose the **Gemini Developer API**, which has a free tier. The other provider requires billing.
4. Register the Android app with the package name `dev.nicolin.character_lens`.

## 2. Register the app for App Check

App Check is required for Firebase AI Logic from 2026-11-02, so requests without a valid token are blocked.

1. In **Security**, then **App Check**, register the app with **Play Integrity**. It asks for the SHA-256 fingerprint of the key that signs your build. For the debug key: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`.
2. For development, generate a debug token (any UUID) and add it under **Manage debug tokens** on the app's row in the **Apps** tab. Delete it when you are done debugging.

## 3. Add your settings locally

Copy `firebase.local.example.json` to `firebase.local.json` and fill it in from **Project settings**, **Your apps** (or from the `google-services.json` you can download there):

| Key | Where it comes from |
| --- | --- |
| `FIREBASE_API_KEY` | `api_key.current_key` |
| `FIREBASE_APP_ID` | `mobilesdk_app_id` |
| `FIREBASE_PROJECT_ID` | `project_id` |
| `FIREBASE_SENDER_ID` | `project_number` |
| `FIREBASE_APPCHECK_DEBUG_TOKEN` | the debug token from step 2 (debug builds only) |

`firebase.local.json` is in `.gitignore`. Do not commit it, and do not copy `google-services.json` into the repo: the app builds its Firebase options from this file instead.

## 4. Run with the settings

```
flutter run --dart-define-from-file=firebase.local.json
```

In VS Code, `.vscode/launch.json` can hold a configuration with the same argument.

## Notes

- Release builds use the Play Integrity provider. In one test on a Google Play emulator image, the App Check metrics counted the requests of an `adb`-installed release build as verified. That is one emulator in monitoring mode. It is not a promise for other devices.
- Only the character, the language and its dictionary entry are sent to the model. Strokes never leave the device.
- On the Gemini Developer API free tier, Google's pricing page says content may be used to improve its products. The paid tier says it is not.
