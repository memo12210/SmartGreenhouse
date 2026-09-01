#include "discovery_service.h"
#include "mqtt_provider.h"
#include "wifi_provider.h"
#include "config_manager.h"
#include "log.h"
#include <ArduinoJson.h>

namespace Greenhouse {

void DiscoveryService::start() {
    LOG_INFO("Starting Discovery Service...");
    // Backend broadcasts on "greenhouse/mapping"
    MQTTProvider::getInstance().subscribe("greenhouse/mapping");
}

void DiscoveryService::handleDiscoveryMessage(const char* topic, uint8_t* payload, unsigned int length) {
    if (SystemContext::getInstance().getState() != SystemState::STATE_DISCOVERY) return;

    JsonDocument doc;
    DeserializationError error = deserializeJson(doc, payload, length);

    if (error) {
        LOG_ERROR("Failed to parse discovery JSON: %s", error.c_str());
        return;
    }

    String myMac = WiFiProvider::getInstance().getMACAddress();
    // Payload format: {"mapping": {"<GH_ID>": {"<MAC>": "<DEV_ID>"}}}
    JsonObject mapping = doc["mapping"].as<JsonObject>();

    for (JsonPair greenhouseMapping : mapping) {
        String ghId = greenhouseMapping.key().c_str();
        JsonObject devices = greenhouseMapping.value().as<JsonObject>();

        for (JsonPair deviceEntry : devices) {
            String mac = deviceEntry.key().c_str();
            String devId = deviceEntry.value().as<String>();

            if (mac == myMac) {
                LOG_INFO("Identity discovered! Device: %s, GH: %s", devId.c_str(), ghId.c_str());
                ConfigManager::getInstance().setDeviceIdentity(devId.c_str(), ghId.c_str());

                // Construct dynamic command topic to subscribe to
                // Pattern: greenhouse/{greenhouse_id}/device/{device_id}/commands
                String cmdTopic = "greenhouse/" + ghId + "/device/" + devId + "/commands";
                MQTTProvider::getInstance().subscribe(cmdTopic.c_str());

                SystemContext::getInstance().transition(SystemEvent::EV_DISCOVERY_COMPLETED);
                return;
            }
        }
    }
}

} // namespace Greenhouse
