import json
from unittest import mock
import pytest
from scripts.configure_redshift import Redshift, configure_role_inheritance

class TestConfigureRoleInheritance():

    @pytest.fixture(scope="function")
    def redshift_mock(self):
        return mock.create_autospec(Redshift)

    @pytest.fixture(scope="session")
    def terraform_output_json(self, terraform_output):
        return json.loads(terraform_output)['redshift_roles']['value'] 

    @pytest.fixture(scope="session")
    def terraform_output_with_one_role_config_json(self, terraform_output_with_one_role):
        return json.loads(terraform_output_with_one_role)['redshift_roles']['value'] 
    
    @pytest.mark.configure_role_inheritance
    def test_configure_role_inheritance_calls_execute_batch_queries_on_redshift_to_grant_a_role_access_to_other_role(self, redshift_mock, terraform_output_json):
        expected_query = ['grant role role_one to role role_two;']

        configure_role_inheritance(redshift_mock, terraform_output_json)

        redshift_mock.execute_batch_queries.assert_called_once_with(expected_query)

    @pytest.mark.configure_role_inheritance
    def test_configure_role_inheritance_ignores_roles_that_are_missing_inheritance_configuration(self, redshift_mock, terraform_output_with_one_role_config_json):
        configure_role_inheritance(redshift_mock, terraform_output_with_one_role_config_json)

        redshift_mock.execute_batch_queries.assert_not_called()
    
    @pytest.mark.configure_role_inheritance
    def test_configure_role_inheritance_outputs_message_when_role_inheritance_is_added(self, redshift_mock, terraform_output_json, capfd):
        configure_role_inheritance(redshift_mock, terraform_output_json)

        readout = capfd.readouterr()

        assert readout.out == "Applied role grants for role role_two\n"
