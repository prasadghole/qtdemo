#include <QApplication>
#include <memory>

// Infrastructure
#include "infrastructure/EventBus.h"
#include "infrastructure/WorkerThread.h"

// Domain
#include "domain/workers/SensorWorker.h"
#include "domain/services/DataProcessingService.h"

// Qt adapter layer (only Qt-aware code)
#include "qt_adapter/QtEventBusAdapter.h"
#include "qt_adapter/QtWorkerAdapter.h"
#include "qt_adapter/ui/MainWindow.h"

// -----------------------------------------------------------------------
// Composition root: the ONLY place that knows about all layers.
// Everything is wired here via dependency injection.
// Nothing else in the codebase does 'new' on domain objects.
// -----------------------------------------------------------------------
int main(int argc, char* argv[]) {
    QApplication app(argc, argv);
    app.setApplicationName("Qt5 Decoupled Architecture Demo");
    app.setOrganizationName("Demo");

    // 1. Infrastructure: create the event bus (shared across all layers)
    auto bus = std::make_shared<EventBus>();

    // 2. Domain: create the sensor worker and processing service
    //    Neither of these knows anything about Qt
    auto sensorWorker = std::make_shared<SensorWorker>(bus);
    auto processingService = std::make_shared<DataProcessingService>(bus);

    // 3. Infrastructure: wrap the domain worker in a std::thread manager
    auto workerThread = std::make_shared<WorkerThread<SensorWorker>>(sensorWorker);

    // 4. Qt adapter layer: bridge the pure-C++ event bus to Qt signals
    //    This is the only QObject in the non-UI code
    auto* busAdapter    = new QtEventBusAdapter(bus);
    auto* workerAdapter = new QtWorkerAdapter(workerThread);

    // 5. Qt UI: create the main window
    MainWindow window;
    window.show();

    // 6. Wire UI signals → adapters → domain
    //    The window never touches domain objects directly
    QObject::connect(&window,       &MainWindow::startRequested,
                     workerAdapter, &QtWorkerAdapter::startWorker);

    QObject::connect(&window,       &MainWindow::stopRequested,
                     workerAdapter, &QtWorkerAdapter::stopWorker);

    // 7. Wire adapters → UI
    QObject::connect(busAdapter, &QtEventBusAdapter::sensorValueChanged,
                     &window,    &MainWindow::onSensorValue);

    QObject::connect(busAdapter, &QtEventBusAdapter::alarmChanged,
                     &window,    &MainWindow::onAlarmChanged);

    QObject::connect(busAdapter, &QtEventBusAdapter::categoryChanged,
                     &window,    &MainWindow::onCategoryChanged);

    QObject::connect(workerAdapter, &QtWorkerAdapter::workerStateChanged,
                     &window,       &MainWindow::onWorkerStateChanged);

    return app.exec();
}
