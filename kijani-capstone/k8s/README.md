# Kubernetes Secrets

## kk-payments Secret

Secret name: `kk-payments-secrets`

Expected keys:
- `DB_PASSWORD`
- `STRIPE_API_KEY`
- `JWT_SECRET`

The Secret is created imperatively and is intentionally not committed to git.

If the cluster is deleted and recreated, the Secret must be recreated manually. Secret values must be obtained from the team before applying.
