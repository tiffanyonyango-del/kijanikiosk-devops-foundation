# Fault Injection Log

## Purpose

This document records controlled failures introduced into the Jenkins pipeline to verify that each stage correctly stops the pipeline when an error is detected. After each fault was observed, the change was reverted and the pipeline was rerun successfully.

| Stage | Fault Introduced | Downstream Behaviour | Why This Is Correct | Resolution |
|-------|------------------|----------------------|---------------------|------------|
| Lint | Introduced invalid JavaScript syntax into a source file. | Build, Verify, Archive and Publish were skipped. | Invalid source code should never continue to later stages because subsequent results would not be reliable. | Restored the valid source code. |
| Build | Temporarily removed the build script. | Verify, Archive and Publish were skipped. | If the application cannot be built, there is nothing valid to test or package. | Restored the build script. |
| Test | Modified a unit test so it intentionally failed. | Archive and Publish were skipped. | A failing test indicates the application no longer behaves as expected, so packaging must stop. | Restored the correct test. |
| Security Audit | Added a dependency or configuration that caused the audit stage to fail. | Archive and Publish were skipped. | Software with known security issues should not proceed to packaging or release. | Removed the vulnerable dependency or restored the secure configuration. |
| Publish | *(To be completed after Nexus publishing is working.)* | *(Pending.)* | Publishing should only occur after every previous stage has passed successfully. | *(Pending.)* |

## Summary

The pipeline behaved as expected during each controlled failure. Each stage stopped the pipeline at the earliest possible point, preventing invalid software from progressing to later stages. After correcting each fault, the pipeline successfully completed again, demonstrating that the delivery process is both reliable and repeatable.