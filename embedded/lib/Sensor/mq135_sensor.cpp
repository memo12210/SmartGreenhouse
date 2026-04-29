#include "mq135_sensor.h"

#define RATIO_CLEAN_AIR 3.6
#define CO2_A 116.6020682
#define CO2_B -2.769034857

namespace Greenhouse::Sensors {
    MQ135Sensor::MQ135Sensor(uint8_t pin, float loadResistance) : Sensor<float>(pin) {
        rl = loadResistance;
        r0 = 0;
        calibrated = false;
    }

    void MQ135Sensor::calibrate(uint16_t samples, uint16_t intervalMs) {
        float rsSum = 0;

        for (uint16_t i = 0; i < samples; i++) {
            int adc = analogRead(pin);
            float rs = calculateRS(adc);
            rsSum += rs;
            delay(intervalMs);
        }

        float rsAvg = rsSum / samples;
        r0 = rsAvg / RATIO_CLEAN_AIR;
        calibrated = true;
    }

    void MQ135Sensor::begin() { calibrate(); }

    float MQ135Sensor::read() {
        if (!calibrated)
            return NAN;

        int adc = analogRead(pin);
        float rs = calculateRS(adc);
        return calculatePPM(rs);
    }

    float MQ135Sensor::calculateRS(int rawADC) {
        float vOut = (rawADC / 1023.0) * 3.3;
        return rl * ((3.3 - vOut) / vOut);
    }

    float MQ135Sensor::calculatePPM(float rs) { return CO2_A * pow((rs / r0), CO2_B); }

} // namespace Greenhouse::Sensors
