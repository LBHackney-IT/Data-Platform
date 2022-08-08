import boto3
import fileinput

glue_client = boto3.client("glue")
s3_client = boto3.client("s3")
bucket_name = "dataplatform-stg-glue-scripts"
workflow_name = "parking-liberator-data-workflow"
directory_to_save_scripts = "parking"
terraform_file_to_write_to = "25-aws-glue-job-parking.tf"

def get_list_of_glue_jobs():
# TODO: get all triggers without having to make a second call, if there are more than 400 then we won't get all
  triggers_first_response = glue_client.get_triggers(
    MaxResults=200,
  )

  triggers_second_response = glue_client.get_triggers(
    MaxResults=200,
    NextToken=triggers_first_response["NextToken"]
  )

  triggers = triggers_first_response["Triggers"] + triggers_second_response["Triggers"]
  print(f"num triggers: {len(triggers)}")

  liberator_triggers = [trigger for trigger in triggers if trigger.get("WorkflowName") == workflow_name]

  job_names = [action.get("JobName") for actions in [trigger["Actions"] for trigger in liberator_triggers] for action in actions if action.get("JobName") is not None]

  return job_names


def copy_python_script_from_s3_to_repo(bucket_name, script_key, script_name):
  with open(f"scripts/jobs/{directory_to_save_scripts}/{script_name}", "wb") as f:
    s3_client.download_fileobj(bucket_name, script_key, f)


def replace_text_with_variable(local_script_location):
    text_to_search = "stg"
    replacement_text = '" + environment + "'

    with fileinput.FileInput(local_script_location, inplace=True) as file:
        for line in file:
            print(line.replace(text_to_search, replacement_text), end='')


def add_environment_variables_to_script(script_name):
    local_script_location = f"scripts/jobs/{directory_to_save_scripts}/{script_name}"
    lines = open(local_script_location, 'r').readlines()
    lines[7] = """
from scripts.helpers.helpers import get_glue_env_var
environment = get_glue_env_var("environment")

"""
    out = open(local_script_location, 'w')
    out.writelines(lines)
    out.close()

    replace_text_with_variable(local_script_location)


def write_terraform_glue_job(script_name, job_description):
  script_name_without_extension = script_name.split(".")[0]
  module_block = """\
module "{module_name}" {{
  source                     = "../modules/aws-glue-job"
  department                 = module.department_parking
  job_name                   = "${{local.short_identifier_prefix}}{job_name}"
  helper_module_key          = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  script_name                = "{script_name}"
  triggered_by_job           = aws_glue_job.copy_parking_liberator_landing_to_raw.name
  job_description            = "{job_description}"
  workflow_name              = aws_glue_workflow.parking_liberator_data.name
  job_parameters = {{
    "--job-bookmark-option" = "job-bookmark-enable"
    "--environment"         = var.environment
  }}
}}\


""".format(module_name=script_name_without_extension, job_name=script_name_without_extension, script_name=script_name_without_extension, job_description=job_description.strip())

  with open(f"terraform/{terraform_file_to_write_to}", "a") as f:
    f.write(module_block)

def get_glue_job_script():
  num_jobs_copied = 0
  jobs_failed_to_copy = []
  jobs_copied = []

  jobs_to_copy = get_list_of_glue_jobs()
  print(f"Jobs to copy: {jobs_to_copy}")
  print(f"Number of jobs to copy: {len(jobs_to_copy)}")

  for job in jobs_to_copy:
    try:
      glue_job = glue_client.get_job(
        JobName=job
      )

      job_name = glue_job["Job"]["Name"]
      script_location = glue_job["Job"]["Command"]["ScriptLocation"]
      job_description = glue_job["Job"]["Description"]
      index_slash_after_bucket_name = script_location.find("/", script_location.find("/") + 2)
      script_key = script_location[index_slash_after_bucket_name + 1:]
      script_name = script_location.split("/")[-1].lower()
      script_name_without_extension = script_name.split(".")[0]

      print(f"script_location: {script_location}")
      print(f"script_key: {script_key}")
      print(f"script_name: {script_name}")
      print(f"job_description: {job_description}")
      print("-------")

      num_jobs_copied += 1
      jobs_copied.append(job)

      copy_python_script_from_s3_to_repo(bucket_name, script_key, script_name)
      add_environment_variables_to_script(script_name)
      write_terraform_glue_job(script_name, job_description)

    except Exception as err:
      print(f"Failed to copy job {job} because: {err}")
      jobs_failed_to_copy.append(job)
      print("-------")


  print(f"Number of jobs copied: {num_jobs_copied}")
  print(f"Jobs copied: {jobs_copied}")
  print(f"Jobs failed to copy: {jobs_failed_to_copy}")




get_glue_job_script()



