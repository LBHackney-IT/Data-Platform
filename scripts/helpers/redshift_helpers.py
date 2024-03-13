from helpers import get_secret_dict
from typing import List, Dict, Optional
import redshift_connector

def rs_command(query: str, fetch_results: bool = False, allow_commit: bool = True, database_name: str = 'academy') -> Optional[List[Dict]]:
   """Executes a SQL query against a Redshift database, optionally fetching results.

   Args:
       query (str): The SQL query to execute.
       fetch_results (bool): Whether to fetch and return the query results (default False).
       allow_commit (bool): Whether to allow committing the transaction (default True).
       database_name: Name of the database to connect to, defaults to 'academy'.

   Returns:
       Optional[List[Dict]]: A list of dictionaries representing rows returned by the query if fetch_results is True; otherwise None.
   """
   creds = get_secret_dict('/data-and-insight/redshift-serverless-connection', 'eu-west-2')
   try:
       # Connects to Redshift cluster using AWS credentials
       conn = redshift_connector.connect(
           host=creds['host'],
           database=database_name,
           user=creds['user'],
           password=creds['password']
       )
       
       # Following the DB-API specification, autocommit is off by default. 
       # https://pypi.org/project/redshift-connector/
       if allow_commit:
           # Add this line to handle commands like CREATE EXTERNAL TABLE
           conn.autocommit = True

       cursor = conn.cursor()

       # Execute the query
       cursor.execute(query)
       
       # Fetch the results if required
       if fetch_results:
           result = cursor.fetchall()
           return [dict(row) for row in result] if result else []
       elif allow_commit:
           # Commit the transaction only if allowed and needed
           conn.commit()

   except redshift_connector.Error as e:
       raise e
   finally:
       if cursor:
           cursor.close()
       if conn:
           conn.close()
   return None  # Return None if fetch_results is False or if there's an error