# Databse certificate

For PrivX 31 or newer versions, when configuring a database in PrivX, the default sslmode setting is ```'verify-full'```. This means that SSL certificate verification is enabled, and a valid certificate is required to establish a connection to the database. The default location for ```sslrootcert``` is ```/opt/privx/etc/privx-db-trust-anchor.pem``` in PrivX.

## PostgreSQL sslmode

### 'verify-ca' vs 'verify-full'

In addition to the ```'verify-full'``` SSL certificate verification method, another option available is ```'verify-ca'```.

The difference between ```verify-ca``` and ```verify-full``` depends on the policy of the root CA. If a public CA is used, ```verify-ca``` allows connections to a server that somebody else may have registered with the CA. In this case, ```verify-full``` should always be used.

More information can be seen in the [PostgreSQL document](https://www.postgresql.org/docs/current/libpq-ssl.html)

## Preparation

1. Set ```sslmode``` in ```values-overrides/privx.yaml``` as ```'verify-full'``` or ```'verify-ca'```
2. Setup the database to use a server certificate and save that certificate or the CA certificate/chain for use later.

## Add ceritificate to PrivX

When adding the database server/CA certificate to PrivX, there are two options available: users can choose to either use a certificate string or upload a certificate file to provide the certificate to PrivX.

The order in which PrivX checks for the certificate:

1. Check for Certificate File: PrivX first checks if it receives a certificate file. If a certificate file is provided, PrivX will use the contents of the file to setup the connection to the database.

2. Check for Certificate String: If no certificate file is provided, PrivX will then check if a certificate string is available. If a certificate string is provided, PrivX will use the string as the source of the database server/CA certificate configuration.

For both methods, the final certificate file will be stored in ```charts/privx/configs/database/certificate/server.crt```, where Helm will use it to store the certificate
to `/opt/privx/etc/privx-db-trust-anchor.pem` in the PrivX volume.

 **It is important to mention that the existing ```server.crt``` is a Helm template file, which is used to generate the certificate from the string value provided in `.Values.db.sslDBCertificate` in ```value-overrides/privx.yaml``` . If the Helm template file is replaced, then make sure the contents of the file are an actual db server certificate.**

Both methods of providing the database certificate to PrivX are explained below:
### 1. Upload certificate file

Users can upload a certificate file to PrivX. The certificate file contains the database server/CA certificate information and must be in PEM format.

There are two conditions when uploading the certificate file, deploying a new PrivX instance or upgrading an existing PrivX installation.

- **New Installation**

    For uploading certificate file, the certificate file must be copied to ```charts/privx/configs/database/certificate/server.crt```.

    **Before copying the new certificate, it is recommended to back up the ```server.crt``` file if the ```server.crt``` already has a database server/CA certificate.**

    ```
    # Upload file
    cp <certificate-path>/<certificate-fileName> charts/privx/configs/database/certificate/server.crt
    ```

- **Upgrade**

    For uploading certificate file, the certificate file must be copied to ```charts/privx/migrations/<version>/configs/database/certificate/server.crt```. 
    
    **All the ```<version>``` mentioned in this chapter needs to be changed to the target PrivX version.**

    ```
    # Upload file
    cp <certificate-path>/<certificate-fileName> charts/privx/migrations/<version>/configs/database/certificate/server.crt
    ```
### 2. Use string certificate

Users can provide the database server/CA certificate as a string. This means that the contents of the certificate are directly included in the configuration.

For using certificate string, the certificate string should be added to ```db.sslDBcertificate``` in ```value-overrides/privx.yaml``` file, and make sure ```charts/privx/configs/database/certificate/server.crt``` file exists, which should be a helm template file.

Below is an example demonstrating how the database server/CA certificate can be added to PrivX using a certificate string.

**NOTE: The |- are intentional and should be added before adding the contents of the PEM certificate. Please use the correct format when copying the certificate contents.**

```
sslDBcertificate: |-
-----BEGIN CERTIFICATE-----
MIIDIjCCAgqgAwIBAgIUe78yuPZhPot/Q0p7uRtOoh9H92IwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAwwKZGItcHNxbC5kYjAeFw0yMzA2MDkwNjU1MjdaFw0yNDA2
MDgwNjU1MjdaMBUxEzARBgNVBAMMCmRiLXBzcWwuZGIwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQDGxEceIp372YfRo7hlJXWYNntcMHl8xWRboIoZLsV7
DjD0Gm7WIUl4NANmbKO4FVJCQ/P1aU6YflpfFz+lIstOaPv2kiGrwjONYfCrAaET
lT5CCNRKTnyh+xeYxxb8c1Kw626MjLS9YMfXOY+cz/JntEHdAzAWjo6R8bKLbz1B
h4zEP31SSNUI7DNXkt9eOjHBMxs/XLWgIvpzkCOvaTCD/vsRGZhm4Mzk+At/FzBm
+FbQJ/Ofpf4toTqTLPsDLnjITptwlPYzELmcaxa399sYnfvrrbibonFLf0R+r8U5
gHzrWq2c7R4bbpExKYMuikfu5gRFJ9QpDjFrt5eq/gmpAgMBAAGjajBoMB0GA1Ud
DgQWBBTgiq8CxrtJxXg5Er8xEWLj1YMXEjAfBgNVHSMEGDAWgBTgiq8CxrtJxXg5
Er8xEWLj1YMXEjAPBgNVHRMBAf8EBTADAQH/MBUGA1UdEQQOMAyCCmRiLXBzcWwu
ZGIwDQYJKoZIhvcNAQELBQADggEBAAl1Sa3oTkHIobahwuQ/8B65aLrLSUEDTiAk
RrMwUDMu+1fbbq8q++sP2/ucf3jr/ZFUzibSFcpYEwJxyQ1rUgB/EgClAVnu29+C
UdcL8Vj8KiVBmJ5cvYv8Z803x/rCZdz1R4Sc6l6NhglsQqPY2O91Fg8WhZJ5FbPU
u3U56Wtes5Id3gtwQlO/X6SouplAFCOvZLwu50zRFiEkyR0A0D+v7UiruvVJtZb9
B+95L4kdcexHorsoTL9YY0hJRGuFaTgBX6EEk5nydLkkVKBBCJL3QDJDK8cWA5xj
sraHT8W2nI75btTbS7Q6sku84nU3uGK4bppkynw3uwVPTMtR4nM=
-----END CERTIFICATE-----
```
