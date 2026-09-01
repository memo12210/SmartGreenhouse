#ifndef SYSTEM_CONTEXT_H
#define SYSTEM_CONTEXT_H

#include "system_events.h"

#ifdef ARDUINO
#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>
#else
// Mock mutex for desktop testing
#include <mutex>
typedef std::recursive_mutex* SemaphoreHandle_t;
#define xSemaphoreCreateRecursiveMutex() new std::recursive_mutex()
#define xSemaphoreTakeRecursive(m, d) (m->lock(), 1)
#define xSemaphoreGiveRecursive(m) m->unlock()
#define portMAX_DELAY 0
#define pdTRUE 1
#endif

namespace Greenhouse {

class SystemContext {
public:
    static SystemContext& getInstance() {
        static SystemContext instance;
        return instance;
    }

    void transition(SystemEvent event);
    SystemState getState();

    // Thread-safe state access
    void setState(SystemState newState);

private:
    SystemContext() : _state(SystemState::STATE_BOOT) {
#ifdef ARDUINO
        _stateMutex = xSemaphoreCreateMutex();
#else
        _stateMutex = new std::mutex();
#endif
    }

    SystemState _state;
#ifdef ARDUINO
    SemaphoreHandle_t _stateMutex;
#else
    std::mutex* _stateMutex;
#endif
};

} // namespace Greenhouse

#endif // SYSTEM_CONTEXT_H
