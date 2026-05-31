#include "MainWindow.h"
#include <QFont>
#include <QDateTime>

MainWindow::MainWindow(QWidget* parent)
    : QMainWindow(parent)
{
    setWindowTitle("Qt5 Decoupled Architecture Demo");
    setMinimumSize(600, 500);
    setupUi();
}

void MainWindow::setupUi() {
    central_ = new QWidget(this);
    setCentralWidget(central_);

    auto* root = new QVBoxLayout(central_);
    root->setSpacing(12);
    root->setContentsMargins(16, 16, 16, 16);

    // --- Sensor value display ---
    auto* sensorGroup = new QGroupBox("Sensor readings", this);
    auto* sensorLayout = new QVBoxLayout(sensorGroup);

    auto* valueRow = new QHBoxLayout();
    auto* valueTitle = new QLabel("Value:", this);
    valueLabel_ = new QLabel("--", this);
    valueLabel_->setObjectName("valueLabel");
    valueLabel_->setAccessibleName("sensor value");
    QFont valFont = valueLabel_->font();
    valFont.setPointSize(22);
    valFont.setBold(true);
    valueLabel_->setFont(valFont);
    valueRow->addWidget(valueTitle);
    valueRow->addWidget(valueLabel_);
    valueRow->addStretch();

    valueBar_ = new QProgressBar(this);
    valueBar_->setObjectName("valueBar");
    valueBar_->setAccessibleName("value bar");
    valueBar_->setRange(0, 100);
    valueBar_->setValue(0);
    valueBar_->setTextVisible(true);
    valueBar_->setFormat("%v / 100");

    auto* statusRow = new QHBoxLayout();
    auto* catLabel = new QLabel("Category:", this);
    categoryLabel_ = new QLabel("--", this);
    categoryLabel_->setObjectName("categoryLabel");
    categoryLabel_->setAccessibleName("category");
    auto* almLabel = new QLabel("Alarm:", this);
    alarmLabel_ = new QLabel("OK", this);
    alarmLabel_->setObjectName("alarmLabel");
    alarmLabel_->setAccessibleName("alarm status");
    alarmLabel_->setStyleSheet("color: green; font-weight: bold;");
    statusRow->addWidget(catLabel);
    statusRow->addWidget(categoryLabel_);
    statusRow->addSpacing(24);
    statusRow->addWidget(almLabel);
    statusRow->addWidget(alarmLabel_);
    statusRow->addStretch();

    sensorLayout->addLayout(valueRow);
    sensorLayout->addWidget(valueBar_);
    sensorLayout->addLayout(statusRow);

    // --- Controls ---
    auto* ctrlGroup = new QGroupBox("Worker control", this);
    auto* ctrlLayout = new QHBoxLayout(ctrlGroup);

    startBtn_ = new QPushButton("Start worker", this);
    startBtn_->setObjectName("startBtn");
    startBtn_->setAccessibleName("Start worker");
    stopBtn_  = new QPushButton("Stop worker", this);
    stopBtn_->setObjectName("stopBtn");
    stopBtn_->setAccessibleName("Stop worker");
    stopBtn_->setEnabled(false);
    statusLabel_ = new QLabel("Worker stopped", this);
    statusLabel_->setObjectName("statusLabel");
    statusLabel_->setAccessibleName("worker status");
    statusLabel_->setStyleSheet("color: gray;");

    ctrlLayout->addWidget(startBtn_);
    ctrlLayout->addWidget(stopBtn_);
    ctrlLayout->addSpacing(16);
    ctrlLayout->addWidget(statusLabel_);
    ctrlLayout->addStretch();

    // --- Event log ---
    auto* logGroup = new QGroupBox("Event log (last 50)", this);
    auto* logLayout = new QVBoxLayout(logGroup);
    logList_ = new QListWidget(this);
    logList_->setObjectName("logList");
    logList_->setAccessibleName("event log");
    logList_->setMaximumHeight(180);
    logLayout->addWidget(logList_);

    root->addWidget(sensorGroup);
    root->addWidget(ctrlGroup);
    root->addWidget(logGroup);

    // Button signals — adapter will connect these to worker slots
    connect(startBtn_, &QPushButton::clicked, this, &MainWindow::startRequested);
    connect(stopBtn_,  &QPushButton::clicked, this, &MainWindow::stopRequested);
}

void MainWindow::onSensorValue(double value) {
    valueLabel_->setText(QString::number(value, 'f', 2));
    valueBar_->setValue(static_cast<int>(value));
    ++eventCount_;

    if (eventCount_ % 5 == 0) {  // log every 5th event to keep list manageable
        addLogEntry(QString("[%1] value=%2  events=%3")
            .arg(QDateTime::currentDateTime().toString("hh:mm:ss"))
            .arg(value, 0, 'f', 2)
            .arg(eventCount_));
    }
}

void MainWindow::onAlarmChanged(bool alarm) {
    if (alarm) {
        alarmLabel_->setText("ALARM");
        alarmLabel_->setStyleSheet("color: red; font-weight: bold;");
        valueBar_->setStyleSheet("QProgressBar::chunk { background-color: #e74c3c; }");
    } else {
        alarmLabel_->setText("OK");
        alarmLabel_->setStyleSheet("color: green; font-weight: bold;");
        valueBar_->setStyleSheet("");
    }
}

void MainWindow::onCategoryChanged(const QString& category) {
    categoryLabel_->setText(category);
}

void MainWindow::onWorkerStateChanged(bool running) {
    startBtn_->setEnabled(!running);
    stopBtn_->setEnabled(running);
    statusLabel_->setText(running ? "Worker running" : "Worker stopped");
    statusLabel_->setStyleSheet(running ? "color: green;" : "color: gray;");
    addLogEntry(running ? "--- Worker STARTED ---" : "--- Worker STOPPED ---");
}

void MainWindow::addLogEntry(const QString& text) {
    logList_->addItem(text);
    // Keep last 50 entries
    while (logList_->count() > 50)
        delete logList_->takeItem(0);
    logList_->scrollToBottom();
}
