#include "WxEventBusAdapter.h"
#include "ui/MainWindow.h"
#include "../domain/models/SensorData.h"
#include <wx/wx.h>

WxEventBusAdapter::WxEventBusAdapter(MainWindow* main_window, IEventBus& event_bus)
    : main_window_(main_window), event_bus_(event_bus)
{
    subscribe_to_events();
}

WxEventBusAdapter::~WxEventBusAdapter() = default;

void WxEventBusAdapter::subscribe_to_events() {
    // Subscribe to sensor.processed events
    processed_subscription_ = event_bus_.subscribe("sensor.processed",
        [this](const std::any& data) {
            try {
                const auto& processed = std::any_cast<const ProcessedSensorData&>(data);

                // Update UI from the event (safely dispatched to main thread via wxWidgets)
                main_window_->on_sensor_value(processed.value);
                main_window_->on_alarm_changed(processed.is_alarm);
                main_window_->on_category_changed(
                    processed.category == SensorCategory::HIGH ? "HIGH" :
                    processed.category == SensorCategory::LOW ? "LOW" : "NORMAL"
                );
            } catch (const std::bad_any_cast&) {
                // Ignore cast errors
            }
        });
}
