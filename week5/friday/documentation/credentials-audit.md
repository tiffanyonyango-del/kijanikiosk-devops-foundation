# Credential Audit

## Objective

The purpose of this audit is to verify that sensitive information such as usernames, passwords, access tokens and secrets are not exposed within the project's source code, Git history or Jenkins build logs.

## Audit Scope

The following areas were reviewed:

1. Jenkinsfile
2. Git commit history
3. Jenkins build logs

## Audit Checks

| Area | Check Performed | Result |
|------|-----------------|--------|
| Jenkinsfile | Verified that credentials are accessed through Jenkins Credentials using `withCredentials` instead of hardcoded usernames or passwords. | Pass |
| Git History | Searched commit history for passwords, secrets and tokens. | Pass |
| Jenkins Build Logs | Confirmed that credentials are masked and are not printed during pipeline execution. | Pass |

## Commands Used

```bash
git log --all -p | grep -i "password"

git log --all -p | grep -i "token"

git log --all -p | grep -i "secret"
```

## Findings

No credentials were intentionally stored within the source code repository. Authentication is managed through the Jenkins Credentials Store, allowing secrets to remain outside version control. During pipeline execution, credentials are injected only when required and are not intended to appear in the console output.

## Conclusion

The pipeline follows good security practices by separating sensitive information from application source code. This reduces the risk of accidental credential exposure while allowing automated access to external services such as the Nexus repository.