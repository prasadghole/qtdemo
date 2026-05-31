#pragma once
#include "../domain/interfaces/IEventBus.h"
#include <unordered_map>
#include <vector>
#include <mutex>
#include <atomic>
#include <functional>
#include <string>
#include <algorithm>

// Thread-safe EventBus. Zero Qt dependency.
// Callbacks are invoked on the publisher's thread.
// The Qt adapter layer is responsible for re-dispatching to the UI thread.
class EventBus : public IEventBus {
public:
    int subscribe(const std::string& topic,
                  std::function<void(const void*)> handler) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
        int token = nextToken_++;
        subscribers_[topic].push_back({token, std::move(handler)});
        return token;
    }

    void unsubscribe(int token) override {
        std::lock_guard<std::mutex> lock(mutex_);
        for (auto& [topic, subs] : subscribers_) {
            subs.erase(
                std::remove_if(subs.begin(), subs.end(),
                    [token](const Sub& s){ return s.token == token; }),
                subs.end());
        }
    }

    void publish(const std::string& topic, const void* data) override {
        // Copy subscriber list under lock to avoid holding lock during callbacks
        std::vector<Sub> snapshot;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            auto it = subscribers_.find(topic);
            if (it != subscribers_.end())
                snapshot = it->second;
        }
        for (const auto& sub : snapshot)
            sub.handler(data);
    }

private:
    struct Sub {
        int token;
        std::function<void(const void*)> handler;
    };

    std::unordered_map<std::string, std::vector<Sub>> subscribers_;
    std::mutex      mutex_;
    std::atomic<int> nextToken_{0};
};
