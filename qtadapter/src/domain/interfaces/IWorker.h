#pragma once

// Pure virtual interface — zero Qt, fully portable
class IWorker {
public:
    virtual ~IWorker() = default;
    virtual void start() = 0;
    virtual void stop()  = 0;
    virtual bool isRunning() const = 0;
};
