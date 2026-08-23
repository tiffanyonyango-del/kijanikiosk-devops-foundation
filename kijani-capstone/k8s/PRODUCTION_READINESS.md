## Production Readiness Assessment

### 1. External Routing

The current Ingress configuration is not adequate for production because it exposes the payment service over HTTP. Since `kk-payments` handles payment credentials, HTTP traffic is unencrypted and could expose credentials, session information, or other sensitive data to interception while travelling between the client and Ingress. Production traffic should therefore use HTTPS with TLS terminated at the Ingress. I would add a Kubernetes `Secret` containing the TLS certificate and private key, then reference it through the Ingress `spec.tls` configuration. The `nginx.ingress.kubernetes.io/ssl-redirect: "true"` annotation should also be enabled so HTTP requests are automatically redirected to HTTPS.

TLS alone is not sufficient. A public payment endpoint should also have rate limiting to reduce abuse and denial-of-service risk. With ingress-nginx, annotations such as `nginx.ingress.kubernetes.io/limit-rps` can restrict requests per second from a client IP. Authentication and authorization should also be implemented where appropriate rather than relying on the Ingress alone.

### 2. Health Signalling

The current readiness and liveness probes provide a useful baseline, but their values should be validated against the actual startup and recovery behaviour of `kk-payments` under production conditions. If the application takes longer to initialize because of database connections, migrations, or other dependencies, the current `initialDelaySeconds: 5` readiness delay may be too short. I would measure normal and worst-case startup times and adjust the delay accordingly. A `startupProbe` would be preferable for a service with variable startup time because it allows initialization to complete before liveness failures are evaluated.

The `failureThreshold: 3` setting should also be chosen based on observed recovery times. If it is too low, temporary database load or a brief dependency slowdown could cause Kubernetes to repeatedly mark healthy payment Pods as unhealthy and restart them. This can reduce available capacity precisely when the system is under pressure and potentially interrupt transactions.

### 3. Capacity

Three manually managed replicas are not sufficient for predictable end-of-month traffic spikes. Production should use a Horizontal Pod Autoscaler (HPA), backed by `metrics-server`, with meaningful CPU and memory resource requests already defined on the Deployment. The HPA could then scale `kk-payments` between a configured minimum and maximum replica count based on observed utilization.

The CPU target must be calibrated carefully. If it is set too high, Pods can become heavily loaded before the HPA reacts, causing slow payment processing, increased latency, and potentially failed transactions. If it is set too low, the HPA may scale out unnecessarily, increasing infrastructure cost and potentially causing excessive scaling activity. A production target should therefore be based on load testing and observed application behaviour rather than an arbitrary percentage.