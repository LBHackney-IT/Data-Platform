import pytest
from pyspark.sql import SparkSession
import os

@pytest.fixture(scope='session')
def spark():
  event_log_dir = os.path.dirname(__file__) + '/../spark_events'
  s = SparkSession.builder.config("spark.eventLog.dir", event_log_dir).config("spark.eventLog.enabled", True).master("local").getOrCreate()
  yield s
  s.stop()

#redshift configuration test setup
def pytest_configure(config):
    config.addinivalue_line("markers", "grant_permissions_to_roles: mark tests for grant_permissions_to_roles function")
    config.addinivalue_line("markers", "main: mark tests for main function")
    config.addinivalue_line("markers", "create_roles: mark tests for create roles function")
    config.addinivalue_line("markers", "get_role_names: mark tests for get role names function")
    config.addinivalue_line("markers", "get_roles: mark tests for get roles function")
    config.addinivalue_line("markers", "configure_role_inheritance: mark tests for configure role inheritance function")

@pytest.fixture(scope='session')
def terraform_output():
  return """{
            "redshift_cluster_id": {
                "value": "redshift-cluster"
            },
            "redshift_iam_role_arn": {
                "value": "arn:aws:iam::role"
            },
            "redshift_schemas": {
                "value": []
            },
            "redshift_users": {
                "value": []
            },
            "redshift_roles": {
                "value": [
                    {
                        "role_name": "role_one",
                        "schemas_to_grant_access_to": [
                            "schema_one",
                            "schema_two",
                            "schema_three"
                        ]
                    },
                    {
                        "role_name": "role_two",
                        "roles_to_inherit_permissions_from": [
                            "role_one"
                        ],
                        "schemas_to_grant_access_to": [
                            "schema_four",
                            "schema_five",
                            "schema_six"
                        ]
                    }
                ]
            }
    }"""

@pytest.fixture(scope="session")
def terraform_output_with_one_role():
  return """{
            "redshift_cluster_id": {
                "value": "redshift-cluster"
            },
            "redshift_iam_role_arn": {
                "value": "arn:aws:iam::role"
            },
            "redshift_schemas": {
                "value": []
            },
            "redshift_users": {
                "value": []
            },
            "redshift_roles": {
                "value": [
                    {
                        "role_name": "role_one",
                        "schemas_to_grant_access_to": [
                            "schema_one"
                        ]
                    }
                ]
            }
    }"""

@pytest.fixture(scope='session')
def terraform_output_without_roles_config():
  return """{
          "redshift_cluster_id": {
              "value": "redshift-cluster"
          },
          "redshift_iam_role_arn": {
              "value": "arn:aws:iam::role"
          },
          "redshift_schemas": {
              "value": []
          },
          "redshift_users": {
              "value": []
          }
  }"""
