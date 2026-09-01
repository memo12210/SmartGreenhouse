#ifndef SOIL_MOISTURE_CONVERSION_H
#define SOIL_MOISTURE_CONVERSION_H

#include <stdint.h>

namespace Greenhouse {

// Maps a raw 12-bit ADC reading from a resistive soil moisture probe to a
// moisture percentage in the range [0, 100].
//
// The module's analog output rises toward Vcc as the soil dries out (high
// resistance) and falls toward ground as it saturates (low resistance), so the
// percentage is the inverted ratio of the reading against the ADC ceiling.
inline float soilMoistureRawToPercent(uint16_t raw) {
    constexpr float ADC_MAX = 4095.0f;
    if (raw > ADC_MAX) {
        raw = static_cast<uint16_t>(ADC_MAX);
    }
    float percent = (1.0f - static_cast<float>(raw) / ADC_MAX) * 100.0f;
    if (percent < 0.0f) percent = 0.0f;
    if (percent > 100.0f) percent = 100.0f;
    return percent;
}

} // namespace Greenhouse

#endif // SOIL_MOISTURE_CONVERSION_H
