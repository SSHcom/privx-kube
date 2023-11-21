
# Information on number of Resources Deployed

The provided Helm chart for PrivX creates the following on Kubernetes:
- 23 Deployments (ReplicaSets) (HorizontalPodAutoscaler if enabled)
- 23 Pods
- 22 Services
- 25 Ingress
- 25 Service Accounts
- 5 Jobs (2 during installation, At least 2 during upgrade and 1 for restoration)
- 9 Configmaps (6 during installation, 3 during upgrade)
- 3 Secrets
- 1 Role
- 1 Role Binding
