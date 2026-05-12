#include <Arduino.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include <constants.h>
#include <dht_sensor.h>
#include <ldr_reader.h>
#include <log.h>
#include <mqtt_client.h>
#include <time.h>
#include <wifi_manager.h>

using namespace Greenhouse::Sensors;
using namespace Greenhouse::Constants;

DHTSensor dht(DHT_PIN, DHTType::DHT22);
WiFiManager wifiManager;
MQTTClient mqttClient(MQTT_SERVER);
Preferences preferences;

String greenhouseId = "";
String discoveryPayload = "";
bool isDiscovered = false;

String getISO8601Time() {
    tm timeInfo;
    if (!getLocalTime(&timeInfo)) {
        return "2000-01-01T14:20:31Z"; // fallback value
    }
    char buffer[25];
    strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%SZ", &timeInfo);
    return String(buffer);
}

String getStatusPayload(bool online) {
    String payload = "{";
    payload += "\"online\": " + String(online ? "true" : "false") + ",";
    payload += "\"timestamp\": \"" + getISO8601Time() + "\"";
    payload += "}";
    return payload;
}

void setup() {
    Serial.begin(MONITOR_SPEED);
    Log::begin(Serial, Log::Level::DEBUG);

    dht.begin();

    wifiManager.begin(WIFI_SSID, WIFI_PASSWORD);

    if (wifiManager.isConnected()) {
        LOG_INFO("WiFi connected successfully. IP: %s", wifiManager.getIPAddress().c_str());

        configTime(GMT_OFFSET_SEC, DAYLIGHT_OFFSET_SEC, NTP_SERVER);

        preferences.begin("gh_system", false);
        greenhouseId = preferences.getString("gh_id", "");

        String macAddress = wifiManager.getMACAddress();
        static String cId = "ESP32_" + macAddress;
        mqttClient.setClientId(cId.c_str());

        mqttClient.begin();

        if (greenhouseId.length() == 0) {
            LOG_INFO("Greenhouse ID not found in NVS. Subscribing to %s for discovery...", DISCOVERY_TOPIC);
            mqttClient.subscribe(DISCOVERY_TOPIC, &discoveryPayload);
        } else {
            LOG_INFO("Loaded saved Greenhouse ID from NVS: %s", greenhouseId.c_str());
            isDiscovered = true;

            String statusTopic = greenhouseId + "/" + macAddress + "/status";

            // Static allocation for MQTTClient internal pointers
            static String willMsg = getStatusPayload(false);
            static String sTopic = statusTopic;

            mqttClient.setWill(sTopic.c_str(), willMsg.c_str(), 1, true);
        }
    } else {
        LOG_WARN("Failed to connect to WiFi");
    }

    LOG_INFO("System initialized.");
}

void processDiscovery() {
    if (discoveryPayload.length() == 0) return;

    LOG_INFO("Received discovery payload. Parsing...");

    JsonDocument doc;
    DeserializationError error = deserializeJson(doc, discoveryPayload);

    if (error) {
        LOG_ERROR("Discovery JSON parsing failed: %s", error.c_str());
        discoveryPayload = "";
        return;
    }

    String mac = wifiManager.getMACAddress();
    JsonObject root = doc.as<JsonObject>();

    for (JsonPair p : root) {
        JsonArray devices = p.value().as<JsonArray>();
        for (JsonVariant v : devices) {
            if (v.as<String>() == mac) {
                greenhouseId = String(p.key().c_str());
                LOG_INFO("Discovered assigned Greenhouse ID: %s", greenhouseId.c_str());

                preferences.putString("gh_id", greenhouseId);
                isDiscovered = true;

                // Setup status topics after discovery
                String statusTopic = greenhouseId + "/" + mac + "/status";
                static String willMsg = getStatusPayload(false);
                static String sTopic = statusTopic;

                mqttClient.setWill(sTopic.c_str(), willMsg.c_str(), 1, true);

                // Reconnect to apply Will and publish Online
                mqttClient.publish(sTopic.c_str(), getStatusPayload(true).c_str(), true);
                return;
            }
        }
    }

    LOG_WARN("MAC address %s not found in discovery payload.", mac.c_str());
    discoveryPayload = ""; // Wait for next update
}

void loop() {
    if (!wifiManager.isConnected())
        LOG_WARN("WiFi connection lost");

    mqttClient.loop();

    if (!isDiscovered) {
        processDiscovery();
        delay(1000);
        return;
    }

    auto dhtReadings = dht.read();
    float temperature = dhtReadings.temperatureC;
    float humidity = dhtReadings.humidity;
    uint16_t light = 0;   // TODO: add real reading
    int soilMoisture = 0; // TODO: add real reading

    String timestamp = getISO8601Time();
    String macAddress = wifiManager.getMACAddress();

    // Construct the JSON payload
    String payload = "{";
    payload += "\"timestamp\": \"" + timestamp + "\",";
    payload += "\"temperature\": " + String(temperature, 1) + ",";
    payload += "\"humidity\": " + String(humidity, 1) + ",";
    payload += "\"soil_moisture\": " + String(soilMoisture) + ",";
    payload += "\"light\": " + String(light);
    payload += "}";

    // Construct the topic greenhouse_id>/<microcontroller_id>/telemetry
    String topic = greenhouseId + "/" + macAddress + "/" + TELEMETRY_TOPIC;

    LOG_INFO("Publishing to %s: %s", topic.c_str(), payload.c_str());
    mqttClient.publish(topic.c_str(), payload.c_str(), true);

    delay(DELAY_MS);
}
