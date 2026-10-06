# Milk Tracker

A small offline Flutter app for tracking milk collected from a farm.

## Default bookkeeping rules

- Milk price: **7.00 SEK/liter**
- Can size: **3.0 liters**
- Half can: **1.5 liters**
- Payment threshold: **500 SEK**
- Money is stored internally as integer **öre**
- Milk quantity is stored internally as integer **milliliters**
- Historical prices are preserved
- Payments mark specific milk entries as cleared rather than deleting history

## Storage

The app works offline and stores a versioned JSON ledger locally using
`shared_preferences`.

The current unpaid balance is **derived from the saved transactions**. It is not
saved as an independent authoritative counter.

## Import this repository into FlutLab

1. Create a GitHub repository, for example `milk-tracker`.
2. Upload/push **the contents of this folder** to the repository root.
   `pubspec.yaml` must be at the top level of the GitHub repository.
3. Open FlutLab Workspace.
4. Create/import a project from **GitHub** and select this repository.
5. Run **Pub get** if FlutLab does not run it automatically.
6. Run the Analyzer.
7. Do a Web build for a quick UI check.
8. Build Android and install the APK on the phone for the final persistence test.

Do not add Firebase. The app does not require Firebase, a backend, authentication,
or internet access while running.

## Repository root should look like this

```text
milk-tracker/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── screens/
│   └── services/
├── test/
├── .gitignore
└── README.md
```

## Android platform files

This repository intentionally does not include hand-written Android Gradle
scaffolding. Flutter/FlutLab platform scaffolding is version-sensitive, and
FlutLab imports Flutter codebases and builds them in its selected Flutter
environment.

If FlutLab asks you to select/generate a codebase/platform configuration during
import, choose a normal Flutter app with Android enabled.

For Google Play release details, see `FLUTLAB_ANDROID_BUILD.md`.
