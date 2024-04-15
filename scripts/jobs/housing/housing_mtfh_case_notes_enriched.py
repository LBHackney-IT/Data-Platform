import boto3
from datetime import datetime, timedelta, timezone, date
import logging
import pandas as pd
import spacy
from spacy.cli import download

download("en_core_web_sm")
from spacy.lang import punctuation
from spacy.lang.en.stop_words import STOP_WORDS

from scripts.helpers.text_analysis_helpers import get_date_today_formatted_python, add_import_time_columns_pandas, \
    get_s3_location, PARTITION_KEYS
from scripts.helpers.helpers import get_glue_env_var, PARTITION_KEYS
from scripts.helpers.housing_mmh_vulnerability_keywords import damp_mould, health, children, elderly, disabled, finance, \
    death, home, immigration, crime, asb, domestic_violence, word_lists

STOP_WORDS |= {"hackney", "tnt", "tenant", "tenancy", "london", "lbh", "borough", "housing", "monday", "2020",
               "2021", "2023", "intro", "introductory", "property", "team", "email", "date", "tnts", "called",
               "completed", "application"}

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# parameters
glue_client = boto3.client('glue')
s3_location_mmh = get_glue_env_var("s3_source_mtfh_notes")
mmh_case_notes = get_glue_env_var('source_table_mtfh_notes')
s3_location_tenure = get_glue_env_var('s3_source_tenure')
tenure_reshaped = get_glue_env_var('source_table_tenure')
s3_output_location = get_glue_env_var('s3_output_path')


def remove_punctuation(text):
    return text.translate(str.maketrans('', '', punctuation))


def remove_stopwords(text):
    return " ".join([word for word in str(text).split() if word not in STOP_WORDS])


def find_keyword(text):
    if any(word in word_lists for word in text.split()):
        return 1
    else:
        return 0


def main():
    # load in datasets
    tenure_path = get_s3_location(tenure_reshaped, s3_location_tenure)
    mmh_casenotes_path = get_s3_location(mmh_case_notes, s3_location_mmh)
    tenure_df = pd.read_parquet(tenure_path)
    mmh_df = pd.read_parquet(mmh_casenotes_path)

    # tidy up columns
    mmh_df['create_date'] = pd.to_datetime(mmh_df['createdAt'], utc=True).dt.date
    mmh_df = mmh_df[['targetId', 'create_date', 'description', 'categorisation']]
    mmh_df = mmh_df.loc[mmh_df['create_date'] >= (get_date_today_formatted_python() - timedelta(days=730))]
    mmh_df.description = mmh_df['description'].astype(str)
    mmh_df.tenancy_id = mmh_df['targetId'].astype(str)
    mmh_df['all_notes'] = mmh_df.groupby(['targetId'])['description'].transform(lambda x: '\n'.join(x))
    tenure_df['start_tenure_date'] = pd.to_datetime(tenure_df['startOfTenureDate'])
    # tenure_df['uprn'] = tenure_df['uprn'].replace('', 999999).astype('int64')
    tenure_df['tenancy_id'] = tenure_df['tenancy_id'].astype('str')
    tenure_df['description'] = tenure_df['description'].astype('str')

    # filter and join tables
    tenure_df = tenure_df[(tenure_df.endoftenuredate.isnull()) & (tenure_df.asset_type == 'Dwelling') & (
        tenure_df.description.isin(['Secure', 'Introductory', 'Mesne Profit Ac', 'Mense Profit Ac']))]
    tenure_df = tenure_df[['tenancy_id', 'start_tenure_date', 'uprn', 'full_address']]

    mmh_notes_df = tenure_df.merge(mmh_df, left_on='tenancy_id', right_on='targetId', how='left')
    logger.info(f'Dataset size: {mmh_notes_df.shape}\nDataset columns: {mmh_notes_df.columns}')

    # get number of case notes by tenancy
    mmh_notes_df['num_case_notes'] = mmh_notes_df.groupby(['tenancy_id'])['create_date'].transform('nunique')

    # drop duplicate data and tidy up responses
    mmh_notes_df = mmh_notes_df.drop_duplicates(subset=['tenancy_id'])
    mmh_notes_df = mmh_notes_df[['tenancy_id', 'start_tenure_date', 'uprn', 'num_case_notes', 'all_notes']].reset_index(
        drop=True)
    mmh_notes_df.all_notes = mmh_notes_df['all_notes'].astype('str').str.strip().str.lower().str.replace('\n', ' ')

    # load spacy dictionary, punctuation and stopwords
    nlp = spacy.load("en_core_web_sm")

    mmh_notes_df['all_notes_no_punct'] = mmh_notes_df['all_notes'].apply(lambda text: remove_punctuation(text))

    mmh_notes_df['all_notes_no_punct_no_stop'] = mmh_notes_df.all_notes_no_punct.apply(
        lambda text: remove_stopwords(text))

    for words in word_lists:
        print(words[0])
        word_list = words[1]
        print(word_list)
        mmh_notes_df[f"flag_{words[0]}"] = mmh_notes_df['all_notes_no_punct_no_stop'].apply(find_keyword)

    logger.info(mmh_notes_df.sample(10))

    # write to s3
    mmh_notes_df = mmh_notes_df.drop(columns={'all_notes_no_punct', 'all_notes_no_punct_no_stop'})
    mmh_notes_df = add_import_time_columns_pandas(mmh_notes_df)
    mmh_notes_df.to_parquet(path=s3_output_location, partition_cols=PARTITION_KEYS)
    glue_client.start_crawler(Name='Housing MTFH case notes enriched to refined')
    logger.info(f'Refined casenotes written to {s3_output_location}')


if __name__ == '__main__':
    main()
