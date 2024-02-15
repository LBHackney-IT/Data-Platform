import os
import boto3

rds = boto3.client('rds')
snapshots_api_response = rds.describe_db_snapshots(
  DBInstanceIdentifier=os.environ['RDS_INSTANCE_ID']
)

snapshots = snapshots_api_response['DBSnapshots']

print("Found ", len(snapshots), " snapshots")

for snapshot in snapshots:
  snapshot_id = snapshot['DBSnapshotIdentifier']

  if snapshot_id.startswith('awsbackup'):
    print("Skipping snapshot ", snapshot_id)
  else:
    print("Deleting snapshot ", snapshot_id)
    rds.delete_db_snapshot(
      DBSnapshotIdentifier=snapshot_id
    )
