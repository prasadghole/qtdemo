#include "MainWindow.h"
#include <wx/sizer.h>
#include <wx/datetime.h>
#include <sstream>
#include <iomanip>

wxBEGIN_EVENT_TABLE(MainWindow, wxFrame)
wxEND_EVENT_TABLE()

MainWindow::MainWindow(const wxString& title)
    : wxFrame(nullptr, wxID_ANY, title, wxDefaultPosition, wxSize(700, 600))
{
    setup_ui();
    Centre();
}

MainWindow::~MainWindow() = default;

void MainWindow::setup_ui() {
    wxPanel* panel = new wxPanel(this);
    wxBoxSizer* root = new wxBoxSizer(wxVERTICAL);
    root->SetMinSize(wxSize(600, 500));

    // --- Sensor readings group ---
    wxStaticBoxSizer* sensor_box = new wxStaticBoxSizer(wxVERTICAL, panel, "Sensor readings");

    // Value row
    wxBoxSizer* value_row = new wxBoxSizer(wxHORIZONTAL);
    wxStaticText* value_title = new wxStaticText(panel, wxID_ANY, "Value:");
    value_label_ = new wxStaticText(panel, wxID_ANY, "--");
    wxFont val_font = value_label_->GetFont();
    val_font.SetPointSize(22);
    val_font.MakeBold();
    value_label_->SetFont(val_font);
    value_row->Add(value_title, 0, wxALIGN_CENTER_VERTICAL | wxRIGHT, 8);
    value_row->Add(value_label_, 0, wxALIGN_CENTER_VERTICAL);
    value_row->AddStretchSpacer();

    // Progress bar
    value_bar_ = new wxGauge(panel, wxID_ANY, 100, wxDefaultPosition, wxDefaultSize,
                             wxGA_HORIZONTAL | wxGA_SMOOTH);
    value_bar_->SetValue(0);

    // Status row (Category and Alarm)
    wxBoxSizer* status_row = new wxBoxSizer(wxHORIZONTAL);
    wxStaticText* cat_label = new wxStaticText(panel, wxID_ANY, "Category:");
    category_label_ = new wxStaticText(panel, wxID_ANY, "--");
    wxStaticText* alm_label = new wxStaticText(panel, wxID_ANY, "Alarm:");
    alarm_label_ = new wxStaticText(panel, wxID_ANY, "OK");
    alarm_label_->SetForegroundColour(*wxGREEN);
    wxFont alarm_font = alarm_label_->GetFont();
    alarm_font.MakeBold();
    alarm_label_->SetFont(alarm_font);

    status_row->Add(cat_label, 0, wxALIGN_CENTER_VERTICAL | wxRIGHT, 8);
    status_row->Add(category_label_, 0, wxALIGN_CENTER_VERTICAL);
    status_row->AddSpacer(24);
    status_row->Add(alm_label, 0, wxALIGN_CENTER_VERTICAL | wxRIGHT, 8);
    status_row->Add(alarm_label_, 0, wxALIGN_CENTER_VERTICAL);
    status_row->AddStretchSpacer();

    sensor_box->Add(value_row, 0, wxEXPAND | wxALL, 8);
    sensor_box->Add(value_bar_, 0, wxEXPAND | wxALL, 8);
    sensor_box->Add(status_row, 0, wxEXPAND | wxALL, 8);

    // --- Worker control group ---
    wxStaticBoxSizer* ctrl_box = new wxStaticBoxSizer(wxHORIZONTAL, panel, "Worker control");

    start_btn_ = new wxButton(panel, wxID_ANY, "Start worker");
    stop_btn_ = new wxButton(panel, wxID_ANY, "Stop worker");
    stop_btn_->Enable(false);
    status_label_ = new wxStaticText(panel, wxID_ANY, "Worker stopped");
    status_label_->SetForegroundColour(*wxLIGHT_GREY);

    start_btn_->Bind(wxEVT_BUTTON, &MainWindow::on_start_button_clicked, this);
    stop_btn_->Bind(wxEVT_BUTTON, &MainWindow::on_stop_button_clicked, this);

    ctrl_box->Add(start_btn_, 0, wxALL, 8);
    ctrl_box->Add(stop_btn_, 0, wxALL, 8);
    ctrl_box->AddSpacer(16);
    ctrl_box->Add(status_label_, 0, wxALIGN_CENTER_VERTICAL | wxALL, 8);
    ctrl_box->AddStretchSpacer();

    // --- Event log group ---
    wxStaticBoxSizer* log_box = new wxStaticBoxSizer(wxVERTICAL, panel, "Event log (last 50)");

    log_list_ = new wxListCtrl(panel, wxID_ANY, wxDefaultPosition, wxSize(-1, 180),
                               wxLC_REPORT | wxLC_SINGLE_SEL);
    log_list_->InsertColumn(0, "Event", wxLIST_FORMAT_LEFT, 500);

    log_box->Add(log_list_, 1, wxEXPAND | wxALL, 8);

    // Assemble layout
    root->Add(sensor_box, 0, wxEXPAND | wxALL, 12);
    root->Add(ctrl_box, 0, wxEXPAND | wxALL, 12);
    root->Add(log_box, 1, wxEXPAND | wxALL, 12);

    panel->SetSizer(root);
}

void MainWindow::on_start_button_clicked(wxCommandEvent& WXUNUSED(event)) {
    if (on_start_worker) {
        on_start_worker();
    }
}

void MainWindow::on_stop_button_clicked(wxCommandEvent& WXUNUSED(event)) {
    if (on_stop_worker) {
        on_stop_worker();
    }
}

void MainWindow::on_sensor_value(double value) {
    std::ostringstream oss;
    oss << std::fixed << std::setprecision(2) << value;
    value_label_->SetLabel(oss.str());
    value_bar_->SetValue(static_cast<int>(value));
    ++event_count_;

    if (event_count_ % 5 == 0) {
        wxDateTime now = wxDateTime::Now();
        std::ostringstream log_oss;
        log_oss << "[" << now.Format("%H:%M:%S").ToStdString() << "] "
                << "value=" << std::fixed << std::setprecision(2) << value
                << "  events=" << event_count_;
        add_log_entry(log_oss.str());
    }
}

void MainWindow::on_alarm_changed(bool alarm) {
    if (alarm) {
        alarm_label_->SetLabel("ALARM");
        alarm_label_->SetForegroundColour(*wxRED);
        value_bar_->SetBackgroundColour(wxColour(231, 76, 60));
    } else {
        alarm_label_->SetLabel("OK");
        alarm_label_->SetForegroundColour(*wxGREEN);
        value_bar_->SetBackgroundColour(wxSystemSettings::GetColour(wxSYS_COLOUR_BTNFACE));
    }
    value_bar_->Refresh();
}

void MainWindow::on_category_changed(const wxString& category) {
    category_label_->SetLabel(category);
}

void MainWindow::on_worker_state_changed(bool running) {
    start_btn_->Enable(!running);
    stop_btn_->Enable(running);
    status_label_->SetLabel(running ? "Worker running" : "Worker stopped");
    status_label_->SetForegroundColour(running ? *wxGREEN : *wxLIGHT_GREY);
    add_log_entry(running ? "--- Worker STARTED ---" : "--- Worker STOPPED ---");
}

void MainWindow::add_log_entry(const wxString& text) {
    long index = log_list_->InsertItem(log_list_->GetItemCount(), text);
    log_list_->SetItemState(index, wxLIST_STATE_FOCUSED, wxLIST_STATE_FOCUSED);

    // Keep last 50 entries
    while (log_list_->GetItemCount() > 50) {
        log_list_->DeleteItem(0);
    }
}
