# Capstone Scope Document

## Problem Statement

KijaniKiosk's receipt-processing workflow does not yet have an independently scalable, cloud-deployed event-driven pipeline. The existing `kk-payments` service runs as a fixed set of Kubernetes replicas, while receipt processing is not yet separated into an independently deployable serverless workflow. This limits the system's ability to handle variable receipt-processing workloads efficiently and prevents receipt events from being extended into analytics independently of the payment service. The capstone will extend the existing Kubernetes payment deployment with an AWS S3-backed serverless receipt-processing chain and add `kk-analytics` to create a production-approaching, event-driven workflow.

## Track

**Track B — Serverless-first**

## What I Will Build

* **Component 1: Serverless receipt chain** — Deploy the receipt-processing functions `kk-receipts`,`kk-processor`, and `kk-notifier` as an event-driven AWS serverless chain, with kk-analytics extending the chain as the fourth function.
* **Component 2: Analytics function** — Add `kk-analytics`, triggered by `kk-notifier`'s output bucket, to aggregate receipt count, total amount, and timestamp range and log the results as a structured summary.
* **Component 3: Kubernetes–S3 integration** — Extend the Week 9 `kk-payments` Kubernetes deployment with the S3 receipt bucket configuration so receipt events are written to the production S3 bucket that triggers the serverless chain.
* **Component 4: Serverless CI/CD pipeline** — Update Jenkins to deploy the serverless stack to staging automatically, require an approval gate, and then deploy the serverless stack to production.
* **Component 5: Production governance** — Apply all six required governance controls to the actual deployed serverless configuration and document findings and remediations.

## What Is Out of Scope

* **Kubernetes HPA and capacity redesign** — The capstone will not redesign `kk-payments` autoscaling or implement a new Kubernetes capacity-management strategy; the focus is the serverless receipt-processing architecture.
* **Kubernetes Ingress security redesign** — TLS termination, authentication/authorization, rate limiting, and other Ingress security improvements identified in the Week 9 production-readiness assessment are outside the Serverless-first track.

## Success Criteria

1. The four-function serverless stack deploys successfully to AWS staging and production, with `serverless info` confirming the deployed resources.
2. A receipt event written by `kk-payments` to the production S3 receipt bucket triggers the serverless chain and results in `kk-analytics` logging a structured summary containing receipt count, total amount, and timestamp range.
3. The Jenkins pipeline demonstrates a serverless deployment to staging followed by a visible approval gate before the production deployment.

## Architecture Diagram

The architecture diagram will be provided as a PNG and will show every capstone component and the labelled flow between the Kubernetes payment service, S3 buckets, serverless functions, Jenkins pipeline, staging environment, and production environment.
