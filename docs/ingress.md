# Information on outside ports needed to be opened

PrivX requries that the port 443 (HTTPS) be open for it to function. The
following ports are optional and are needed to be opened for allowing specific
features to work correctly:

- 1080 (Needed by SSH Bastion for SOCKS proxy connections)
- 2222 (Needed by SSH Bastion for SSH native connections)
- 3389 (Needed by RDP Bastion for RDP native conenctions)
- 8443 (Needed by Authorizer for Client Cert endpoints)

# Information on Sticky Sessions

PrivX microservices use sticky sessions to make sure that all communication
for a particular session happens with the same pod throughout its lifetime if
possible. For this reason, PrivX uses supported Ingress annotations to use
sticky sessions (affinity cookies). This should be kept in mind
when deciding on a particular Ingress Controller.

# Information on TLS Communication

PrivX also secures the communcation between the ingress controller and the Pod
using TLS. PrivX uses supported Ingress annotations for this.
