#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd 
import numpy as np 
import urllib.request, json
from pandas.io.json import json_normalize
import datetime
import math


# In[46]:


def get_json(json_web):
    with urllib.request.urlopen(json_web) as url:
        data = json.loads(url.read())
    return data

def get_openfda(open_dict):
    '''
    A function designed to be used inconjunction with the openfda MAUDE database.  It targets the 
    openfda column and extracts the information that is important to pull from the nested json openfda 
    column.
    '''
    
    try:
        # The data is housed in a json dictionary structure
        device_name = open_dict['device_name']
        device_class = open_dict['device_class']
        medical_specialty = open_dict['medical_specialty_description']
    except:
        return [np.NaN, np.NaN, np.NaN]
    # returning all of the captured information
    return [device_name, device_class, medical_specialty]

def get_mdr_text(open_list):
    '''
    A function designed to be used inconjunction with the openfda MAUDE database.  It targets the 
    mdr_text column and extracts the information that is important to pull from the nested json 
    mdr_text column.
    '''
    # looping through the dictionaries in the list
    # There is typically 1-2 dictionaries in each list 
    for mdr_text in open_list:
        # check to see if the text type is a descrption of the event
        if mdr_text['text_type_code'] == 'Description of Event or Problem':
            try:
                # Getting the text data from the JSON dictionary structure
                text = mdr_text['text']
                 # returning all of the captured information
                return text
            except:
                return np.NaN

def normalize_maude(data):
    '''
    Takes nested JSON returned during a MAUDE openfda query and flattens it out into a dataframe 
    preserving columns related to the manufacturer and the device. 
    '''
    # Normalize the data based on the "results" section of the JSON
    # First normalization to see the structure of the data
    maude_general = json_normalize(data['results'])
    
    # Most of the imformation is housed within the "device" section of the "results
    maude_device = json_normalize(data=data['results'], record_path='device', 
    # Appending meta data to the end of each row with information we want to keep from "results"
         meta=['adverse_event_flag', 'date_received', 'event_type', 'report_number',
         'health_professional', 'reporter_occupation_code', 'mdr_text'], meta_prefix='base.',
        errors='ignore')
    
    # Creating a series containing all of the results using df.apply
    openfda = maude_device['openfda'].apply(get_openfda)
    
    # Converting the lists in the series to a dataframe
    openfda_df = pd.DataFrame.from_items(zip(openfda.index, openfda.values))
    openfda_df = openfda_df.transpose()
    openfda_df.columns = ['general_device_name', 'device_class', 'medical_specialty']
    
    # Combining the two dataframes
    maude_tot = pd.concat([maude_device, openfda_df], axis=1)
    
    # Extracting the Problem Description from the MDR text data
    maude_tot['problem_description'] = maude_tot['base.mdr_text'].apply(get_mdr_text)
    
    # Removing the initial openfda column
    droplist = ['baseline_510_k__exempt_flag', 'baseline_510_k__flag', 'baseline_510_k__number', 
            'catalog_number', 'date_removed_flag', 'date_returned_to_manufacturer', 'device_age_text', 
            'device_availability', 'device_evaluated_by_manufacturer', 'device_event_key',  'device_sequence_number',
            'implant_flag', 'lot_number', 'manufacturer_d_address_1', 'manufacturer_d_address_2',
            'manufacturer_d_city','manufacturer_d_postal_code', 'manufacturer_d_state', 
            'manufacturer_d_zip_code', 'manufacturer_d_zip_code_ext', 'model_number', 
            'other_id_number', 'openfda', 'base.mdr_text']
    maude_tot.drop(droplist, axis=1, inplace=True, errors='ignore')
    return maude_tot


# In[38]:


def get_skips(json_meta):
    '''
    Get the number of items returned from a MAUDE query to determine the of queries needed to return
    all of the results
    '''
    json_meta = json_normalize(json_meta['meta'])
    total = json_meta['results.total']
    skips = math.ceil(total/100)
    skip_list = np.arange(0, skips)*100
    return skip_list

def concat_json(full_url, skip_array):
    '''
    Send multiple json requests to the openFDA to get all of the relevant items and combine them into
    a single dataframe.
    '''
    maude_dict = {}
    for skip in skip_array:
        maude_dict[skip] = normalize_maude(get_json(full_url+ str(skip)))
    maude_df = pd.concat(maude_dict, axis=0, sort=False).reset_index(drop=True)
    maude_df = convert_dates(maude_df)
    return maude_df

def convert_dates(data):
    '''
    Convert all columns that contain the phrase "Date" into datetime objects to allow 
    for better functionality.
    data: dataframe with dates
    '''
    cols = data.columns
    date_cols = cols[cols.str.contains('date')]
    for date in date_cols:
        data[date] = pd.to_datetime(data[date])
    return data 

