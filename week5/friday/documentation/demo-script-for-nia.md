# KijaniKiosk Board Demonstration Script for Nia

[The pipeline is open on screen. The blue version is currently serving normal traffic.]

**Nia:** Today I’ll demonstrate how KijaniKiosk can release a new version while keeping the service available. We’ll move traffic to the new version, deliberately introduce a failure, and let the system recover automatically.

[The pipeline deploys version 1.4.0 to the green environment.]

**Nia:** The new version has now been deployed alongside the existing version. The current service remains available while we verify the new version before sending traffic to it.

[Run the blue-to-green traffic switch. Show the successful health check returning version 1.4.0.]

**Nia:** The new version is healthy, so traffic is now being served by it. No interruption was required to make the change.

[Stop the green application service to simulate a critical application failure. Leave the monitoring process running.]

**Nia:** Now I’m introducing a failure in the new version. I am not manually switching the service back. The system will detect the problem and decide what to do.

[The monitor detects consecutive failures and triggers the automated rollback. Show the rollback completing with version 1.3.0 healthy.]

**Nia:** The system detected the problem and restored normal service in **73 seconds**, faster than a person could have responded.

[Show the final health check and blue environment state.]

**Nia:** The value is simple: we can release changes with less risk, detect serious problems quickly, and recover automatically without waiting for someone to notice and respond.
