AI Governance — KijaniKiosk Capstone

1. Purpose

This document defines how AI tools are used, reviewed, governed, and constrained during development of the KijaniKiosk Serverless-first capstone.

The purpose is to ensure that AI assistance improves development productivity without transferring engineering accountability or production authority to an AI system.

The capstone uses AI as a development assistant, not as an autonomous deployment authority.

2. Project Context

The capstone builds an event-driven serverless receipt-processing pipeline consisting of:

kk-payments
    |
    v
Receipts S3 Bucket
    |
    v
kk-receipts
    |
    v
Processed S3 Bucket
    |
    v
kk-processor
    |
    v
Notifications S3 Bucket
    |
    v
kk-notifier
    |
    v
Analytics S3 Bucket
    |
    v
kk-analytics

The CI/CD workflow is:

Validation
    |
    v
Staging Deployment
    |
    v
Human Approval
    |
    v
Production Deployment

AI assistance must operate within these boundaries.

3. AI Usage Principles

Principle 1 — Human accountability

The project owner remains responsible for:

source-code decisions;

configuration decisions;

security decisions;

testing;

deployment approval;

governance findings;

and final capstone submission.

AI suggestions are recommendations and must be reviewed.

Principle 2 — Verify before accepting

AI-generated code or configuration must not be accepted solely because it appears plausible.

It should be checked through appropriate mechanisms such as:

syntax validation;

unit or behavioral testing;

serverless print;

serverless info;

local integration testing;

AWS staging validation;

code review; and

comparison with the capstone requirements.

Principle 3 — Least privilege

AI tools must not be given unnecessary access to:

AWS access keys;

Jenkins secrets;

private credentials;

production tokens;

personal authentication information;

or other sensitive secrets.

Credentials must be supplied through the appropriate CI/CD or cloud credential mechanisms rather than committed to source control.

Principle 4 — No autonomous production approval

AI must not replace the Jenkins production approval gate.

The production sequence must remain:

Staging Deployment
       |
       v
Human Review
       |
       v
Approval
       |
       v
Production Deployment

AI may assist with reviewing logs or identifying possible issues, but the final production approval belongs to a human.

4. Approved AI Uses

AI assistance is appropriate for:

explaining AWS, Serverless, JavaScript, and Jenkins concepts;

reviewing code for potential defects;

suggesting test cases;

explaining command output;

identifying configuration inconsistencies;

proposing documentation structures;

helping compare implementation against the assignment scope;

assisting with troubleshooting;

suggesting security and governance improvements;

and helping draft non-secret configuration.

AI-generated code must be reviewed before being committed.

5. Restricted AI Uses

The following uses require additional human verification and must not be treated as automatically trustworthy:

Infrastructure configuration

AI may suggest:

Serverless configuration;

IAM configuration;

S3 event configuration;

Jenkins stages;

environment variables; and

deployment commands.

However, these suggestions must be checked against the actual deployment requirements.

Security configuration

AI may identify possible vulnerabilities or governance gaps, but security recommendations must be validated against:

AWS documentation;

project requirements;

deployed configuration;

and least-privilege principles.

Production deployment

AI may help interpret deployment output but must not independently authorize production deployment.

6. Prohibited AI Practices

The following practices are prohibited:

Hard-coding production AWS credentials into source code.

Committing AWS credentials, API tokens, passwords, or Jenkins secrets.

Giving an AI tool unnecessary access to production secrets.

Allowing AI-generated code to bypass required tests.

Removing the Jenkins production approval gate because an AI tool considers the deployment safe.

Treating an AI response as evidence that an AWS deployment succeeded without checking the actual deployment.

Claiming a security or governance control is implemented without verifying the deployed configuration.

Using AI-generated documentation as evidence for a control that has not actually been implemented.

7. Data Handling

The following information should not be supplied to AI tools unless explicitly required and appropriately protected:

AWS secret access keys;

Jenkins credentials;

private tokens;

passwords;

private certificates;

personally identifiable customer information;

production receipt data containing sensitive information;

internal authentication material.

For debugging, use sanitized examples.

For example, a receipt such as:

{
  "orderId": "ORD-003",
  "amount": 1500,
  "currency": "KES"
}

is preferable to supplying real customer information.

8. AI-Generated Code Review Process

AI-assisted code should follow this process:

AI Suggestion
     |
     v
Human Review
     |
     v
Syntax / Static Validation
     |
     v
Behavioral Testing
     |
     v
