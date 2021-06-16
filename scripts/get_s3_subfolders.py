
def get_s3_subfolders(s3_client, bucket_name, prefix):
  there_are_more_objects_in_the_bucket_to_fetch = True
  folders = []
  continuation_token = {}
  while there_are_more_objects_in_the_bucket_to_fetch:
    list_objects_response = s3_client.list_objects_v2(
      Bucket=bucket_name,
      Delimiter='/',
      Prefix=prefix,
      **continuation_token
    )

    folders.extend(x['Prefix'] for x in list_objects_response.get('CommonPrefixes', []))
    there_are_more_objects_in_the_bucket_to_fetch = list_objects_response['IsTruncated']
    continuation_token['ContinuationToken'] = list_objects_response.get('NextContinuationToken')

  return set(folders)
