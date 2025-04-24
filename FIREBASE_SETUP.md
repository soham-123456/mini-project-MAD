# Firebase Setup Instructions

To enable Firebase authentication in the Image Separator app, follow these steps:

## 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the setup wizard
3. Enter a project name (e.g., "Image Separator")
4. Configure Google Analytics if desired
5. Create the project

## 2. Register Your App with Firebase

### For Android:

1. In the Firebase console, click the Android icon
2. Enter your app's package name (found in `android/app/build.gradle` under `applicationId`)
3. Enter a nickname for your app (optional)
4. Enter your SHA-1 certificate (optional, but required for Google Sign-in)
5. Click "Register app"
6. Download the `google-services.json` file
7. Place the file in the `android/app` directory of your Flutter project

### For iOS:

1. In the Firebase console, click the iOS icon
2. Enter your iOS bundle ID (found in Xcode under the General tab)
3. Enter a nickname for your app (optional)
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Add the file to your Xcode project (open iOS folder in Xcode and drag file into Runner folder)

### For Web:

1. In the Firebase console, click the Web icon
2. Enter a nickname for your app (e.g., "image-separator-web")
3. Check "Also set up Firebase Hosting" if you want to host your app on Firebase
4. Click "Register app"
5. Copy the Firebase configuration snippet

## 3. Update Firebase Configuration

Update the `lib/firebase_options.dart` file with your Firebase project's credentials:

1. For Web, update the variables in the `kIsWeb` section
2. For Android, update the variables in the `TargetPlatform.android` section
3. For iOS, update the variables in the `TargetPlatform.iOS` section

The Firebase CLI can also be used to generate this file automatically:

```
flutter pub global activate flutterfire_cli
flutterfire configure
```

## 4. Enable Authentication Methods

1. In the Firebase console, navigate to "Authentication"
2. Click "Get Started"
3. Enable "Email/Password" authentication
4. Optionally enable "Google" authentication
5. Configure other auth providers as needed

## 5. Testing Authentication

Once Firebase is set up:

1. Run the app and try to register a new account
2. Verify that users can login with email/password
3. If enabled, verify that Google Sign-in works

## Troubleshooting

- If you encounter errors related to Firebase initialization, ensure your configuration values in `firebase_options.dart` are correct
- For Google Sign-in on Android, make sure you've added the correct SHA-1 certificate to your Firebase project
- For web authentication issues, check that you've enabled the correct authentication domains in Firebase console

## Additional Resources

- [Firebase Flutter Codelab](https://firebase.google.com/codelabs/firebase-get-to-know-flutter)
- [Firebase Auth Documentation for Flutter](https://firebase.flutter.dev/docs/auth/overview/)
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/overview/) 