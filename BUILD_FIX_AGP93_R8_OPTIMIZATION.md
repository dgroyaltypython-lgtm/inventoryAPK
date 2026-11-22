# Build fix: AGP 9.3 release resource shrinking

The latest Codemagic log reports that resource shrinking was requested without code shrinking.

In `android/app/build.gradle.kts`, the release build type previously set `isMinifyEnabled = false`. With AGP 9.3+, use the new optimization DSL instead:

```kotlin
release {
    signingConfig = signingConfigs.getByName("debug")
    optimization {
        enable = true
    }
}
```

AGP 9.3's `optimization { enable = true }` enables code and resource optimization together. This avoids the invalid configuration where unused resources are removed while code shrinking is disabled.

The Codemagic workflow remains on `mac_mini_m2`, Flutter stable, and Java 17. Debug signing remains for test APK installation only; use a private release keystore before publishing to an app store.

This is a source/configuration patch. A full APK build must still be verified by Codemagic.
