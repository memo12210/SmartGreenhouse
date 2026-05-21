#ifndef SENSOR_MANAGER_H
#define SENSOR_MANAGER_H

#include "sensor_interface.h"
#include <vector>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "system_context.h"

namespace Greenhouse {

class SensorManager {
public:
    static SensorManager& getInstance() {
        static SensorManager instance;
        return instance;
    }

    void addSensor(SensorInterface* sensor);
    void begin(uint32_t intervalMs = 10000);

private:
    SensorManager() : _intervalMs(10000) {}
    static void taskEntry(void* pvParameters);
    void run();

    std::vector<SensorInterface*> _sensors;
    uint32_t _intervalMs;
    TaskHandle_t _taskHandle = nullptr;
};

} // namespace Greenhouse

#endif // SENSOR_MANAGER_H
