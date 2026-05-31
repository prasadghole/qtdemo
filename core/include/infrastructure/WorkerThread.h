#pragma once
#include "../domain/interfaces/IWorker.h"
#include <thread>
#include <atomic>
#include <memory>

// Infrastructure: provides the actual std::thread.
// The domain worker (TWorker) only needs a run(atomic<bool>&) method.
// No Qt involvement here.
template<typename TWorker>
class WorkerThread : public IWorker {
public:
    explicit WorkerThread(std::shared_ptr<TWorker> worker)
        : worker_(std::move(worker))
        , running_(false)
    {}

    ~WorkerThread() override {
        stop();
    }

    void start() override {
        if (running_.load()) return;
        running_.store(true);
        thread_ = std::thread([this]{ worker_->run(running_); });
    }

    void stop() override {
        running_.store(false);
        if (thread_.joinable())
            thread_.join();
    }

    bool isRunning() const override {
        return running_.load();
    }

private:
    std::shared_ptr<TWorker> worker_;
    std::thread              thread_;
    std::atomic<bool>        running_;
};
