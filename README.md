# Milk Tracker

Offline Flutter Android app for tracking milk collections and payments.

## This repository is FlutLab/GitHub import ready

The repository root contains:

- `pubspec.yaml`
- `lib/`
- `test/`
- `android/`

The `android/` directory is included specifically because FlutLab's GitHub
importer validates that an Android Flutter project contains it.

## Upload to GitHub

Upload the CONTENTS of this folder to the ROOT of your GitHub repository.

Correct:

    your-repository/
      pubspec.yaml
      lib/
      android/
      test/
      README.md

Incorrect:

    your-repository/
      milk-tracker/
        pubspec.yaml
        lib/
        android/

`pubspec.yaml` and `android/` must be directly at the repository root.

## Import into FlutLab

1. Push these files to GitHub.
2. Open FlutLab Workspace.
3. Choose import from GitHub.
4. Select the repository URL.
5. Base branch: `main`.
6. Feature branch: `initial-setup` (or any unused branch name).
7. Import.
8. Run Pub Get / Analyzer if FlutLab asks.
9. Build Android.

## Android notes

- Application ID: `se.rickard.milktracker`
- Android Gradle Plugin: 8.7.3
- Gradle distribution: 8.9
- Java compatibility: 17
- Main/release manifest does not request INTERNET permission.
- Debug/profile manifests request INTERNET only for Flutter debugging/hot reload.
- No Firebase.
- No backend.
- The installed release app works offline.

The Gradle wrapper executable/JAR is intentionally not committed. Flutter tooling
injects missing Gradle wrapper files when preparing an Android build, and
`gradle-wrapper.properties` is included to pin the Gradle distribution.

Before Google Play publication, replace debug signing with a private release/upload key.


## Full standard platform layout

This package additionally contains the standard Flutter platform directories:

- `android/`
- `ios/`
- `web/`
- `linux/`
- `macos/`
- `windows/`

The app is intended to be built for Android in FlutLab. The additional platform
scaffolds are included so FlutLab's GitHub importer recognizes the repository as
a full Flutter application rather than rejecting it for a missing platform directory.
