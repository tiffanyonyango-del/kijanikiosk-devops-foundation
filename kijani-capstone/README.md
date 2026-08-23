KijaniKiosk Capstone

Serverless-First Receipt Processing Pipeline

KijaniKiosk's capstone extends the existing Kubernetes-based payment service with an independently deployable, event-driven serverless receipt-processing workflow.

The capstone follows Track B — Serverless-first and introduces an AWS S3-backed chain of four Lambda functions, with kk-analytics extending the workflow to produce structured receipt analytics.

1. Problem Statement

The existing kk-payments service runs as a fixed Kubernetes deployment, while receipt processing is not yet separated into an independently scalable serverless workflow.

This capstone addresses that limitation by:

separating receipt processing into serverless functions;

using Amazon S3 as the event-driven integration layer;

allowing receipt-processing workloads to scale independently of the payment service;

extending receipt events into analytics; and

introducing a Jenkins CI/CD pipeline with a staging deployment and explicit production approval gate.

2. Capstone Scope

Track

Track B — Serverless-first

Components

Serverless receipt chain

kk-receipts

kk-processor

kk-notifier

kk-analytics

Analytics function

Aggregates receipt count.

Calculates total receipt amount.

Determines earliest and latest receipt timestamps.

Logs a structured analytics summary.

Kubernetes–S3 integration

The existing kk-payments deployment is extended so receipt events can be written to the production receipt S3 bucket.

Serverless CI/CD

Jenkins deploys the serverless stack to staging.

A visible approval gate is required before production deployment.

Production deployment occurs only after approval.

Production governance

Required governance controls are applied to the deployed serverless configuration.

Findings and remediations are documented.

3. Architecture

The intended receipt flow is:

kk-payments (Kubernetes)
        |
        v
Production Receipts S3 Bucket
        |
        v
kk-receipts
processReceiptUpload
        |
        v
Processed S3 Bucket
        |
        v
kk-processor
processReceipt
        |
        v
Notifications S3 Bucket
        |
        v
kk-notifier
notifyReceipt
        |
        v
Analytics S3 Bucket
        |
        v
kk-analytics
analyzeReceipts
        |
        v
Structured Analytics Summary

The HTTP generateReceipt function is also provided by kk-receipts for receipt-generation/testing purposes.

CI/CD flow

Git Repository
      |
      v
Jenkins
      |
      v
Validation / Tests
      |
      v
Serverless Deploy — Staging
      |
      v
Manual Approval Gate
      |
      v
Serverless Deploy — Production

4. Functions

generateReceipt

Handler: handlers/receipts.generateReceipt

HTTP endpoint:

POST /dev/receipts

Responsibilities:

validates that orderId is present;

creates a receipt object;

assigns the default currency (KES);

generates a timestamp;

generates a unique receipt ID;

returns the receipt as JSON.

Example response:

{
  "orderId": "ORD-003",
  "amount": 1500,
  "currency": "KES",
  "timestamp": "2026-08-23T02:25:12.465Z",
  "receiptId": "receipt-ORD-003-1787451912465"
}

processReceiptUpload

Handler: handlers/receipts.processReceiptUpload

Triggered by:

S3 ObjectCreated event

on the receipts bucket.

Responsibilities:

reads the uploaded receipt object;

validates the S3 bucket/key information;

copies the receipt to the processed bucket;

preserves the source object key;

logs a structured receipt.uploaded event.

processReceipt

Handler: handlers/processor.processReceipt

Triggered when a receipt is created in the processed bucket.

Responsibilities:

reads the receipt;

adds processedAt;

writes the processed receipt to the notifications bucket;

logs a structured receipt.processed event.

notifyReceipt

Handler: handlers/notifier.notifyReceipt

Triggered when an object is created in the notifications bucket.

Responsibilities:

reads the processed receipt;

writes it to the analytics bucket;

logs a structured receipt.notified event.

analyzeReceipts

