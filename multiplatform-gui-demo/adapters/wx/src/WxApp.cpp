#include "WxApp.h"
#include "ui/MainWindow.h"
#include "WxEventBusAdapter.h"
#include "infrastructure/EventBus.h"
#include "infrastructure/WorkerThread.h"
#include "domain/services/DataProcessingService.h"
#include "domain/workers/SensorWorker.h"

wxIMPLEMENT_APP(WxApp);

WxApp::~WxApp() = default;

bool WxApp::OnInit() {
    if (!wxApp::OnInit())
        return false;

    event_bus_ = std::make_shared<EventBus>();

    auto sensor_worker = std::make_shared<SensorWorker>(event_bus_);
    data_service_ = std::make_unique<DataProcessingService>(event_bus_);

    main_window_ = new MainWindow("wxWidgets Decoupled Architecture Demo");

    event_adapter_ = std::make_unique<WxEventBusAdapter>(main_window_, *event_bus_);

    worker_thread_ = std::make_unique<WorkerThread<SensorWorker>>(sensor_worker);

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
    if (worker_thread_)
        worker_thread_->stop();
    return wxApp::OnExit();
}
