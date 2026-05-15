# ESP32 Firmware: Multi-User Architecture

This firmware is designed for the Smart Greenhouse Monitoring System with full support for multi-user isolation and secure device registration.

## 🚀 Key Features

- **Hierarchical MQTT Topics**: Supports isolation via `gh/v1/<user_id>/<gh_id>/<mac>/<type>`.
- **Authenticated MQTT**: Uses the device's MAC address as the username and a pre-shared Secret as the password.
- **Persistent Configuration**: Stores User and Greenhouse identity in Non-Volatile Storage (NVS).
- **LWT (Last Will & Testament)**: Real-time "Offline" detection for the dashboard.
- **Remote Commands**: Automatically subscribes to a command topic upon registration.

---

## 🛠 Configuration

Update `include/constants.h` before flashing:

```cpp
constexpr char WIFI_SSID[] = "Your_SSID";
constexpr char WIFI_PASSWORD[] = "Your_Password";
constexpr char MQTT_SERVER[] = "your.broker.address";
constexpr char DEVICE_SECRET[] = "your_unique_device_secret";
```

## 🔄 Provisioning Flow

1.  **Flash**: Flash the ESP32 with your unique `DEVICE_SECRET`.
2.  **Claim**: Use the Flutter app to "Claim" the device. The backend will publish a discovery message.
3.  **Onboard**: The ESP32 receives the `user_id` and `greenhouse_id` from the discovery topic, saves them to memory, and begins secure telemetry transmission.

---

## 📂 MQTT Topics

| Category | Full Topic |
| :--- | :--- |
| **Telemetry** | `gh/v1/<u_id>/<g_id>/<mac>/telemetry` |
| **Status** | `gh/v1/<u_id>/<g_id>/<mac>/status` |
| **Commands** | `gh/v1/<u_id>/<g_id>/<mac>/cmd` |
| **Alerts** | `gh/v1/<u_id>/<g_id>/<mac>/alert` |

## 🧪 Verification

Monitor the Serial console at `115200` baud. You should see:
1.  WiFi connection success.
2.  MQTT connection with MAC/Secret credentials.
3.  Discovery message parsing (if not already onboarded).
4.  Periodic telemetry JSON payloads.
