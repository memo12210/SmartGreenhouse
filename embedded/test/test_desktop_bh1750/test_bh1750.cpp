#include <unity.h>
#include "bh1750_conversion.h"

using namespace Greenhouse;

// The BH1750 library returns negative sentinel values (-1.0 "no values",
// -2.0 "device error") when an I2C read fails, and a non-negative lux value
// otherwise. A valid reading must be rejected before it is published so a
// failed bus read does not masquerade as "pitch black".

void test_negative_sentinels_are_invalid(void) {
    TEST_ASSERT_FALSE(bh1750IsValidReading(-1.0f));
    TEST_ASSERT_FALSE(bh1750IsValidReading(-2.0f));
}

void test_nan_is_invalid(void) {
    TEST_ASSERT_FALSE(bh1750IsValidReading(0.0f / 0.0f));
}

void test_zero_lux_is_valid(void) {
    // Total darkness is a legitimate measurement, not an error.
    TEST_ASSERT_TRUE(bh1750IsValidReading(0.0f));
}

void test_typical_and_bright_readings_are_valid(void) {
    TEST_ASSERT_TRUE(bh1750IsValidReading(120.0f));
    TEST_ASSERT_TRUE(bh1750IsValidReading(54612.5f));
}

int main(int argc, char **argv) {
    UNITY_BEGIN();
    RUN_TEST(test_negative_sentinels_are_invalid);
    RUN_TEST(test_nan_is_invalid);
    RUN_TEST(test_zero_lux_is_valid);
    RUN_TEST(test_typical_and_bright_readings_are_valid);
    return UNITY_END();
}
