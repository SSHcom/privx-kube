# privx-kube

privx-kube is a means to deploy [PrivX](https://www.ssh.com/products/privx/) in
a kubernetes cluster.

## Introduction
This repo contains the PrivX chart and in addition uses [Bitnami Nginx Ingress
Controller](https://github.com/bitnami/charts/tree/master/bitnami/nginx-ingress-controller). The purpose of the
ingress controller is to setup ingress to the PrivX microservices in a dynamic
way.

## Prequisites

- Kubernetes >= 1.19
- Kubectl >= 1.19
- Helm >= 3.6.3

## Pre-Install requirements

The helm chart for PrivX makes a few assumptions and those have to be in place
for PrivX to work.

### Ingress Controller

privx-kube provides a file [ingress.yaml](values-overrides/ingress.yaml) with
extra settings for deploying the Bitnami nginx ingress controller. The purpose
of the file is to provide settings that are crucial to the workings of PrivX.

Depending on the type of Kubernetes cluster, this file might require further
settings (e.g Load balancer settings). But the main requirement after installing
the ingress controller is that it should be accessible for the clients that
would end up using PrivX.

To install the ingress controller chart, do the following:

```
helm install \
    -n ingress --create-namespace \
    -f values-overrides/ingress.yaml \
    ingress charts/nginx-ingress-controller/
```

### Working Postgres Database

PrivX uses Postgres database for relational transactions and internal
notifications. Therefore, it is important that a database is available either
internally in the cluster or outside of the cluster.

Once the database is present, the following values in the file
[privx.yaml](values-overrides/privx.yaml) should be changed for privx to be able
to reach and interact with the database.

    - db.address (database address)
    - db.port (database port)
    - db.name (database name)
    - db.sslmode (database sslmode (optional: default value=`require`))
    - db.admin.name (database admin username)
    - db.admin.password (database admin password)
    - db.user.name (database privx user)
    - db.user.password (database privx user password)

**NOTE: Apart from the db.sslmode, all the other settings are mandatory and
PrivX deployment will not work without setting these.**

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
utilize it for a long-living configuration. The value `ingress.common.host` in
the file [privx.yaml](values-overrides/privx.yaml) should be changed to the
domain that these certificates are issued for.

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

### Privx Admin user
The values for the following are **mandatory** and need to be set before
installing PrivX in the file [privx.yaml](values-overrides/privx.yaml).

    - privx.admin.username (admin username for PrivX UI login)
    - privx.admin.password (admin password for PrivX UI login)
    - privx.admin.email (admin email for PrivX UI login)

## Install PrivX

To install Privx use the following command:

```
helm install \
    -f values-overrides/privx.yaml \
    --namespace privx \
    privx charts/privx/
```
