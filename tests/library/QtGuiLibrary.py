"""
Robot Framework keyword library for the Qt5DecoupledDemo application.
Uses AT-SPI2 (pyatspi) for widget discovery and interaction.

System prerequisites (apt):
    xvfb at-spi2-core at-spi2-common python3-pyatspi python3-dbus python3-gi dbus-x11

The test runner must be wrapped with dbus-run-session so AT-SPI has a session bus.
"""

import os
import re
import subprocess
import time

import pyatspi
from robot.api import logger
from robot.api.deco import keyword

ROBOT_LIBRARY_SCOPE = "SUITE"


class QtGuiLibrary:

    def __init__(self):
        self._proc = None
        self._app_acc = None
        self._xvfb_proc = None

    # ── Application lifecycle ─────────────────────────────────────────────────

    @keyword("Start Application")
    def start_application(self, binary_path, display=":99", timeout=10,
                          extra_env=None):
        """Launch the Qt5 binary and wait for it to appear in the AT-SPI tree."""
        env = os.environ.copy()
        env["DISPLAY"] = display
        env["QT_ACCESSIBILITY"] = "1"
        env["QT_LINUX_ACCESSIBILITY_ALWAYS_ON"] = "1"
        env["QT_QPA_PLATFORM"] = "xcb"
        if extra_env:
            env.update(extra_env)

        self._proc = subprocess.Popen(
            [binary_path],
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self._app_acc = self._wait_for_app("Qt5 Decoupled Architecture Demo",
                                           float(timeout))
        if self._app_acc is None:
            self._proc.kill()
            raise RuntimeError(
                f"Application did not register in AT-SPI tree within {timeout}s"
            )
        logger.info(f"Application registered in AT-SPI: {self._app_acc.get_name()}")

    @keyword("Stop Application")
    def stop_application(self):
        """Terminate the application process."""
        if self._proc:
            self._proc.terminate()
            try:
                self._proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self._proc.kill()
            self._proc = None
        self._app_acc = None

    @keyword("Start Xvfb")
    def start_xvfb(self, display=":99", screen="1024x768x24"):
        """Launch a virtual framebuffer on the given display number."""
        self._xvfb_proc = subprocess.Popen(
            ["Xvfb", display, "-screen", "0", screen, "-ac",
             "+extension", "RANDR"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        time.sleep(1)
        logger.info(f"Xvfb started on {display}")

    @keyword("Stop Xvfb")
    def stop_xvfb(self):
        """Terminate the Xvfb process."""
        if self._xvfb_proc:
            self._xvfb_proc.terminate()
            try:
                self._xvfb_proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self._xvfb_proc.kill()
            self._xvfb_proc = None

    # ── Widget location ───────────────────────────────────────────────────────

    @keyword("Find Widget By Name")
    def find_widget_by_name(self, name, role=None, timeout=5):
        """
        Return the Atspi.Accessible whose accessible name equals `name`.
        Polls for up to `timeout` seconds. Raises AssertionError if not found.
        """
        deadline = time.monotonic() + float(timeout)
        while time.monotonic() < deadline:
            result = self._dfs(self._app_acc, name, role)
            if result is not None:
                return result
            time.sleep(0.1)
        raise AssertionError(
            f"Widget with accessible name '{name}' not found within {timeout}s"
        )

    def _dfs(self, node, name, role=None):
        if node is None:
            return None
        try:
            if node.get_name() == name:
                if role is None or node.getRole() == role:
                    return node
            for child in node:
                found = self._dfs(child, name, role)
                if found is not None:
                    return found
        except Exception:
            pass
        return None

    def _wait_for_app(self, window_title, timeout):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            try:
                desktop = pyatspi.Registry.getDesktop(0)
                for app in desktop:
                    if app is None:
                        continue
                    try:
                        for child in app:
                            if child and window_title in (child.get_name() or ""):
                                return app
                    except Exception:
                        pass
            except Exception:
                pass
            time.sleep(0.3)
        return None

    # ── Button interaction ────────────────────────────────────────────────────

    @keyword("Click Button")
    def click_button(self, accessible_name):
        """Find a push-button by accessible name and invoke its click action."""
        btn = self.find_widget_by_name(accessible_name,
                                       role=pyatspi.ROLE_PUSH_BUTTON)
        action_iface = btn.queryAction()
        for i in range(action_iface.nActions):
            if action_iface.getName(i).lower() in ("click", "press"):
                action_iface.doAction(i)
                return
        action_iface.doAction(0)

    @keyword("Button Should Be Enabled")
    def button_should_be_enabled(self, accessible_name):
        btn = self.find_widget_by_name(accessible_name,
                                       role=pyatspi.ROLE_PUSH_BUTTON)
        if not btn.getState().contains(pyatspi.STATE_ENABLED):
            raise AssertionError(f"Button '{accessible_name}' is not enabled")

    @keyword("Button Should Be Disabled")
    def button_should_be_disabled(self, accessible_name):
        btn = self.find_widget_by_name(accessible_name,
                                       role=pyatspi.ROLE_PUSH_BUTTON)
        if btn.getState().contains(pyatspi.STATE_ENABLED):
            raise AssertionError(
                f"Button '{accessible_name}' is enabled (expected disabled)"
            )

    # ── Label / text reading ──────────────────────────────────────────────────

    @keyword("Get Label Text")
    def get_label_text(self, accessible_name):
        """Return the visible text of a label widget."""
        widget = self.find_widget_by_name(accessible_name)
        try:
            return widget.queryText().getText(0, -1)
        except Exception:
            return widget.get_name()

    @keyword("Label Text Should Be")
    def label_text_should_be(self, accessible_name, expected_text):
        actual = self.get_label_text(accessible_name)
        if actual != expected_text:
            raise AssertionError(
                f"Label '{accessible_name}': expected '{expected_text}', "
                f"got '{actual}'"
            )

    @keyword("Label Text Should Match Regexp")
    def label_text_should_match_regexp(self, accessible_name, pattern):
        actual = self.get_label_text(accessible_name)
        if not re.fullmatch(pattern, actual):
            raise AssertionError(
                f"Label '{accessible_name}': '{actual}' does not match "
                f"pattern '{pattern}'"
            )

    # ── Progress bar ──────────────────────────────────────────────────────────

    @keyword("Get Progress Bar Value")
    def get_progress_bar_value(self, accessible_name):
        """Return the integer current value of a QProgressBar."""
        widget = self.find_widget_by_name(accessible_name)
        return int(widget.queryValue().currentValue)

    @keyword("Progress Bar Value Should Be Between")
    def progress_bar_value_should_be_between(self, accessible_name, low, high):
        val = self.get_progress_bar_value(accessible_name)
        low, high = int(low), int(high)
        if not (low <= val <= high):
            raise AssertionError(
                f"Progress bar '{accessible_name}': value {val} not in "
                f"[{low}, {high}]"
            )

    # ── Event log (QListWidget) ───────────────────────────────────────────────

    @keyword("Get Log Entry Count")
    def get_log_entry_count(self, accessible_name="event log"):
        """Return the number of items in the QListWidget."""
        widget = self.find_widget_by_name(accessible_name)
        return widget.childCount

    @keyword("Log Should Contain Entry Matching")
    def log_should_contain_entry_matching(self, pattern,
                                          accessible_name="event log"):
        """Assert that at least one log item matches the given regex pattern."""
        widget = self.find_widget_by_name(accessible_name)
        for i in range(widget.childCount):
            item = widget.getChildAtIndex(i)
            text = item.get_name() if item else ""
            if re.search(pattern, text):
                return text
        raise AssertionError(
            f"No log entry matching '{pattern}' found in '{accessible_name}'"
        )

    # ── Wait helpers ──────────────────────────────────────────────────────────

    @keyword("Wait For Label Text")
    def wait_for_label_text(self, accessible_name, expected_text,
                             timeout=10, poll_interval=0.1):
        """Poll until the label shows exactly expected_text or timeout expires."""
        deadline = time.monotonic() + float(timeout)
        while time.monotonic() < deadline:
            try:
                if self.get_label_text(accessible_name) == expected_text:
                    return
            except Exception:
                pass
            time.sleep(float(poll_interval))
        actual = self.get_label_text(accessible_name)
        raise AssertionError(
            f"Label '{accessible_name}' never showed '{expected_text}' "
            f"within {timeout}s; last value: '{actual}'"
        )

    @keyword("Wait For Label Text Matching")
    def wait_for_label_text_matching(self, accessible_name, pattern,
                                      timeout=10, poll_interval=0.1):
        """Poll until the label text matches the regex pattern."""
        deadline = time.monotonic() + float(timeout)
        while time.monotonic() < deadline:
            try:
                actual = self.get_label_text(accessible_name)
                if re.fullmatch(pattern, actual):
                    return actual
            except Exception:
                pass
            time.sleep(float(poll_interval))
        raise AssertionError(
            f"Label '{accessible_name}' never matched '{pattern}' "
            f"within {timeout}s"
        )

    @keyword("Wait For Alarm State")
    def wait_for_alarm_state(self, expected_text, timeout=15,
                              poll_interval=0.1):
        """Wait until the alarm status label shows expected_text (ALARM or OK)."""
        self.wait_for_label_text("alarm status", expected_text,
                                 timeout=float(timeout),
                                 poll_interval=float(poll_interval))

    @keyword("Wait For Category")
    def wait_for_category(self, expected_category, timeout=15,
                           poll_interval=0.1):
        """Wait until the category label shows HIGH, NORMAL, or LOW."""
        self.wait_for_label_text("category", expected_category,
                                 timeout=float(timeout),
                                 poll_interval=float(poll_interval))

    @keyword("Sleep")
    def sleep(self, seconds):
        time.sleep(float(seconds))
