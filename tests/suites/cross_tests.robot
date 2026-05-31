*** Settings ***
Documentation    Cross-build ARM64 GUI tests for Qt5DecoupledDemo.
...
...              The ARM64 binary runs on a Raspberry Pi. Tests control it
...              via SSH + X11 forwarding to a local Xvfb display, with
...              pyatspi attached on the host side.
...
...              Prerequisites (host):
...                xvfb at-spi2-core python3-pyatspi python3-dbus dbus-x11
...                pip3 install robotframework robotframework-sshlibrary
...              Prerequisites (Pi):
...                at-spi2-core (installed automatically by deploy_pi.sh)
...                SSH key auth configured (or pass PI_PASSWORD variable)
...
...              Run via Makefile:
...                make test-cross PI_HOST=192.168.1.55   (from qtadapter/)
...
...              Or after deploy:
...                dbus-run-session -- python3 -m robot
...                    --variablefile ../variables/cross_vars.py
...                    --variable PI_HOST:192.168.1.55
...                    suites/cross_tests.robot

Variables        ../variables/cross_vars.py
Resource         ../resources/qt_keywords.resource

Suite Setup      Launch Remote App Via SSH
Suite Teardown   Teardown App

Test Timeout     90 seconds


*** Variables ***
${PI_PASSWORD}    ${EMPTY}    # Pass via --variable PI_PASSWORD:xxx or use SSH keys


*** Test Cases ***

TC-X-01: Application Starts With Correct Initial State On Pi
    [Documentation]    Same initial-state assertions as TC-N-01, running the
    ...                ARM64 binary on the Raspberry Pi.
    [Tags]    smoke    initial-state    cross
    Verify Initial State

TC-X-02: Start Button Click Activates Worker On Pi
    [Documentation]    Click 'Start worker' on the Pi build. Verify button
    ...                state and status label update within 5s (network latency).
    [Tags]    smoke    worker-lifecycle    cross
    Click Button                 Start worker
    Wait For Label Text          worker status    Worker running    timeout=5
    Button Should Be Disabled    Start worker
    Button Should Be Enabled     Stop worker

TC-X-03: Sensor Values Update On Pi
    [Documentation]    Sensor label must leave '--' and show NN.NN format
    ...                within 3s on the Pi (slower CPU/bus than x86_64).
    [Tags]    sensor    live-data    cross
    Wait For Label Text Matching    sensor value    \d{1,2}\.\d{2}    timeout=3
    Value Bar Should Show Active Reading

TC-X-04: Alarm State Reached On Pi
    [Documentation]    First HIGH alarm at ~500ms on native; allow 15s for Pi.
    ...                Alarm must also clear within 8s.
    [Tags]    alarm    cross
    Wait For Alarm State    ALARM    timeout=15
    Wait For Alarm State    OK       timeout=8

TC-X-05: All Categories Seen On Pi
    [Documentation]    HIGH, NORMAL, LOW categories must each appear.
    ...                Timeouts increased for Pi scheduling jitter.
    [Tags]    sensor    category    cross
    Wait For Category    HIGH      timeout=8
    Wait For Category    NORMAL    timeout=8
    Wait For Category    LOW       timeout=12

TC-X-06: Stop Button Halts Worker On Pi
    [Documentation]    Click 'Stop worker' on the Pi build. Verify state reverts.
    [Tags]    smoke    worker-lifecycle    cross
    Stop Worker And Verify Stopped

TC-X-07: Event Log Populated On Pi
    [Documentation]    Full log lifecycle: start → check entries → stop.
    [Tags]    log    cross
    Start Worker And Verify Running
    Log Should Record Worker Started
    Log Should Have Sensor Entries
    Stop Worker And Verify Stopped
    Log Should Record Worker Stopped
