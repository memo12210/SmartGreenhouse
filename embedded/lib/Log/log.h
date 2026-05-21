#ifndef LOG_H
#define LOG_H

#ifdef ARDUINO
#include <Arduino.h>
#else
#include <iostream>
#include <cstdio>
#include <chrono>
#include <ctime>
#include <string>

// Mock Stream for desktop
class Stream {
public:
    virtual void printf(const char* format, ...) = 0;
    virtual void println(const char* s) = 0;
};
#endif

class Log {
public:
    enum class Level { DEBUG = 0, INFO, WARN, ERROR, NONE };

    static void begin(Stream &stream, Level level = Level::INFO);
    static void setLevel(Level level);
    static void log(Level level, const char *file, int line, const char *format, ...);

private:
    static Stream *_stream;
    static Level _currentLevel;
    static const char *levelToString(Level level);
    static void printTimestamp();
};

#define LOG_DEBUG(fmt, ...) Log::log(Log::Level::DEBUG, __FILE__, __LINE__, fmt, ##__VA_ARGS__);
#define LOG_INFO(fmt, ...) Log::log(Log::Level::INFO, __FILE__, __LINE__, fmt, ##__VA_ARGS__);
#define LOG_WARN(fmt, ...) Log::log(Log::Level::WARN, __FILE__, __LINE__, fmt, ##__VA_ARGS__);
#define LOG_ERROR(fmt, ...) Log::log(Log::Level::ERROR, __FILE__, __LINE__, fmt, ##__VA_ARGS__);

#endif // LOG_H
