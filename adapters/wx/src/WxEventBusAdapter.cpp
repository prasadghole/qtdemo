#include "WxEventBusAdapter.h"
#include "ui/MainWindow.h"
#include "domain/services/DataProcessingService.h"
#include <wx/wx.h>

WxEventBusAdapter::WxEventBusAdapter(MainWindow* main_window, IEventBus& event_bus)
    : main_window_(main_window), event_bus_(event_bus)
{
    subscribe_to_events();
}

WxEventBusAdapter::~WxEventBusAdapter() {
    if (processed_token_ >= 0)
        event_bus_.unsubscribe(processed_token_);
}

void WxEventBusAdapter::subscribe_to_events() {
    // Handler runs on the worker thread; use CallAfter to dispatch to UI thread.
    processed_token_ = event_bus_.subscribe("sensor.processed",
        [this](const void* data) {
            const auto& p = *static_cast<const DataProcessingService::ProcessedData*>(data);
            double value       = p.rawValue;
            bool   alarm       = p.alarm;
            std::string category = p.category;
            wxTheApp->CallAfter([this, value, alarm, category]() {
                main_window_->on_sensor_value(value);
                main_window_->on_alarm_changed(alarm);
                main_window_->on_category_changed(category);
            });
        });
}
