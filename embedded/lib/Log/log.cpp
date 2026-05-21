#include "log.h"
#include <stdarg.h>

Stream *Log::_stream = nullptr;
Log::Level Log::_currentLevel = Log::Level::INFO;

void Log::begin(Stream &stream, Level level) {
    _stream = &stream;
    _currentLevel = level;
}

void Log::setLevel(Level level) {
    _currentLevel = level;
}

void Log::printTimestamp() {
#ifdef ARDUINO
    if (!_stream) return;
    unsigned long ms = millis();
    unsigned long seconds = ms / 1000;
    unsigned long minutes = seconds / 60;
    unsigned long hours = minutes / 60;
    _stream->printf("[%02lu:%02lu:%02lu.%03lu] ", hours % 24, minutes % 60, seconds % 60, ms % 1000);
#else
    auto now = std::chrono::system_clock::now();
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;
    auto timer = std::chrono::system_clock::to_time_t(now);
    std::tm bt = *std::localtime(&timer);
    std::printf("[%02d:%02d:%02d.%03ld] ", bt.tm_hour, bt.tm_min, bt.tm_sec, ms.count());
#endif
}

const char *Log::levelToString(Level level) {
    switch (level) {
        case Level::DEBUG: return "DEBUG";
        case Level::INFO:  return "INFO";
        case Level::WARN:  return "WARN";
        case Level::ERROR: return "ERROR";
        default:           return "UNKNOWN";
    }
}

void Log::log(Level level, const char *file, int line, const char *format, ...) {
    if (level < _currentLevel) return;

    printTimestamp();
#ifdef ARDUINO
    if (_stream) {
        _stream->printf("%-5s [%s:%d] ", levelToString(level), file, line);
        va_list args;
        va_start(args, format);
        char buffer[256];
        vsnprintf(buffer, sizeof(buffer), format, args);
        _stream->println(buffer);
        va_end(args);
    }
#else
    std::printf("%-5s [%s:%d] ", levelToString(level), file, line);
    va_list args;
    va_start(args, format);
    std::vprintf(format, args);
    std::printf("\n");
    va_end(args);
#endif
}
