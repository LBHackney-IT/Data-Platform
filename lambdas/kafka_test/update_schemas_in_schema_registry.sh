#! /bin/bash

#contact details api schema
contact_details_api_schema_string=$(jq -c . ./topic-schemas/contact_details_api.json | jq -R)
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data "{ \"schema\": ${contact_details_api_schema_string} }" "http://localhost:8081/subjects/contact_details_api-value/versions"

#tenure api schema
contact_details_api_schema_string=$(jq -c . ./topic-schemas/tenure_api.json | jq -R)
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data "{ \"schema\": ${contact_details_api_schema_string} }" "http://localhost:8081/subjects/tenure_api-value/versions"
