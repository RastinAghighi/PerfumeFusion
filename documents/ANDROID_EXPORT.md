# Android Export Plan

Documentation and planning only. Do not start the Android build until the web version is live and earning revenue. This guide assumes Godot 4.x.

---

## 1. Android Setup Steps

### 1.1 Install prerequisites
- **Android Studio** (latest stable): https://developer.android.com/studio
  - During first launch, let it install the **Android SDK**, **Platform Tools**, **Build Tools**, and at least one **SDK Platform** (API 34 recommended).
  - Accept all SDK licenses when prompted.
- **Java Development Kit (JDK 17)** — Godot 4 requires JDK 17.
  - On Windows, install via Adoptium Temurin 17 (https://adoptium.net) or use the JBR bundled with Android Studio.
- **Command-line tools**: in Android Studio → SDK Manager → SDK Tools, enable **Android SDK Command-line Tools (latest)**. Required for `sdkmanager` and `apksigner`.

### 1.2 Configure Godot
1. Open Godot → **Editor → Editor Settings → Export → Android**.
2. Set the following paths (Windows examples):
   - **Android SDK Path**: `C:\Users\moham\AppData\Local\Android\Sdk`
   - **Java SDK Path** (`Java SDK Path` / `JDK Path`): `C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot`
   - Optional: **OpenJDK Path** if a separate field is shown.
3. Verify Godot detects `adb`, `apksigner`, `zipalign`, and `jarsigner`. Restart the editor if any path was updated.
4. **Project → Install Android Build Template** (required for custom build, plugins like AdMob, and gradle builds).

### 1.3 Generate keystores

#### Debug keystore (one per machine, reused for all dev builds)
```bash
keytool -keyalg RSA -genkeypair -alias androiddebugkey \
  -keypass android -keystore debug.keystore \
  -storepass android -dname "CN=Android Debug,O=Android,C=US" \
  -validity 9999 -deststoretype pkcs12
```
Store at: `C:\Users\moham\.android\debug.keystore` (Android Studio uses this path by default).

#### Release keystore (one per app — back this up!)
```bash
keytool -v -genkey -keystore perfumefusion-release.keystore \
  -alias perfumefusion -keyalg RSA -keysize 2048 -validity 10000
```
- Store password and key password in a password manager. **Losing this keystore means you can never publish updates to the same Play listing.**
- Store at: `C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\export\android\perfumefusion-release.keystore` (back up to a second location).

### 1.4 Create the Android export preset
In Godot → **Project → Export → Add → Android**, configure:
- **Name**: `Android`
- **Architectures**: `arm64-v8a` (required by Play), optionally `armeabi-v7a`.
- **Package → Unique Name**: `com.introtogreatness.perfumefusion`
- **Package → Name**: `Perfume Fusion`
- **Version Code**: `1` (increment every Play upload)
- **Version Name**: `1.0.0`
- **Min SDK**: `24` (Android 7.0) — AdMob's minimum.
- **Target SDK**: `34` (Play requirement as of 2024+).
- **Keystore → Debug**: path to `debug.keystore`, user `androiddebugkey`, password `android`.
- **Keystore → Release**: path to `perfumefusion-release.keystore`, user `perfumefusion`, password from password manager.
- **Permissions**: only enable `INTERNET` and `ACCESS_NETWORK_STATE` (AdMob needs these). Do not request unnecessary permissions — Play will demand justification.
- **Custom Build**: enabled (required for AdMob plugin).

This will be persisted to `export_presets.cfg` in the project root once configured.

---

## 2. AdMob Integration Plan (do not implement yet)

### 2.1 Plugin
- Use **godot-admob-plugin** (open source): https://github.com/Poing-Studios/godot-admob-plugin
- Verify the latest release supports your Godot version (4.x branch).
- Drop the plugin into `addons/admob/` and enable in **Project Settings → Plugins**.
- Plugin requires Custom Build template (see 1.4).

### 2.2 Ad units (create in AdMob console after Play listing is live)
| Unit | Purpose | Test ID (Google-provided) | Production ID |
|---|---|---|---|
| Rewarded Video | Hint / extra moves | `ca-app-pub-3940256099942544/5224354917` | TBD |
| Interstitial | Commercial break between rounds | `ca-app-pub-3940256099942544/1033173712` | TBD |
| App ID | AndroidManifest meta-data | `ca-app-pub-3940256099942544~3347511713` | TBD |

- During development, **always use the Google test IDs above** to avoid AdMob policy strikes.
- Add your physical test device's advertising ID to AdMob's test devices list, or call `MobileAds.setRequestConfiguration(...)` with the test device hash logged on first ad request.

### 2.3 AdManager routing strategy
`AdManager.gd` already exposes `show_rewarded_ad(callback)`, `show_commercial_break()`, `is_ad_available()`, and `init_web_sdk()`. The plan is to add a parallel Android branch:
- `detect_platform()` returns `"admob"` when `OS.has_feature("android")`.
- `init_web_sdk()` becomes the canonical init entry; on Android it routes to `_init_admob()` instead.
- `show_rewarded_ad()` calls `_admob_rewarded()` when platform is `admob`.
- `show_commercial_break()` calls `_admob_interstitial()` (with the same 180s cooldown that already exists).
- All AdMob calls go through plugin singletons (`MobileAds`, `RewardedAd`, `InterstitialAd`) once the plugin is installed.

A skeleton has been added to `AdManager.gd` so the routing exists today; the actual plugin calls remain `push_warning` stubs until the plugin is installed.

---

## 3. Google Play Listing Checklist

- [ ] **$25 developer registration fee** paid at https://play.google.com/console
- [ ] Identity verification completed (Play now requires government ID for new individual accounts)
- [ ] **App icon** — 512×512 PNG, 32-bit, no alpha
- [ ] **Feature graphic** — 1024×500 PNG/JPG, no transparency
- [ ] **Phone screenshots** — at least 2, max 8, 16:9 or 9:16, min 320 px, max 3840 px
- [ ] **7" tablet screenshots** — at least 1
- [ ] **10" tablet screenshots** — at least 1
- [ ] **Short description** — ≤ 80 chars
- [ ] **Full description** — ≤ 4000 chars, ASO keywords woven in (perfume, fragrance, puzzle, match, fusion, scent)
- [ ] **Privacy policy URL** — required because the app shows ads / collects ad ID (host on GitHub Pages or similar)
- [ ] **Content rating questionnaire** completed (IARC) — expected: Everyone
- [ ] **Target audience and content** declaration — confirm age range; if any age < 13, Families Policy applies
- [ ] **Data safety form** — declare AdMob's data collection (advertising ID, approximate device info)
- [ ] **Ads declaration** — Yes, contains ads
- [ ] **App access** — declare no login required
- [ ] **Government apps / financial / health** declarations — none apply
- [ ] **App category** — Games → Puzzle
- [ ] **Tags** — Puzzle, Casual, Brain Games
- [ ] **Contact email** for Play listing
- [ ] **Internal testing track** uploaded and tested before promoting to production
- [ ] **Pre-launch report** reviewed (Play runs the APK on real devices, surfaces crashes)
- [ ] **Signed AAB** uploaded (Play requires App Bundle, not APK, since 2021)
- [ ] **Play App Signing** enrolled (Google holds the upload key; you keep the signing key locally)

---

## 4. Order of Operations (when web is validated)

1. Web revenue confirmed and stable for ≥ 4 weeks.
2. Install Android Studio + JDK 17, configure Godot paths.
3. Install Android Build Template in Godot.
4. Drop in godot-admob-plugin, wire `AdManager.gd` skeleton functions to real plugin calls.
5. Test build with Google test ad IDs on a physical device via `adb install`.
6. Create AdMob app and ad units, swap test IDs for production IDs behind a build flag.
7. Pay Play developer fee, prepare store assets (section 3).
8. Upload signed AAB to Internal Testing.
9. Run pre-launch report, fix any crashes.
10. Promote to Production.
