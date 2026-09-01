#include <unity.h>
#include "soil_moisture_conversion.h"

using namespace Greenhouse;

// Resistive soil moisture module: analog output is HIGH when dry, LOW when wet.
// So percentage (0% = bone dry, 100% = saturated) is the inverted ratio.

void test_dry_soil_reads_zero_percent(void) {
    TEST_ASSERT_FLOAT_WITHIN(0.1f, 0.0f, soilMoistureRawToPercent(4095));
}

void test_wet_soil_reads_full_percent(void) {
    TEST_ASSERT_FLOAT_WITHIN(0.1f, 100.0f, soilMoistureRawToPercent(0));
}

void test_midpoint_reads_about_half(void) {
    TEST_ASSERT_FLOAT_WITHIN(0.5f, 50.0f, soilMoistureRawToPercent(2048));
}

void test_out_of_range_raw_is_clamped(void) {
    // Values above the 12-bit ADC ceiling must not produce a negative percentage.
    TEST_ASSERT_FLOAT_WITHIN(0.1f, 0.0f, soilMoistureRawToPercent(5000));
}

int main(int argc, char **argv) {
    UNITY_BEGIN();
    RUN_TEST(test_dry_soil_reads_zero_percent);
    RUN_TEST(test_wet_soil_reads_full_percent);
    RUN_TEST(test_midpoint_reads_about_half);
    RUN_TEST(test_out_of_range_raw_is_clamped);
    return UNITY_END();
}
