# Android build fix — Gradle 9 toolchain

This version fixes the Codemagic error stating that Gradle 8.14.0 is below the Flutter SDK minimum of 9.3.1.

Pinned versions:
- Gradle wrapper: 9.5.0
- Android Gradle Plugin: 9.3.1
- Kotlin Gradle Plugin: 2.4.20
- Java: 17 (Codemagic workflow)

Gradle 9.5.0 satisfies AGP 9.3.1's minimum Gradle requirement. The two properties below preserve the current project's legacy Kotlin Gradle Plugin and DSL configuration while using AGP 9.x, as documented by Flutter during migration:

```properties
android.builtInKotlin=false
android.newDsl=false
```

No Flutter/Dart application code or database contents were changed for this build-system fix.

In Codemagic, push this updated project to your repository and start the existing **Coastal Pearl Inventory - Android APK** workflow again. Keep `flutter: stable` and `java: 17`.
