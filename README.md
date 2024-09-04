# **BREAKING CHANGES IN PRIVX 35.0**

- PrivX requires PostgreSQL server version to >= 11.X. Before installing/upgrading
to PrivX 35.0, please make sure that a supported PostgreSQL server version is
used. For more information and supported helm variables, please check
[here](docs/breaking-35-0-0.md).

# privx-kube

privx-kube is a means to deploy [PrivX](https://www.ssh.com/products/privx/) in
a kubernetes cluster.

## Introduction
This repo contains the PrivX helm chart that can be used to deploy the supported
versions of PrivX on Kubernetes.

For more information on PrivX, please find the documentation
[here](https://privx.docs.ssh.com/). An architecture diagram for PrivX on
Kubernetes can be found [here](https://privx.docs.ssh.com/docs/privx-on-kubernetes#architecture-diagram-for-privx-on-kubernetes).

For a list of Kubernetes resources that are deployed, please check
[here](docs/resources.md).

## Prequisites

- Kubernetes >= 1.19
- Kubectl >= 1.19
- Helm >= 3.6.3
- Volume/Storage requirements as described below

### Volume Requirements
PrivX depends on its different components to be able to share storage for it to work
correctly. For this reason, it is important that a choice for storage is made in
such a way so that the following requirement is fulfilled:

#### Support for ReadWriteMany AccessMode:
    This is required because it allows the PrivX pods to be able to share storage
    and at the same time, the pods can be on different nodes in the cluster, which
    allows for PrivX to be scalable in Highly Available (HA) fashion.

#### Support for ReadWriteOnce AccessMode:
    If for any reason, ReadWriteMany access mode is not available, the next best
    option is to have the ReadWriteOnce access mode for the storage. The only
    downside to this is that all the pods in a PrivX deployment would have to be
    co-located in a single node. This makes it prone to failure if the node goes
    down and manual intervention will be needed and possible loss of data.

## Pre-Install requirements

The helm chart for PrivX makes a few assumptions and those have to be in place
for PrivX to work.

### Ingress Controller

As in any kubernetes cluster, a gateway or ingress is required to reach the
application. PrivX uses [Bitnami Nginx Ingress Controller](https://github.com/bitnami/charts/tree/master/bitnami/nginx-ingress-controller)
as the ingress controller.

**NOTE: Please keep [this](docs/ingress.md) information in mind if an Ingress
Controller or a similar component other than the one mentioned above is used.**

The purpose of the ingress controller is to setup ingress to the PrivX
microservices in a dynamic way.
privx-kube provides an override file [ingress.yaml](values-overrides/ingress.yaml) with
extra settings for deploying the Bitnami nginx ingress controller. The purpose
of the file is to provide settings that are crucial to the workings of PrivX.

Depending on the type of Kubernetes cluster, this file might require further
settings (e.g Load balancer settings). But the main requirement after installing
the ingress controller is that it should be accessible for the clients that
would end up using PrivX.

The installation instructions are split in to two sections depending on the
version of Kubernetes in use =1.19 or >1.19. This is because of the backward
incompatible changes done by the developers of the ingress controller helm chart.
To install the ingress controller chart, do the following:


##### Kubernetes =1.19:
```
helm repo add bitnami-full-index https://raw.githubusercontent.com/bitnami/charts/archive-full-index/bitnami
helm install \
    -n ingress --create-namespace \
    -f values-overrides/ingress.yaml \
    --version 7.6.6 \
    ingress bitnami-full-index/nginx-ingress-controller
```

##### Kubernetes >1.19:
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install \
    -n ingress --create-namespace \
    -f values-overrides/ingress.yaml \
    --version 9.3.0 \
    ingress bitnami/nginx-ingress-controller
```

Up to date instructions on new releases and any breaking changes can be found
in the original
[repo](https://github.com/bitnami/charts/tree/master/bitnami/nginx-ingress-controller#upgrading).

#### Restricted access Ingress Controller

If the ingress controller is deployed in a more secure fashion, then the
following command can be used:

**NOTE: The pre-requisite for using the command is to have a volume claim named
`ingress-claim`**

```
helm upgrade --install \
    -n ingress --create-namespace \
    -f values-overrides/ingress.yaml \
    -f values-overrides/ingress-secure.yaml \
    ingress charts/nginx-ingress-controller/
```

The command above uses an extra override file called
[ingress-secure.yaml](values-overrides/ingress-secure.yaml).

The file restricts privilege escalation, writing to container
filesystem and drops all file capabilities including the `NET_BIND_SERVICE`
that is needed by the ingress controller. The last setting is dropped with the
help of a wrapper container around the Bitnami Ingress Controller Docker container
by dropping the file capability `cap_net_bind_service`.

### Working Postgres Database

PrivX uses Postgres database for relational transactions and internal
notifications. Therefore, it is important that a database is available either
internally in the cluster or outside of the cluster.

Once the database is present, the following values in the file
[privx.yaml](values-overrides/privx.yaml) should be changed for privx to be able
to reach and interact with the database.

    - db.address (database address) [mandatory]
    - db.port (database port) [mandatory]
    - db.name (database name) [mandatory]
    - db.sslmode (database sslmode) [optional: default value=`verify-full`]
    - db.sslDBcertificate (database string certificate) [mandatory if db.sslmode is `verify-full` or `verify-ca` and certificate file is not uploaded and the certificate is not inherently trusted]
    - db.admin.createDB (true: create db.name, false: skip) [optional: default value=`true`]
    - db.admin.createDBUser (true: create db.user, false: skip) [optional: default value=`true`]
    - db.admin.name (database admin username) [mandatory if either db.admin.createDB or db.admin.createDBUser is true]
    - db.admin.password (database admin password) [mandatory if either db.admin.createDB or db.admin.createDBUser is true]
    - db.user.name (database privx user) [mandatory]
    - db.user.password (database privx user password) [mandatory]

**NOTE: The values db.sslmode and db.sslDBcertificate are important to setup**
**correctly. More details on how to use these can be found [here](db-certificate.md).**

### Namespace

PrivX should be deployed in the `privx` namespace. To create the namespace, do
the following:

```
kubectl create namespace privx
```

### Certificates

PrivX assumes that at least two kubernetes secrets with specific certificates
are present in the `privx` namespace.

1. `privx-tls` (Used for storing server certificate for HTTPS Ingress)
2. `privx-ca-secret` (Used for storing CA certificate that issued the server
   certificate)

The first certificate can be valid for a short duration and is used for securing
the ingress endpoints. The purpose of the second certificate is to be valid for
a longer duration so that any clients that rely on proxies and extenders can
utilize it for a long-living configuration. The value `ingress.common.hosts[*].host` in
the file [privx.yaml](values-overrides/privx.yaml) must be changed to the
domain(s) that these certificates are issued for.

To create `privx-tls` use the following command:

```
kubectl create secret tls privx-tls \
    --cert=<Path to cert file> \
    --key=<Path to key file> \
    --namespace privx
```

To create `privx-ca-secret` use the following command:

```
kubectl create secret generic privx-ca-secret \
    --from-file=ca.crt=<Path to ca cert file> \
    --namespace privx
```

**NOTE: The names of the secrets should match exactly**

### Volume Claims

PrivX assumes that a volume claim named `privx-claim` be present with
`ReadWrite(Once/Many)` access.

**NOTE: The names of the volume claim should match exactly**

### PrivX license

The value for `ms.licensemanager.licenseCode.prod.value` in the file
[privx.yaml](values-overrides/privx.yaml) should be changed to a
valid license value. **NOTE:** If offline licenses are used, then please wait
for more instructions as support for that is still under work.

### PrivX Admin user
The values for the following are **mandatory** and need to be set before
installing PrivX in the file [privx.yaml](values-overrides/privx.yaml).

    - privx.admin.username (admin username for PrivX UI login)
    - privx.admin.password (admin password for PrivX UI login)
    - privx.admin.email (admin email for PrivX UI login)

### PrivX Container Custom User ID and Group ID

By default, PrivX containers are runing under User ID (`uid`) and Group ID (`gid`) `5111`. To run containers under a custom `uid/gid`, customize the following values in `charts/privx/values.yaml`:

    - podSecurityContext.fsGroup (Custom gid)
    - podSecurityContext.runAsUser (Custom uid)
    - securityContext.runAsUser (Custom uid)

## Install PrivX

To install PrivX use the following command:

```
helm install \
    -f values-overrides/privx.yaml \
    --namespace privx \
    privx charts/privx/
```

# PrivX Version Upgrade
For upgrading privx to the current version, follow the instructions [here](charts/privx/migrations/36/README.md)
