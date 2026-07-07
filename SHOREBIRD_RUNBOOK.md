# Shorebird Patching Runbook

## Overview
This runbook provides the workflow and safety checklist for deploying over-the-air (OTA) updates using Shorebird to fix Dart-level bugs in Lunara post-launch, without waiting for app store reviews.

## How to Ship a Patch
1. **Verify you are on the correct release branch.** You must patch against the exact release you are modifying.
2. **Make your Dart code changes.**
3. **Run safety checklist** (see below) to ensure changes are patchable.
4. **Deploy the patch:**
   - Android: `shorebird patch android`
   - iOS: `shorebird patch ios`
   - Both: Run both commands sequentially.

## Safety Checklist Before Patching
> [!WARNING]
> Shorebird **cannot** patch changes to native code, assets, or new plugins that include native code. If you violate this, the patched app might crash.

Before running `shorebird patch`, always run:
```bash
git diff <previous_release_commit_hash> --stat
```
Verify that the output **ONLY** contains:
- `lib/**/*.dart`
- `pubspec.yaml` (only if bumping Dart-only packages)

If you see changes to `android/`, `ios/`, `assets/`, `Info.plist`, `AndroidManifest.xml`, or native dependencies added in `pubspec.yaml`, **STOP**. You must do a full store release via `shorebird release`.

## First Time Release
The very first version you release to the app store must be built with Shorebird so it can receive patches later.
- Instead of `flutter build appbundle`, use: `shorebird release android`
- Instead of `flutter build ipa`, use: `shorebird release ios`

## Rollout Status & Verification
- **Check Patch Status:** `shorebird patches list`
- **Verify locally:** Shorebird allows you to test patches locally using the Shorebird CLI and dashboard. You can run `shorebird preview` to see how the app runs with the patch before full deployment.
- **Rollback:** If a bad patch goes out, immediately commit a revert and push a new patch. 

## Best Practice: Remote Config
Shorebird fixes code. It won't help if a *feature itself* is fundamentally broken and you need to hide it instantly. Consider adding **Firebase Remote Config** (or Supabase Remote Config) feature flags around your riskiest features (cycle prediction logic, hormone insight calculations) so you have an instant kill-switch layer on top of Shorebird's patch layer.
