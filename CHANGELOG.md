## Unreleased

* fix(android): method calls no longer fail with `MissingPluginException` when the app runs more
  than one Flutter engine (e.g. a `firebase_messaging` background isolate, or a new activity starting
  before the old one is destroyed). Each engine now uses its own messenger and view registry (#46)

## 0.2.0

* feat: audio volume — `DotLottieViewController.setAudioVolume()` and `audioVolume()`
* feat: slots — `setSlot()`, `setColorSlot()`, `setScalarSlot()`, `setTextSlot()`,
  `setVectorSlot()`, `setPositionSlot()`, `setImageSlot()`, `setBezierPathSlot()`,
  `clearSlot()`, `clearSlots()`, `resetSlot()`, `resetSlots()`, `getSlotIds()`,
  `getSlotType()`, `getSlot()` and `getSlots()`
* feat: state machines — `stateMachineStatus()`, `stateMachineSetSeed()`,
  `stateMachineOverrideState()` and `stateMachineResetInput()`
* feat: `DotLottieView.externalAssets` supplies the bytes of assets the animation references
  but does not embed (not supported on Windows/Linux, ignored on Android with `useOpenGL`)
* feat: playback — `setLoopCount()` and `setBackgroundColor()`
* feat(desktop): `setSlots()`, `stateMachineGetInputs()` and the `speed()`, `loop()`,
  `autoplay()`, `mode()` and `useFrameInterpolation()` getters are now wired to the FFI player
* fix(android): `stateMachineGetInputs()` is implemented
* fix: `stateMachineGetInputs()` no longer lists built-in inputs such as `@elapsedTime`
* fix(android): `setTheme()`, `setThemeData()` and `setSlots()` no longer report failure;
  `stateMachineLoadData()` and `getStateMachine()` are implemented; the `loopCount`, `marker`
  and `themeId` properties are applied on load; `stateMachineOnInputFired` no longer throws
* fix(web): `setSlots()`, `setSegments()`, `currentProgress()` and `stateMachineCurrentState()`
* fix: `markers()` no longer throws when reading a marker. Markers now carry `name`, `start`,
  `end`, `time` and `duration` on every platform
* fix: `'reverse-bounce'` and `'reverseBounce'` are both accepted as the playback mode
* chore: bumped dotlottie-android to 0.18.0, dotlottie-ios to 0.17.0 and dotlottie-web to 0.83.0

## 0.1.7

* chore(android): migrate to Flutter's Built-in Kotlin. The Android plugin no
  longer applies the Kotlin Gradle Plugin (KGP) itself; Flutter's Gradle plugin
  auto-applies KGP on the plugin subproject instead. This silences the
  `Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP)`
  warning that Flutter prints for consumers of `dotlottie_flutter`, and
  prepares the plugin for AGP 9. Matches the pattern used across all current
  `flutter/packages` plugins (video_player, camera_android_camerax,
  shared_preferences_android, url_launcher_android, etc.).
* Raises the minimum supported Flutter to 3.44 / Dart 3.12, as required by the
  Built-in Kotlin migration. No Dart API changed: pub resolves consumers on
  older SDKs to `dotlottie_flutter: 0.1.6` automatically.

## 0.1.6

* fix: `DotLottieView` now honours its `width` and `height` — the platform view is
  wrapped in a `SizedBox` when either is set, instead of expanding to the parent
* fix(ios): opt out of `UIHostingController` safe-area insets so the animation stays
  inside the platform view's bounds (iOS 16.4+)
* fix(example): removed a duplicate plugin package that broke SPM resolution

## 0.1.5

* chore: upgrading macos and ios deps to fix SPM error related to wgpu

## 0.1.4

* chore: spm integration, bumped dotlottie-ios dep. to v0.15.7 for layout fixes
* feat: live layout updates — `DotLottieViewController.setLayout()` and automatic
  re-layout when `DotLottieView.fit` changes (iOS, macOS, Android, web, desktop)

## 0.1.3

* chore: bumped dotlottie-ios dep. to v0.15.6

## 0.1.2

* fix: Load web asset via rootBundle

## 0.1.1

* fix: Moved animation loading from url to main thread

## 0.1.0

* feat: Windows and Linux support

## 0.0.7

* fix: crash when multiple animations are unloaded

## 0.0.6

* fix: manual loading of animations from urls

## 0.0.5

* fix: hot reload crash, add fit property (translates in to Layout for dotLottie)

## 0.0.4

* fix: crash when loading DotLottieView a second time for android

## 0.0.3

* chore: upgraded dependancies for web, android and ios. Added opengl support for android.

## 0.0.2

* chore: small fixes to example file, updated contact information

## 0.0.1

* feat: initial release of dotLottie Flutter!
