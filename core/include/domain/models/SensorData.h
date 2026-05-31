#pragma once
#include <cstdint>
#include <string>

// Pure C++ domain model — zero Qt dependency
struct SensorData {
    double   value;
    uint64_t timestamp_ms;
    uint8_t  channel;
    std::string label;
};

struct SystemStatus {
    bool    workerRunning;
    int     eventCount;
    double  lastValue;
};
