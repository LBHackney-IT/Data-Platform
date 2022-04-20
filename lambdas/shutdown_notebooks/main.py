import boto3

def shutdown_notebooks(_event, _lambda_context, glueClient = None, sagemakerClient = None):
    sagemaker = sagemakerClient or boto3.client("sagemaker")
    glue = glueClient or boto3.client("glue")
    # get all notebook instances
    notebooks = sagemaker.list_notebook_instances(MaxResults=100, StatusEquals='InService')['NotebookInstances']

    # stop them all
    for notebook in notebooks:
        print(f"Stopping notebook: {notebook}")
        sagemaker.stop_notebook_instance(
           NotebookInstanceName=notebook['NotebookInstanceName']
        )

    # get all dev endpoints
    endpoint_names =  glue.list_dev_endpoints(MaxResults=100)['DevEndpointNames']

    # delete them all
    for endpoint in endpoint_names:
        print(f"Deleting endpoint: {endpoint}")
        glue.delete_dev_endpoint(EndpointName=endpoint)

if __name__ == '__main__':
    shutdown_notebooks('event','lambda_context')
