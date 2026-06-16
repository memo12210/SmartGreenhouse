#ifndef BH1750_CONVERSION_H
#define BH1750_CONVERSION_H

namespace Greenhouse {

// Decides whether a lux value returned by the BH1750 light meter is a real
// measurement. The driver signals an I2C failure with negative sentinel values
// (-1.0 "no values yet", -2.0 "device error"); a stuck/disconnected bus can
// also surface as NaN. Anything non-negative and finite is a genuine reading,
// including 0 lux (total darkness).
inline bool bh1750IsValidReading(float lux) {
    if (lux != lux) return false; // NaN
    return lux >= 0.0f;
}

} // namespace Greenhouse

#endif // BH1750_CONVERSION_H
