OUTPUT='{
  "arn": {
    "sensitive": false,
    "type": "string",
    "value": ""
  },
  "identity_store_id": {
    "sensitive": false,
    "type": "string",
    "value": ""
  },
  "network_vpc_arn": {
    "sensitive": false,
    "type": "string",
    "value": "arn:aws:ec2:eu-west-2:484466746276:vpc/vpc-076a7c128ec4a2cf9"
  },
  "network_vpc_subnet_cider_blocks": {
    "sensitive": false,
    "type": [
      "tuple",
      [
        "string",
        "string",
        "string"
      ]
    ],
    "value": [
      "10.120.30.128/26",
      "10.120.30.64/26",
      "10.120.30.0/26"
    ]
  },
  "network_vpc_subnets": {
    "sensitive": false,
    "type": [
      "set",
      "string"
    ],
    "value": [
      "subnet-03982d71297d968ca",
      "subnet-09de42c945f5507df",
      "subnet-0c1bd8eaff9d7fd96"
    ]
  },
  "redshift_cluster_id": {
    "sensitive": false,
    "type": "string",
    "value": ""
  },
  "redshift_iam_role_arn": {
    "sensitive": false,
    "type": "string",
    "value": ""
  },
  "redshift_schemas": {
    "sensitive": false,
    "type": [
      "object",
      {
        "dataplatform_joates_tascomi_refined_zone": "string",
        "joates_bens_housing_needs_raw_zone": "string",
        "joates_bens_housing_needs_refined_zone": "string",
        "joates_bens_housing_needs_trusted_zone": "string",
        "joates_data_and_insight_raw_zone": "string",
        "joates_data_and_insight_refined_zone": "string",
        "joates_data_and_insight_trusted_zone": "string",
        "joates_env_enforcement_raw_zone": "string",
        "joates_env_enforcement_refined_zone": "string",
        "joates_env_enforcement_trusted_zone": "string",
        "joates_env_services_raw_zone": "string",
        "joates_env_services_refined_zone": "string",
        "joates_env_services_trusted_zone": "string",
        "joates_finance_raw_zone": "string",
        "joates_finance_refined_zone": "string",
        "joates_finance_trusted_zone": "string",
        "joates_housing_raw_zone": "string",
        "joates_housing_refined_zone": "string",
        "joates_housing_repairs_raw_zone": "string",
        "joates_housing_repairs_refined_zone": "string",
        "joates_housing_repairs_trusted_zone": "string",
        "joates_housing_trusted_zone": "string",
        "joates_parking_raw_zone": "string",
        "joates_parking_refined_zone": "string",
        "joates_parking_trusted_zone": "string",
        "joates_planning_raw_zone": "string",
        "joates_planning_refined_zone": "string",
        "joates_planning_trusted_zone": "string",
        "joates_revenues_raw_zone": "string",
        "joates_revenues_refined_zone": "string",
        "joates_revenues_trusted_zone": "string",
        "joates_unrestricted_raw_zone": "string",
        "joates_unrestricted_refined_zone": "string",
        "joates_unrestricted_trusted_zone": "string",
        "liberator_raw_zone": "string",
        "liberator_refined_zone": "string",
        "parking_raw_zone_liberator": "string",
        "parking_refined_zone_liberator": "string"
      }
    ],
    "value": {
      "dataplatform_joates_tascomi_refined_zone": "dataplatform-joates-tascomi-refined-zone",
      "joates_bens_housing_needs_raw_zone": "joates-bens-housing-needs-raw-zone",
      "joates_bens_housing_needs_refined_zone": "joates-bens-housing-needs-refined-zone",
      "joates_bens_housing_needs_trusted_zone": "joates-bens-housing-needs-trusted-zone",
      "joates_data_and_insight_raw_zone": "joates-data-and-insight-raw-zone",
      "joates_data_and_insight_refined_zone": "joates-data-and-insight-refined-zone",
      "joates_data_and_insight_trusted_zone": "joates-data-and-insight-trusted-zone",
      "joates_env_enforcement_raw_zone": "joates-env-enforcement-raw-zone",
      "joates_env_enforcement_refined_zone": "joates-env-enforcement-refined-zone",
      "joates_env_enforcement_trusted_zone": "joates-env-enforcement-trusted-zone",
      "joates_env_services_raw_zone": "joates-env-services-raw-zone",
      "joates_env_services_refined_zone": "joates-env-services-refined-zone",
      "joates_env_services_trusted_zone": "joates-env-services-trusted-zone",
      "joates_finance_raw_zone": "joates-finance-raw-zone",
      "joates_finance_refined_zone": "joates-finance-refined-zone",
      "joates_finance_trusted_zone": "joates-finance-trusted-zone",
      "joates_housing_raw_zone": "joates-housing-raw-zone",
      "joates_housing_refined_zone": "joates-housing-refined-zone",
      "joates_housing_repairs_raw_zone": "joates-housing-repairs-raw-zone",
      "joates_housing_repairs_refined_zone": "joates-housing-repairs-refined-zone",
      "joates_housing_repairs_trusted_zone": "joates-housing-repairs-trusted-zone",
      "joates_housing_trusted_zone": "joates-housing-trusted-zone",
      "joates_parking_raw_zone": "joates-parking-raw-zone",
      "joates_parking_refined_zone": "joates-parking-refined-zone",
      "joates_parking_trusted_zone": "joates-parking-trusted-zone",
      "joates_planning_raw_zone": "joates-planning-raw-zone",
      "joates_planning_refined_zone": "joates-planning-refined-zone",
      "joates_planning_trusted_zone": "joates-planning-trusted-zone",
      "joates_revenues_raw_zone": "joates-revenues-raw-zone",
      "joates_revenues_refined_zone": "joates-revenues-refined-zone",
      "joates_revenues_trusted_zone": "joates-revenues-trusted-zone",
      "joates_unrestricted_raw_zone": "joates-unrestricted-raw-zone",
      "joates_unrestricted_refined_zone": "joates-unrestricted-refined-zone",
      "joates_unrestricted_trusted_zone": "joates-unrestricted-trusted-zone",
      "liberator_raw_zone": "dataplatform-joates-liberator-raw-zone",
      "liberator_refined_zone": "dataplatform-joates-liberator-refined-zone",
      "parking_raw_zone_liberator": "dataplatform-joates-liberator-raw-zone",
      "parking_refined_zone_liberator": "dataplatform-joates-liberator-refined-zone"
    }
  },
  "redshift_users": {
    "sensitive": false,
    "type": [
      "tuple",
      [
        [
          "object",
          {
            "schemas_to_grant_access_to": [
              "tuple",
              [
                "string",
                "string",
                "string",
                "string",
                "string",
                "string"
              ]
            ],
            "secret_arn": "string",
            "user_name": "string"
          }
        ],
        [
          "object",
          {
            "schemas_to_grant_access_to": [
              "tuple",
              [
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string"
              ]
            ],
            "secret_arn": "string",
            "user_name": "string"
          }
        ],
        [
          "object",
          {
            "schemas_to_grant_access_to": [
              "tuple",
              [
                "string",
                "string",
                "string",
                "string",
                "string",
                "string"
              ]
            ],
            "secret_arn": "string",
            "user_name": "string"
          }
        ],
        [
          "object",
          {
            "schemas_to_grant_access_to": [
              "tuple",
              [
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string"
              ]
            ],
            "secret_arn": "string",
            "user_name": "string"
          }
        ],
        [
          "object",
          {
            "schemas_to_grant_access_to": [
              "tuple",
              [
                "string",
                "string",
                "string",
                "string",
                "string",
                "string"
              ]
            ],
            "secret_arn": "string",
            "user_name": "string"
          }
        ],
        [
          "object",
          {
            "schemas_to_grant_access_to": [
              "tuple",
              [
                "string",
                "string",
                "string",
                "string",
                "string",
                "string",
                "string"
              ]
            ],
            "secret_arn": "string",
            "user_name": "string"
          }
        ],
        [
          "object",
          {
            "schemas_to_grant_access_to": [
              "tuple",
              [
                "string",
                "string",
                "string",
                "string",
                "string",
                "string"
              ]
            ],
            "secret_arn": "string",
            "user_name": "string"
          }
        ],
        [
          "object",
          {
            "schemas_to_grant_access_to": [
              "tuple",
              [
                "string",
                "string",
                "string",
                "string",
                "string",
                "string"
              ]
            ],
            "secret_arn": "string",
            "user_name": "string"
          }
        ],
        [
          "object",
          {
            "schemas_to_grant_access_to": [
              "tuple",
              [
                "string",
                "string",
                "string",
                "string",
                "string",
                "string"
              ]
            ],
            "secret_arn": "string",
            "user_name": "string"
          }
        ],
        [
          "object",
          {
            "schemas_to_grant_access_to": [
              "tuple",
              [
                "string",
                "string",
                "string",
                "string",
                "string",
                "string"
              ]
            ],
            "secret_arn": "string",
            "user_name": "string"
          }
        ],
        [
          "object",
          {
            "schemas_to_grant_access_to": [
              "tuple",
              [
                "string",
                "string",
                "string",
                "string",
                "string",
                "string"
              ]
            ],
            "secret_arn": "string",
            "user_name": "string"
          }
        ]
      ]
    ],
    "value": [
      {
        "schemas_to_grant_access_to": [
          "joates_housing_repairs_raw_zone",
          "joates_housing_repairs_refined_zone",
          "joates_housing_repairs_trusted_zone",
          "joates_unrestricted_raw_zone",
          "joates_unrestricted_refined_zone",
          "joates_unrestricted_trusted_zone"
        ],
        "secret_arn": "arn:aws:secretsmanager:eu-west-2:484466746276:secret:dataplatform-joates/housing-repairs/redshift-cluster-user20220318120428260100000009-wSxgRF",
        "user_name": "housing_repairs"
      },
      {
        "schemas_to_grant_access_to": [
          "joates_parking_raw_zone",
          "parking_raw_zone_liberator",
          "liberator_raw_zone",
          "joates_parking_refined_zone",
          "parking_refined_zone_liberator",
          "liberator_refined_zone",
          "joates_parking_trusted_zone",
          "joates_unrestricted_raw_zone",
          "joates_unrestricted_refined_zone",
          "joates_unrestricted_trusted_zone"
        ],
        "secret_arn": "arn:aws:secretsmanager:eu-west-2:484466746276:secret:dataplatform-joates/parking/redshift-cluster-user2022031812042842500000000b-PKfwO6",
        "user_name": "parking"
      },
      {
        "schemas_to_grant_access_to": [
          "joates_finance_raw_zone",
          "joates_finance_refined_zone",
          "joates_finance_trusted_zone",
          "joates_unrestricted_raw_zone",
          "joates_unrestricted_refined_zone",
          "joates_unrestricted_trusted_zone"
        ],
        "secret_arn": "arn:aws:secretsmanager:eu-west-2:484466746276:secret:dataplatform-joates/finance/redshift-cluster-user2022031812045108180000000e-O5580n",
        "user_name": "finance"
      },
      {
        "schemas_to_grant_access_to": [
          "dataplatform_joates_tascomi_refined_zone",
          "joates_housing_repairs_raw_zone",
          "joates_housing_repairs_refined_zone",
          "joates_housing_repairs_trusted_zone",
          "parking_raw_zone_liberator",
          "parking_refined_zone_liberator",
          "joates_parking_raw_zone",
          "joates_parking_refined_zone",
          "joates_parking_trusted_zone",
          "joates_finance_raw_zone",
          "joates_finance_refined_zone",
          "joates_finance_trusted_zone",
          "joates_data_and_insight_raw_zone",
          "joates_data_and_insight_refined_zone",
          "joates_data_and_insight_trusted_zone",
          "joates_env_enforcement_raw_zone",
          "joates_env_enforcement_refined_zone",
          "joates_env_enforcement_trusted_zone",
          "joates_planning_raw_zone",
          "joates_planning_refined_zone",
          "joates_planning_trusted_zone",
          "joates_bens_housing_needs_raw_zone",
          "joates_bens_housing_needs_refined_zone",
          "joates_bens_housing_needs_trusted_zone",
          "joates_revenues_raw_zone",
          "joates_revenues_refined_zone",
          "joates_revenues_trusted_zone",
          "joates_env_services_raw_zone",
          "joates_env_services_refined_zone",
          "joates_env_services_trusted_zone",
          "joates_housing_raw_zone",
          "joates_housing_refined_zone",
          "joates_housing_trusted_zone",
          "joates_unrestricted_raw_zone",
          "joates_unrestricted_refined_zone",
          "joates_unrestricted_trusted_zone"
        ],
        "secret_arn": "arn:aws:secretsmanager:eu-west-2:484466746276:secret:dataplatform-joates/data-and-insight/redshift-cluster-user20220318120428118500000007-LOkO4F",
        "user_name": "data_and_insight"
      },
      {
        "schemas_to_grant_access_to": [
          "joates_env_enforcement_raw_zone",
          "joates_env_enforcement_refined_zone",
          "joates_env_enforcement_trusted_zone",
          "joates_unrestricted_raw_zone",
          "joates_unrestricted_refined_zone",
          "joates_unrestricted_trusted_zone"
        ],
        "secret_arn": "arn:aws:secretsmanager:eu-west-2:484466746276:secret:dataplatform-joates/env-enforcement/redshift-cluster-user2022031812042829090000000a-Mxbdft",
        "user_name": "env_enforcement"
      },
      {
        "schemas_to_grant_access_to": [
          "dataplatform_stg_tascomi_refined_zone",
          "joates_unrestricted_raw_zone",
          "joates_unrestricted_refined_zone",
          "joates_unrestricted_trusted_zone"
        ],
        "secret_arn": "arn:aws:secretsmanager:eu-west-2:484466746276:secret:dataplatform-joates/planning/redshift-cluster-user2022011714081622190000001f-FdO4cQ",
        "user_name": "planning"
      },
      {
        "schemas_to_grant_access_to": [
          "joates_bens_housing_needs_raw_zone",
          "joates_bens_housing_needs_refined_zone",
          "joates_bens_housing_needs_trusted_zone",
          "joates_unrestricted_raw_zone",
          "joates_unrestricted_refined_zone",
          "joates_unrestricted_trusted_zone"
        ],
        "secret_arn": "arn:aws:secretsmanager:eu-west-2:484466746276:secret:dataplatform-joates/bens-housing-needs/redshift-cluster-user20220404202155253800000001-q3imVD",
        "user_name": "bens_housing_needs"
      },
      {
        "schemas_to_grant_access_to": [
          "joates_revenues_raw_zone",
          "joates_revenues_refined_zone",
          "joates_revenues_trusted_zone",
          "joates_unrestricted_raw_zone",
          "joates_unrestricted_refined_zone",
          "joates_unrestricted_trusted_zone"
        ],
        "secret_arn": "arn:aws:secretsmanager:eu-west-2:484466746276:secret:dataplatform-joates/revenues/redshift-cluster-user20220404202155277600000002-K9RhZE",
        "user_name": "revenues"
      },
      {
        "schemas_to_grant_access_to": [
          "joates_env_services_raw_zone",
          "joates_env_services_refined_zone",
          "joates_env_services_trusted_zone",
          "joates_unrestricted_raw_zone",
          "joates_unrestricted_refined_zone",
          "joates_unrestricted_trusted_zone"
        ],
        "secret_arn": "arn:aws:secretsmanager:eu-west-2:484466746276:secret:dataplatform-joates/env-services/redshift-cluster-user20220404202155312400000004-QqZQoh",
        "user_name": "env_services"
      },
      {
        "schemas_to_grant_access_to": [
          "joates_housing_raw_zone",
          "joates_housing_refined_zone",
          "joates_housing_trusted_zone",
          "joates_unrestricted_raw_zone",
          "joates_unrestricted_refined_zone",
          "joates_unrestricted_trusted_zone"
        ],
        "secret_arn": "arn:aws:secretsmanager:eu-west-2:484466746276:secret:dataplatform-joates/housing/redshift-cluster-user20220404202155443200000005-XcTtRb",
        "user_name": "housing"
      }
    ]
  },
  "ssl_connection_resources_bucket_id": {
    "sensitive": false,
    "type": "string",
    "value": ""
  }
}'
python3 ./configure_redshift.py "$OUTPUT"