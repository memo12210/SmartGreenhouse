#ifndef LDR_READER_H
#define LDR_READER_H

#include <Arduino.h>

class LDRReader {
public:
    LDRReader(uint8_t pin);
    void begin();
    uint16_t readLightLevel();
    float getBrightnessPercentage();

private:
    uint8_t _pin;
};

#endif // LDR_READER_H
