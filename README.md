# Trio Glucose — Garmin Watch App

Displays live blood glucose, trend arrow, IOB/COB, and pump status on your Garmin watch.  
Lets you deliver a bolus from your wrist with a two-step confirm on the watch itself.

---

## What you need before starting

- A **Mac** (Xcode only runs on macOS — this whole guide is Mac-based)
- Your **iPhone** already in Developer Mode (`Settings → Privacy & Security → Developer Mode → On`)
- **Trio** installed on your iPhone and working
- **Garmin Connect** installed on your iPhone, your watch paired to it
- A USB cable for your watch (the one that came with it)
- A USB cable for your iPhone (or wireless via Xcode)

Nothing else needs to be installed yet — the guide covers every step.

---

## How it works

```
Trio (iPhone) — writes glucose to HealthKit every 5 min
        ↓
TrioGarminCompanion (the iOS app you build from this repo)
        ↓  sends glucose over Bluetooth via Garmin's SDK
Garmin Connect (already on your iPhone)
        ↓  BLE
Your Garmin Watch — shows glucose, trend, IOB, COB, pump status
        ↑  bolus request (two-step confirm on watch)
        ↓  sent straight to Trio's local API
```

---

## Step 1 — Get the code onto your Mac

Open Terminal on your Mac and run:

```bash
git clone https://github.com/theomex/GarminTrioApp.git
cd GarminTrioApp
```

---

## Step 2 — Enable HealthKit in Trio

The companion app reads glucose from HealthKit, which Trio writes to.

1. Open **Trio** on your iPhone
2. Go to **Settings → Services**
3. Turn on **Health** (HealthKit integration)
4. Make sure **Blood Glucose** and **Insulin Delivery** are both enabled

---

## Step 3 — Get a free Apple Developer account

You need this to install your own app on your iPhone.  
A free account works but the app expires after 7 days and must be re-installed.  
A paid account ($99/year) gives 1-year installs — worth it if you use this daily.

1. Go to https://developer.apple.com and sign in with your Apple ID
2. That's it — you're enrolled. Xcode will handle the rest automatically.

---

## Step 4 — Install Xcode

