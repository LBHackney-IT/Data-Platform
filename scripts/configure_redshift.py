import boto3
import sys
import json
from time import sleep
from itertools import islice

from botocore.client import BaseClient


def chunk_list(lst, size):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), size):
        yield lst[i:i + size]


def chunk_list_2(lst, size):
    lst = iter(lst)
    return iter(lambda: list(islice(lst, size)), ())


class Redshift:
    def __init__(self, redshift_client, cluster_id, redshift_role, admin_user, database_name):
        self.redshift_client = redshift_client
        self.cluster_id = cluster_id
        self.role = redshift_role
        self.admin_user = admin_user
        self.database_name = database_name

    def execute_query(self, sql):
        response = self.redshift_client.execute_statement(
            ClusterIdentifier=self.cluster_id,
            Database=self.database_name,
            DbUser=self.admin_user,
            Sql=sql
        )
        status = ""
        while status != "FINISHED":
            query = self.describe_query(response['Id'])
            status = query['Status']

            if query['Status'] == "FAILED":
                print(f"query failed with error {query['Error']}")
                raise Exception(f"query failed with error {query['Error']}")
            print(query)
            sleep(0.5)
        return response['Id']

    def execute_batch_queries(self, sqls: list):
        chunks = list(chunk_list(sqls, 10))
        for chunk in chunks:
            self.execute_batch_queries_sub(chunk)

    def execute_batch_queries_sub(self, sqls: list):
        response = self.redshift_client.batch_execute_statement(
            ClusterIdentifier=self.cluster_id,
            Database=self.database_name,
            DbUser=self.admin_user,
            Sqls=sqls
        )
        finished = False
        while not finished:
            query = self.describe_query(response['Id'])
            finished = all([sub_statement['Status'] == "FINISHED" for sub_statement in query['SubStatements']])
            failed_queries = [sub_statement for sub_statement in query['SubStatements'] if
                              sub_statement['Status'] == "FAILED" or sub_statement['Status'] == "ABORTED"]

            if len(failed_queries) > 0:
                print(f"{len(failed_queries)} queries failed with errors:")
                for query in failed_queries:
                    print(query)
                raise Exception(f"Some queries failed.")
            print(query)
            sleep(0.5)
        return response['Id']

    def get_results(self, statement_id):
        result = self.redshift_client.get_statement_result(Id=statement_id)
        records = result['Records']
        next_token = result.get('NextToken')
        while next_token:
            result = self.redshift_client.get_statement_result(Id=statement_id, NextToken=next_token)
            records = records + result['Records']
            next_token = result.get('NextToken')

        return records

    def describe_query(self, statement_id):
        response = self.redshift_client.describe_statement(
            Id=statement_id
        )
        return response


def create_schemas(redshift, schemas: dict) -> None:
    create_schema_queries = [f"CREATE EXTERNAL SCHEMA IF NOT EXISTS {schema}" +
                             " FROM DATA CATALOG" +
                             " DATABASE '{database}'" +
                             " IAM_ROLE '{redshift.role}'" +
                             " CREATE EXTERNAL DATABASE IF NOT EXISTS;" for schema, database in schemas.items()]

    redshift.execute_batch_queries(create_schema_queries)
    print(f"Created schemas")


def get_users(redshift) -> list:
    get_users_query = "select usename from pg_user_info"

    get_users_query_id = redshift.execute_query(get_users_query)

    return [record[0]['stringValue'] for record in redshift.get_results(get_users_query_id)]


def get_password(secrets_manager: BaseClient, secret_arn: str) -> str:
    response = secrets_manager.get_secret_value(
        SecretId=secret_arn,
    )
    if 'SecretString' in response:
        secret = json.loads(response['SecretString'])
        return secret['Password']
    else:
        raise Exception(f"Couldn't find a password for the secret arn {secret_arn}")


def create_users(redshift, logins: list) -> None:
    if len(logins) == 0:
        print("No users to create")
        return
    create_user_queries = [f"CREATE USER {login['user']} WITH PASSWORD '{login['password']}'" for login in logins]

    redshift.execute_batch_queries(create_user_queries)


def update_passwords(redshift, logins: list) -> None:
    if len(logins) == 0:
        print("No users to update")
        return
    alter_password_queries = [f"ALTER USER {login['user']} WITH PASSWORD '{login['password']}'" for login in logins]

    redshift.execute_batch_queries(alter_password_queries)


def configure_users(redshift, secrets_manager: BaseClient, users: list) -> None:
    logins = [{'user': user['user_name'], 'password': get_password(secrets_manager, user['secret_arn'])} for user in users]
    existing_usernames = get_users(redshift)

    existing_users_with_passwords = [login for login in logins if login["user"] in existing_usernames]
    update_passwords(redshift, existing_users_with_passwords)

    new_users_with_password = [login for login in logins if login["user"] not in existing_usernames]
    create_users(redshift, new_users_with_password)


def grant_permissions_to_users(redshift, users: list) -> None:
    for user in users:
        username = user["user_name"]
        grant_temp_permissions = f"GRANT temp ON DATABASE {redshift.database_name} TO {username};"
        redshift.execute_query(grant_temp_permissions)

        grant_schema_permissions = [f"GRANT USAGE ON SCHEMA {schema} TO {username};" for schema in
                                    user["schemas_to_grant_access_to"]]
        grant_table_permissions = [f"GRANT SELECT ON ALL TABLES IN SCHEMA {schema} TO {username};" for schema in
                                   user["schemas_to_grant_access_to"]]

        redshift.execute_batch_queries(grant_schema_permissions)
        redshift.execute_batch_queries(grant_table_permissions)
        print(f"Add permissions for user {username}")
    return


def main() -> None:
    secrets_manager: BaseClient = boto3.client('secretsmanager')
    terraform_outputs_json = sys.argv[1]

    terraform_outputs = json.loads(terraform_outputs_json)

    cluster_id = terraform_outputs['redshift_cluster_id']['value']
    redshift_iam_role = terraform_outputs['redshift_iam_role_arn']['value']

    redshift_client = boto3.client('redshift-data')

    redshift = Redshift(
        cluster_id=cluster_id,
        redshift_client=redshift_client,
        redshift_role=redshift_iam_role,
        admin_user="data_engineers",
        database_name="data_platform"
    )

    create_schemas(redshift, terraform_outputs['redshift_schemas']['value'])
    configure_users(redshift, secrets_manager, terraform_outputs['redshift_users']['value'])
    grant_permissions_to_users(redshift, terraform_outputs['redshift_users']['value'])


main()
