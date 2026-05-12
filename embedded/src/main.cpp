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
String statusTopic = "";
bool statusPublishedOnline = false;
bool wifiWasConnected = false;

String getISO8601Time() {
    tm timeInfo;
    if (!getLocalTime(&timeInfo)) {
        return "2000-01-01T14:20:31Z"; // fallback value
    }
    char buffer[25];
    strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%SZ", &timeInfo);
    return String(buffer);
}

String normalizeMacAddress(String mac) {
    mac.replace(":", "");
    mac.replace("-", "");
    mac.toUpperCase();
    return mac;
}

String getStatusPayload(bool online) {
    String payload = "{";
    payload += "\"online\": " + String(online ? "true" : "false") + ",";
    payload += "\"timestamp\": \"" + getISO8601Time() + "\"";
    payload += "}";
    return payload;
}

void publishDeviceStatus(bool online) {
    if (statusTopic.length() == 0) {
        return;
    }

    if (!mqttClient.isConnected()) {
        return;
    }

    mqttClient.publish(statusTopic.c_str(), getStatusPayload(online).c_str(), true);
    statusPublishedOnline = online;
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

        String macAddress = normalizeMacAddress(wifiManager.getMACAddress());
        static String cId = "ESP32_" + macAddress;
        mqttClient.setClientId(cId.c_str());

        mqttClient.begin();

        if (greenhouseId.length() == 0) {
            LOG_INFO("Greenhouse ID not found in NVS. Subscribing to %s for discovery...", DISCOVERY_TOPIC);
            mqttClient.subscribe(DISCOVERY_TOPIC, &discoveryPayload);
        } else {
            LOG_INFO("Loaded saved Greenhouse ID from NVS: %s", greenhouseId.c_str());
            isDiscovered = true;

            statusTopic = greenhouseId + "/" + macAddress + "/status";

            // Static allocation for MQTTClient internal pointers
            static String willMsg = getStatusPayload(false);
            static String sTopic = statusTopic;

            mqttClient.setWill(sTopic.c_str(), willMsg.c_str(), 1, true);
            wifiWasConnected = true;
        }
    } else {
        LOG_WARN("Failed to connect to WiFi");
    }

    LOG_INFO("System initialized.");
}

void processDiscovery() {
    if (discoveryPayload.length() == 0)
        return;

    LOG_INFO("Received discovery payload. Parsing...");

    JsonDocument doc;
    DeserializationError error = deserializeJson(doc, discoveryPayload);

    if (error) {
        LOG_ERROR("Discovery JSON parsing failed: %s", error.c_str());
        discoveryPayload = "";
        return;
    }

    String mac = normalizeMacAddress(wifiManager.getMACAddress());
    JsonObject root = doc.as<JsonObject>();

    for (JsonPair p: root) {
        JsonArray devices = p.value().as<JsonArray>();
        for (JsonVariant v: devices) {
            if (normalizeMacAddress(v.as<String>()) == mac) {
                greenhouseId = String(p.key().c_str());
                LOG_INFO("Discovered assigned Greenhouse ID: %s", greenhouseId.c_str());

                preferences.putString("gh_id", greenhouseId);
                isDiscovered = true;
                statusTopic = greenhouseId + "/" + mac + "/status";

                // Setup status topics after discovery
                static String willMsg = getStatusPayload(false);
                static String sTopic = statusTopic;

                mqttClient.setWill(sTopic.c_str(), willMsg.c_str(), 1, true);

                // Publish online status once the device has an assigned greenhouse.
                publishDeviceStatus(true);
                return;
            }
        }
    }

    LOG_WARN("MAC address %s not found in discovery payload.", mac.c_str());
    discoveryPayload = ""; // Wait for next update
}

void loop() {
    bool wifiConnected = wifiManager.isConnected();

    if (!wifiConnected) {
        if (wifiWasConnected) {
            LOG_WARN("WiFi disconnected; marking device offline.");
            publishDeviceStatus(false);
            wifiWasConnected = false;
        }

        LOG_WARN("WiFi connection lost");
        delay(1000);
        return;
    }

    if (!wifiWasConnected) {
        wifiWasConnected = true;
    }

    mqttClient.loop();

    if (isDiscovered && !statusPublishedOnline) {
        publishDeviceStatus(true);
    }

    if (!isDiscovered) {
        static unsigned long lastDiscoveryLog = 0;
        if (millis() - lastDiscoveryLog > 5000) {
            LOG_INFO("Waiting for discovery payload on %s", DISCOVERY_TOPIC);
            lastDiscoveryLog = millis();
        }

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
    String macAddress = normalizeMacAddress(wifiManager.getMACAddress());

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
