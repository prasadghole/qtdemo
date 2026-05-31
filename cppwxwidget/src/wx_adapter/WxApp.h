#pragma once

#include <wx/wx.h>
#include <memory>

class EventBus;
class WorkerThread;
class MainWindow;
class WxEventBusAdapter;

class WxApp : public wxApp {
public:
    bool OnInit() override;
    int OnExit() override;

private:
    std::unique_ptr<EventBus> event_bus_;
    std::unique_ptr<WorkerThread> worker_thread_;
    std::unique_ptr<WxEventBusAdapter> event_adapter_;
    MainWindow* main_window_ = nullptr;
};

wxDeclareApp(WxApp)
