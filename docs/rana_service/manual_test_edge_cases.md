# Manual Testing Plan: Rana Service

This document outlines the manual tests to be performed to ensure the Rana Service is functioning correctly.

## 1. Test Cases

| Test Case ID | Description | Expected Result |
| :--- | :--- | :--- |
| TC-01 | **Verify Service Installation** | The `rana.service` is successfully installed and enabled. |
| TC-02 | **Verify Service Start** | The `rana.service` starts without errors. |
| TC-03 | **Verify Rana Process** | The `rana` mining process is running with a `nice` value of 19. |
| TC-04 | **Verify Repo Cloning** | The `rana` repository is cloned into the user's home directory. |
| TC-05 | **Verify Repo Update** | The `rana` repository is updated on service restart. |
| TC-06 | **Verify Service Restart** | The `rana.service` restarts automatically after a failure. |

## 2. Test Steps

### TC-01: Verify Service Installation
1.  Copy the `rana.service` file to `/etc/systemd/system/`.
2.  Run `sudo systemctl daemon-reload`.
3.  Run `sudo systemctl enable rana.service`.
4.  Check the output for any errors.

### TC-02: Verify Service Start
1.  Run `sudo systemctl start rana.service`.
2.  Run `sudo systemctl status rana.service`.
3.  Verify that the service is `active (running)`.

### TC-03: Verify Rana Process
1.  Run `ps aux | grep rana`.
2.  Verify that a `rana` process is running.
3.  Run `ps -o ni,cmd -p $(pgrep rana)`.
4.  Verify that the `NI` (nice) value is `19`.

### TC-04: Verify Repo Cloning
1.  Ensure the `~/rana` directory does not exist.
2.  Start the `rana.service`.
3.  Verify that the `~/rana` directory has been created.

### TC-05: Verify Repo Update
1.  Stop the `rana.service`.
2.  Make a change to the local `~/rana` repository (e.g., delete a file).
3.  Start the `rana.service`.
4.  Verify that the change has been reverted (the deleted file is restored).

### TC-06: Verify Service Restart
1.  Find the process ID (PID) of the `rana` miner.
2.  Kill the `rana` process using `kill -9 <PID>`.
3.  Run `sudo systemctl status rana.service`.
4.  Verify that the service has restarted and a new `rana` process is running.