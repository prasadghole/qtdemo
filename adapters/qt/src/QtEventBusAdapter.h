#pragma once
#include <QObject>
#include <QTimer>
#include <QString>
#include "domain/interfaces/IEventBus.h"
#include "domain/models/SensorData.h"
#include "domain/services/DataProcessingService.h"
#include <memory>
#include <atomic>
#include <cmath>        // std::abs

// The ONLY class in this project that uses QObject / Q_OBJECT / MOC.
//
// Design rules:
//  1. Each signal is emitted ONLY when its value actually changes.
//  2. One QTimer::singleShot per domain event — but inside the lambda
//     we do per-field change detection before firing any signal.
//  3. Last-seen values are stored as members so comparisons are cheap.

class QtEventBusAdapter : public QObject {
    Q_OBJECT

public:
    explicit QtEventBusAdapter(std::shared_ptr<IEventBus> bus,
                                QObject* parent = nullptr)
        : QObject(parent)
        , bus_(std::move(bus))
        , lastValue_(0.0)
        , lastAlarm_(false)
        , lastCategory_("--")
    {
        // NOTE: this callback fires on the worker's std::thread, NOT the UI thread.
        // We capture changed values by value into the lambda, then post ONE
        // singleShot(0) to the UI thread. Inside that lambda we check each
        // field individually and only emit the signals that changed.
        processedToken_ = bus_->subscribe("sensor.processed",
            [this](const void* raw) {
                const auto* d =
                    static_cast<const DataProcessingService::ProcessedData*>(raw);

                // Capture new values by value — raw pointer lifetime ends here
                const double  newVal      = d->rawValue;
                const bool    newAlarm    = d->alarm;
                const QString newCategory = QString::fromStdString(d->category);

                // Qt5 cross-thread dispatch: post to the UI event loop
                QTimer::singleShot(0, this, [this, newVal, newAlarm, newCategory]() {

                    // --- value: emit only if changed beyond float noise ---
                    if (std::abs(newVal - lastValue_) > 0.001) {
                        lastValue_ = newVal;
                        emit sensorValueChanged(newVal);
                    }

                    // --- alarm: emit only on state transition ---
                    if (newAlarm != lastAlarm_) {
                        lastAlarm_ = newAlarm;
                        emit alarmChanged(newAlarm);
                    }

                    // --- category: emit only when string changes ---
                    if (newCategory != lastCategory_) {
                        lastCategory_ = newCategory;
                        emit categoryChanged(newCategory);
                    }
                });
            });
    }

    ~QtEventBusAdapter() override {
        bus_->unsubscribe(processedToken_);
    }

signals:
    // Each signal fires ONLY when its value has actually changed.
    void sensorValueChanged(double value);   // fires every sample (value always moves)
    void alarmChanged(bool alarm);           // fires only on NORMAL→ALARM or ALARM→NORMAL
    void categoryChanged(const QString& category); // fires only on category transition

private:
    std::shared_ptr<IEventBus> bus_;
    int processedToken_;

    // Last-seen values — compared inside the UI-thread lambda.
    // These are only ever read/written on the Qt UI thread (inside the
    // singleShot lambda), so no mutex is needed.
    double  lastValue_;
    bool    lastAlarm_;
    QString lastCategory_;
};
