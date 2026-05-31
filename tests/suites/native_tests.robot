*** Settings ***
Documentation    Native x86_64 GUI tests for Qt5DecoupledDemo.
...
...              Tests run the binary directly on the host under Xvfb and
...              interact with it via AT-SPI2 (pyatspi). Tests share a single
...              application instance across the suite (stateful by design).
...
...              Prerequisites:
...                sudo apt-get install xvfb at-spi2-core at-spi2-common
...                                    python3-pyatspi python3-dbus dbus-x11
...                pip3 install robotframework robotframework-pythonlibcore
...
...              Run via Makefile:
...                make test-native          (from qtadapter/)
...
...              Or directly (must be inside dbus-run-session):
...                dbus-run-session -- python3 -m robot
...                    --variablefile ../variables/native_vars.py
...                    suites/native_tests.robot

Variables        ../variables/native_vars.py
Resource         ../resources/qt_keywords.resource

Suite Setup      Launch Native App
Suite Teardown   Teardown App

Test Timeout     60 seconds


*** Test Cases ***

TC-N-01: Application Starts With Correct Initial State
    [Documentation]    Every widget shows its startup default before the
    ...                worker is started.
    [Tags]    smoke    initial-state
    Verify Initial State

TC-N-02: Start Button Click Activates Worker
    [Documentation]    Click 'Start worker'. Verify button states flip and
    ...                status label changes to 'Worker running'.
    [Tags]    smoke    worker-lifecycle
    Click Button                 Start worker
    Wait For Label Text          worker status    Worker running    timeout=3
    Button Should Be Disabled    Start worker
    Button Should Be Enabled     Stop worker

TC-N-03: Sensor Values Update After Worker Starts
    [Documentation]    Within 2s of start the value label must leave '--' and
    ...                display a floating-point number in NN.NN format.
    [Tags]    sensor    live-data
    Wait For Sensor Value To Update
    Label Text Should Match Regexp    sensor value    \d{1,2}\.\d{2}
    Value Bar Should Show Active Reading

TC-N-04: Category Transitions Through HIGH NORMAL LOW
    [Documentation]    The sine wave (period ~4.19s) visits HIGH at ~500ms,
    ...                LOW at ~2600ms. Verify all three categories appear.
    [Tags]    sensor    category
    Wait For Category    HIGH      timeout=5
    Wait For Category    NORMAL    timeout=5
    Wait For Category    LOW       timeout=8

TC-N-05: Alarm Triggers And Clears
    [Documentation]    Alarm activates when value > 80 (HIGH) or < 20 (LOW).
    ...                First HIGH alarm at ~500ms; clears at ~1700ms.
    [Tags]    alarm
    Wait For Alarm
    Wait For Alarm Clear

TC-N-06: Event Log Records Worker Start Entry
    [Documentation]    The event log must contain '--- Worker STARTED ---'
    ...                after the worker has been started.
    [Tags]    log
    Log Should Record Worker Started

TC-N-07: Event Log Accumulates Sensor Entries
    [Documentation]    Every 5th sensor update is logged (10Hz / 5 = 1/500ms).
    ...                After 3 seconds of running, expect at least 5 entries.
    [Tags]    log    timing
    Log Should Have Sensor Entries

TC-N-08: Stop Button Halts Worker
    [Documentation]    Click 'Stop worker'. Verify button states revert and
    ...                status label changes to 'Worker stopped'.
    [Tags]    smoke    worker-lifecycle
    Stop Worker And Verify Stopped

TC-N-09: Event Log Records Worker Stop Entry
    [Documentation]    After stopping the worker the log must contain
    ...                '--- Worker STOPPED ---'.
    [Tags]    log
    Log Should Record Worker Stopped

TC-N-10: Restart Worker Produces Fresh Sensor Data
    [Documentation]    Start → Stop → Start again. After the second start,
    ...                sensor value and progress bar must update.
    [Tags]    worker-lifecycle    regression
    Start Worker And Verify Running
    Stop Worker And Verify Stopped
    Start Worker And Verify Running
    Wait For Sensor Value To Update
    Value Bar Should Show Active Reading

TC-N-11: Stop Button Disabled After Final Stop
    [Documentation]    After the last stop in TC-N-10, the Stop button must
    ...                be disabled and the Start button enabled.
    [Tags]    smoke    worker-lifecycle
    Stop Worker And Verify Stopped
    Button Should Be Disabled    Stop worker
    Button Should Be Enabled     Start worker