Integration Testing
     |
     v
Staging Validation
     |
     v
Human Approval

No stage should be skipped merely because an AI tool reports that the implementation is correct.

9. Evidence and Verification

The project records concrete evidence rather than relying on AI claims.

Examples already performed during development include:

JavaScript syntax validation

npm test

The current command checks:

handlers/receipts.js
handlers/processor.js
handlers/notifier.js
handlers/analytics.js

Serverless configuration validation

npx serverless print

This confirmed that the configured development stage resolves the four S3 bucket names and their associated Lambda event mappings.

Local receipt-generation test

curl -X POST http://localhost:3003/dev/receipts \
  -H "Content-Type: application/json" \
  -d '{"orderId":"ORD-003","amount":1500}'

The test successfully generated a receipt.

Local S3 upload test

The generated receipt was successfully uploaded to:

s3://kijani-payments-receipts-dev/receipt-ORD-003.json

The object was then confirmed to exist in the local S3 bucket.

Local event-chain limitation

The local S3 upload did not trigger processReceiptUpload in the Serverless Offline logs.

This result is recorded as an unresolved local event-simulation issue rather than being incorrectly reported as proof that the Lambda handler is defective.

The installed tooling includes:

serverless@4.41.0
serverless-offline@14.8.0
serverless-s3-local@0.8.5
s3rver@3.7.1

The local tooling configuration therefore requires further validation.

10. AI-Assisted Troubleshooting Record

During development, AI assistance was used to:

review the capstone scope;

compare the four handlers against the intended event-driven chain;

inspect the resolved Serverless configuration;

interpret local port conflicts;

identify the locally running S3 service;

distinguish the configured Lambda runtime from the local Node.js version;

interpret the local S3 event-testing failure;

and determine that further investigation should focus on the local testing toolchain before rewriting application code.

A key governance decision was to avoid changing application code merely because a local simulator failed to trigger an event.

This preserves the distinction between:

Application defect

and:

Local tooling/integration defect

until sufficient evidence exists.

11. Human-in-the-Loop Production Governance

The Jenkins pipeline must maintain an explicit human approval step.

Required sequence:

1. Checkout source
2. Install dependencies
3. Run validation/tests
4. Deploy to staging
5. Verify staging
6. Human approval
7. Deploy to production
8. Verify production

AI can assist with steps 3, 5, and 8 by helping interpret results, but it must not silently approve step 6.

12. AI Output Quality Controls

Before incorporating AI-generated code or documentation, the project owner should ask:

Does this match the capstone scope?

Does this match the actual repository?

Has the code been executed?

Has the configuration been printed or inspected?

Does the implementation satisfy the stated success criterion?

Does the recommendation introduce unnecessary dependencies?

Does it expose credentials or sensitive information?

Does it weaken the approval or security controls?

Is the claim supported by actual test or deployment evidence?

If the answer to these questions is not satisfactory, the AI output must not be treated as final.

13. Production Readiness Rule

The project must not claim production readiness merely because:

the code compiles;

npm test passes;

serverless print succeeds;

an AI tool says the configuration is correct; or

a local simulator behaves as expected.

Production readiness requires evidence from the actual deployment environment.

For this capstone, the key production-readiness evidence includes:

successful staging deployment;

successful production deployment;

correct S3 event wiring;

successful receipt propagation through the four-function chain;

structured analytics output;

Jenkins approval-gate evidence;

verification of the required governance controls.

14. Governance Ownership

Human owner: Project owner / student

The project owner is responsible for:

reviewing AI-generated recommendations;

validating implementation;

protecting credentials;

approving production deployment;

documenting governance findings;

and ensuring that the final implementation satisfies the capstone requirements.

AI tools provide assistance but do not own the system or its deployment decisions.

15. Governance Status

Control Area

Status

Human review of AI output

In use

AI-assisted code verification

In use

Credential protection

Required

No hard-coded production credentials

Required

Human production approval

Required

AI cannot bypass Jenkins approval

Required

Test evidence before deployment

In use

Staging before production

Required

Production deployment verification

Pending

Full serverless governance validation

Pending

16. Final Governance Statement

AI is used in this capstone as a controlled engineering assistant.

The project does not delegate production authority, credential management, security accountability, or final deployment decisions to AI.

AI-generated recommendations are subject to human review and technical verification, and production deployment remains protected by an explicit Jenkins approval gate.

The goal is to obtain the productivity benefits of AI while preserving traceability, accountability, security, and reproducibility.