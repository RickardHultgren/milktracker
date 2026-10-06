# FlutLab / Android build guide

## 1. Create the FlutLab project

1. In FlutLab, create a new ordinary Flutter project.
2. Choose a current Flutter version. The source requires Dart 3.4 or newer.
3. Replace the generated `pubspec.yaml` with the one in this package.
4. Replace the generated `lib/` folder with the `lib/` folder in this package.
5. Optionally copy `test/` as well.
6. Run **Pub get**.
7. Open FlutLab's **Analyzer** and resolve any environment-specific warning before building.

Do not enable Firebase. This app does not use Firebase or any backend.

## 2. Run during development

FlutLab recommends doing a web build for quick UI iteration, but the persistence
behavior that matters here should also be tested on an Android build.

For Android:
1. Select an Android build target in FlutLab's Builder.
2. Press **Build Project**.
3. Download/install the resulting APK, scan the provided QR code if available,
   or use FlutLab Installer with auto-upload to a connected Android phone.
4. Test persistence by adding milk, fully closing the app, reopening it, recording
   a payment, and reopening again.

## 3. APK for your own phone

An APK is appropriate for direct installation/testing.

Use FlutLab's Android builder. FlutLab's documented Android flow creates an APK,
which can be downloaded or sent to a connected phone using FlutLab Installer.

If Android blocks manual installation, allow installation from the browser,
file manager, or FlutLab Installer that you used to open the APK.

## 4. Google Play release

For a Play Store release, use a unique and permanent Android application ID,
for example:

    se.yourname.milktracker

Do this before publishing. Do not change the application ID after the app is
published.

Also set a proper app name, icon, and increment `version:` in pubspec.yaml for
each release.

As of October 2026, Google Play requires new phone/tablet apps and updates to
target Android 16 / API level 36 or higher (unless an applicable temporary
extension exists). Make sure the Android builder/Flutter version selected in
FlutLab produces a targetSdk of at least 36 before uploading to Play Console.

Google Play normally expects an Android App Bundle (AAB) for new Play apps.
If your FlutLab account/builder exposes an **App Bundle / AAB / signed release**
build option, use that for Play Console.

If your FlutLab Android builder only exposes APK output, export/download the
same Flutter project and build the release bundle in a current Flutter
environment with:

    flutter pub get
    flutter build appbundle --release

The resulting bundle is normally:

    build/app/outputs/bundle/release/app-release.aab

You must keep the same signing identity/upload key for future updates. Configure
release signing before the Play upload; never publish a debug-signed build.

## 5. No internet/backend requirements

The app itself:
- does not use Firebase;
- does not make HTTP requests;
- does not require authentication;
- does not require network access for operation;
- stores its ledger locally with shared_preferences.

FlutLab needs internet while developing/building because FlutLab is a cloud IDE
and Pub must obtain dependencies, but the installed milk app works offline.
