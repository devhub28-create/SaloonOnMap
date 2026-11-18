# Mobile release configuration

Both Flutter apps fail closed when an Android release signing key is missing and disable clear-text HTTP outside debug builds.

## Firebase push notifications

Push registration is optional in local builds and activates only when all required values are provided as Dart defines:

```sh
flutter build appbundle --release \
  --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://salononmap.vercel.app/api/v1 \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_IOS_BUNDLE_ID=...
```

Use the customer Firebase app ID for `apps/customer_app` and the partner Firebase app ID for `apps/partner_app`. Configure APNs credentials in Firebase for iOS and enable the Push Notifications capability for both App IDs in the Apple Developer portal. The Xcode projects use the development APNs entitlement for debug builds and production for profile/release builds. The app requests notification permission, registers the FCM token with `/devices`, follows token refreshes, and unregisters the token on logout or session expiry.

## Android signing

Create each app's `android/key.properties` locally (never commit it):

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

Release tasks stop with an explicit error when this file is absent; they never fall back to the debug key.

## Database migration

Deploy the backend migration before releasing the updated customer app:

```sh
cd apps/backend
npm run migration:run
```

This adds server-synced notification preferences and favorite salon IDs.

When Firebase defines are present, release builds also enable Firebase Analytics
(`app_open` plus an `app_type` user property) and Crashlytics fatal error
reporting. Collection stays disabled in debug/profile builds.
