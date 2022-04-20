from unittest import TestCase
import botocore.session
from botocore.stub import Stubber

from shutdown_notebooks.main import shutdown_notebooks


class ShutdownNotebookInstancesTests(TestCase):
  def setUp(self) -> None:
    self.boto_session = botocore.session.get_session()
    self.boto_session.set_credentials("", "")
    
    self.glue = self.boto_session.create_client('glue', region_name='eu-west-2')
    self.glueStubber = Stubber(self.glue)

    self.sagemaker = self.boto_session.create_client('sagemaker', region_name='eu-west-2')
    self.sagemakerStubber = Stubber(self.sagemaker)
    return super().setUp()

  def stub_list_notebooks(self, notebook_names):
    response = {
        'NotebookInstances': [
          { 'NotebookInstanceName': name, 'NotebookInstanceArn': f"aws::arn::sagemaker:::notebook/{name}" } for name in notebook_names
        ]
    }
    self.sagemakerStubber.add_response('list_notebook_instances', response, {'MaxResults': 100, 'StatusEquals': 'InService'})
  
  def stub_stop_notebook(self, notebook_name):
    self.sagemakerStubber.add_response('stop_notebook_instance', {}, {'NotebookInstanceName': notebook_name})

  def stub_list_devlopment_endpoints(self, endpoint_names):
    response = {
      'DevEndpointNames': endpoint_names
    }
    self.glueStubber.add_response('list_dev_endpoints', response, {'MaxResults': 100})

  def stub_delete_devlopment_endpoint(self, endpoint_name):
    self.glueStubber.add_response('delete_dev_endpoint', {}, {'EndpointName': endpoint_name})
  
  def activate_stubbers(self):
    self.sagemakerStubber.activate()
    self.glueStubber.activate()


  def test_gets_stops_all_running_notebooks(self):
    my_notebooks = ["shiny_notebooks", "book_of_works", "record_the_trees"]
    self.stub_list_notebooks(my_notebooks)
    self.stub_list_devlopment_endpoints([])

    for notebook in my_notebooks:
      self.stub_stop_notebook(notebook)
    
    self.activate_stubbers()
    shutdown_notebooks({}, {}, self.glue, self.sagemaker)
    self.sagemakerStubber.assert_no_pending_responses()

  def test_gets_stops_any_running_notebooks(self):
    my_notebooks = ["parking", "housing", "tenures"]
    self.stub_list_notebooks(my_notebooks)
    self.stub_list_devlopment_endpoints([])

    for notebook in my_notebooks:
      self.stub_stop_notebook(notebook)
    
    self.activate_stubbers()
    shutdown_notebooks({}, {}, self.glue, self.sagemaker)
    self.sagemakerStubber.assert_no_pending_responses()

  def test_removes_all_dev_endpoints(self):
    my_endpoints = ["development", "my_secondary_endpoint"]
    self.stub_list_devlopment_endpoints(my_endpoints)
    self.stub_list_notebooks([])

    for endpoint in my_endpoints:
      self.stub_delete_devlopment_endpoint(endpoint)
    
    self.activate_stubbers()
    shutdown_notebooks({}, {}, self.glue, self.sagemaker)
    self.glueStubber.assert_no_pending_responses()


