import pytest, json
from scripts.configure_redshift import Redshift, main, grant_permissions_to_roles
from unittest.mock import call

class TestConfigureRolePermissions():

    @pytest.fixture(scope="function")
    def grant_permissions_to_roles_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.create_roles')

    @pytest.fixture(scope="function")
    def redshift_mock(self, mocker):
        return mocker.Mock(autospec=Redshift)

    @pytest.fixture(scope="function", autouse=True)
    def boto3_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.boto3')
    
    @pytest.fixture(scope="function", autouse=True)
    def create_roles_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.create_roles')

    @pytest.fixture(scope="function")
    def grant_permissions_to_roles_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.grant_permissions_to_roles')

    @pytest.fixture(scope="function", autouse=True)
    def create_schemas_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.create_schemas')
    
    @pytest.fixture(scope="function", autouse=True)
    def configure_users(self, mocker):
        return mocker.patch('scripts.configure_redshift.configure_users')
    
    @pytest.fixture(scope="function", autouse=True)
    def grant_permissions_to_users(self, mocker):
        return mocker.patch('scripts.configure_redshift.grant_permissions_to_users')

    @pytest.fixture(scope="session")
    def terraform_output_json(self, terraform_output):
        return json.loads(terraform_output)['redshift_roles']['value'] 

    #main
    @pytest.mark.main
    def test_main_calls_grant_permissions_to_roles_when_roles_config_is_present(self, terraform_output, redshift_mock, grant_permissions_to_roles_mock):
        main(terraform_output, redshift_mock)

        assert grant_permissions_to_roles_mock.call_count == 1
    
    @pytest.mark.main
    def test_main_skips_grant_permissions_to_roles_when_roles_configuration_not_present(self, terraform_output_without_roles_config, redshift_mock, grant_permissions_to_roles_mock):
        main(terraform_output_without_roles_config, redshift_mock)

        assert grant_permissions_to_roles_mock.call_count == 0

    #grant_permissions_to_roles
    @pytest.mark.grant_permissions_to_roles
    def test_grant_permissions_to_roles_calls_execute_query_on_redshift_to_grant_temp_permissions_to_database_when_config_is_present(self, mocker, redshift_mock, terraform_output):
        role_name_one = "role_one"
        role_name_two = "role_two"
        spy = mocker.spy(redshift_mock, "execute_query")
        expected_query_one = f"grant temp on database {redshift_mock.database_name} to role {role_name_one};"
        expected_query_two = f"grant temp on database {redshift_mock.database_name} to role {role_name_two};"
        
        main(terraform_output, redshift_mock)

        spy.assert_any_call(expected_query_one) 
        spy.assert_any_call(expected_query_two) 

    @pytest.mark.grant_permissions_to_roles
    def test_grant_permissions_to_roles_calls_execute_batch_queries_on_redshift_to_grant_schema_permissions_when_config_is_present(self, mocker, redshift_mock, terraform_output):
        spy = mocker.spy(redshift_mock, "execute_batch_queries")

        expected_queries_for_role_one = ['grant usage on schema schema_one to role role_one;',
                                         'grant usage on schema schema_two to role role_one;',
                                         'grant usage on schema schema_three to role role_one;']
        
        expected_queries_for_role_two = ['grant usage on schema schema_four to role role_two;',
                                         'grant usage on schema schema_five to role role_two;',
                                         'grant usage on schema schema_six to role role_two;']

        main(terraform_output, redshift_mock)

        spy.assert_any_call(expected_queries_for_role_one)
        spy.assert_any_call(expected_queries_for_role_two)

    @pytest.mark.grant_permissions_to_roles
    def test_grant_permissions_to_roles_calls_execute_batch_queries_on_redshift_to_grant_table_permissions_on_allowed_schemas(self, mocker, redshift_mock, terraform_output):
        spy = mocker.spy(redshift_mock, "execute_batch_queries")

        expected_queries_for_role_one = ['grant select on all tables in schema schema_one to role role_one;',
                                         'grant select on all tables in schema schema_two to role role_one;',
                                         'grant select on all tables in schema schema_three to role role_one;']

        expected_queries_for_role_two = ['grant select on all tables in schema schema_four to role role_two;', 'grant select on all tables in schema schema_five to role role_two;', 'grant select on all tables in schema schema_six to role role_two;']

        main(terraform_output, redshift_mock)

        spy.assert_any_call(expected_queries_for_role_one)
        spy.assert_any_call(expected_queries_for_role_two)
    
    @pytest.mark.grant_permissions_to_roles
    def test_grant_permissions_roles_calls_redshift_with_queries_in_the_correct_order(self, redshift_mock, terraform_output_with_one_role):
        expected_temp_database_access_query = f"grant temp on database {redshift_mock.database_name} to role role_one;"
        expected_schema_usage_query         = ['grant usage on schema schema_one to role role_one;']
        expected_table_access_query         = ['grant select on all tables in schema schema_one to role role_one;']

        main(terraform_output_with_one_role, redshift_mock)

        expected_calls = [
            call.execute_query(expected_temp_database_access_query),
            call.execute_batch_queries(expected_schema_usage_query),
            call.execute_batch_queries(expected_table_access_query)
            ]

        redshift_mock.assert_has_calls(expected_calls, any_order=False)

    @pytest.mark.grant_permissions_to_roles
    def test_graant_permissions_to_roles_outputs_message_when_roles_were_created(self, redshift_mock, terraform_output_json, capfd):
        grant_permissions_to_roles(redshift_mock, terraform_output_json)

        readout = capfd.readouterr()

        assert readout.out == "Granted permissions for roles: role_one, role_two\n"
