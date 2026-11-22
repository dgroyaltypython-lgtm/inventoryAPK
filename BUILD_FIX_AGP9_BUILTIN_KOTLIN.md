# Android build configuration migration (AGP 9)

This project now uses the AGP 9 public Android DSL and AGP built-in Kotlin.

- Gradle wrapper: 9.5.0
- Android Gradle Plugin: 9.3.1
- Java target: 17
- `android.newDsl=true`
- `android.builtInKotlin=true`
- Removed the legacy `org.jetbrains.kotlin.android` plugin declaration.
- Removed deprecated `kotlinOptions {}` and configured JVM 17 using `kotlin.compilerOptions`.

These changes address the previous Kotlin DSL compilation errors that reported the legacy
`Project.android(Action<BaseAppModuleExtension>)` call and deprecated `kotlinOptions` APIs.

## Rebuild in Codemagic

1. Replace the repository contents with this project version and push the commit.
2. Keep the workflow on Flutter `stable`, Java 17, and `mac_mini_m2`.
3. Run `Coastal Pearl Inventory - Android APK`.
4. Download `build/app/outputs/flutter-apk/app-release.apk` from the artifacts.

The project configuration has been statically checked here. A complete APK build still needs
to run on Codemagic with its Flutter and Android SDK installations.
