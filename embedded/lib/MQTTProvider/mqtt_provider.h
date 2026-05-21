#ifndef MQTT_PROVIDER_H
#define MQTT_PROVIDER_H

#include <WiFi.h>
#include <PubSubClient.h>
#include <vector>
#include "system_context.h"

namespace Greenhouse {

class MQTTProvider {
public:
    static MQTTProvider& getInstance() {
        static MQTTProvider instance;
        return instance;
    }

    void begin();
    void loop();
    bool isConnected();

    bool publish(const char* topic, const char* payload, bool retained = false);
    bool subscribe(const char* topic);

    typedef std::function<void(const char*, uint8_t*, unsigned int)> MessageCallback;
    void setCallback(MessageCallback callback);

private:
    MQTTProvider();
    void reconnect();

    WiFiClient _wifiClient;
    PubSubClient _client;
    MessageCallback _onMessage;

    std::vector<String> _subscriptions;

    unsigned long _lastReconnectAttempt = 0;
    unsigned long _reconnectDelay = 1000;
    const unsigned long MAX_RECONNECT_DELAY = 60000;
};

} // namespace Greenhouse

#endif // MQTT_PROVIDER_H
