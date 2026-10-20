# pr-3: gh-2 Create mobile Flutter project with simple login page (Google/Apple sign-in, remember me)

## Description

Closes #2
### What changed

Created the mobile Flutter project (Android + iOS) and implemented a login page with email/password sign-in, validation + error states, a **Remember me** toggle that persists the session across restarts, Google sign-in (`google_sign_in` 7.x), and Sign in with Apple (`sign_in_with_apple`, entitlement wired into the Xcode project).

### Key decisions

- Layered auth: `AuthGateway` (provider ops) → `DefaultAuthService` (flows + persistence) → `SessionStore` (`shared_preferences`); `DmToolsApp` restores the session on startup and skips login when present
- Email/password is a local stub (no backend in this example) — swap the body of `DefaultAuthGateway.signInWithEmail` for a real identity API
- Autofill/credential save wired via `AutofillGroup` + `TextInput.finishAutofillContext` (platform password managers); Google credential save rides the plugin; Apple button hidden where Sign in with Apple is unavailable (Apple guidelines)
- Google/Apple plugins resolved to current majors (7.x / 8.x) and wired to their new APIs (`initialize`/`authenticate`, `scopes:`)

### How to verify

```bash
flutter pub get && flutter analyze   # clean
flutter test                          # 35 tests pass (login page widget tests included)
```

Platform builds: `flutter build apk --debug` / `flutter build ios --no-codesign` (needs Xcode for iOS; runtime Google sign-in needs OAuth client config, see README).
