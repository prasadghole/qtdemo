#pragma once
#include <functional>
#include <string>

// Pure virtual interface — zero Qt, fully portable
class IEventBus {
public:
    virtual ~IEventBus() = default;

    // Returns a subscription token used to unsubscribe later
    virtual int subscribe(const std::string& topic,
                          std::function<void(const void* data)> handler) = 0;

    virtual void unsubscribe(int token) = 0;

    virtual void publish(const std::string& topic, const void* data) = 0;
};
