# Coastal Pearl Inventory — Android / Flutter project

A polished, local-first kitchen and restaurant inventory app prepared from the supplied Coastal Pearl workbook.

## What's included

- **359 starter items**: all 338 existing workbook entries plus 21 additional non-veg items, grouped by category.
- Existing entries retained: bangda, paplet, bombil, saundala, surmai, crab / खेकडा, eggs / अंडी, chicken and the other original kitchen items.
- New local fish: tarli, ghol, dhoma, halwa, rani fish, black pomfret and mori.
- New dried seafood: dried prawns and dried bombil.
- New poultry and eggs: country chicken, boneless chicken, chicken liver, chicken gizzard, chicken sausage, duck eggs and quail eggs.
- New mutton items: mutton, mince, liver, bones and chops.
- **SQLite on the Android phone** — no login, server, Firebase or internet connection is needed for day-to-day inventory operations.
- Purchase, Used and Wastage entries with date, quantity, optional rate, supplier, bill/reference, payment mode, staff name and notes.
- Live stock balance and reorder calculation; purchase entries add stock and Used/Wastage entries reduce stock.
- Search by English name, Marathi name or item code; category-wise inventory screen.
- Set minimum stock levels and add custom inventory items.
- Daily, weekly, monthly, yearly and custom-date reports.
- CSV export (UTF-8 with BOM; includes English and Marathi names) and print-friendly PDF export.
- Reorder list grouped by category with editable quantities. Share the purchase request through Android's share menu and select WhatsApp and the supplier/contact/group.

## Build with Codemagic Free

1. Extract this ZIP. Push the **contents** of the `coastal_pearl_inventory_app` folder to a GitHub, GitLab or Bitbucket repository.
2. In Codemagic, add the repository and choose the Flutter project.
3. Keep `codemagic.yaml` at the repository root. Select the workflow **Coastal Pearl Inventory - Android APK**.
4. The workflow explicitly selects `instance_type: mac_mini_m2`, Codemagic's default Mac mini M2 machine for the Free individual plan. It does not request a paid/custom runner.
5. Start the build. It resolves packages, runs `flutter analyze` and `flutter test`, then builds the release APK.
6. Download `app-release.apk` from the build artifacts and install it on your Android phone.

Codemagic currently lists 500 free Mac mini M2 build minutes per month for personal Free accounts. Free minutes do not apply to Team accounts, and the allowance/machine availability is controlled by Codemagic. See its [pricing](https://codemagic.io/pricing/) and [machine configuration docs](https://docs.codemagic.io/knowledge-codemagic/machine-type/).

## Local build (optional)

Install Flutter stable (Flutter 3.50 or later recommended for this toolchain) and Android SDK, then run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`.

The Android toolchain is aligned with the Flutter 3.50 template: Gradle 9.5.0, Android Gradle Plugin 9.3.1, Kotlin Gradle Plugin 2.4.20, and Java 17+. The existing Kotlin Gradle configuration is retained using Flutter's documented temporary compatibility flags (`android.builtInKotlin=false` and `android.newDsl=false`). The Gradle wrapper downloads and caches Gradle 9.5.0 on the first build; the runner needs outbound network access to `services.gradle.org` for that first download.

## Local database and report files

The database file is `coastal_pearl_inventory.db` in Android's private app database directory. It persists across app launches and works offline. Uninstalling the app or clearing its app data removes this local database, so export/back up reports regularly.

Generated files are stored in the app's `CoastalPearlReports` documents folder and then passed to Android's share menu. CSV contains both English and Marathi item names. PDF item labels use English for predictable display across PDF readers.

## WhatsApp sharing

Open **Order** → review the low-stock list → change the suggested quantities → tap **Share requirement on WhatsApp**. Android opens the share menu; select WhatsApp and then choose the supplier/contact/group. The app prepares the message but does not send without your final confirmation in WhatsApp.

## Release signing

The included release build uses the Android debug signing key so it can be installed for internal testing. Before publishing to Google Play or distributing a production release, configure your own private Android keystore in Codemagic and update the release signing configuration. Never commit the keystore or passwords to the repository.

## Important stock setup

- Existing opening stock and minimum stock values are retained from the workbook.
- The 21 new non-veg items start with opening stock `0` and minimum stock `1`. Change these minimums in the Stock screen to match actual usage and supplier cycles.
- The workbook already contained the specific fish and eggs named in the request, so the app keeps those entries and adds more varieties/cuts without duplicating them.
