#include "WxApp.h"
#include "ui/MainWindow.h"
#include "WxEventBusAdapter.h"
#include "../infrastructure/EventBus.h"
#include "../infrastructure/WorkerThread.h"
#include "../domain/services/DataProcessingService.h"
#include "../domain/workers/SensorWorker.h"

wxImplementApp(WxApp)

bool WxApp::OnInit() {
    if (!wxApp::OnInit()) {
        return false;
    }

    // Create domain objects (composition root / dependency injection)
    event_bus_ = std::make_unique<EventBus>();
    auto sensor_worker = std::make_unique<SensorWorker>();
    auto data_service = std::make_unique<DataProcessingService>();

    // Wire event subscriptions
    data_service->subscribe(*event_bus_);

    // Create UI
    main_window_ = new MainWindow("wxWidgets Decoupled Architecture Demo");

    // Create adapters
    event_adapter_ = std::make_unique<WxEventBusAdapter>(main_window_, *event_bus_);

    // Create and configure worker thread
    worker_thread_ = std::make_unique<WorkerThread>(
        [this]() { return std::make_unique<SensorWorker>(); },
        [this](IWorker& worker) {
            auto& sensor_worker = dynamic_cast<SensorWorker&>(worker);
            sensor_worker.set_event_bus(*event_bus_);
            event_bus_->publish("worker.started", std::any());
        },
        [this](IWorker& worker) {
            auto& sensor_worker = dynamic_cast<SensorWorker&>(worker);
            event_bus_->publish("worker.stopped", std::any());
        }
    );

    // Connect UI callbacks
    main_window_->on_start_worker = [this]() {
        worker_thread_->start();
        main_window_->on_worker_state_changed(true);
    };

    main_window_->on_stop_worker = [this]() {
        worker_thread_->stop();
        main_window_->on_worker_state_changed(false);
    };

    main_window_->Show();
    return true;
}

int WxApp::OnExit() {
    if (worker_thread_) {
        worker_thread_->stop();
    }
    return wxApp::OnExit();
}
