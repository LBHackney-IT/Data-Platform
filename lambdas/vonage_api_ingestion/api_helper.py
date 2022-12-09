import boto3
import re

def list_subfolders_in_directory(s3_client,bucket,directory):
    response = s3_client.list_objects_v2(
        Bucket=bucket,
        Prefix=directory,
        Delimiter="/")

    subfolders = response.get('CommonPrefixes')
    return subfolders

# Takes a list of "importyear=X" values and finds the largest one
def get_latest_value(list_of_import_years: list) -> str:
  list_of_raw_dates = []
  # print(list_of_raw_dates)

  # print(f'Cleaning Import Years')
  for subfolder in list_of_import_years:
    #print(type(subfolder))
    path_dictionary = dict(subfolder)
    #print(path_dictionary)

    importstring = path_dictionary["Prefix"]
    # print(f'Raw Prefix: {importstring}')

    importstring = re.search("[0-9]*\/$", importstring).group()
    # print(f'Date with /: {importstring}')

    # print(f'Cleaning "{importstring}"')
    importstring = re.sub(string=importstring,
                       pattern="[^0-9.]".format(),
                       repl="")
    # print(f'Output "{importstring}"')
    list_of_raw_dates.append(importstring)

  list_of_raw_dates = sorted(list_of_raw_dates, key=int, reverse=True)

  # print(list_of_raw_dates)
  largest_value = list_of_raw_dates[0]
  return largest_value

def get_latest_data_date(s3_client,bucket,folder_name):

    # Get Year
    folder_path = f'{folder_name}/'
    year_subfolders = list_subfolders_in_directory(s3_client, bucket, folder_path)
    latest_year = get_latest_value(year_subfolders)
    # print(f'The Latest Year is {latest_year}')

    # Get Month
    monthly_path = f'{folder_path}import_year={latest_year}/'
    monthly_subfolders = list_subfolders_in_directory(s3_client, bucket, monthly_path)
    latest_month = get_latest_value(monthly_subfolders)
    # print(f'The Latest Month is {latest_month}')

    daily_path = f'{monthly_path}import_month={latest_month}/'
    daily_subfolders = list_subfolders_in_directory(s3_client, bucket, daily_path)
    # print(f'The Daily Subfolders is {daily_subfolders}')

    latest_day = get_latest_value(daily_subfolders)
    # print(f'The Latest Day is {latest_day}')

    latest_date = f'{latest_year}-{latest_month}-{latest_day}'
    return latest_date

def list_s3_files_in_folder_using_client(s3_client,bucket,directory):

    response = s3_client.list_objects_v2(Bucket=bucket, Prefix=directory)
    files = response.get("Contents")

    for file in files:
        file['Key'] = re.sub(string=file['Key'],
                       pattern=f"{directory}/".format(),
                       repl="")
    # returns a list of dictionaries with file metadata
    return files

def check_pages(s3_client,bucket,folder_name,date_string):

    year = date_string[0:4]
    month = date_string[5:7]
    day = date_string[8:10]
    path_to_partition = f'{folder_name}/import_year={year}/import_month={month}/import_day={day}/import_date={date_string}'
    # print(f'path_to_partition = {path_to_partition}')

    filelist = list_s3_files_in_folder_using_client(s3_client,bucket,path_to_partition)

    # Find the page number
    # List the pages
    list_of_pages = []
    max_pages = int(re.search(string=filelist[0]['Key'], pattern="of_(\d\d)".format()).group(1))

    for file in filelist:
        list_of_pages.append(int(re.search(string=file['Key'], pattern="page_(\d\d)_of".format()).group(1)))
    print (filelist)
    print(f'List of Pages: {list_of_pages}')

    latest_page = sorted(list_of_pages, key=int, reverse=True)[0]
    print(f'Latest Page: {latest_page}')
    print(f'Max Page: {max_pages}')

    if(latest_page == max_pages ):
        print(f'We have all the pages. {latest_page} of {max_pages}')
        return True
    else:
        return False


