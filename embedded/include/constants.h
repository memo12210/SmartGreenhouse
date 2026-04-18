#ifndef CONSTANTS_H
#define CONSTANTS_H

#include <stdint.h>

namespace Greenhouse::Constants {
    constexpr uint32_t MONITOR_SPEED = 115200;
    constexpr uint32_t DELAY_MS = 10000; // 10 seconds of delay between each `loop()`

    constexpr uint8_t DHT_PIN = 4;

    constexpr char WIFI_SSID[] = "";
    constexpr char WIFI_PASSWORD[] = "";

    constexpr char MQTT_SERVER[] = "";

    constexpr char TEMPERATURE_TOPIC[] = "sensor/DHT22/temperature_celsius";
    constexpr char HUMIDITY_TOPIC[] = "sensor/DHT22/humidity";

    constexpr char TIME_YEAR_TOPIC[] = "sensor/time/year";
    constexpr char TIME_MONTH_TOPIC[] = "sensor/time/month";
    constexpr char TIME_DAY_TOPIC[] = "sensor/time/day";
    constexpr char TIME_HOUR_TOPIC[] = "sensor/time/hour";
    constexpr char TIME_MINUTE_TOPIC[] = "sensor/time/minute";
    constexpr char TIME_SECOND_TOPIC[] = "sensor/time/second";

    constexpr char NTP_SERVER[] = "pool.ntp.org";
    constexpr long GMT_OFFSET_SEC = 3 * 3600; // GMT+3 in Turkey
    constexpr int DAYLIGHT_OFFSET_SEC = 0;


} // namespace Greenhouse::Constants

#endif // CONSTANTS_H
