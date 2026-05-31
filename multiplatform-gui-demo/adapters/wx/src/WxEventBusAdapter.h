#pragma once

#include "domain/interfaces/IEventBus.h"

class MainWindow;

class WxEventBusAdapter {
public:
    explicit WxEventBusAdapter(MainWindow* main_window, IEventBus& event_bus);
    ~WxEventBusAdapter();

private:
    void subscribe_to_events();

    MainWindow* main_window_;
    IEventBus& event_bus_;
    int processed_token_ = -1;
};
