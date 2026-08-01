# Post-Incident Review: Investor Demonstration Environment Mix-Up

## Section 1: Incident Summary

During an investor demonstration, a deployment pipeline ran against the wrong environment and temporarily made the staging service unavailable for 48 seconds. The demonstration was affected because the deployment process did not sufficiently prevent a staging target from being selected when the intended target was different.

## Section 2: Timeline

The following timeline is reconstructed from the known incident duration and sequence rather than from preserved event logs.

| Time               | Event                                                                                                                            |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| T+00:00            | The deployment pipeline was started for the investor demonstration.                                                              |
| T+00:10            | The pipeline selected the wrong environment because the target was not sufficiently constrained by the deployment configuration. |
| T+00:15            | Deployment activity began against staging instead of the intended environment.                                                   |
| T+00:20            | The staging service became unavailable during the deployment.                                                                    |
| T+00:20 to T+01:08 | Staging remained unavailable while the environment mismatch was identified and the deployment was corrected.                     |
| T+01:08            | Staging service availability was restored.                                                                                       |
| T+01:10            | The team confirmed that service had recovered and the demonstration could continue.                                              |

**Total observed unavailability: 48 seconds.**

## Section 3: Root Cause

The immediate cause was a configuration gap that allowed the pipeline to target the wrong environment. The deeper cause was not simply human error; the deployment process lacked sufficient structural safeguards to prevent an incorrect target from being accepted.

### Five Whys

**Why did staging become unavailable during the demonstration?**
Because the deployment pipeline ran deployment actions against staging when the intended deployment target was different.

**Why could the pipeline run against staging?**
Because the target environment was selectable through configuration without a sufficiently strong validation step tying the pipeline run to the intended environment.

**Why was there no strong validation step?**
Because environment selection and deployment authorization were treated as configuration values rather than as a controlled deployment decision that required explicit validation.

**Why was environment selection treated as ordinary configuration?**
Because the pipeline design assumed that the configured target would be correct and did not enforce a separation between deployment configuration and the environment being deployed.

**Why was that assumption present in the design?**
Because the pipeline had been designed around successful execution rather than around preventing a dangerous target selection. The structural gap was therefore the absence of an environment-target guard that validates the requested deployment environment before any deployment-changing action is performed.

### Root-cause finding

The structural root cause was **missing environment-target validation and enforcement in the deployment pipeline**. A deployment should not be able to proceed solely because a target value is present; the pipeline must verify that the requested environment is explicitly authorized for that run before changing it.

## Section 4: Contributing Factors

Several conditions made the configuration gap capable of causing an incident:

* The deployment pipeline had the ability to operate against multiple environments.
* Environment selection was not sufficiently separated from ordinary pipeline configuration.
* There was no mandatory pre-deployment check that stopped the pipeline when its target did not match the intended environment.
* The process relied on the deployment configuration being correct rather than enforcing the correct target structurally.
* The incident occurred during a live investor demonstration, increasing the impact of even a short service interruption.
* The absence of an automated environment guard meant the mistake could reach the deployment stage before being detected.

## Section 5: What Went Well

The service was restored after **48 seconds**, limiting the impact of the incident. The problem was also identifiable and recoverable without requiring a prolonged outage, allowing the investor demonstration to continue.

## Section 6: Action Items

| Owner role       | Action                                                                                                                                                                                                          | Target timeframe                       |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| DevOps Engineer  | Add a mandatory environment-target validation stage that compares the requested deployment target with an explicitly supplied deployment context and fails the pipeline before deployment if they do not match. | Within 3 working days                  |
| CI/CD Maintainer | Separate environment-specific configuration from the general pipeline configuration and require an explicit, reviewed deployment target for every environment-changing run.                                     | Within 1 week                          |
| DevOps Engineer  | Add an automated pipeline test that intentionally supplies a mismatched environment target and verifies that no deployment action is executed.                                                                  | Within 1 week                          |
| Release Manager  | Add a pre-demonstration deployment checklist requiring verification of the target environment and a successful dry-run before investor-facing demonstrations.                                                   | Before the next investor demonstration |
