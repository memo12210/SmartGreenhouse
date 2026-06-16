#ifndef SOIL_MOISTURE_SENSOR_IMPL_H
#define SOIL_MOISTURE_SENSOR_IMPL_H

#include "sensor_interface.h"
#include "soil_moisture_conversion.h"
#include <Arduino.h>

namespace Greenhouse {

class SoilMoistureSensorImpl : public SensorInterface {
public:
    SoilMoistureSensorImpl(uint8_t pin) : _pin(pin) {}

    void begin() override {
        pinMode(_pin, INPUT);
    }

    bool read(JsonDocument& doc) override {
        uint16_t analogValue = analogRead(_pin);

        doc["soil_moisture"] = soilMoistureRawToPercent(analogValue);
        return true;
    }

    const char* getName() const override { return "SoilMoisture"; }

private:
    uint8_t _pin;
};

} // namespace Greenhouse

#endif // SOIL_MOISTURE_SENSOR_IMPL_H
