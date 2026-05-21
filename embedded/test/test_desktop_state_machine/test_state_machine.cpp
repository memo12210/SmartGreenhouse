#include <unity.h>
#include "system_context.h"
#include "system_events.h"

using namespace Greenhouse;

void setUp(void) {
    SystemContext::getInstance().setState(SystemState::STATE_BOOT);
}

void tearDown(void) {
}

void test_initial_state(void) {
    TEST_ASSERT_EQUAL(SystemState::STATE_BOOT, SystemContext::getInstance().getState());
}

void test_boot_to_wifi_connecting(void) {
    SystemContext::getInstance().transition(SystemEvent::EV_WIFI_DISCONNECTED);
    TEST_ASSERT_EQUAL(SystemState::STATE_WIFI_CONNECTING, SystemContext::getInstance().getState());
}

void test_wifi_connected_transition(void) {
    SystemContext::getInstance().transition(SystemEvent::EV_WIFI_CONNECTED);
    TEST_ASSERT_EQUAL(SystemState::STATE_MQTT_CONNECTING, SystemContext::getInstance().getState());
}

int main(int argc, char **argv) {
    UNITY_BEGIN();
    RUN_TEST(test_initial_state);
    RUN_TEST(test_boot_to_wifi_connecting);
    RUN_TEST(test_wifi_connected_transition);
    return UNITY_END();
}
