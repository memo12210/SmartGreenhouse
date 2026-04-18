#include "mqtt_client.h"
#include <log.h>

MQTTClient *MQTTClient::instance = nullptr;

MQTTClient::MQTTClient(const char *mqttServer, int mqttPort) :
    _mqttServer(mqttServer), _mqttPort(mqttPort), _client(_espClient), _bindingCount(0) {

    // PubSubClient requires a static callback; keep a pointer to the active instance.
    instance = this;
}

void MQTTClient::begin() {
    _client.setServer(_mqttServer, _mqttPort);
    _client.setCallback(MQTTClient::callback);
}

void MQTTClient::reconnect() {
    while (!_client.connected()) {
        LOG_INFO("Attempting MQTT connection...");

        if (_client.connect("ESP32Client")) {
            LOG_INFO("Connected");

            // MQTT subscriptions are not guaranteed after reconnect, so restore all bindings.
            for (int i = 0; i < _bindingCount; i++) {
                _client.subscribe(_subscribers[i].topic);
            }

        } else {
            LOG_INFO("Failed, rc=%d", _client.state());
            LOG_INFO("Trying again in 5 seconds");
            delay(5000);
        }
    }
}

void MQTTClient::loop() {
    if (!_client.connected()) {
        reconnect();
    }
    _client.loop();
}

bool MQTTClient::isConnected() { return _client.connected(); }

void MQTTClient::publish(const char *topic, const char *payload, bool retained) {
    if (!isConnected()) {
        LOG_ERROR("Cannot publish, MQTT client not connected.");
        return;
    }

    _client.publish(topic, payload, retained);
}

void MQTTClient::subscribe(const char *topic, String *target) {
    if (_bindingCount >= MAX_BINDINGS) {
        LOG_ERROR("Max bindings reached");
        return;
    }

    _subscribers[_bindingCount].topic = topic;
    _subscribers[_bindingCount].target = target;
    _bindingCount++;

    if (_client.connected()) {
        _client.subscribe(topic);
    }
}

void MQTTClient::callback(char *topic, byte *payload, unsigned int length) {
    if (!instance)
        return;

    // Rebuild message from raw payload bytes delivered by PubSubClient.
    String message;
    for (unsigned int i = 0; i < length; i++) {
        message += (char) payload[i];
    }

    // Fan out the payload to the bound String target for matching topics.
    for (int i = 0; i < instance->_bindingCount; i++) {
        if (strcmp(topic, instance->_subscribers[i].topic) == 0) {
            if (instance->_subscribers[i].target) {
                *(instance->_subscribers[i].target) = message;
            }
        }
    }
}
