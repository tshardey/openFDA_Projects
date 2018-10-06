# OpenFDA Power BI Dashboard

## Why these datasets?
- 	The dashboard was initially created to provide incite for the medical device company I currently work for but was modified to look at some of the Top 10 medical device companies.  

## Issues
- 	OpenFDA limits the json results returned per request to 100, in order to offset this and pull the JSON data directly into Power BI list.generate was used to keep requesting data and adjusting the skip factor by 100 each time until all of the available data had been gathered. 
-	list.combine was used to combine all of the gathered data together in one list prior to cleaning. 
-	As a lot of this data is gathered through voluntary online submission, a lot of the data fields are left blank or repeatative.  

## PDF Preview Report
The pages contain the following data:
1. Registration Listings
2. MAUDE Adverse Events
3. Recalls and Recall Enforcements Reports
4. 510(k) Registrations
5. Unique Device Identifiers
6. Drug Labeling and FAERS

## Queries

The M-Code for each query is provided, but an API key should be obtained in order to avoid running into openFDA imposed limits. 

## PBIX

The Web API option will need to be selected for the database access and the key will  need to be entered in order to get the queries to run properly.  