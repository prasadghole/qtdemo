#pragma once
#include "../interfaces/IEventBus.h"
#include "../models/SensorData.h"
#include <atomic>
#include <memory>
// Needed for sleep_for inside run()
#include <thread>
#include <chrono>
#include <cmath>
// Needed for sleep_for inside run()
#include <thread>
#include <chrono>
#include <cmath>

// Pure domain logic — no Qt, no std::thread (thread is injected externally)
// This class only knows how to produce sensor data and publish it.
class SensorWorker {
public:
    explicit SensorWorker(std::shared_ptr<IEventBus> bus)
        : bus_(std::move(bus))
        , eventCount_(0)
        , angle_(0.0)
    {}

    // Called by WorkerThread on its thread
    void run(std::atomic<bool>& running) {
        while (running.load()) {
            SensorData data;
            data.channel      = 0;
            data.timestamp_ms = currentTimeMs();
            data.value        = generateSineValue();
            data.label        = "Channel-A";

            bus_->publish("sensor.data", &data);
            ++eventCount_;

            // Simulate ~10 Hz sampling
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
    }

    int eventCount() const { return eventCount_.load(); }

private:
    double generateSineValue() {
        angle_ += 0.15;
        if (angle_ > 6.283185307) angle_ -= 6.283185307;
        return 50.0 + 45.0 * std::sin(angle_);
    }

    uint64_t currentTimeMs() {
        using namespace std::chrono;
        return duration_cast<milliseconds>(
            steady_clock::now().time_since_epoch()).count();
    }

    std::shared_ptr<IEventBus> bus_;
    std::atomic<int>  eventCount_;
    double            angle_;
};

