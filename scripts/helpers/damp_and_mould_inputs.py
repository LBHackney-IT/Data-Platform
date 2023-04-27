"""Contains lists of columns needed for various parts of the damp and mould analysis work"""

id_cols = ['uprn']

target = ['flag_dam_mould_repair_pre_2019']

vulnerability_cols = {'benefits': {'counter_of_live_hb_claim', 'council_has_uc'},
                      'age_over_65_yrs': {'max_ten_age'},
                      'flag_child': {'child_count', 'no_of_children'},
                      'flag_sen': {'SEN_cases', 'SEN_support_cases'},
                      'flag_ehcp': {'EHCP_cases'},
                      'flag_disabled': {'sum_reps_with_wetroom_pre_2019', 'ct_disc_disabled',
                                        'flag_blue_badge_property', 'no_of_disabled_members'
                                        },
                      'flag_fsm': {'FSM_cases'},
                      'flag_social_care': {'num_asc_cases', 'num_csc_cases', 'asc_long_term_support',
                                           'asc_short_term_support', 'asc_social_care_involvement'}
                      }

occupants = ['no_of_people_hb', 'num_of_people_ctax', 'person_count', 'est_num_occupants']

bool_cols = [
    'counter_of_live_hb_claim',
    'flag_void_before_tenancy',
    'council_has_uc',
    'flag_ten_sust'
    #             'flag_damp_and_mould_complaint'
]

cat_cols = ['estate_street',
            'Attachment',
            'Boiler Efficiency',
            'Glazing',
            'Heated Rooms',
            'Heating',
            'main_fuel_type',
            'band_tenancy_length',
            #             'building_age_band',
            'conservation_area',
            'estate_name',
            'external_wall_type_criteria',
            #             'floor_no',
            #             'group_typology',
            'open_to_air_walkways',
            #             'purpose_built_as_social_housing',
            'roof_insulation',
            'type_of_communal_area',
            'typologies',
            'no_of_disabled_members',
            #             'period_of_built'
            #             'ct_band'
            ]

cont_cols = [
    'no_of_adults',
    'no_of_children',
    'num_of_people_ctax',
    'person_count',
    'number_of_bedrooms',
    'max_ten_age',
    #             'age_of_tenancy',
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

date_cols = ['startoftenuredate',
             'endoftenuredate',
             'date_first_damp_mould',
             'date_last_damp_mould']

repairs_cols = cat_cols + bool_cols + cont_cols + date_cols + target

ml_cols = ['uprn',
           'typologies',
           'estate_street',
           'band_tenancy_length',
           'flag_void_before_tenancy',
           'flag_ten_sust',
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
