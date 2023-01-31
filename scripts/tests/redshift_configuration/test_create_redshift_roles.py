import pytest
from scripts.configure_redshift import create_roles, get_role_names_from_configuration, get_roles_to_be_added, main, Redshift
import json

class TestCreateRedshiftRoles():

    @pytest.fixture(scope='function')
    def redshift_mock(self, mocker):
        return mocker.Mock(spec=Redshift)

    #boto3 is not relevant here, so patch it automatically for every test
    @pytest.fixture(scope='function', autouse=True)
    def boto3_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.boto3')

    @pytest.fixture(scope='function')
    def create_roles_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.create_roles')

    @pytest.fixture(scope='function', autouse=True)
    def get_roles_to_be_added_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.get_roles_to_be_added')

    @pytest.fixture(scope='function')
    def get_role_names_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.get_role_names_from_configuration')     

    @pytest.fixture(scope='session')
    def terraform_output_json(self, terraform_output):
        return json.loads(terraform_output)['redshift_roles']['value']   

    @pytest.fixture(scope="function", autouse=True)
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
        return mocker.patch('scripts.configure_redshift.configure_users')

    #main
    @pytest.mark.main
    def test_main_skips_create_roles_if_role_configuration_not_present(self, terraform_output_without_roles_config, redshift_mock, create_roles_mock):
        main(terraform_output_without_roles_config, redshift_mock)
        
        assert create_roles_mock.call_count == 0

    @pytest.mark.main
    def test_main_outputs_a_message_when_roles_configuration_not_present(self, terraform_output_without_roles_config, capfd, redshift_mock):
        main(terraform_output_without_roles_config, redshift_mock)

        readout = capfd.readouterr()
        assert readout.out == "No role configuration found\n"    

    @pytest.mark.main
    def test_main_calls_create_roles_with_role_configuration(self, terraform_output, redshift_mock, create_roles_mock, terraform_output_json):
        main(terraform_output, redshift_mock)    
        
        create_roles_mock.assert_called_once_with(redshift_mock, terraform_output_json)

    #get_role_names
    @pytest.mark.get_role_names
    def test_get_role_names_returns_comma_separated_string(self, terraform_output_json):
        assert get_role_names_from_configuration(terraform_output_json) ==  "'role_one','role_two'"

    @pytest.mark.get_role_names
    def test_get_role_names_returns_empty_string_when_input_list_is_empty(self):
        assert get_role_names_from_configuration([]) == ""

    #ceate_roles
    @pytest.mark.create_roles
    def test_create_roles_calls_get_role_names_when_roles_list_is_not_empty(self, redshift_mock, get_role_names_mock, terraform_output_json):
        create_roles(redshift_mock, terraform_output_json)

        assert get_role_names_mock.call_count == 1

    @pytest.mark.create_roles
    def test_create_roles_calls_execute_query_on_redshift_with_correct_params_when_provided_roles_list_is_valid(self, mocker, redshift_mock, terraform_output_json):
        spy = mocker.spy(redshift_mock, "execute_query")
        expected_query = "select role_name from svv_roles where role_name in('role_one','role_two');"
        
        create_roles(redshift_mock, terraform_output_json)

        spy.assert_called_once_with(expected_query)
    
    @pytest.mark.create_roles
    def test_create_roles_calls_get_results_on_redshift_with_correct_query_id(self, mocker, redshift_mock, terraform_output_json):
        spy = mocker.spy(redshift_mock, "get_results")
        redshift_mock.execute_query.side_effect = "1"

        create_roles(redshift_mock, terraform_output_json)

        spy.assert_called_once_with("1")

    @pytest.mark.create_roles
    def test_create_roles_calls_get_roles_to_be_added(self, redshift_mock, get_roles_to_be_added_mock, terraform_output_json):
        create_roles(redshift_mock, terraform_output_json)

        assert get_roles_to_be_added_mock.call_count == 1

    @pytest.mark.create_roles
    def test_create_roles_calls_execute_batch_queries_on_redshift_when_there_are_new_roles_to_be_added(self, mocker, capfd, redshift_mock, terraform_output_json):
        spy = mocker.spy(redshift_mock, "execute_batch_queries")
        mocker.patch('scripts.configure_redshift.get_roles_to_be_added', return_value=['role_three'])
        expected_query = ['CREATE ROLE role_three']
        
        create_roles(redshift_mock, terraform_output_json)
    
        spy.assert_called_once_with(expected_query)
        readout = capfd.readouterr()

        assert readout.out == "Added following roles: ['role_three']\n"
    
    @pytest.mark.create_roles
    def test_create_roles_outputs_newly_added_roles(self, mocker, capfd, redshift_mock, terraform_output_json):
        mocker.patch('scripts.configure_redshift.get_roles_to_be_added', return_value=['role_one','role_two'])
        
        create_roles(redshift_mock, terraform_output_json)

        readout = capfd.readouterr()
        assert readout.out == "Added following roles: ['role_one', 'role_two']\n"
    
    @pytest.mark.create_roles
    def test_create_roles_outputs_notification_when_no_roles_to_be_added(self, mocker, capfd, redshift_mock, terraform_output_json):
        mocker.patch('scripts.configure_redshift.get_roles_to_be_added', return_value=[])
        
        create_roles(redshift_mock, terraform_output_json)

        readout = capfd.readouterr()
        assert readout.out == "No roles to be added\n"

    #get_roles
    @pytest.mark.get_roles
    def test_get_roles_to_be_added_returns_list_of_new_roles(self):
        new_roles_to_be_added = ['role_four', 'role_five']
        roles_config = """'role_one','role_two','role_three','role_four','role_five'"""
        
        #based on a return value from existing function
        existing_roles_in_redshift = [
                [
                    {'stringValue': 'role_one'}
                ], 
                [
                    {'stringValue': 'role_two'}
                ],
                [
                    {'stringValue': 'role_three'}
                ]
            ]

        #order doesn't matter, so just check that lists have the same items
        assert sorted(get_roles_to_be_added(existing_roles_in_redshift, roles_config)) == sorted(new_roles_to_be_added)
   