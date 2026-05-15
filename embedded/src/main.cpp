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

String userId = "";
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

String getMqttTopic(const char* type) {
    String mac = wifiManager.getMACAddress();
    // gh/v1/<user_id>/<greenhouse_id>/<device_mac>/<type>
    String topic = String(MQTT_ROOT_NAMESPACE) + "/" + MQTT_PROTOCOL_VER + "/";
    topic += userId + "/" + greenhouseId + "/" + mac + "/" + type;
    return topic;
}

String getStatusPayload(bool online) {
    JsonDocument doc;
    doc["online"] = online;
    doc["timestamp"] = getISO8601Time();
    String payload;
    serializeJson(doc, payload);
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
        userId = preferences.getString("u_id", "");
        greenhouseId = preferences.getString("gh_id", "");

        String macAddress = wifiManager.getMACAddress();
        static String cId = "ESP32_" + macAddress;
        mqttClient.setClientId(cId.c_str());

        // Use MAC as username and Secret as password
        mqttClient.setCredentials(macAddress.c_str(), DEVICE_SECRET);
        mqttClient.begin();

        if (userId.length() == 0 || greenhouseId.length() == 0) {
            LOG_INFO("Identity not found in NVS. Subscribing to %s for discovery...", DISCOVERY_TOPIC);
            mqttClient.subscribe(DISCOVERY_TOPIC, &discoveryPayload);
        } else {
            LOG_INFO("Loaded saved identity. User: %s, GH: %s", userId.c_str(), greenhouseId.c_str());
            isDiscovered = true;

            // Setup LWT (Last Will and Testament)
            static String sTopic = getMqttTopic(STATUS_TOPIC);
            static String willMsg = getStatusPayload(false);
            mqttClient.setWill(sTopic.c_str(), willMsg.c_str(), 1, true);

            // Notify we are online
            mqttClient.publish(sTopic.c_str(), getStatusPayload(true).c_str(), true);
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

    // New discovery format: {"MAC": {"u_id": "...", "gh_id": "..."}}
    if (root.containsKey(mac)) {
        JsonObject data = root[mac].as<JsonObject>();
        userId = data["u_id"].as<String>();
        greenhouseId = data["gh_id"].as<String>();

        LOG_INFO("Discovered identity. User: %s, GH: %s", userId.c_str(), greenhouseId.c_str());

        preferences.putString("u_id", userId);
        preferences.putString("gh_id", greenhouseId);
        isDiscovered = true;

        // Reset MQTT to apply new LWT topics
        String sTopic = getMqttTopic(STATUS_TOPIC);
        String willMsg = getStatusPayload(false);
        mqttClient.setWill(sTopic.c_str(), willMsg.c_str(), 1, true);
        mqttClient.publish(sTopic.c_str(), getStatusPayload(true).c_str(), true);

        // Subscribe to command topic
        mqttClient.subscribe(getMqttTopic(CMD_TOPIC).c_str());
    } else {
        LOG_WARN("MAC address %s not found in discovery payload.", mac.c_str());
        discoveryPayload = "";
    }
}

void loop() {
    if (!wifiManager.isConnected()) {
        LOG_WARN("WiFi connection lost. Reconnecting...");
        return;
    }

    mqttClient.loop();

    if (!isDiscovered) {
        processDiscovery();
        delay(1000);
        return;
    }

    if (!mqttClient.isConnected()) {
        LOG_WARN("MQTT disconnected. Attempting to reconnect...");
        // Re-publish online status after reconnecting
        if (mqttClient.isConnected()) {
            mqttClient.publish(getMqttTopic(STATUS_TOPIC).c_str(), getStatusPayload(true).c_str(), true);
            mqttClient.subscribe(getMqttTopic(CMD_TOPIC).c_str());
        }
    }

    auto dhtReadings = dht.read();

    JsonDocument telemetry;
    telemetry["timestamp"] = getISO8601Time();
    telemetry["temperature"] = serialized(String(dhtReadings.temperatureC, 1));
    telemetry["humidity"] = serialized(String(dhtReadings.humidity, 1));
    telemetry["soil_moisture"] = 0; // TODO
    telemetry["light"] = 0;         // TODO

    String payload;
    serializeJson(telemetry, payload);

    String topic = getMqttTopic(TELEMETRY_TOPIC);
    LOG_INFO("Publishing to %s: %s", topic.c_str(), payload.c_str());
    mqttClient.publish(topic.c_str(), payload.c_str(), true);

    delay(DELAY_MS);
}
