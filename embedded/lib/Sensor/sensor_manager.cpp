#include "sensor_manager.h"
#include "log.h"
#include "mqtt_provider.h"
#include "config_manager.h"
#include "wifi_provider.h"

namespace Greenhouse {

void SensorManager::addSensor(SensorInterface* sensor) {
    _sensors.push_back(sensor);
}

void SensorManager::begin(uint32_t intervalMs) {
    _intervalMs = intervalMs;
    for (auto sensor : _sensors) {
        sensor->begin();
    }

    xTaskCreate(taskEntry, "SensorTask", 4096, this, 1, &_taskHandle);
}

void SensorManager::taskEntry(void* pvParameters) {
    static_cast<SensorManager*>(pvParameters)->run();
}

void SensorManager::run() {
    LOG_INFO("Sensor Manager task started.");
    while (true) {
        if (SystemContext::getInstance().getState() == SystemState::STATE_OPERATIONAL) {
            JsonDocument doc;
            bool success = true;
            for (auto sensor : _sensors) {
                if (!sensor->read(doc)) {
                    LOG_WARN("Failed to read from sensor: %s", sensor->getName());
                    success = false;
                }
            }

            if (success) {
                String payload;
                serializeJson(doc, payload);

                String deviceId = ConfigManager::getInstance().getDeviceId();
                String ghId = ConfigManager::getInstance().getGreenhouseId();

                // greenhouse/{greenhouse_id}/device/{device_id}/telemetry
                String topic = "greenhouse/" + ghId + "/device/" + deviceId + "/telemetry";

                LOG_INFO("Publishing telemetry to %s: %s", topic.c_str(), payload.c_str());
                MQTTProvider::getInstance().publish(topic.c_str(), payload.c_str());
            }
        }
        vTaskDelay(pdMS_TO_TICKS(_intervalMs));
    }
}

} // namespace Greenhouse