1. Open the **App Store** on your Mac
2. Search **Xcode** and install it (it's large — ~15 GB, takes a while)
3. Once installed, open it once and accept the licence agreement
4. Open Terminal and run:

```bash
sudo xcode-select --switch /Applications/Xcode.app
```

---

## Step 5 — Get the Garmin Connect IQ Companion SDK

This is the library that lets the iOS app talk to your Garmin watch.

```bash
cd ~/GarminTrioApp
git clone https://github.com/garmin/connectiq-companion-app-sdk-ios.git
```

---

## Step 6 — Build the iOS companion app in Xcode

### Open the project

```bash
open ios_companion
```

Xcode will open. If it asks you to install additional components, click Install.

### Add the Garmin SDK framework

1. In the Xcode file list on the left, click the **TrioGarminCompanion** project (top item)
2. Select the **TrioGarminCompanion** target
3. Click the **General** tab
4. Scroll down to **Frameworks, Libraries, and Embedded Content**
5. Click **+**
6. Click **Add Other… → Add Files…**
7. Navigate to `~/GarminTrioApp/connectiq-companion-app-sdk-ios/ConnectIQ.xcframework` and click **Add**
8. Make sure it shows **Embed & Sign** (not "Do Not Embed")

### Add the URL scheme (required by the Garmin SDK)

1. Still in the **TrioGarminCompanion** target, click the **Info** tab
2. Expand **URL Types** at the bottom
3. Click **+** and fill in:
   - **Identifier**: `com.yourname.triogarmin` (anything unique)
   - **URL Schemes**: `trio-garmin`

### Sign the app with your Apple ID

1. Click the **Signing & Capabilities** tab
2. Under **Team**, choose your Apple ID from the dropdown
3. Xcode will automatically create a signing certificate — if it says "Fix Issue", click it

### Enable HealthKit capability

1. Still on **Signing & Capabilities**
2. Click **+ Capability** (top left of that tab)
3. Search **HealthKit** and double-click it to add it

### Install on your iPhone

1. Plug your iPhone into your Mac (or use wireless: Window → Devices and Simulators → pair)
2. At the top of Xcode, click the device selector and pick your iPhone
3. Press **Cmd+R** to build and install
4. On your iPhone, go to **Settings → General → VPN & Device Management** → find your Apple ID developer certificate → tap **Trust**
5. Open the **Trio Garmin** app on your iPhone — grant the HealthKit permissions it asks for

> Keep this app running in the background whenever you want watch data. You can put it in the background; it will wake periodically via background refresh.

---

## Step 7 — Install the Connect IQ SDK on your Mac

This is needed to build the Garmin watch app.

1. Go to https://developer.garmin.com/connect-iq/sdk/
2. Download the **Connect IQ SDK Manager** for Mac
3. Open the downloaded `.dmg` and run the installer
4. Open **SDK Manager** from your Applications folder
5. Click **Install** next to the latest SDK version (7.x)
6. Note the SDK path shown — usually `~/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-7.x.x/`

---

## Step 8 — Install VS Code and the Monkey C extension

Monkey C is the programming language Garmin watches use.

1. Download VS Code from https://code.visualstudio.com and install it
2. Open VS Code
3. Click the **Extensions** icon in the left sidebar (or press `Cmd+Shift+X`)
4. Search **Monkey C** — install the one by **Garmin**
5. When prompted, point it at your SDK folder (the path from Step 7)

---

## Step 9 — Get a free Garmin developer key

You need this once to sign the watch app for sideloading. It's free.

1. Go to https://developer.garmin.com and create a free account (or sign in)
2. Click your profile → **Keys**
3. Click **Generate Key**
4. Download the `.der` file — save it somewhere you'll remember, e.g. `~/garmin-developer-key.der`

---

## Step 10 — Build and sideload the watch app

### Open the project

```bash
code ~/GarminTrioApp
```

VS Code will open the repo folder. The Monkey C extension will detect `manifest.xml`.

### Add a placeholder launcher icon

The app requires a 70×70 PNG icon. A quick option:

```bash
# Creates a solid red 70x70 PNG as a placeholder
python3 -c "
from PIL import Image
img = Image.new('RGB', (70, 70), color=(200, 0, 0))
img.save('$(pwd)/resources/drawables/launcher_icon.png')
" 2>/dev/null || \
  curl -s "https://via.placeholder.com/70/CC0000/FFFFFF.png" \
       -o ~/GarminTrioApp/resources/drawables/launcher_icon.png
```

Or simply copy any 70×70 PNG into `resources/drawables/launcher_icon.png` yourself.

### Build for your specific watch model

In VS Code, press `Cmd+Shift+P`, type **Connect IQ: Build for Device**, press Enter, then pick your watch model from the list (e.g. `fenix7`, `fr955`, `vivoactive4`).

If your model isn't listed, add it to the `<iq:products>` section in `manifest.xml` using the device ID from https://developer.garmin.com/connect-iq/compatible-devices/.

### Copy the app to your watch via USB

1. Connect your watch to your Mac with its USB charging cable
2. It will appear as a USB drive in Finder (named after your watch model)
3. Open it in Finder → navigate to the **GARMIN** folder → open **APPS**
4. Drag `~/GarminTrioApp/bin/TrioGlucose.prg` into the **APPS** folder
5. Eject the watch drive in Finder
6. The **Trio Glucose** app will appear in your watch's app list immediately

> If you don't see a `bin/` folder after building, check the VS Code terminal panel for any build errors — the most common one is a missing or wrong developer key path.

**Alternative — build and sideload in one step via VS Code:**

1. With your watch connected via USB, press `Cmd+Shift+P` → **Connect IQ: Run on Device**
2. VS Code builds and copies in one go

---

## Step 11 — First run

1. Open **Garmin Connect** on your iPhone (must be open or running in background)
2. Open **Trio Glucose** on your watch
3. Open **Trio Garmin Companion** on your iPhone
4. Within about 60 seconds your glucose should appear on the watch

If the watch shows "Waiting for Trio data..." for more than 2 minutes:
- Make sure the companion app has HealthKit permission (iPhone Settings → Privacy → Health → Trio Garmin → turn on Blood Glucose)
- Make sure Trio's HealthKit integration is enabled (Step 2)
- Make sure Garmin Connect is open on your iPhone

---

## Watch controls

| Button | Action |
|--------|--------|
| **UP** | Open bolus dose picker |
| **DOWN** | Show pump detail screen (reservoir, battery, temp basal) |
| **SELECT** (middle button) | Request an immediate glucose refresh |
| **BACK** | Go back / exit |

**Bolus flow (no phone confirmation required):**

1. Press **UP** to open the dose picker
2. Press **UP/DOWN** to set the dose (steps of 0.05 u, max 25 u)
3. Press **SELECT** — watch shows a confirm screen with the dose
4. Press **SELECT** again — bolus is sent directly to Trio

---

## Keeping the companion app installed (free account only)

With a free Apple developer account, the app expires after 7 days. To re-install:

1. Plug in your iPhone, open Xcode, press `Cmd+R`

That's it — no code changes needed, just a rebuild. Consider upgrading to a paid Apple developer account ($99/year) to avoid this.

---

## Safety note

Trio's own safety limits (max bolus, glucose thresholds) still apply on every bolus request — this app can't send more than Trio allows. That said, this is a personal DIY tool, not a certified medical device. Always glance at your CGM reading before confirming a bolus.
