#include <Arduino.h>
#include <constants.h>
#include <mqtt_client.h>
#include <unity.h>
#include <wifi_manager.h>

using namespace Greenhouse::Constants;

WiFiManager wifiManager;
MQTTClient mqttClient(MQTT_SERVER);

void test_mqtt_connection() {
    wifiManager.begin(WIFI_SSID, WIFI_PASSWORD);
    TEST_ASSERT_TRUE(wifiManager.isConnected());

    mqttClient.begin();

    unsigned long start = millis();
    while (millis() - start < 3000) {
        mqttClient.loop();
    }

    TEST_ASSERT_TRUE(mqttClient.isConnected());
}

void test_mqtt_pubsub() {
    TEST_ASSERT_TRUE(mqttClient.isConnected());
    String test;

    // First, publish a dummy message
    mqttClient.subscribe("test", &test);
    delay(200);
    mqttClient.publish("test", "foo", true);

    // Wait for a bit...
    unsigned long start = millis();
    while (millis() - start < 2000) {
        mqttClient.loop();
    }

    // Assert that the message received from the broker is same as the one sended.
    TEST_ASSERT_EQUAL_STRING("foo", test.c_str());
}

void setup() {
    delay(2000);

    UNITY_BEGIN();

    RUN_TEST(test_mqtt_connection);
    RUN_TEST(test_mqtt_pubsub);

    UNITY_END();
}

void loop() { /* do nothing */ }
