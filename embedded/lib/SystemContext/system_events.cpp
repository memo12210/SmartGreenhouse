#include "system_events.h"

namespace Greenhouse {

const char* stateToString(SystemState state) {
    switch (state) {
        case SystemState::STATE_BOOT: return "BOOT";
        case SystemState::STATE_WIFI_CONNECTING: return "WIFI_CONNECTING";
        case SystemState::STATE_MQTT_CONNECTING: return "MQTT_CONNECTING";
        case SystemState::STATE_DISCOVERY: return "DISCOVERY";
        case SystemState::STATE_OPERATIONAL: return "OPERATIONAL";
        case SystemState::STATE_ERROR: return "ERROR";
        case SystemState::STATE_RECOVERY: return "RECOVERY";
        default: return "UNKNOWN";
    }
}

} // namespace Greenhouse
