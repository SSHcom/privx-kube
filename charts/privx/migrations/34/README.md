Upgrade Guide to PrivX 34.X
===========================

## Current Helm revision for PrivX

Before proceeding to upgrade PrivX from 33.X to 34.X, take a note of the current
Helm revision for the PrivX release. To do this, run the following command:

```
helm history --namespace privx privx
```

The last entry in the command is the revision of PrivX that is currently
running. It's usually the one with the `STATUS=deployed`.

This is needed so there will be a known working revision of PrivX that can be
roll backed to in case the upgrade doesn't work out.

## Shutdown PrivX and take backup

The first part of the upgrade is to shutdown PrivX so that further changes to
settings or the database are not possible. At the same time, all PrivX settings
and configurations will be backed up.

To this end, a separate volume claim named `privx-backup-claim` must be
created in the `privx` namespace. This claim would be used to write all of the
backed up files to.

To shutdown PrivX and take a backup, run the following command:

```
helm upgrade --history-max 0 \
    -f values-overrides/privx.yaml \
    -f charts/privx/migrations/34/stage1.yaml \
    --wait privx -n privx charts/privx/
```

The backup will be created under the volume that was mounted as the claim
`privx-backup-claim`. The backup folder will have the following naming
structure:

`privx-backup-PPPPP_YYYY-MM-DD-hhmm_33.X.X`

Where the `P` is a random alpha-numeric representation of the backup pod, `Y` is
the year the backup was generated, `M` is the month, `D` the day, `h` the hour
and `m` the minute.

## Backup database

At this point, the database should be backed up according the documentation
provided by the database service in use.

## Upgrade PrivX

After the database and PrivX are successfully backed up, run the following
command to upgrade to PrivX 34.X.

```
helm upgrade --history-max 0 \
    -f values-overrides/privx.yaml \
    -f charts/privx/migrations/34/stage2.yaml \
    privx -n privx charts/privx/
```

The command above will copy the new configurations and start the new versions of
PrivX microservices.

# Rollback Instructions

If things go south at any point during the upgrade, follow these instructions to
get back to the original revision of PrivX:

1. Shutdown PrivX using the following command:

```
helm upgrade --history-max 0 \
    -f values-overrides/privx.yaml \
    --set shutdown=true \
    --wait privx -n privx charts/privx/
```

2. Restore the database that was previously backed up
3. Replace the placeholder backup folder name for the environment variable
   `BACKUP_DIR` in the file [restore.yaml](../restore.yaml) with the one from
   when the backup was taken (`privx-backup-PPPPP_YYYY-MM-DD-hhmm_33.X.X`). Make
   sure the correct backup folder is used. The backup folder name can also be
   copied from the logs of the backup job by running the following command:

```
kubectl logs -n privx <name-of-the-backup-pod>
```

4. Restore PrivX settings using the following command:

```
helm upgrade --history-max 0 \
    -f values-overrides/privx.yaml \
    -f charts/privx/migrations/34/restore.yaml \
    privx -n privx charts/privx/
```

5. Rollback to the original PrivX revision by running the following command:

```
helm rollback --namespace privx privx <revision-number>
```

The revision-number above should be the same as noted in the first step
before the upgrade.
