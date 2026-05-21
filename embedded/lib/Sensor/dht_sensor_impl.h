#ifndef DHT_SENSOR_IMPL_H
#define DHT_SENSOR_IMPL_H

#include "sensor_interface.h"
#include <DHT.h>

namespace Greenhouse {

class DHTSensorImpl : public SensorInterface {
public:
    DHTSensorImpl(uint8_t pin, uint8_t type) : _dht(pin, type) {}

    void begin() override {
        _dht.begin();
    }

    bool read(JsonDocument& doc) override {
        float h = _dht.readHumidity();
        float t = _dht.readTemperature();

        if (isnan(h) || isnan(t)) return false;

        doc["temperature"] = t;
        doc["humidity"] = h;
        return true;
    }

    const char* getName() const override { return "DHT"; }

private:
    DHT _dht;
};

} // namespace Greenhouse

#endif // DHT_SENSOR_IMPL_H
