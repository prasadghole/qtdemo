#pragma once
#include <QMainWindow>
#include <QLabel>
#include <QPushButton>
#include <QProgressBar>
#include <QListWidget>
#include <QGroupBox>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QTimer>

// Pure Qt UI class. Connects ONLY to adapter signals.
// Zero domain headers included here.
class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(QWidget* parent = nullptr);
    ~MainWindow() override = default;

public slots:
    // Connected to QtEventBusAdapter signals
    void onSensorValue(double value);
    void onAlarmChanged(bool alarm);
    void onCategoryChanged(const QString& category);

    // Connected to QtWorkerAdapter signal
    void onWorkerStateChanged(bool running);

signals:
    // Emitted by UI buttons — connects to QtWorkerAdapter slots
    void startRequested();
    void stopRequested();

private:
    void setupUi();
    void addLogEntry(const QString& text);

    // Widgets
    QWidget*      central_;
    QLabel*       valueLabel_;
    QLabel*       categoryLabel_;
    QLabel*       alarmLabel_;
    QProgressBar* valueBar_;
    QPushButton*  startBtn_;
    QPushButton*  stopBtn_;
    QListWidget*  logList_;
    QLabel*       statusLabel_;

    // Stats
    int eventCount_ = 0;
};
