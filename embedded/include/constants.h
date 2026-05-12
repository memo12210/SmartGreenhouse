#ifndef CONSTANTS_H
#define CONSTANTS_H

#include <stdint.h>

namespace Greenhouse::Constants {
    constexpr uint32_t MONITOR_SPEED = 115200;
    constexpr uint32_t DELAY_MS = 10000; // 10 seconds of delay between each `loop()`

    constexpr uint8_t DHT_PIN = 4;
    constexpr uint8_t MQ135_PIN = 34;

    constexpr char WIFI_SSID[] = "";
    constexpr char WIFI_PASSWORD[] = "";

    constexpr char MQTT_SERVER[] = "";

    constexpr char DISCOVERY_TOPIC[] = "greenhouses/";
    constexpr char TELEMETRY_TOPIC[] = "telemetry";

    constexpr char NTP_SERVER[] = "pool.ntp.org";
    constexpr long GMT_OFFSET_SEC = 3 * 3600; // GMT+3 in Turkey
    constexpr int DAYLIGHT_OFFSET_SEC = 0;


} // namespace Greenhouse::Constants

#endif // CONSTANTS_H
