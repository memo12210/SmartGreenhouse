#include <Arduino.h>
#include <constants.h>
#include <unity.h>
#include <wifi_manager.h>

using namespace Greenhouse::Constants;

WiFiManager wifiManager;

void test_wifi_connection() {
    wifiManager.begin(WIFI_SSID, WIFI_PASSWORD);
    TEST_ASSERT_TRUE(wifiManager.isConnected());
}

void test_get_ip_address() {
    String ip = wifiManager.getIPAddress();
    TEST_ASSERT(ip.c_str() != "Not Connected");
}

void setup() {
    delay(2000);

    UNITY_BEGIN();

    RUN_TEST(test_wifi_connection);
    RUN_TEST(test_get_ip_address);

    UNITY_END();
}

void loop() { /* do nothing */ }
