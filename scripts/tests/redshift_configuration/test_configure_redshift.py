from unittest import mock
import pytest
from scripts.configure_redshift import main, Redshift

class TestConfigureRedshift():

    @pytest.fixture(scope="function", autouse=True)
    def boto3_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.boto3')
    
    @pytest.fixture(scope="function")
    def redshift_mock(self):
        return mock.create_autospec(Redshift)

    @pytest.fixture(scope="function", autouse=True)
    def create_schemas_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.create_schemas')

    @pytest.fixture(scope="function", autouse=True)
    def configure_users_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.configure_users')

    @pytest.fixture(scope="function", autouse=True)
    def create_roles_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.create_roles')

    @pytest.fixture(scope="function", autouse=True)
    def grant_permissions_to_roles_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.grant_permissions_to_roles')   

    # @pytest.fixture(scope="function", autouse=True)
    # def configure_role_inheritance_mock(self, mocker):
    #     return mocker.patch('scripts.configure_redshift.configure_role_inheritance')

    # @pytest.fixture(scope="function", autouse=True)
    # def revoke_role_grants_mock(self, mocker):
    #     return mocker.patch('scripts.configure_redshift.revoke_role_grants')

    @pytest.mark.main
    def test_main_skips_create_roles_if_role_configuration_not_present(self, terraform_output_without_roles_config, redshift_mock, create_roles_mock):
        main(terraform_output_without_roles_config, redshift_mock)
        assert create_roles_mock.call_count == 0
    
    @pytest.mark.main
    def test_main_calls_create_roles_if_role_configuration_not_present(self, terraform_output, redshift_mock, create_roles_mock):
        main(terraform_output, redshift_mock)
        assert create_roles_mock.call_count == 1

    @pytest.mark.main
    def test_main_skips_grant_permissions_to_roles_when_roles_config_not_present(self, terraform_output_without_roles_config, redshift_mock, grant_permissions_to_roles_mock):
        main(terraform_output_without_roles_config, redshift_mock)
        assert grant_permissions_to_roles_mock.call_count == 0
    
    @pytest.mark.main
    def test_main_calls_grant_permissions_to_roles_when_roles_config_is_present(self, terraform_output, redshift_mock, grant_permissions_to_roles_mock):
        main(terraform_output, redshift_mock)
        assert grant_permissions_to_roles_mock.call_count == 1

    @pytest.mark.main
    def test_main_calls_configure_role_inheritance_when_role_configuration_is_present(self, redshift_mock, terraform_output, configure_role_inheritance_mock):
        main(terraform_output, redshift_mock)
        assert configure_role_inheritance_mock.call_count == 1

    @pytest.mark.main
    def test_main_skips_call_configure_role_inhertance_when_role_configuration_is_not_present(self, redshift_mock, terraform_output_without_roles_config, configure_role_inheritance_mock):
        main(terraform_output_without_roles_config, redshift_mock)
        assert configure_role_inheritance_mock.call_count == 0
    
    @pytest.mark.main
    def test_main_skips_revoke_role_grants_when_role_configuration_is_present(self, redshift_mock, terraform_output_without_roles_config, revoke_role_grants_mock):
        main(terraform_output_without_roles_config, redshift_mock)
        assert revoke_role_grants_mock.call_count == 0

    @pytest.mark.main
    def test_main_calls_revoke_role_grants_when_role_configuration_is_present(self, redshift_mock, terraform_output, revoke_role_grants_mock):
        main(terraform_output, redshift_mock)
        assert revoke_role_grants_mock.call_count == 1
