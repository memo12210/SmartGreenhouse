#ifndef LDR_SENSOR_IMPL_H
#define LDR_SENSOR_IMPL_H

#include "sensor_interface.h"
#include <Arduino.h>

namespace Greenhouse {

class LDRSensorImpl : public SensorInterface {
public:
    LDRSensorImpl(uint8_t pin) : _pin(pin) {}

    void begin() override {
        pinMode(_pin, INPUT);
    }

    bool read(JsonDocument& doc) override {
        uint16_t analogValue = analogRead(_pin);
        float percentage = (float)analogValue / 4095.0f * 100.0f;

        doc["light_intensity"] = percentage;
        return true;
    }

    const char* getName() const override { return "LDR"; }

private:
    uint8_t _pin;
};

} // namespace Greenhouse

#endif // LDR_SENSOR_IMPL_H
