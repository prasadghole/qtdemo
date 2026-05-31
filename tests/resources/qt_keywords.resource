*** Settings ***
Library    ../library/QtGuiLibrary.py
Library    SSHLibrary


*** Keywords ***

# ── Application lifecycle ─────────────────────────────────────────────────────

Launch Native App
    [Documentation]    Start Xvfb then launch the native binary.
    Start Xvfb         display=${DISPLAY}
    Start Application  binary_path=${BINARY_PATH}    display=${DISPLAY}

Launch Remote App Via SSH
    [Documentation]    SSH to the Pi, launch the ARM64 binary with X11
    ...                forwarded back to a local Xvfb display, then attach
    ...                pyatspi on the host side.
    Start Xvfb         display=${DISPLAY}
    Open Connection    ${PI_HOST}    alias=pi
    Login              ${PI_USER}    ${PI_PASSWORD}
    Write              DISPLAY=${DISPLAY} QT_ACCESSIBILITY=1 QT_LINUX_ACCESSIBILITY_ALWAYS_ON=1 ${PI_BINARY} &
    Sleep              2s
    Start Application  binary_path=${PI_BINARY}    display=${DISPLAY}

Teardown App
    Stop Application
    Stop Xvfb
    Run Keyword If    "${PI_HOST}" != ""    Close All Connections


# ── Initial state ─────────────────────────────────────────────────────────────

Verify Initial State
    [Documentation]    Assert every widget is at its startup default before
    ...                the worker has been started.
    Button Should Be Enabled     Start worker
    Button Should Be Disabled    Stop worker
    Label Text Should Be         sensor value     --
    Label Text Should Be         category         --
    Label Text Should Be         alarm status     OK
    Label Text Should Be         worker status    Worker stopped
    ${val}=    Get Progress Bar Value    value bar
    Should Be Equal As Integers    ${val}    0


# ── Worker lifecycle ──────────────────────────────────────────────────────────

Start Worker And Verify Running
    Click Button                 Start worker
    Wait For Label Text          worker status    Worker running    timeout=3
    Button Should Be Disabled    Start worker
    Button Should Be Enabled     Stop worker

Stop Worker And Verify Stopped
    Click Button                 Stop worker
    Wait For Label Text          worker status    Worker stopped    timeout=3
    Button Should Be Enabled     Start worker
    Button Should Be Disabled    Stop worker


# ── Sensor data ───────────────────────────────────────────────────────────────

Wait For Sensor Value To Update
    [Documentation]    After start, the value label leaves '--' within ~200ms.
    Wait For Label Text Matching    sensor value    \\d+\\.\\d{2}    timeout=2

Value Bar Should Show Active Reading
    ${val}=    Get Progress Bar Value    value bar
    Should Be True    ${val} > 4    msg=Progress bar shows ${val}, expected > 4
    Should Be True    ${val} < 96   msg=Progress bar shows ${val}, expected < 96


# ── Alarm ─────────────────────────────────────────────────────────────────────

Wait For Alarm
    [Documentation]    Sine wave hits HIGH alarm (~value > 80) at ~500ms.
    ...                Use 10s to tolerate loaded CI machines.
    Wait For Alarm State    ALARM    timeout=10

Wait For Alarm Clear
    [Documentation]    Alarm clears when value returns to NORMAL range.
    Wait For Alarm State    OK    timeout=5


# ── Event log ─────────────────────────────────────────────────────────────────

Log Should Record Worker Started
    Log Should Contain Entry Matching    --- Worker STARTED ---

Log Should Record Worker Stopped
    Log Should Contain Entry Matching    --- Worker STOPPED ---

Log Should Have Sensor Entries
    [Documentation]    At 10Hz with every-5th-event logging → 1 entry/500ms.
    ...                After sleeping 3s expect at least 5 entries total.
    Sleep    3
    ${count}=    Get Log Entry Count
    Should Be True    ${count} >= 5    msg=Expected ≥5 log entries, got ${count}
