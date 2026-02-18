# Firebase Authentication Setup Guide for Modaics iOS

This guide will help you set up Firebase Authentication for the Modaics iOS app.

## Prerequisites

1. Xcode 15.0 or later
2. iOS 16.0 or later target
3. A Firebase account

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter "Modaics" as the project name
4. Follow the prompts to create the project

## Step 2: Register Your iOS App

1. In Firebase Console, click the iOS icon to add an iOS app
2. Enter your Bundle ID (e.g., `com.modaics.app`)
3. Enter an App nickname (e.g., "Modaics iOS")
4. Click "Register App"

## Step 3: Download GoogleService-Info.plist

1. Download the `GoogleService-Info.plist` file
2. Replace the template file at:
   `/ModaicsAppTemp/ModaicsAppTemp/IOS/Resources/GoogleService-Info.plist`
3. **Important**: Do NOT commit this file to version control. Add it to `.gitignore`.

## Step 4: Enable Authentication Methods

In Firebase Console, go to **Authentication > Sign-in method** and enable:

### Required Methods:

1. **Email/Password**
   - Enable "Email/Password" 
   - Optional: Enable "Email link (passwordless sign-in)"

2. **Google Sign-In**
   - Enable "Google"
   - Add your web client ID (auto-generated)
   - Configure OAuth consent screen in Google Cloud Console

3. **Apple Sign-In**
   - Enable "Apple"
   - Requires Apple Developer account
   - Configure Sign in with Apple capability in Xcode

## Step 5: Configure Firestore Database

1. Go to **Firestore Database** in Firebase Console
2. Click "Create Database"
3. Start in "test mode" for development
4. Choose a location close to your users

### Security Rules

Update Firestore security rules in Production:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profiles
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 6: Xcode Configuration

### Sign in with Apple Capability

1. Open your project in Xcode
2. Select your target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Sign in with Apple"

### URL Types (for Google Sign-In)

1. In Xcode, select your target
2. Go to "Info" tab
3. Expand "URL Types"
4. Add URL scheme from `REVERSED_CLIENT_ID` in `GoogleService-Info.plist`
   - Example: `com.googleusercontent.apps.YOUR_CLIENT_ID`

## Step 7: Build and Test

1. Clean build folder (Cmd+Shift+K)
2. Build the project (Cmd+B)
3. Run on simulator or device

## Testing Authentication

### Test Users

Create test users in Firebase Console:
1. Go to **Authentication > Users**
2. Click "Add User"
3. Enter email and password

### Test Flows

1. **Sign Up**: Create a new account with email/password
2. **Sign In**: Log in with existing credentials
3. **Password Reset**: Test "Forgot Password" flow
4. **Social Sign-In**: Test Google and Apple sign-in
5. **Email Verification**: Verify email addresses

## Troubleshooting

### Common Issues

**"Configuration not found" error**
- Ensure `GoogleService-Info.plist` is in the correct location
- Verify Bundle ID matches Firebase registration

**Google Sign-In fails**
- Check URL scheme is correctly configured
- Verify Google Sign-In is enabled in Firebase
- Check OAuth consent screen is configured

**Apple Sign-In fails**
- Ensure "Sign in with Apple" capability is added
- Verify Apple Developer account is set up

**Firestore permission denied**
- Check Firestore security rules
- Ensure user is authenticated before accessing data

### Debug Logging

Enable Firebase debug logging in Xcode console:

```swift
// Add to AppDelegate or early in app lifecycle
FirebaseConfiguration.shared.setLoggerLevel(.debug)
```

## Production Checklist

Before releasing to production:

- [ ] Add real `GoogleService-Info.plist` (not the template)
- [ ] Update Firestore security rules
- [ ] Enable App Check
- [ ] Configure OAuth consent screen for production
- [ ] Test on physical device
- [ ] Test all authentication methods
- [ ] Verify email verification flow
- [ ] Test password reset flow
- [ ] Review Firebase billing plan

## Additional Resources

- [Firebase iOS Setup Guide](https://firebase.google.com/docs/ios/setup)
- [Firebase Auth Documentation](https://firebase.google.com/docs/auth/ios/start)
- [Sign in with Apple Guide](https://firebase.google.com/docs/auth/ios/apple)
- [Google Sign-In Guide](https://firebase.google.com/docs/auth/ios/google-signin)

## Support

For issues or questions:
- Check Firebase documentation
- Review Stack Overflow tags: `firebase`, `firebase-authentication`, `ios`, `swift`
- Contact Firebase support
