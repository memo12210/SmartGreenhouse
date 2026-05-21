#include "mqtt_provider.h"
#include "config_manager.h"
#include "wifi_provider.h"
#include "log.h"

namespace Greenhouse {

MQTTProvider::MQTTProvider() : _client(_wifiClient) {
}

void MQTTProvider::begin() {
    String server = ConfigManager::getInstance().getMQTTServer();
    uint16_t port = ConfigManager::getInstance().getMQTTPort();

    if (server.length() == 0) {
        LOG_WARN("MQTT Server not configured.");
        return;
    }

    _client.setServer(server.c_str(), port);
    _client.setCallback([this](char* topic, uint8_t* payload, unsigned int length) {
        if (_onMessage) {
            _onMessage(topic, payload, length);
        }
    });
}

void MQTTProvider::loop() {
    if (!_client.connected()) {
        reconnect();
    } else {
        _client.loop();
    }
}

bool MQTTProvider::isConnected() {
    return _client.connected();
}

void MQTTProvider::reconnect() {
    if (WiFi.status() != WL_CONNECTED) return;

    String server = ConfigManager::getInstance().getMQTTServer();
    if (server.length() == 0) {
        LOG_WARN("Cannot reconnect: MQTT Server not configured.");
        return;
    }

    unsigned long now = millis();
    if (now - _lastReconnectAttempt > _reconnectDelay) {
        _lastReconnectAttempt = now;

        String clientId = "ESP32_" + WiFiProvider::getInstance().getMACAddress();
        uint16_t port = ConfigManager::getInstance().getMQTTPort();
        LOG_INFO("Attempting MQTT connection to %s:%u as %s...", server.c_str(), port, clientId.c_str());

        // Ensure server is set (in case begin() failed or config changed)
        _client.setServer(server.c_str(), port);

        if (_client.connect(clientId.c_str())) {
            LOG_INFO("MQTT Connected");
            _reconnectDelay = 1000; // Reset delay

            // Restore subscriptions
            for (const auto& topic : _subscriptions) {
                _client.subscribe(topic.c_str());
            }

            SystemContext::getInstance().transition(SystemEvent::EV_MQTT_CONNECTED);
        } else {
            LOG_ERROR("MQTT connection failed, rc=%d", _client.state());
            _reconnectDelay = std::min(_reconnectDelay * 2, MAX_RECONNECT_DELAY);
            LOG_INFO("Next reconnect attempt in %lu ms", _reconnectDelay);
        }
    }
}

bool MQTTProvider::publish(const char* topic, const char* payload, bool retained) {
    if (!_client.connected()) return false;
    return _client.publish(topic, payload, retained);
}

bool MQTTProvider::subscribe(const char* topic) {
    // Check if already subscribed
    for (const auto& sub : _subscriptions) {
        if (sub == topic) return true;
    }

    _subscriptions.push_back(String(topic));

    if (!_client.connected()) return false;
    return _client.subscribe(topic);
}

void MQTTProvider::setCallback(MessageCallback callback) {
    _onMessage = callback;
}

} // namespace Greenhouse
