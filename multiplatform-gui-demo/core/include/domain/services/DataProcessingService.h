#pragma once
#include "../interfaces/IEventBus.h"
#include "../models/SensorData.h"
#include <memory>
#include <atomic>
#include <string>

// Domain service — subscribes to raw sensor data, publishes processed results.
// Zero Qt. Fully unit-testable with a mock IEventBus.
class DataProcessingService {
public:
    explicit DataProcessingService(std::shared_ptr<IEventBus> bus)
        : bus_(std::move(bus))
        , processedCount_(0)
        , lastValue_(0.0)
    {
        token_ = bus_->subscribe("sensor.data",
            [this](const void* raw) {
                onSensorData(static_cast<const SensorData*>(raw));
            });
    }

    ~DataProcessingService() {
        bus_->unsubscribe(token_);
    }

    int    processedCount() const { return processedCount_.load(); }
    double lastValue()      const { return lastValue_.load(); }

private:
    void onSensorData(const SensorData* d) {
        // Simple domain logic: classify the value
        ProcessedData result;
        result.rawValue  = d->value;
        result.channel   = d->channel;
        result.alarm     = (d->value > 80.0 || d->value < 20.0);
        result.category  = classify(d->value);

        lastValue_.store(d->value);
        ++processedCount_;

        // Publish processed result for the UI adapter to pick up
        bus_->publish("sensor.processed", &result);
    }

    std::string classify(double v) {
        if (v > 80.0) return "HIGH";
        if (v < 20.0) return "LOW";
        return "NORMAL";
    }

    std::shared_ptr<IEventBus> bus_;
    int    token_;
    std::atomic<int>    processedCount_;
    std::atomic<double> lastValue_;

public:
    // Inner result type — plain struct, no Qt
    struct ProcessedData {
        double      rawValue;
        uint8_t     channel;
        bool        alarm;
        std::string category;
    };
};
