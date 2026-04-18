#ifndef DHT_SENSOR_H
#define DHT_SENSOR_H

#include <Arduino.h>
#include <DHT.h>
#include "sensor.h"

namespace Greenhouse::Sensors {
    enum class DHTType { DHT11, DHT22 };

    struct DHTReading {
        float temperatureC;
        float humidity;
    };

    class DHTSensor : public Sensor<DHTReading> {
    public:
        DHTSensor(uint8_t pin, DHTType type);
        void begin() override;
        DHTReading read() override;

    private:
        ::DHT _dht;
    };
} // namespace Greenhouse::Sensors


#endif // DHT_SENSOR_H
