# KijaniKiosk Payments — SLI and SLO Specification

## Purpose

This document defines the proposed service level indicators (SLIs) and service level objectives (SLOs) for the `kk-payments` service. The targets are **proposed targets (not yet measured against production traffic)** because the current project uses a simulator rather than real customer payment traffic.

## 1. Availability

**SLI:** Successful availability of the payments service.

**Data source:** A hypothetical metrics system collecting successful and unsuccessful health-check requests, supplemented by the service health endpoint and reverse-proxy access logs.

**Calculation:** Availability percentage is calculated as the number of successful health checks divided by the total number of health checks, multiplied by 100.

**Measurement window:** Rolling 30-day window for the SLO. A short five-minute window is used for automated rollback decisions.

**Proposed SLO target:** **99.9% availability over 30 days**, proposed target (not yet measured against production traffic).

**Automated rollback threshold:** Roll back when availability falls below **99% during a five-minute window**.

**Relationship to SLO:** The short-window threshold is intentionally less demanding than the 99.9% 30-day objective. A brief degradation does not automatically imply that the long-term objective will be missed, but a sustained five-minute availability failure is serious enough to trigger an automated recovery.

## 2. Latency

**SLI:** Response latency for successful payments-service requests.

**Data source:** Nginx access logs or, in a production implementation, a hypothetical metrics system recording request duration at the proxy and application layers.

**Calculation:** The SLI uses the percentage of successful requests completed within the defined latency limit. The proposed measurement is the percentage of requests completing within **500 milliseconds**.

**Measurement window:** Rolling 30-day window for the SLO, with a five-minute short window used for automated rollback decisions.

**Proposed SLO target:** **99% of successful requests completing within 500 milliseconds over 30 days**, proposed target (not yet measured against production traffic).

**Automated rollback threshold:** Roll back when fewer than **95% of successful requests complete within 500 milliseconds during a five-minute window**.

**Relationship to SLO:** The short-window threshold is deliberately below the 99% long-term objective. This allows occasional latency spikes without immediately causing a rollback, while sustained degradation indicates that the newly deployed version may be unsafe to keep serving.

## 3. Payment Error Rate

**SLI:** Percentage of payment requests that result in an application or payment-processing error.

**Data source:** A hypothetical metrics system recording payment outcomes, with Nginx access logs and application logs used for investigation and validation.

**Calculation:** Payment error rate is the number of failed payment requests divided by the total number of payment requests, multiplied by 100. Expected client-side validation failures that are not service faults would be excluded from the numerator.

**Measurement window:** Rolling 30-day window for the SLO, with a five-minute short window used for automated rollback decisions.

**Proposed SLO target:** **99.5% of payment requests complete without a service-side error over 30 days**, equivalent to a maximum proposed service-side error rate of 0.5%. This is a proposed target (not yet measured against production traffic).

**Automated rollback threshold:** Roll back when the service-side payment error rate reaches **2% or higher during a five-minute window**, provided there are enough requests in the window for the result to be meaningful.

**Relationship to SLO:** The 2% short-window threshold is four times the maximum 0.5% error rate allowed by the 30-day SLO. This separation prevents a small number of isolated failures from triggering an unnecessary rollback while still reacting quickly to a significant payment failure spike.

## Rollback Threshold Summary

| SLI                | 30-day SLO target                         | Short-window rollback threshold  | Relationship                                                                                                           |
| ------------------ | ----------------------------------------- | -------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Availability       | ≥ 99.9%                                   | < 99% for 5 minutes              | Short-window threshold is below the long-term target to tolerate brief interruptions while catching sustained outages. |
| Latency            | ≥ 99% of successful requests under 500 ms | < 95% under 500 ms for 5 minutes | Short-window threshold allows temporary latency spikes but reacts to sustained degradation.                            |
| Payment error rate | ≤ 0.5% service-side errors                | ≥ 2% for 5 minutes               | Rollback threshold is four times the maximum error rate permitted by the SLO.                                          |

## What We Do Not Commit To

**Infrastructure utilization:** CPU, memory, disk, and network utilization are operational indicators, but they are not customer-facing commitments in this SLO specification. High resource usage may require investigation without automatically representing a breach of a payments-service SLO.

**Deployment frequency:** The number of deployments made during a month is not an SLO. Deployment frequency can be tracked as an engineering performance metric, but it does not define whether the payments service is delivering reliable service to customers.
