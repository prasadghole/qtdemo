#pragma once
#include <QObject>
#include <QTimer>
#include <QString>
#include "../domain/interfaces/IEventBus.h"
#include "../domain/models/SensorData.h"
#include "../domain/services/DataProcessingService.h"
#include <memory>

// The ONLY class in this project that uses QObject / Q_OBJECT / MOC.
// Subscribes to the pure-C++ EventBus and re-emits data as Qt signals,
// safely marshalled to the Qt UI thread via QTimer::singleShot (Qt5 compatible).
class QtEventBusAdapter : public QObject {
    Q_OBJECT

public:
    explicit QtEventBusAdapter(std::shared_ptr<IEventBus> bus,
                                QObject* parent = nullptr)
        : QObject(parent)
        , bus_(std::move(bus))
    {
        // Subscribe to processed sensor results from the domain service.
        // NOTE: this callback fires on the worker's std::thread, NOT the UI thread.
        // We use QTimer::singleShot(0, this, lambda) — the Qt5-compatible way
        // to safely dispatch a lambda to the object's (UI) thread.
        processedToken_ = bus_->subscribe("sensor.processed",
            [this](const void* raw) {
                const auto* d =
                    static_cast<const DataProcessingService::ProcessedData*>(raw);

                // Capture by value — the raw pointer is stack-owned by the caller
                double   val      = d->rawValue;
                bool     alarm    = d->alarm;
                QString  category = QString::fromStdString(d->category);

                // Qt5 cross-thread dispatch: singleShot(0) posts to the UI event loop
                QTimer::singleShot(0, this, [this, val, alarm, category]() {
                    emit sensorValueChanged(val);
                    emit alarmChanged(alarm);
                    emit categoryChanged(category);
                });
            });
    }

    ~QtEventBusAdapter() override {
        bus_->unsubscribe(processedToken_);
    }

signals:
    // UI layer connects ONLY to these signals — it never touches domain objects
    void sensorValueChanged(double value);
    void alarmChanged(bool alarm);
    void categoryChanged(const QString& category);

private:
    std::shared_ptr<IEventBus> bus_;
    int processedToken_;
};
