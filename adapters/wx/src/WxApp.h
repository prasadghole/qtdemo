#pragma once

#include <wx/wx.h>
#include <memory>

class EventBus;
class DataProcessingService;
class IWorker;
class WxEventBusAdapter;
class MainWindow;

class WxApp : public wxApp {
public:
    bool OnInit() override;
    int OnExit() override;
    ~WxApp() override;  // defined in .cpp so incomplete unique_ptr types are resolved there

private:
    std::shared_ptr<EventBus> event_bus_;
    std::unique_ptr<DataProcessingService> data_service_;
    std::unique_ptr<IWorker> worker_thread_;
    std::unique_ptr<WxEventBusAdapter> event_adapter_;
    MainWindow* main_window_ = nullptr;
};

wxDECLARE_APP(WxApp);
