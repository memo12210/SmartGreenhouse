#ifndef MQ135_SENSOR_H
#define MQ135_SENSOR_H

#include <Arduino.h>
#include "sensor.h"

namespace Greenhouse::Sensors {
    class MQ135Sensor : public Sensor<float> {
    public:
        MQ135Sensor(uint8_t pin, float loadResistance = 10000);
        void begin() override;
        float read() override;

    private:
        float rl, r0;
        bool calibrated;

        void calibrate(uint16_t samples = 100, uint16_t intervalMs = 200);
        float calculateRS(int rawADC);
        float calculatePPM(float rs);
    };
} // namespace Greenhouse::Sensors

#endif // MQ135_SENSOR_H
