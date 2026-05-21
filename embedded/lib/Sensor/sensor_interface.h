#ifndef SENSOR_INTERFACE_H
#define SENSOR_INTERFACE_H

#include <ArduinoJson.h>

namespace Greenhouse {

class SensorInterface {
public:
    virtual ~SensorInterface() {}
    virtual void begin() = 0;
    virtual bool read(JsonDocument& doc) = 0;
    virtual const char* getName() const = 0;
};

} // namespace Greenhouse

#endif // SENSOR_INTERFACE_H
