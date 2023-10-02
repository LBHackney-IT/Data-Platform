
import json
import boto3

AWS_REGION = "eu-west-2"

def s3_copy_folder(s3_client, source_bucket_name: str, source_path: str, target_bucket_name: str, target_path: str, snapshot_time: str, export_task_identifier: dict[str, str], is_backdated: bool):
    """
    List objects in source bucket and copy to target bucket.
    Partitioned by year, month, day, date. Where import is backdated, use snapshot time instead of today's date. 

    Args:
        s3_client (): A low-level client representing Amazon Simple Storage Service (S3)
        source_bucket_name (str): name of source bucket
        source_path (str): prefix for source objects
        target_bucket_name (str): name of target bucket
        target_path (str): prefix for target objects
        snapshot_time (str): time the snapshot was created
        export_task_identifier (dict): 
        is_backdated (bool): 
    """

    print("source_bucket_name", source_bucket_name)
    print("target_bucket_name", target_bucket_name)
    print("source_path", source_path)
    print("target_path", target_path)
    print("snapshot_time", snapshot_time)
    print("export_task_identifier", export_task_identifier)
    print("is_backdated", is_backdated)
    print()

    # Plan, list through the source, if got continuation token, recursive
    list_response = None

    while True:
        list_objects_params = {
            'Bucket': source_bucket_name,
            'Prefix': source_path,
            'ContinuationToken': list_response.get('NextContinuationToken') if list_response else None
        }
        print("continuation token", list_response.get('NextContinuationToken') if list_response else None)

        list_response = s3_client.list_objects_v2(**list_objects_params)
        contents = list_response.get('Contents', [])
        print("list response contents", contents)

        for file in contents:
            if not file['Key'].endswith(".parquet"):
                continue

            snap_shot_name, database_name, table_name = file['Key'].split('/', 2)
            file_name = file['Key'][len(f"{snap_shot_name}/{database_name}/{table_name}") + 1:]
            parquet_file_name = get_parquet_file_name(file_name)

            print("fileName:", file_name)
            print("parquetFileName:", parquet_file_name)

            copy_object_params = {
                'Bucket': target_bucket_name,
                'CopySource': f"{source_bucket_name}/{file['Key']}",
                'Key': f"{target_path}/{database_name}/{table_name}/import_year={year}/import_month={month}/import_day={day}/import_date={date}/{parquet_file_name}",
                'ACL': 'bucket-owner-full-control',
            }
            print("copyObjectParams", copy_object_params)

            try:
                s3_client.copy_object(**copy_object_params)
            except Exception as e:
                print(e)

        if not list_response.get('IsTruncated') or not list_response.get('NextContinuationToken'):
            break

    



def get_date_time(snapshot_time: str, export_task_identifier: str, is_backdated: bool) -> tuple[str, str, str, str] | None:
    """
    Get date and time from snapshot_time. If backdated, use date from exportTaskIdentifier.

    Args:
        snapshot_time (str): _description_
        export_task_identifier (str): _description_
        is_backdated (bool): _description_
    """
    if is_backdated:
        # example task identifier string: "ExportTaskIdentifier":"sql-to-parquet-22-06-01-backdated"
        year = f"20{export_task_identifier.split('-')[3]}"
        month, day = export_task_identifier.split('-')[4:6]
        date = f"{year}-{month}-{day}"
        return day, month, year, date
    else:
        # example output "SnapshotTime": "2020-03-27T20:48:42.023Z"
        year, month, day = snapshot_time.split('-')[0:3]
        date = f"{year}-{month}-{day}"
        return day, month, year, date
    
    
def get_parquet_file_name(file_name):
    # Your get_parquet_file_name function logic here...

def start_workflow_run(workflow_name):
    # Your start_workflow_run function logic here...

def start_backdated_workflow_run(workflow_name, import_date):
    # Your start_backdated_workflow_run function logic here...

def lambda_handler(event, context):
    rds_client = boto3.client("rds", region_name=AWS_REGION)
    s3_client = boto3.client("s3", region_name=AWS_REGION)
    sqs_client = boto3.client("sqs", region_name=AWS_REGION)

    for record in event['Records']:
        message = json.loads(record['body'])
        print("event", record)
        print("message.ExportTaskIdentifier", message['ExportTaskIdentifier'])
        
        describe_export_tasks = rds_client.describe_export_tasks(
            ExportTaskIdentifier=message['ExportTaskIdentifier']
        )

        print("describe_export_tasks", describe_export_tasks)

        if not describe_export_tasks or not describe_export_tasks['ExportTasks'] or len(describe_export_tasks['ExportTasks']) == 0:
            raise Exception('describe_export_tasks or its child ExportTasks is missing')

        export_task_status = describe_export_tasks['ExportTasks'][-1]

        # Don't re-queue if status is canceled
        if export_task_status['Status'] == 'CANCELED':
            continue

        # Check to see if the export has finished
        if export_task_status['Status'] != 'COMPLETE':
            # If NOT then requeue the event with an extended delay
            print(record['eventSourceARN'])

            queue_name = record['eventSourceARN'].split(':')[-1]

            get_queue_url_response = sqs_client.get_queue_url(QueueName=queue_name)

            print(get_queue_url_response)

            sqs_client.send_message(
                QueueUrl=get_queue_url_response['QueueUrl'],
                MessageBody=record['body'],
                DelaySeconds=300
            )
            continue

        source_bucket_name = message['ExportBucket']
        target_bucket_name = bucket_destination
        path_prefix = f"{message['ExportTaskIdentifier']}"
        snapshot_time = export_task_status['SnapshotTime']
        is_backdated = False

        # Example: sql-to-parquet-2021-07-01-override - backdated ingestion so use time from snapshot instead of today
        pattern = r'^sql-to-parquet-\d\d\d\d-\d\d-\d\d-backdated$'
        if pattern.match(path_prefix):
            is_backdated = True

        # If it has copy the files from s3 bucket A => s3 bucket B
        s3_copy_folder(s3_client, source_bucket_name, path_prefix, target_bucket_name, target_service_area, snapshot_time, path_prefix, is_backdated)

        if workflow_name and not is_backdated:
            start_workflow_run(workflow_name)

        if backdated_workflow_name and is_backdated:
            day, month, year, date = get_date_time(snapshot_time, path_prefix, is_backdated)
            start_backdated_workflow_run(backdated_workflow_name, date)
