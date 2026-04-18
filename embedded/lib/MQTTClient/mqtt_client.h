#ifndef MQTT_CLIENT_H
#define MQTT_CLIENT_H

#include <Arduino.h>
#include <PubSubClient.h>
#include <WiFiClient.h>

/**
 * @brief Lightweight MQTT wrapper for ESP32.
 *
 * This class wraps PubSubClient for easier access.
 */
class MQTTClient {
public:
    MQTTClient(const char *mqttServer, int mqttPort = 1883);
    void begin();
    void loop();
    void publish(const char *topic, const char *payload, bool retained = false);
    bool isConnected();
    void subscribe(const char *topic, String *target);

private:
    struct Subscriber {
        const char *topic;
        String *target;
    };

    void reconnect();
    static void callback(char *topic, byte *payload, unsigned int length);
    static const int MAX_BINDINGS = 10;
    const char *_mqttServer;
    int _mqttPort;
    WiFiClient _espClient;
    PubSubClient _client;
    Subscriber _subscribers[MAX_BINDINGS];
    int _bindingCount;
    static MQTTClient *instance;
};

#endif // MQTT_CLIENT_H
