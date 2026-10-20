# dm_tools_app_example

Flutter mobile app (Android + iOS) with a login page: email/password sign-in,
**Remember me** session persistence, Google sign-in, and Sign in with Apple.

## Run

```bash
flutter pub get
flutter run            # device or emulator with Android/iOS target
flutter test           # unit + widget tests
flutter analyze
```

## Architecture

- `lib/domain/` — `AuthUser`, `AuthException`, credential validation rules
- `lib/services/` — `AuthGateway` (provider operations) → `DefaultAuthService`
  (flows + persistence) → `SessionStore` (`shared_preferences`)
- `lib/ui/` — `LoginPage` (form, remember-me, federated buttons), `HomePage`

Sign-in flows delegate to `AuthGateway`; the service persists the session when
**Remember me** is on, and `DmToolsApp` restores it on startup (login page is
skipped when a session exists).

## Provider setup

- **Google** — `google_sign_in` 7.x needs an OAuth client for Android
  (`google-services.json` / SHA-1 in the console) and iOS (URL scheme from the
  client ID). Without it the button compiles but sign-in fails at runtime.
- **Apple** — the `com.apple.developer.applesignin` entitlement is already
  wired into `ios/Runner/Runner.entitlements` and the Xcode project; enable the
  capability for your App ID in the Apple developer portal. The button is
  hidden automatically where Sign in with Apple is unavailable.
- **Email/password** — local stub (no backend); replace the body of
  `DefaultAuthGateway.signInWithEmail` with a real identity API call.
- Password managers / autofill: the form uses an `AutofillGroup` and finishes
  the autofill context on success, so platforms that support it offer to save
  and later autofill credentials.
