# gh-2: Create mobile Flutter project with simple login page (Google/Apple sign-in, remember me)

## Description

## Task

Create a new **mobile Flutter project** in this repository and implement a simple login page.

## Requirements

- Flutter mobile project (Android + iOS targets), clean default structure
- Login page: email/password fields, sign-in button, basic validation and error states
- **Remember me**: persist the session locally so the user stays signed in across app restarts
- **Google sign-in** integration (credential save / autofill where the platform supports it)
- **Apple sign-in** integration (per Apple guidelines)

## Acceptance criteria

- [ ] `flutter pub get` and `flutter analyze` pass
- [ ] `flutter test` passes (at least a widget test for the login page)
- [ ] Login page renders on Android and iOS
- [ ] Google and Apple sign-in wired, with saved credentials / autofill where supported
