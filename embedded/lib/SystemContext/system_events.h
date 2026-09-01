#ifndef SYSTEM_EVENTS_H
#define SYSTEM_EVENTS_H

namespace Greenhouse {

enum class SystemState {
    STATE_BOOT,
    STATE_WIFI_CONNECTING,
    STATE_MQTT_CONNECTING,
    STATE_DISCOVERY,
    STATE_OPERATIONAL,
    STATE_ERROR,
    STATE_RECOVERY
};

enum class SystemEvent {
    EV_WIFI_CONNECTED,
    EV_WIFI_DISCONNECTED,
    EV_MQTT_CONNECTED,
    EV_MQTT_DISCONNECTED,
    EV_DISCOVERY_COMPLETED,
    EV_CRITICAL_ERROR,
    EV_RECOVERY_TRIGGERED
};

const char* stateToString(SystemState state);

} // namespace Greenhouse

#endif // SYSTEM_EVENTS_H
