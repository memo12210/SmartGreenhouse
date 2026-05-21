#ifndef MQ135_SENSOR_IMPL_H
#define MQ135_SENSOR_IMPL_H

#include "sensor_interface.h"
#include <Arduino.h>

namespace Greenhouse {

class MQ135SensorImpl : public SensorInterface {
public:
    MQ135SensorImpl(uint8_t pin) : _pin(pin) {}

    void begin() override {
        pinMode(_pin, INPUT);
    }

    bool read(JsonDocument& doc) override {
        uint16_t analogValue = analogRead(_pin);
        // Basic conversion for demo purposes
        // In a real scenario, this would involve calibration and R0/RS calculations
        float co2 = (float)analogValue * (2000.0f / 4095.0f);

        doc["co2"] = co2;
        return true;
    }

    const char* getName() const override { return "MQ135"; }

private:
    uint8_t _pin;
};

} // namespace Greenhouse

#endif // MQ135_SENSOR_IMPL_H