Handler: handlers/analytics.analyzeReceipts

Triggered when an object is created in the analytics bucket.

Responsibilities:

reads receipt objects from the S3 event;

counts receipts;

calculates total amount;

determines the earliest timestamp;

determines the latest timestamp;

logs a structured receipt.analytics.summary event.

Example summary fields:

{
  "receiptCount": 1,
  "totalAmount": 1500,
  "currency": "KES",
  "earliestTimestamp": "2026-08-23T02:25:12.465Z",
  "latestTimestamp": "2026-08-23T02:25:12.465Z",
  "analyzedAt": "..."
}

5. S3 Buckets

The current Serverless configuration resolves the development-stage buckets to:

kijani-payments-receipts-dev
kijani-payments-processed-dev
kijani-payments-notifications-dev
kijani-payments-analytics-dev

The stage is configurable through Serverless:

stage: ${opt:stage, 'dev'}

Therefore the bucket names change according to the deployment stage.

6. Serverless Configuration

The service is defined as:

service: kijani-capstone

Provider configuration:

provider:
  name: aws
  runtime: nodejs20.x
  stage: ${opt:stage, 'dev'}
  region: ${opt:region, 'af-south-1'}

The functions are wired to the S3 buckets using ObjectCreated:* events.

The configuration also includes:

serverless-offline

serverless-s3-local

for local development and testing.

7. Environment Variables

The serverless configuration supplies:

DEFAULT_CURRENCY
PROCESSED_BUCKET
NOTIFICATIONS_BUCKET
ANALYTICS_BUCKET

The local S3 simulator uses:

Endpoint: http://localhost:4569
Access key: S3RVER
Secret key: S3RVER

These local S3 credentials are for the local simulator only and must not be reused as production AWS credentials.

8. Local Development

Prerequisites

Node.js

npm

AWS CLI

Serverless Framework

Access to the project repository

The configured Lambda runtime is Node.js 20.x.

The current local development machine was observed running Node.js 18.19.1. Serverless emitted an AWS SDK support warning during local commands. This does not change the configured Lambda runtime, but the local Node.js version should be aligned with the project/tooling requirements for reproducible CI execution.

Install dependencies

npm install

Syntax validation

The current npm test command performs JavaScript syntax checks:

npm test

It currently executes:

node --check handlers/receipts.js
node --check handlers/processor.js
node --check handlers/notifier.js
node --check handlers/analytics.js

A successful run confirms that all four handler files are syntactically valid.

Print resolved Serverless configuration

npx serverless print

The command was verified to resolve the development stage and all four bucket names correctly.

9. Local S3 Testing

The local S3 service uses port 4569.

It can be started with:

npx serverless s3 start

The local S3 service was verified to respond successfully at:

http://localhost:4569

and to contain the four development buckets.

Serverless Offline

Because port 3000 was already occupied in the local environment, Serverless Offline was started on port 3003:

npx serverless offline --config serverless.offline.yml --httpPort 3003

The temporary serverless.offline.yml removes serverless-s3-local from the plugin list because the S3-local process is already running separately.

The resulting local endpoints were:

HTTP/API:  http://localhost:3003
Lambda:    http://localhost:3002
S3-local:  http://localhost:4569

10. Validation Performed

Handler syntax

npm test

Result:

PASS

All four JavaScript files passed Node.js syntax checking.

Serverless configuration

npx serverless print

Result:

PASS

The configuration correctly resolved:

Stage: dev
Region: af-south-1

Receipts bucket:
kijani-payments-receipts-dev

Processed bucket:
kijani-payments-processed-dev

Notifications bucket:
kijani-payments-notifications-dev

Analytics bucket:
kijani-payments-analytics-dev

Receipt generation

The local HTTP endpoint was tested with:

curl -X POST http://localhost:3003/dev/receipts \
  -H "Content-Type: application/json" \
  -d '{"orderId":"ORD-003","amount":1500}'

