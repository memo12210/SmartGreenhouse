#include "system_context.h"
#include "log.h"

namespace Greenhouse {

#ifdef ARDUINO
#define LOCK_MUTEX() (xSemaphoreTake(_stateMutex, portMAX_DELAY) == pdTRUE)
#define UNLOCK_MUTEX() xSemaphoreGive(_stateMutex)
#else
#define LOCK_MUTEX() (_stateMutex->lock(), true)
#define UNLOCK_MUTEX() _stateMutex->unlock()
#endif

void SystemContext::transition(SystemEvent event) {
    if (LOCK_MUTEX()) {
        SystemState nextState = _state;

        switch (_state) {
            case SystemState::STATE_BOOT:
                if (event == SystemEvent::EV_WIFI_CONNECTED) nextState = SystemState::STATE_MQTT_CONNECTING;
                else nextState = SystemState::STATE_WIFI_CONNECTING;
                break;

            case SystemState::STATE_WIFI_CONNECTING:
                if (event == SystemEvent::EV_WIFI_CONNECTED) nextState = SystemState::STATE_MQTT_CONNECTING;
                break;

            case SystemState::STATE_MQTT_CONNECTING:
                if (event == SystemEvent::EV_MQTT_CONNECTED) nextState = SystemState::STATE_DISCOVERY;
                else if (event == SystemEvent::EV_WIFI_DISCONNECTED) nextState = SystemState::STATE_WIFI_CONNECTING;
                break;

            case SystemState::STATE_DISCOVERY:
                if (event == SystemEvent::EV_DISCOVERY_COMPLETED) nextState = SystemState::STATE_OPERATIONAL;
                else if (event == SystemEvent::EV_MQTT_DISCONNECTED) nextState = SystemState::STATE_MQTT_CONNECTING;
                break;

            case SystemState::STATE_OPERATIONAL:
                if (event == SystemEvent::EV_MQTT_DISCONNECTED) nextState = SystemState::STATE_MQTT_CONNECTING;
                else if (event == SystemEvent::EV_WIFI_DISCONNECTED) nextState = SystemState::STATE_WIFI_CONNECTING;
                break;

            case SystemState::STATE_ERROR:
                if (event == SystemEvent::EV_RECOVERY_TRIGGERED) nextState = SystemState::STATE_BOOT;
                break;

            default:
                break;
        }

        if (event == SystemEvent::EV_CRITICAL_ERROR) nextState = SystemState::STATE_ERROR;

        if (nextState != _state) {
            LOG_INFO("State transition: %s -> %s", stateToString(_state), stateToString(nextState));
            _state = nextState;
        }

        UNLOCK_MUTEX();
    }
}

SystemState SystemContext::getState() {
    SystemState current;
    if (LOCK_MUTEX()) {
        current = _state;
        UNLOCK_MUTEX();
    }
    return current;
}

void SystemContext::setState(SystemState newState) {
    if (LOCK_MUTEX()) {
        _state = newState;
        UNLOCK_MUTEX();
    }
}

} // namespace Greenhouse
