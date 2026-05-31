#pragma once

#include <wx/wx.h>
#include <wx/listctrl.h>
#include <memory>
#include <functional>

class EventBus;
class IWorker;
class WorkerThread;

class MainWindow : public wxFrame {
public:
    explicit MainWindow(const wxString& title);
    ~MainWindow();

    // Callbacks from adapters — set by composition root
    std::function<void()> on_start_worker;
    std::function<void()> on_stop_worker;

private:
    // UI event handlers
    void on_start_button_clicked(wxCommandEvent& event);
    void on_stop_button_clicked(wxCommandEvent& event);

    // Data update handlers (called from adapter)
    void on_sensor_value(double value);
    void on_alarm_changed(bool alarm);
    void on_category_changed(const wxString& category);
    void on_worker_state_changed(bool running);

    void add_log_entry(const wxString& text);
    void setup_ui();

    // Widgets
    wxStaticText* value_label_;
    wxGauge* value_bar_;
    wxStaticText* category_label_;
    wxStaticText* alarm_label_;
    wxButton* start_btn_;
    wxButton* stop_btn_;
    wxStaticText* status_label_;
    wxListCtrl* log_list_;

    int event_count_ = 0;

    wxDECLARE_EVENT_TABLE();
    friend class WxEventBusAdapter;
};
