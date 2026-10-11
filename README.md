# Firebase Task Manager (Module 16)

Flutter + Firebase app: Auth (Email + Google), Firestore task CRUD, FCM push notifications,
and local notifications for foreground messages.

## Features
- Email/password sign in & sign up, Google Sign In
- Tasks in Firestore (`users/{uid}/tasks/{taskId}`): title, description, due date, priority, completed, created date
- Add / edit / delete (with confirm dialog) / complete, search, Pending/Completed filter
- FCM token (printed in console, copy button in app bar, saved to `users/{uid}.fcmToken`)
- Foreground: `onMessage` -> `flutter_local_notifications`
- Background: Firebase shows it, tap handled by `onMessageOpenedApp`
- Terminated: `getInitialMessage()` on launch
- Tap opens Task List, or the exact task when `taskId` is in the data payload
- Priority-based notification (data `priority: High` -> max-importance channel)

## Setup
1. Create the Flutter platform folders (if missing): `flutter create --platforms=android,ios .`
2. `flutter pub get`
3. Create a Firebase project, enable **Authentication** (Email/Password + Google) and **Firestore**.
4. `dart pub global activate flutterfire_cli` then `flutterfire configure` (overwrites `lib/firebase_options.dart`).
5. Android: add debug **SHA-1 and SHA-256** (`cd android && ./gradlew signingReport`) in Firebase console, re-download `google-services.json` into `android/app/`.
6. Android `android/app/build.gradle(.kts)`:
   - `compileOptions { coreLibraryDesugaringEnabled = true }`
   - `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }`
   - `minSdk` at least 23
7. Android `AndroidManifest.xml` (inside `<manifest>`): `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`
   and inside `<application>`:
   `<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id" android:value="task_default_channel"/>`
8. iOS: real device, upload an APNs key in Firebase, enable Push Notifications + Background Modes (Remote notifications) in Xcode.
9. Paste `firestore.rules` into Firestore Rules.
10. `flutter run`

## Testing notifications
1. Run on a device, sign in, copy the FCM token (key icon) or take it from the console (`FCM TOKEN:`).
2. Firebase Console -> Messaging -> New campaign -> Notification -> "Send test message", paste the token.
   - Title: `New Task`, Body: `You have a new task: Complete Flutter Assignment`
   - In **Additional options -> Custom data** add `taskId` = (a Firestore task id) and optionally `priority` = `High`.
3. Test each state: app open (local notification appears), app in background, app killed (tap notification to launch).

## UI
The UI follows the Figma screens: Splash, Login, Task List, Edit Task, New Task, Delete Confirmation.
Extras from the design: "Forgot Password?" (sends a reset email) and the optional "Course Bucket"
dropdown on the Edit screen (stored as `course` in Firestore). The logo is built from icons; swap `AppLogo`
in `lib/theme.dart` with an `Image.asset` if you export the real logo from Figma.
