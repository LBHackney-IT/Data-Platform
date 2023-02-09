import pytest
import json
from scripts.configure_redshift import Redshift, revoke_role_grants
from unittest import mock

class TestRevokeRoleGrants():

    @pytest.fixture(scope="function", autouse=True)
    def boto_3_mock(self, mocker):
        return mocker.patch('scripts.configure_redshift.boto3')
    
    @pytest.fixture(scope="function")
    def terraform_output_json(self, terraform_output):
        return json.loads(terraform_output)['redshift_roles']['value']

    @pytest.fixture(scope="function")
    def query_id(self):
        return "aaa111bb-1234-1234-1234-123456789abc" 
    
    @pytest.fixture(scope="function")
    def redshift_mock(self, query_id):
        redshift_mock = mock.create_autospec(Redshift)
        redshift_mock.execute_query.return_value = query_id
        redshift_mock.get_results.return_value = [[{'stringValue': 'role_ten'}]]  
        return redshift_mock

    @pytest.mark.revoke_role_grants
    def test_revoke_role_grants_calls_execute_query_on_redshift_to_get_query_id_for_fetching_the_role_grant_results(self, redshift_mock, terraform_output_json):
        exptected_get_role_grants_query = "select granted_role_name from svv_role_grants where role_name = 'role_two';"

        revoke_role_grants(redshift_mock, terraform_output_json)

        redshift_mock.execute_query.assert_called_once_with(exptected_get_role_grants_query)

    @pytest.mark.revoke_role_grants
    def test_revoke_role_grants_calls_get_results_on_redshift_with_correct_query_id_to_get_the_current_role_grants_for_a_given_role(self, redshift_mock, terraform_output_json, query_id):
        revoke_role_grants(redshift_mock, terraform_output_json)

        redshift_mock.get_results.assert_called_once_with(query_id)
    
    @pytest.mark.revoke_role_grants
    def test_revoke_role_grants_calls_execute_batch_query_on_redshift_to_revoke_single_role_grant(self, terraform_output_json, redshift_mock):
        expected_query = ['revoke role role_ten from role role_two;']

        revoke_role_grants(redshift_mock, terraform_output_json)

        redshift_mock.execute_batch_queries.assert_called_once_with(expected_query)

    @pytest.mark.revoke_role_grants
    def test_revoke_role_grants_calls_execute_batch_query_on_redshift_to_revoke_multiple_role_grants(self, terraform_output_json, redshift_mock):
        redshift_mock.get_results.return_value = [[{'stringValue': 'role_ten'}], [{'stringValue': 'role_eleven'}]]       
        expected_query = ['revoke role role_ten from role role_two;', 'revoke role role_eleven from role role_two;']

        revoke_role_grants(redshift_mock, terraform_output_json)

        redshift_mock.execute_batch_queries.assert_called_once_with(expected_query)

    @pytest.mark.revoke_role_grants
    def test_revoke_role_grants_outputs_correct_message_when_role_grants_are_revoke(self, redshift_mock, terraform_output_json, capfd):
        redshift_mock.get_results.return_value = [[{'stringValue': 'role_ten'}], [{'stringValue': 'role_eleven'}]]      
        
        revoke_role_grants(redshift_mock, terraform_output_json)

        redout = capfd.readouterr()

        assert redout.out == "Revoked role grants: ['revoke role role_ten from role role_two;', 'revoke role role_eleven from role role_two;']\n"
