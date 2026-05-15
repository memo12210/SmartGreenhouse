#ifndef CONSTANTS_H
#define CONSTANTS_H

#include <stdint.h>

namespace Greenhouse::Constants {
    constexpr uint32_t MONITOR_SPEED = 115200;
    constexpr uint32_t DELAY_MS = 10000; // 10 seconds of delay between each `loop()`

    constexpr uint8_t DHT_PIN = 4;
    constexpr uint8_t MQ135_PIN = 34;

    constexpr char WIFI_SSID[] = "***REDACTED_WIFI_SSID***";
    constexpr char WIFI_PASSWORD[] = "***REDACTED_WIFI_PASSWORD***";

    constexpr char MQTT_SERVER[] = "***REDACTED_LOCAL_IP***";
    constexpr char DEVICE_SECRET[] = "secret";

    constexpr char MQTT_PROTOCOL_VER[] = "v1";
    constexpr char MQTT_ROOT_NAMESPACE[] = "gh";

    constexpr char DISCOVERY_TOPIC[] = "greenhouses/";

    // Message types
    constexpr char TELEMETRY_TOPIC[] = "telemetry";
    constexpr char STATUS_TOPIC[] = "status";
    constexpr char CMD_TOPIC[] = "cmd";
    constexpr char ALERT_TOPIC[] = "alert";

    constexpr char NTP_SERVER[] = "pool.ntp.org";
    constexpr long GMT_OFFSET_SEC = 3 * 3600; // GMT+3 in Turkey
    constexpr int DAYLIGHT_OFFSET_SEC = 0;


} // namespace Greenhouse::Constants

#endif // CONSTANTS_H
