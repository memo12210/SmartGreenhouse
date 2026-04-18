#include <Arduino.h>
#include <constants.h>
#include <dht_sensor.h>
#include <unity.h>

using namespace Greenhouse::Sensors;
using namespace Greenhouse::Constants;

void test_read_dht_data() {
    DHTSensor dht(DHT_PIN);
    dht.begin();
    delay(2000); // DHT22 takes around 2 seconds to initialize

    auto dhtReadings = dht.read();
    float temperature = dhtReadings.temperatureC;
    float humidity = dhtReadings.humidity;

    TEST_ASSERT_FLOAT_IS_NOT_NAN(temperature);
    TEST_ASSERT_FLOAT_IS_NOT_NAN(humidity);
}

void setup() {
    delay(2000);

    UNITY_BEGIN();
    RUN_TEST(test_read_dht_data);
    UNITY_END();
}

void loop() { /* do nothing */ }
