# Smart Greenhouse Frontend — Manual Testing Guide

A step-by-step, tap-by-tap guide for manually exercising **every screen and user
action** in the Flutter mobile app. Where the app only *reacts* to data produced
elsewhere (telemetry, alerts, ML predictions), this guide includes copy-paste
backend commands so you can drive those flows and watch the UI respond.

> Tested flow: first-launch consent → register → log in → add a greenhouse →
> add a device → (simulate telemetry) → watch dashboard/trends → create an alert
> rule → trigger & resolve an alert → view ML insights → manage greenhouses →
> check system status → log out. Plus validation, empty-state, offline and
> session-expiry checks.

This guide pairs with [backend/TESTING_GUIDE.md](../backend/TESTING_GUIDE.md):
the backend guide is the easiest way to push telemetry and train the ML model
so the app has something to show.

---

## 0. Prerequisites

### 0.1 Backend must be running

The app is a thin client; nothing works without the API. Start it first
(see the backend guide §0):

```bash
cd backend
docker-compose up -d
docker-compose exec api alembic upgrade head
```

Confirm it answers: `curl -s http://localhost:8000/health` → `{"status":"ok"}`.

### 0.2 Toolchain

```bash
cd frontend
flutter pub get
flutter devices          # list emulators / connected devices
```

### 0.3 Point the app at your backend (important)