The function successfully returned a receipt containing:

orderId

amount

currency

timestamp

receiptId

Local S3 upload

A receipt was uploaded successfully to:

s3://kijani-payments-receipts-dev/receipt-ORD-003.json

The object was confirmed to exist in the local receipts bucket.

Local event-chain status

The local S3 object upload did not cause processReceiptUpload to appear in the Serverless Offline invocation log.

This has been recorded as a local testing/integration issue, not as proof that the handler logic is incorrect.

The installed versions are:

serverless@4.41.0
serverless-offline@14.8.0
serverless-s3-local@0.8.5
s3rver@3.7.1

serverless-s3-local@0.8.5 also brings a nested serverless-offline@13.10.1 using Serverless Framework 3.40.0.

The local event simulation therefore requires further validation before it is treated as proof of end-to-end behavior.

11. Deployment

The serverless stack is intended to be deployed by Jenkins rather than relying on manually performed production deployments.

The expected pipeline is:

Checkout
   |
   v
Install dependencies
   |
   v
Validation / Tests
   |
   v
Deploy to staging
   |
   v
Approval gate
   |
   v
Deploy to production

The Jenkins pipeline should use the Serverless CLI with explicit stages rather than relying on the local development stage.

Example deployment commands:

npx serverless deploy --stage staging --region af-south-1

and, after approval:

npx serverless deploy --stage production --region af-south-1

The exact Jenkins credentials and credential IDs must be supplied by the Jenkins environment and must never be hard-coded in this repository.

12. Out of Scope

The following are deliberately outside this capstone's scope:

Kubernetes HPA and capacity redesign

The capstone does not redesign kk-payments autoscaling or implement a new Kubernetes capacity-management strategy.

Kubernetes Ingress security redesign

The capstone does not redesign:

TLS termination;

authentication/authorization;

rate limiting; or

other Ingress security improvements from the previous production-readiness assessment.

The focus remains the serverless receipt architecture.

13. Success Criteria

The capstone is considered successful when:

The four-function serverless stack deploys successfully to AWS staging and production, with serverless info confirming the deployed resources.

A receipt written by kk-payments to the production S3 receipt bucket triggers the serverless chain and results in kk-analytics logging a structured summary containing:

receipt count;

total amount; and

timestamp range.

Jenkins demonstrates:

serverless deployment to staging;

a visible approval gate; and

production deployment after approval.

14. AI-Assisted Development

AI tools were used as development assistance during the capstone.

AI assistance was used for:

reviewing existing Lambda handlers;

checking Serverless configuration against the capstone scope;

reasoning about event-driven architecture;

identifying potential configuration/tooling issues;

helping interpret test output;

supporting documentation;

and assisting with CI/CD planning.

AI-generated suggestions were reviewed and tested by the project owner before being treated as implementation decisions.

AI tools do not have authority to:

approve production deployment;

access or generate production credentials;

bypass Jenkins approval gates;

determine whether the capstone is complete without human verification; or

replace required testing.

Further details are documented in AI-GOVERNANCE.md.

15. Current Status

Area

Status

Four Lambda handlers present

Complete

JavaScript syntax validation

Passed

Serverless configuration validation

Passed

Local S3 service

Working

Local HTTP receipt generation

Working

Local receipt upload to S3

Working

Local S3 → Lambda event simulation

Requires further validation

AWS staging deployment

Pending

AWS production deployment

Pending

Kubernetes → production S3 integration

Pending

Jenkins pipeline

Pending

Production governance controls

Pending

The local S3 event-simulation issue should not be confused with a failed AWS deployment. AWS event behavior must be validated separately as part of staging deployment.

16. Repository Hygiene

The capstone should remain focused on the Serverless-first architecture.

Files and configuration from unrelated earlier Kubernetes/Docker exercises should not be used as drivers for the capstone architecture.

The project should be reproducible from a clean checkout using the documented dependencies, configuration, tests, and deployment process.