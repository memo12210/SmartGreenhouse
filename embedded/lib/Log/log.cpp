#include "log.h"
#include <stdarg.h>

Stream *Log::_stream = nullptr;
Log::Level Log::_currentLevel = Log::Level::INFO;

void Log::begin(Stream &stream, Level level) {
    _stream = &stream;
    _currentLevel = level;
}

void Log::setLevel(Level level) { _currentLevel = level; }

const char *Log::levelToString(Level level) {
    switch (level) {
        case Level::DEBUG:
            return "DEBUG";
        case Level::INFO:
            return "INFO";
        case Level::WARN:
            return "WARN";
        case Level::ERROR:
            return "ERROR";
        default:
            return "UNKNOWN";
    }
}

void Log::log(Level level, const char *file, int line, const char *format, ...) {
    if (!_stream || level < _currentLevel)
        return;

    // printing time, level, file:line
    _stream->print("[");
    _stream->print(millis());
    _stream->print(" ms] ");
    _stream->print(levelToString(level));
    _stream->print(" (");
    _stream->print(file);
    _stream->print(":");
    _stream->print(line);
    _stream->print("): ");

    // print formatted message
    char buf[256];
    va_list args;
    va_start(args, format);
    vsnprintf(buf, sizeof(buf), format, args);
    va_end(args);
    _stream->println(buf);
}