The base URL defaults to `http://10.0.2.2:8000`, which is **only** correct for
the **Android emulator** (it maps to the host's `localhost`). For anything else,
override it at launch:

| Target | Run command |
|---|---|
| Android emulator | `flutter run` (default `10.0.2.2:8000`) |
| iOS simulator | `flutter run --dart-define=API_BASE_URL=http://localhost:8000` |
| Physical device (same LAN) | `flutter run --dart-define=API_BASE_URL=http://<your-PC-LAN-IP>:8000` |
| Web (dev) | `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000` |

> Release builds are HTTPS-only (cleartext HTTP is allowed only in debug/profile).
> A physical device must also be able to reach the PC (same Wi-Fi, firewall open
> on 8000).

### 0.4 Permissions

- **Camera** — required for the QR scanner (§6.2). Android prompts on first use.
  On iOS you must have `NSCameraUsageDescription` in `Info.plist` or the scanner
  view stays black.
- **Notifications** — the app requests permission on launch (§12); allow it to
  test push deep-links.

### 0.5 A note on test accounts / passwords

The **login/register forms** validate: a valid email format and a password of
**≥ 8 characters**. The **backend** registration is stricter — it requires
**12–72 characters**. So to register successfully end-to-end, use a password of
**at least 12 characters** (e.g. `supersecret123`). A 8–11 char password passes
the form but the server returns an error you'll see as a red snackbar.

---

## 1. First launch — KVKK consent

On a fresh install the first screen is the **KVKK Aydınlatma Metni** (data-privacy
notice, Turkish).

1. Scroll the consent text (it scrolls independently).
2. Tap **“Okudum ve Anladım”**.

Expected:
- You proceed to the **Login** screen.
- Consent is persisted (SharedPreferences key `kvkk_accepted`). Fully close and
  relaunch the app → the consent screen does **not** appear again.

> To re-test the consent screen, clear app storage (Android: App info → Storage →
> Clear data) or reinstall.

---

## 2. Authentication

### 2.1 Register

From the Login screen tap **Register** (bottom).

1. **Full Name** — optional; if filled, must be ≥ 2 chars.
2. **Email** — must be a valid email format.
3. **Password** — ≥ 8 chars for the form, but use **≥ 12** so the backend accepts it.
4. Tap **Register**.

Expected (happy path):
- Button shows a spinner, then the app **auto-logs-in** and lands on the
  **dashboard** (Home tab) — registration immediately signs you in.

Validation checks (no network call should fire):
- Empty email / bad email (`abc`) → inline “Enter a valid email address”.
- Password `short` → inline “Password must be at least 8 characters”.
- A valid-looking but 8–11 char password → form passes, **server rejects** →
  red snackbar (e.g. registration failed / password too short).
- Registering an email that already exists → red snackbar with the server message.

### 2.2 Login

If you’re already authenticated, log out first (§11) to reach this screen.

1. Enter **Email** and **Password**.
2. Tap **Login** (or submit from the password field).

Expected:
- Spinner on the button, then the dashboard.
- Wrong password / unknown email → red snackbar; the form stays usable
  (the button re-enables immediately — no stuck spinner).
- Same inline validation as register for empty/invalid fields.

### 2.3 Session persistence & expiry

- **Persistence:** with a valid session, fully close and relaunch → you land on
  the dashboard without logging in (a brief spinner while the token is verified).
- **Transient network blip:** stop the backend, launch the app, then start the
  backend within a few seconds → the app retries and should still reach the
  dashboard (it does **not** drop you to login on a transient error).
- **Expired/invalid session:** if the refresh token is no longer valid, the next
  authenticated request routes you back to **Login** automatically (rather than
  showing repeated errors).

---

## 3. Main navigation

After login you’re in the **bottom-tab shell** with five tabs:

| Index | Label | Screen |
|---|---|---|
| 0 | **Home** | Dashboard |
| 1 | **Devices** | Device list |
| 2 | **Insights** | ML prediction |
| 3 | **Alerts** | Alert center |
| 4 | **Profile** | Settings |

- Tap each tab; the selected tab highlights in neon-green.
- The **notification bell** on the dashboard header jumps to the **Alerts** tab.
- A push notification of type `greenhouse_alert`, when tapped, also opens the
  **Alerts** tab (§12).

The **active greenhouse** is shared across Home, Devices, Insights, Alerts and
Profile. Changing it in one place (§4.3) updates all of them.

---

## 4. Greenhouses

### 4.1 Empty state

A brand-new account has no greenhouses. The dashboard shows **“No Greenhouses
Added”** with an **Add Greenhouse** button. Devices/Alerts/Insights show their own
“add a greenhouse first” empty states.

### 4.2 Add a greenhouse

Open the form via dashboard **Add Greenhouse**, the **Quick Actions → Add
Greenhouse**, the greenhouse selector’s **Add New Greenhouse**, or Settings →
**Add Greenhouse**.

Fill the form (**Greenhouse Profile**):
1. **Greenhouse Name** — required.
2. **Crop Type** — dropdown (Tomato/Cucumber/Pepper/Lettuce/Other).
3. **Variety** — dropdown; options change with the crop.
4. **Planting Date** / **Expected Harvest Date** — date pickers (neon-themed).
   Harvest must be **after** planting (otherwise inline error).
5. **Agricultural Inputs** — Nitrogen / Phosphorus / Potasium fertilizer (kg/ha),
   all required, numeric (comma or dot decimal accepted).
6. **Location** — **City** then **District** (District enables after a City is
   chosen; loaded from `assets/data/turkey_locations.json`).
7. **Area Size** (m²) — optional; if present must be a positive number.
8. **Optional Attributes** — tap **Add Attribute** to add free-form key/value
   rows (numeric keys like `soil_pH` are stored as numbers).
9. Tap **Save Greenhouse**.

Expected:
- Spinner → green success snackbar → returns to the previous screen.
- The new greenhouse appears in the dashboard / selector / Settings list and
  becomes selectable.

Validation checks:
- Submit with empty name / missing dates / missing fertilizer → inline errors,
  no submit.
- Pick a harvest date before planting → “Harvest must be after planting”.
- City required; District required once a city is picked.

> The crop/variety/planting/harvest/fertilizer values are exactly what the ML
> worker consumes — set them realistically so Insights (§9) can produce a
> prediction.

### 4.3 Switch the active greenhouse

If you have ≥ 2 greenhouses:
1. On Home/Devices/Profile tap the **greenhouse name row** (eco-leaf icon + ▾).
2. The **My Greenhouses** bottom sheet lists them; the active one is checked.
3. Tap another → sheet closes and **all tabs** now reflect that greenhouse.

### 4.4 Delete a greenhouse

Profile (Settings) → **My Greenhouses** → trash icon on a card → confirm
**Delete**.

Expected:
- The greenhouse disappears; if it was the selected one, selection resets to the
  first remaining greenhouse.
- Deletion cascades on the backend (its devices/telemetry/alerts go too).

---

## 5. Dashboard (Home)

With a greenhouse selected (and ideally a device + telemetry, see §6–§7):

Verify each section:
- **Header** — “Greenhouse Overview”, the greenhouse name • location, the
  selector row, and the **bell** (→ Alerts).
- **Greenhouse Health** — status pill (“Stable” when a device exists, else
  “Setup Required”) and mini-stats **Devices / Online / Sync (Live)**.
- **No device** → an orange “no device linked” card. **With a device** →
  **Live Sensor Overview**:
  - big **Temperature** card (“Optimal” at 18–30 °C else “Attention needed”),
  - **Humidity / Soil / Light / CO₂** metric cards,
  - **Device Battery** card (“Low” under 40%).
  - Values show `--` until telemetry arrives.
- **Today’s Recommendation** card.
- **Quick Actions** — **Add Greenhouse**, **View Devices** (jumps to Devices tab).

Behaviours:
- **Live polling:** telemetry refreshes about every **5 s**. Push a new reading
  (§7) and watch the cards update without manual refresh.
- **Backgrounding:** send the app to the background and return — polling pauses
  while backgrounded and resumes (with an immediate fetch) on resume.
- **Pull-to-refresh:** pull down to refresh greenhouses/devices.
- **Error state:** stop the backend and pull-to-refresh → a red error message
  (no silent blank).

---

## 6. Devices

Open the **Devices** tab.

- **Summary card** — system status (“All Systems Online” / “Attention Needed” /
  “No Devices”) and **Total / Online / Offline** counts.
- **Connected Devices** list — each card shows name, serial, type, firmware,
  a status badge, and a connectivity line.
- Empty → **“No Devices Added”**.
- **Pull-to-refresh** re-fetches devices.

### 6.1 Add a device (manual entry)

**Connected Devices → Add Device**:
1. **Device Name** — required, ≥ 3 chars.
2. **Serial Number** — required, ≥ 3 chars (or scan, §6.2).
3. Tap **Add Device**.

Expected:
- Green success snackbar → back to the list; the device appears.
- **Status is `OFFLINE` on creation** (type/firmware are auto-set). It flips to
  **ONLINE** only after the device actually reports telemetry (§7). This is the
  correct, honest behaviour — a freshly added device is not “online”.

Validation: empty/short name or serial → inline errors.

### 6.2 Add a device by QR

On the Add Device form tap the **scan icon** in the Serial Number field.
1. Grant the camera permission if prompted.
2. Point at any QR code (e.g. generate one containing `AA:BB:CC:DD:EE:01`).
3. **Toggle Flash** turns the torch on/off.

Expected: on a successful scan the scanner closes, the serial field is filled,
and a “scanned successfully” snackbar shows.

### 6.3 Make a device report (so it goes ONLINE + produces telemetry)

The app can’t emit telemetry — a device (or the backend guide) does. Quickest way
to light everything up, using the backend guide’s tools. From the **backend**
folder, get a token and IDs, then publish:

```bash
export BASE="http://localhost:8000"; export MQTT_HOST="localhost"
export EMAIL="tester@example.com"; export PASSWORD="supersecret123"

# token
ACCESS=$(curl -s -X POST "$BASE/api/v1/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$EMAIL&password=$PASSWORD" | jq -r .access_token)
AUTH="Authorization: Bearer $ACCESS"

# grab the greenhouse + its first device id (created in the app)
GH_ID=$(curl -s "$BASE/api/v1/greenhouses/" -H "$AUTH" | jq -r '.[0].id')
DEV_ID=$(curl -s "$BASE/api/v1/devices/greenhouse/$GH_ID" -H "$AUTH" | jq -r '.[0].id')

# publish a telemetry reading over MQTT (humidity 88 will also trip a >80 rule)
mosquitto_pub -h "$MQTT_HOST" -q 1 \
  -t "greenhouse/$GH_ID/device/$DEV_ID/telemetry" \
  -m '{"temperature":26.1,"humidity":88.0,"soil_moisture":42,"light_intensity":13500,"co2":640,"battery_level":95}'
```

> You can also get `DEV_ID` from the app: open the device → **Device Information →
> Device ID**.

Back in the app: pull-to-refresh **Devices** → the device now shows **ONLINE**,
and the **Dashboard** sensor cards populate within ~5 s.

### 6.4 Device detail

Tap a device card.

- **Status card** — Online/Offline with description.
- **Latest Telemetry** — Temperature / Humidity / Soil / Light / CO₂ / Battery
  cards, or an “no telemetry received yet” card.
- **Telemetry Trends** — a line chart with metric chips **Temp / Humidity / Soil /
  Light / CO₂**. Needs **≥ 2** telemetry points for the selected metric; otherwise
  shows “Not enough telemetry history”. Switch metrics; check Latest/Avg/Min/Max.
  (Send several readings via §6.3 in a loop to populate it.)
- **Device Information** — id, serial, type, firmware, status.
- **Maintenance Actions:**
  - **Restart** / **Calibrate** → informational snackbars (command flow is a
    backend stub; no command is sent).
  - **Remove** → confirm dialog → deletes the device and pops back to the list
    (success snackbar). Errors show a red snackbar.

---

## 7. Telemetry (driving the live UI)

Telemetry is produced by devices/backend, not the app. Use §6.3 to publish.
To **simulate a stream** and watch the dashboard + trends move:

```bash
for h in 50 60 75 88 91 40; do
  mosquitto_pub -h "$MQTT_HOST" -q 1 \
    -t "greenhouse/$GH_ID/device/$DEV_ID/telemetry" \
    -m "{\"temperature\":25,\"humidity\":$h,\"soil_moisture\":40,\"light_intensity\":12000,\"co2\":600,\"battery_level\":80}"
  sleep 2
done
```

Watch:
- Dashboard cards update (~5 s cadence).
- Device detail **Telemetry Trends** chart grows.
- A `humidity > 80` alert rule (§8) fires on the 88/91 readings.

> REST ingestion also marks a device ONLINE. If you prefer REST over MQTT, use the
> backend guide §7 (`POST /api/v1/telemetry/`).

---

## 8. Alert rules (per device)

Open a device → **Alert Rules → Add Rule** (bottom sheet **Create Alert Rule**):
1. **Sensor Field** — temperature / humidity / soil_moisture / light_intensity /
   co2 / battery_level.
2. **Operator** — `>= <= > < == !=`.
3. **Threshold** — numeric, required (invalid → red snackbar).
4. **Severity** — info / warning / critical.
5. **Custom Message** — optional.
6. **Rule Enabled** — toggle.
7. **Save Rule**.

Expected:
- The rule appears in the **Alert Rules** list with a severity icon and
  ACTIVE/OFF badge.
- **Enable/Disable** toggles the rule (badge updates).
- **Delete** → confirm → removed (snackbar).

Create e.g. **humidity `>` 80, critical** so the §7 stream produces an alert.

---

## 9. Alerts

Open the **Alerts** tab (it reflects the **selected** greenhouse).

- **Summary** — **Active Alerts**, **Critical**, and a **Greenhouse Alert Health**
  card.
- **Filter tabs** — **All / Critical / Warning / Resolved**.
- **RECENT ALERTS** list — newest first; unacknowledged appear above resolved.
  Each card shows: a friendly title, the raw alert type, a severity badge, the
  message, and a metadata block (**Time**, Current Value, Measured Field,
  Threshold, Device ID).
- **Pull-to-refresh**; **Retry** button on error; empty-state per filter.

Actions on an unacknowledged alert:
- **Mark as Resolved** → card moves to **Resolved**, shows “This alert has been
  resolved.”, green snackbar.
- **Dismiss** → confirm dialog → alert removed from the list.

Behaviours to confirm:
- After §7/§8 produces an alert, it shows here without restarting the app
  (pull-to-refresh if needed).
- Switching the active greenhouse (§4.3) changes which alerts are shown.
- The **Time** field reflects when the alert was created (newest first ordering).

---

## 10. Insights (ML prediction)

Open the **Insights** tab. It shows the **latest backend prediction for the
selected greenhouse**.

Possible states:
- **No greenhouse selected** — add a greenhouse first.
- **No prediction yet** — explains the requirements (trained model + complete
  greenhouse metadata + recent telemetry). This is expected until the backend has
  produced one.
- **Loaded** — **Predicted Yield** (kg/m²), **Model Version**, **Timestamp**, plus
  an **Insight Status** panel.
- **Error** — “Prediction could not be loaded” + **Retry**.
- **Pull-to-refresh** re-fetches.

To make a prediction appear (see backend guide §11):
1. Train a model (ADMIN): backend `POST /api/v1/ml/train` with
   `data/raw/greenhouse_crop_yields.csv` present; confirm
   `GET /api/v1/ml/health` → `model_loaded: true`.
2. Ensure the greenhouse metadata has crop/variety/planting/harvest (§4.2).
3. Stream telemetry (§7).
4. Wait ~2 minutes for the prediction worker, then pull-to-refresh Insights.

---

## 11. Profile / Settings

Open the **Profile** tab.

- **Header** — “Profile”, greenhouse selector row.
- **Profile card** — greenhouse operator summary with **Greenhouses / Devices /
  Online** counts.
- **System Status** (live, from the backend):
  - **Backend** — `Online` (green) when `/health` responds, else `Offline` (red);
    shows `...` while loading. Stop the backend and revisit/refresh → `Offline`.
  - **ML Model** — `Ready` when `/api/v1/ml/health` reports a loaded model, else
    `Not trained` (orange).
  - **Telemetry** — `Active` when the greenhouse has ≥ 1 device, else `Waiting`.
- **My Greenhouses** — select (highlights + check), delete (confirm), and
  **Add Greenhouse**.
- **Security → Log Out** — clears the session and returns to **Login**.
- Footer shows **“Smart Greenhouse v1.0.0”** (matches `pubspec.yaml`).

> The previous fake “Database: Synced / MQTT: Ready” cards and the non-functional
> notification/temperature-unit toggles have been removed — everything shown here
> reflects real backend state.

---

## 12. Push notifications (FCM)

Full push testing needs Firebase configured on the backend
(`FIREBASE_SERVICE_ACCOUNT_PATH`) and a real device/emulator with Google Play
services.

- On login the app requests notification permission and **registers its FCM
  token** with the backend (`POST /api/v1/notifications/fcm-token`). The reported
  `platform` reflects the real platform (`android`/`ios`/`web`).
- Trigger a test push from the backend (it targets your registered tokens):

  ```bash
  curl -s -X POST "$BASE/api/v1/notifications/test" -H "$AUTH" | jq
  ```

- **Foreground:** the message is logged (debug console) — no system banner.
- **Background/terminated:** tapping a notification whose data `type` is
  `greenhouse_alert` opens the app on the **Alerts** tab.

> Without valid Firebase credentials the backend `/test` reports failures; that’s
> expected and not an app bug.

---

## 13. Cross-cutting / negative checks

- **Offline launch:** with the backend down, the app should not crash; screens
  show loading→error states and pull-to-refresh recovers once the backend is up.
- **Validation:** every form blocks submit on invalid input with inline messages
  (auth §2, add greenhouse §4.2, add device §6.1, alert rule §8).
- **Ownership/scoping:** the app only ever shows the logged-in user’s greenhouses,
  devices, telemetry and alerts.
- **No stuck spinners:** failed login/register re-enable the form; failed actions
  surface a red snackbar.
- **Empty states:** new account (no greenhouse), greenhouse with no device, device
  with no telemetry, no alerts, no ML prediction — each has a friendly message.

---

## Appendix — screen / action inventory

| Area | Screen | Key actions |
|---|---|---|
| Consent | KVKK page | Accept (persisted) |
| Auth | Login | Validate, log in, error snackbar |
| Auth | Register | Validate, register → auto-login |
| Auth | (global) | Session persist, transient-retry, auto-logout on expiry |
| Shell | Bottom nav | Switch Home/Devices/Insights/Alerts/Profile; bell→Alerts |
| Greenhouse | Add Greenhouse | Crop/variety/dates/fertilizer/location/area/custom attrs |
| Greenhouse | Selector sheet | Switch active greenhouse |
| Greenhouse | (Settings) | Delete greenhouse (confirm) |
| Dashboard | Home | Health card, live sensor cards, recommendation, quick actions, pull-to-refresh, live polling |
| Devices | Device list | Summary, list, add, pull-to-refresh |
| Devices | Add Device | Manual entry + QR scan; registers OFFLINE |
| Devices | QR scanner | Scan serial, torch toggle |
| Devices | Device detail | Latest telemetry, trends chart, alert rules CRUD, info, restart/calibrate/remove |
| Alerts | Alert center | Summary, filters, time/metadata, resolve, dismiss, pull-to-refresh |
| Insights | ML prediction | Predicted yield/model/timestamp; loading/empty/error; pull-to-refresh |
| Settings | Profile | Profile stats, live system status, greenhouse list, log out |
| Notifications | (background) | FCM token registration, alert deep-link to Alerts tab |

> For anything that requires server-side data (telemetry, alerts firing, ML
> predictions, push sends), use [backend/TESTING_GUIDE.md](../backend/TESTING_GUIDE.md)
> to produce it and watch the app react.
