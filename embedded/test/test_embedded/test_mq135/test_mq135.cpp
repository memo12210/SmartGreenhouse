#include <Arduino.h>
#include <constants.h>
#include <mq135_sensor.h>
#include <unity.h>

using namespace Greenhouse::Sensors;
using namespace Greenhouse::Constants;

void test_read_mq135_data() {
    MQ135Sensor mq135(MQ135_PIN);
    mq135.begin();

    float co2PPM = mq135.read();
    TEST_ASSERT_FLOAT_IS_NOT_NAN(co2PPM);
}

void setup() {
    delay(10000);

    UNITY_BEGIN();
    RUN_TEST(test_read_mq135_data);
    UNITY_END();
}

void loop() { /* do nothing */ }
