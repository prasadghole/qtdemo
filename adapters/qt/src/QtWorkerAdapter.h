#pragma once
#include <QObject>
#include "domain/interfaces/IWorker.h"
#include <memory>

// Wraps the pure-C++ IWorker so the UI can drive worker lifecycle
// via Qt signals/slots without the worker knowing anything about Qt.
class QtWorkerAdapter : public QObject {
    Q_OBJECT

public:
    explicit QtWorkerAdapter(std::shared_ptr<IWorker> worker,
                              QObject* parent = nullptr)
        : QObject(parent)
        , worker_(std::move(worker))
    {}

public slots:
    void startWorker() {
        worker_->start();
        emit workerStateChanged(true);
    }

    void stopWorker() {
        worker_->stop();
        emit workerStateChanged(false);
    }

signals:
    void workerStateChanged(bool running);

private:
    std::shared_ptr<IWorker> worker_;
};
