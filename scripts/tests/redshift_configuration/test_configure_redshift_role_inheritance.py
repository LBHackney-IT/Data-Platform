import json
import pytest
from scripts.configure_redshift import main, Redshift, configure_role_inheritance

class TestConfigureRoleInheritance():

    @pytest.fixture(scope="function", autouse=True)
    def boto3_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.boto3')
    
    @pytest.fixture(scope="function", autouse=True)
    def create_schemas_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.create_schemas')
    
    @pytest.fixture(scope="function", autouse=True)
    def configure_users(self, mocker):
        return mocker.patch('scripts.configure_redshift.configure_users')
    
    @pytest.fixture(scope="function", autouse=True)
    def grant_permissions_to_users(self, mocker):
        return mocker.patch('scripts.configure_redshift.grant_permissions_to_users')

    @pytest.fixture(scope="function", autouse=True)
    def grant_permissions_to_users(self, mocker):
        return mocker.patch('scripts.configure_redshift.get_roles_to_be_added')

    @pytest.fixture(scope="function")
    def configure_role_inheritance_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.configure_role_inheritance')
    
    @pytest.fixture(scope="function")
    def redshift_mock(self, mocker):
        return mocker.Mock(autospec=Redshift)

    @pytest.fixture(scope="session")
    def terraform_output_json(self, terraform_output):
        return json.loads(terraform_output)['redshift_roles']['value'] 

    @pytest.fixture(scope="session")
    def terraform_output_with_one_role_config_json(self, terraform_output_with_one_role):
        return json.loads(terraform_output_with_one_role)['redshift_roles']['value'] 

    @pytest.mark.main
    def test_main_calls_configure_role_inheritance_when_role_configuration_is_present(self, redshift_mock, terraform_output, configure_role_inheritance_mock):
        main(terraform_output, redshift_mock)
        assert configure_role_inheritance_mock.call_count == 1

    @pytest.mark.configure_role_inheritance
    def test_main_does_not_call_configure_role_inhertance_when_role_configuration_is_not_present(self, redshift_mock, terraform_output_without_roles_config, configure_role_inheritance_mock):
        main(terraform_output_without_roles_config, redshift_mock)
        assert configure_role_inheritance_mock.call_count == 0
    
    @pytest.mark.configure_role_inheritance
    def test_configure_role_inheritance_calls_execute_batch_queries_on_redshift_to_grant_a_role_access_to_other_role(self, mocker, redshift_mock, terraform_output_json):
        spy = mocker.spy(redshift_mock, "execute_batch_queries")
        expected_query = ['grant role role_one to role role_two;']

        configure_role_inheritance(redshift_mock, terraform_output_json)

        spy.assert_called_once_with(expected_query)

    @pytest.mark.configure_role_inheritance
    def test_configure_role_inheritance_ignores_roles_that_are_missing_inheritance_configuration(self, mocker, redshift_mock, terraform_output_with_one_role_config_json):
        spy = mocker.spy(redshift_mock, "execute_batch_queries")
        configure_role_inheritance(redshift_mock, terraform_output_with_one_role_config_json)

        spy.assert_not_called()
    
    @pytest.mark.configure_role_inheritance
    def test_configure_role_inheritance_outputs_message_when_role_inheritance_is_added(self, redshift_mock, terraform_output_json, capfd):
        configure_role_inheritance(redshift_mock, terraform_output_json)

        readout = capfd.readouterr()

        assert readout.out == "Applied role grants for role role_two\n"
