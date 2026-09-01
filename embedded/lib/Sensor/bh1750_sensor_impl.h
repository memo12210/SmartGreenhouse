#ifndef BH1750_SENSOR_IMPL_H
#define BH1750_SENSOR_IMPL_H

#include "sensor_interface.h"
#include "bh1750_conversion.h"
#include <Arduino.h>
#include <Wire.h>
#include <BH1750.h>

namespace Greenhouse {

class BH1750SensorImpl : public SensorInterface {
public:
    BH1750SensorImpl(uint8_t sdaPin, uint8_t sclPin) : _sdaPin(sdaPin), _sclPin(sclPin) {}

    // Default 7-bit I2C address with the ADDR pin tied low.
    static constexpr uint8_t I2C_ADDR = 0x23;

    void begin() override {
        Wire.begin(_sdaPin, _sclPin);
        _meter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE, I2C_ADDR, &Wire);
    }

    bool read(JsonDocument& doc) override {
        float lux = _meter.readLightLevel();

        if (!bh1750IsValidReading(lux)) return false;

        doc["light_intensity"] = lux;
        return true;
    }

    const char* getName() const override { return "BH1750"; }

private:
    uint8_t _sdaPin;
    uint8_t _sclPin;
    BH1750 _meter;
};

} // namespace Greenhouse

#endif // BH1750_SENSOR_IMPL_H
