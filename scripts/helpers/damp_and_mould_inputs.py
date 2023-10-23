"""Contains lists and dicts of features needed to train a model to predict dwellings ate risk of disrepair
related to dmp and mould."""

id_cols = ['uprn']

target = ['flag_damp_mould_pre_2019']

vulnerability_cols = {'benefits': {'counter_of_live_hb_claim', 'council_has_uc'},
                      'age_over_65_yrs': {'max_ten_age'},
                      'flag_child': {'child_count'},
                      'flag_sen': {'SEN_cases', 'SEN_support_cases'},
                      'flag_ehcp': {'EHCP_cases'},
                      'flag_disabled': {'sum_reps_with_wetroom_pre_2019', 'ct_disc_disabled',
                                        'flag_blue_badge_property'
                                        },
                      'flag_fsm': {'FSM_cases'},
                      'flag_social_care': {'num_asc_cases', 'num_csc_cases', 'asc_long_term_support',
                                           'asc_short_term_support', 'asc_social_care_involvement'}
                      }

vulnerability_cols_input = {'benefits': {'counter_of_live_hb_claim'},
                            'age_over_65_yrs': {'max_ten_age', 'er_over60s_at_prop'},
                            'flag_child': {'child_count_all'},
                            'flag_sen': {'SEN_cases', 'SEN_support_cases'},
                            'flag_ehcp': {'EHCP_cases'},
                            'flag_disabled': {'sum_reps_with_wetroom_post_2019', 'ct_disc_disabled',
                                              'hb_no_of_disabled_members'
                                              },
                            'flag_fsm': {'FSM_cases'},
                            'flag_social_care': {'ASC_allocations', 'cfs_adult_allocations', 'cfs_child_allocations',
                                                 'cfs_allocations'}
                            }

occupants = ['est_num_occupants']

bool_cols = [
    'counter_of_live_hb_claim',
    'flag_void_before_2019',
    'council_has_uc',
    'flag_ten_sust',
    'flag_leak_pre_2019'
]

cat_cols = ['Attachment',
            'Glazing',
            'Heating',
            'main_fuel_type',
            'conservation_area',
            'estate_name',
            'external_wall_type_criteria',
            'open_to_air_walkways',
            'roof_insulation',
            'type_of_communal_area',
            'typologies']

ohe_cols = ['number_bedrooms_bands',
            'typologies'
            ]

cont_cols = [
    'number_of_bedrooms',
    'max_ten_age',
    'SEN_cases',
    'EHCP_cases',
    'SEN_support_cases',
    'FSM_cases',
    'ct_disc_disabled',
    'num_asc_cases',
    'asc_long_term_support',
    'asc_short_term_support',
    'asc_social_care_involvement',
    'num_csc_cases',
    'child_count',
    'flag_blue_badge_property',
    'est_num_occupants',
    'sum_reps_with_wetroom_pre_2019',
    'sum_reps_with_wetroom',
]

deleted_estates = ['Aikin Court Estate *Demolished*',
                   'Elm House Estate *DELETED*',
                   'Faircroft Estate *DELETED*',
                   'Durley House Estate *DELETE*']

ti_cols = [
    'uprn',
    'SEN_cases',
    'EHCP_cases',
    'SEN_support_cases',
    'FSM_cases',
    'ct_disc_disabled',
    'num_asc_cases',
    'asc_long_term_support',
    'asc_short_term_support',
    'asc_social_care_involvement',
    'num_csc_cases',
    'flag_blue_badge_property',
    'est_num_occupants',
    'ct_band',
    'child_count',
    'flag_ten_sust',
    'council_has_uc'
]

repairs_cols = id_cols + cat_cols + bool_cols + cont_cols + target

ml_cols = ['uprn',
           'typologies',
           'flag_void',
           # 'flag_ten_sust',
           'total_occupants',
           'number_bedrooms_bands',
           'flag_has_external_walls',
           'flag_communal_area',
           'flag_roof_insulation_or_dwelling_above',
           'flag_main_fuel_gas_individual',
           'flag_heating_boilers',
           'flag_open_to_air_walkways',
           'vulnerability_score',
           'confidence_score',
           'target']

ml_cols_inputs = ['uprn',
                  'typologies',
                  'flag_void',
                  # 'flag_ten_sust',
                  'total_occupants',
                  'number_bedrooms_bands',
                  'flag_has_external_walls',
                  'flag_communal_area',
                  'flag_roof_insulation_or_dwelling_above',
                  'flag_main_fuel_gas_individual',
                  'flag_heating_boilers',
                  'flag_open_to_air_walkways',
                  'vulnerability_score',
                  'target']

household_input_cols = ['uprn',
                        'er_records_at_prop',
                        'er_over60s_at_prop',
                        'ct_council_ha_ind',
                        'ct_disc_single',
                        'ct_disc_disabled',
                        'ct_current_liabilities',
                        'ct_tenancy_age_yr',
                        'hb_current_adults',
                        'hb_current_children',
                        'hb_total_occupants',
                        'hb_no_of_disabled_chidren',
                        'hb_no_of_disabled_adults',
                        'hb_no_of_disabled_members',
                        'hb_council_tenant',
                        'hb_ta_tenant',
                        'ASC_allocations',
                        'cfs_adult_allocations',
                        'cfs_child_allocations',
                        'cfs_allocations',
                        'council_tenant',
                        'council_num_bedrooms',
                        'current_tenancy_balance',
                        'council_length_tenancy_yr',
                        'flag_tenant_over_60',
                        'ta_flag',
                        'ta_num_of_bedrooms',
                        'ta_number_in_family',
                        'SEN_cases',
                        'EHCP_cases',
                        'SEN_support_cases',
                        'FSM_cases',
                        'child_count']

repairs_input_cols = ['flag_void_since_2019', 'Roof Insulation']
