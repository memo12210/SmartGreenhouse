#include <Arduino.h>
#include <constants.h>
#include <dht_sensor.h>
#include <log.h>
#include <mqtt_client.h>
#include <time.h>
#include <wifi_manager.h>

using namespace Greenhouse::Sensors;
using namespace Greenhouse::Constants;

DHTSensor dht(DHT_PIN, DHTType::DHT22);
WiFiManager wifiManager;
MQTTClient mqttClient(MQTT_SERVER);

void setup() {
    Serial.begin(MONITOR_SPEED);
    Log::begin(Serial, Log::Level::DEBUG);

    dht.begin();

    wifiManager.begin(WIFI_SSID, WIFI_PASSWORD);

    if (wifiManager.isConnected()) {
        LOG_INFO("WiFi connected successfully. IP: %s", wifiManager.getIPAddress().c_str());

        configTime(GMT_OFFSET_SEC, DAYLIGHT_OFFSET_SEC, NTP_SERVER);

        tm timeInfo;
        if (!getLocalTime(&timeInfo)) {
            LOG_WARN("Failed to obtain time from NTP server");
        }

        mqttClient.begin();
    } else {
        LOG_WARN("Failed to connect to WiFi");
    }

    LOG_INFO("System initialized.");
}

void loop() {
    if (!wifiManager.isConnected())
        LOG_WARN("WiFi connection lost");

    mqttClient.loop();

    auto dhtReadings = dht.read();
    float temperature = dhtReadings.temperatureC;
    float humidity = dhtReadings.humidity;

    LOG_INFO("Temperature: %.2f°C, Humidity: %.2f%%", temperature, humidity);

    mqttClient.publish(TEMPERATURE_TOPIC, String(temperature).c_str(), true);
    mqttClient.publish(HUMIDITY_TOPIC, String(humidity).c_str(), true);

    tm timeInfo;
    if (getLocalTime(&timeInfo)) {
        uint16_t year = timeInfo.tm_year + 1900;
        uint8_t month = timeInfo.tm_mon + 1;
        uint8_t day = timeInfo.tm_mday;
        uint8_t hour = timeInfo.tm_hour;
        uint8_t minute = timeInfo.tm_min;
        uint8_t second = timeInfo.tm_sec;

        LOG_INFO("Current time: %04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, minute, second);

        mqttClient.publish(TIME_YEAR_TOPIC, String(year).c_str(), true);
        mqttClient.publish(TIME_MONTH_TOPIC, String(month).c_str(), true);
        mqttClient.publish(TIME_DAY_TOPIC, String(day).c_str(), true);
        mqttClient.publish(TIME_HOUR_TOPIC, String(hour).c_str(), true);
        mqttClient.publish(TIME_MINUTE_TOPIC, String(minute).c_str(), true);
        mqttClient.publish(TIME_SECOND_TOPIC, String(second).c_str(), true);
    } else {
        LOG_WARN("Failed to get local time");
    }

    delay(DELAY_MS);
}
