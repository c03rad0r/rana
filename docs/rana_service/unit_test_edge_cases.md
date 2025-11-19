# Unit Testing Plan: Rana Service

This document outlines the unit tests for the `runner.sh` script.

## 1. Testing Framework

We will use `shellcheck` to perform static analysis on the `runner.sh` script to identify potential issues. For dynamic testing, we will use a testing framework like `shunit2` or `bats` to write and run unit tests.

## 2. Test Cases

| Test Case ID | Description | Mocked Commands | Expected Result |
| :--- | :--- | :--- | :--- |
| UT-01 | **Test `git clone`** | `git` | The `git clone` command is called with the correct URL and directory. |
| UT-02 | **Test `git pull`** | `git` | The `git pull` command is called when the directory exists. |
| UT-03 | **Test `cargo build`** | `cargo` | The `cargo build --release` command is called. |
| UT-04 | **Test `nice`** | `nice` | The `nice -n 19` command is called with the correct `rana` command. |

## 3. Mocking

We will create mock scripts for `git`, `cargo`, and `nice` to verify that they are being called with the correct arguments. These mock scripts will write their arguments to a temporary file, which will be asserted in the test cases.

### Example Mock `git` script:

```bash
#!/bin/bash
echo "$@" >> /tmp/git_calls.log
```

## 4. Test Implementation

The test script will:
1.  Set up the mock scripts and add them to the `PATH`.
2.  Source the `runner.sh` script.
3.  Run the functions to be tested.
4.  Assert the contents of the log files to verify the correct commands were called.