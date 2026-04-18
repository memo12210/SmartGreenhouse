#include "dht_sensor.h"

namespace Greenhouse::Sensors {
    DHTSensor::DHTSensor(uint8_t pin, DHTType type) :
        Sensor<DHTReading>(pin), _dht(pin, (type == DHTType::DHT11) ? ::DHT11 : ::DHT22) {}

    void DHTSensor::begin() { _dht.begin(); }

    DHTReading DHTSensor::read() {
        DHTReading reading{};
        reading.temperatureC = _dht.readTemperature();
        reading.humidity = _dht.readHumidity();
        return reading;
    }
} // namespace Greenhouse::Sensors
