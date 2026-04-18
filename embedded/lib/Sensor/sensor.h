#ifndef SENSOR_H
#define SENSOR_H

#include <stdint.h>

namespace Greenhouse::Sensors {

    template<typename T>
    class Sensor {
    public:
        virtual void begin() = 0;
        virtual T read() = 0;
        virtual ~Sensor() {};

    protected:
        Sensor(uint8_t pin) : pin(pin) {}
        uint8_t pin;
    };
} // namespace Greenhouse::Sensors

#endif // SENSOR_H
