#include "ldr_reader.h"

LDRReader::LDRReader(uint8_t pin) : _pin(pin) {}

void LDRReader::begin() {}

uint16_t LDRReader::readLightLevel() { return analogRead(_pin); }

float LDRReader::getBrightnessPercentage() {
    uint16_t analogValue = readLightLevel();
    return (float) analogValue / 4095.0f * 100.0f;
}
