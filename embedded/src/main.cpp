#include <Arduino.h>
#include "log.h"
#include "config_manager.h"
#include "wifi_provider.h"
#include "mqtt_provider.h"
#include "system_context.h"
#include "sensor_manager.h"
#include "dht_sensor_impl.h"
#include "ldr_sensor_impl.h"
#include "mq135_sensor_impl.h"
#include "discovery_service.h"
#include "constants.h"

using namespace Greenhouse;

// Global Instances
DHTSensorImpl dhtSensor(Constants::DHT_PIN, 22); // DHT22
LDRSensorImpl ldrSensor(32); // Using GPIO 32 for LDR
MQ135SensorImpl mq135Sensor(Constants::MQ135_PIN);

void setup() {
    Serial.begin(115200);
    Log::begin(Serial, Log::Level::DEBUG);
    LOG_INFO("Smart Greenhouse Firmware Starting...");

    // Initialize Config
    if (!ConfigManager::getInstance().begin()) {
        LOG_ERROR("Failed to initialize ConfigManager!");
    }

    // Load defaults if needed (for demo/development)
    // In production, these would be provisioned via BLE or AP Mode
    if (ConfigManager::getInstance().getWiFiSSID().length() == 0) {
        LOG_INFO("Provisioning default WiFi credentials...");
        ConfigManager::getInstance().setWiFiCredentials(Constants::WIFI_SSID, Constants::WIFI_PASSWORD);
    }

    if (ConfigManager::getInstance().getMQTTServer().length() == 0) {
        LOG_INFO("Provisioning default MQTT configuration...");
        ConfigManager::getInstance().setMQTTConfig(Constants::MQTT_SERVER, 1883);
    }

    // Configure Time synchronization (required for TLS)
    configTime(Constants::GMT_OFFSET_SEC, Constants::DAYLIGHT_OFFSET_SEC, Constants::NTP_SERVER);

    // Initialize Components
    WiFiProvider::getInstance().begin();
    MQTTProvider::getInstance().begin();

    MQTTProvider::getInstance().setCallback([](const char* topic, uint8_t* payload, unsigned int length) {
        DiscoveryService::getInstance().handleDiscoveryMessage(topic, payload, length);
    });

    // Setup Sensors
    SensorManager::getInstance().addSensor(&dhtSensor);
    SensorManager::getInstance().addSensor(&ldrSensor);
    SensorManager::getInstance().addSensor(&mq135Sensor);
    SensorManager::getInstance().begin(Constants::DELAY_MS);

    LOG_INFO("Initialization complete. Entering state machine loop.");
}

void loop() {
    static SystemState lastState = SystemState::STATE_BOOT;
    SystemState currentState = SystemContext::getInstance().getState();
    bool stateChanged = (currentState != lastState);
    lastState = currentState;

    switch (currentState) {
        case SystemState::STATE_BOOT:
            // Handled by setup and events
            break;

        case SystemState::STATE_WIFI_CONNECTING:
            // WiFiProvider handles reconnection via events
            break;

        case SystemState::STATE_MQTT_CONNECTING:
            MQTTProvider::getInstance().loop();
            break;

        case SystemState::STATE_DISCOVERY:
            MQTTProvider::getInstance().loop();
            if (stateChanged) {
                DiscoveryService::getInstance().start();
            }
            break;

        case SystemState::STATE_OPERATIONAL:
            MQTTProvider::getInstance().loop();
            // SensorManager runs in its own task
            break;

        case SystemState::STATE_ERROR:
            LOG_ERROR("System in ERROR state. Restarting in 10s...");
            delay(10000);
            ESP.restart();
            break;

        default:
            break;
    }

    // Small delay to prevent watchdog issues in loop()
    delay(10);
}
