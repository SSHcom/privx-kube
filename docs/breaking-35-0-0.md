# PrivX >= 35.0 PostgreSQL requirements

PrivX will stop supporting the use of PostgreSQL server version 10.X and below
because those have reached EOL (End Of Life). From PrivX 35.0 onwards, the
**minimum supported** PostgreSQL version is **11.X** and PrivX further recommends
using server version >= 12.X.

When using an unsupported PostgreSQL server version, PrivX >= 35.X will fail
to install/upgrade.

## Changes to PrivX installation/upgrade

When installing/upgrading PrivX, it will try to check for the PostgreSQL server
version in use. If it is successful in finding out the server version and it is
one of the supported ones, then it will continue installing/upgrading as before.

If it fails to find the server version, then it will by default fail the
installation/upgrade of PrivX as well. This behavior can be overridden by
intervening with a new Helm variable.

## Overriding PostgreSQL version check failures

A new Helm variable is introduced in PrivX Helm chart called `db.skipVersionCheck`.
This variable can be set in the override file currently in use.

`db.skipVersionCheck` is by default set to `false`, which means that a failure
to check the PostgreSQL version will stop PrivX installation/upgrade from moving forward.

When this variable is set to `true`, the admin confirms that the PostgreSQL
version in use is one of the supported ones and the installation/upgrade will
move forward. This setting should only be used when PostgreSQL indeed is greater
than or equal to version 11.X.
