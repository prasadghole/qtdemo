#pragma once

#include "../../../src/domain/interfaces/IEventBus.h"
#include <memory>
#include <functional>

class MainWindow;

class WxEventBusAdapter {
public:
    explicit WxEventBusAdapter(MainWindow* main_window, IEventBus& event_bus);
    ~WxEventBusAdapter();

    void subscribe_to_events();

private:
    MainWindow* main_window_;
    IEventBus& event_bus_;
    std::shared_ptr<IEventBus::Subscription> sensor_subscription_;
    std::shared_ptr<IEventBus::Subscription> processed_subscription_;
};
