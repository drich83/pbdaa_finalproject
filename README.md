Daniel Richardson and Michael Losev
PBDAA - Final Project
Readme

Our code is a series of queries that run in Impala. In order to run the code you need to connect to dumbo, impala and be able to run the code from Daniel's account at netID dr2675:
	- impala-shell
	- connect compute-1-1;
	- use dr2675;
	- source DRichardson_MLosev_final_code.sql

The data can be accessed at Daniel's NYU HDFS account via the following paths:
	- /user/dr2675/311/CLEANED_311Data2.csv
	- /user/dr2675/nypd/CLEANED_NYPD_Data.csv

The raw data can be accessed online at these links:
	- NYPD: https://data.cityofnewyork.us/Public-Safety/NYPD-Complaint-Data-Current-Year-To-Date-/5uac-w243
	- 311:  https://data.cityofnewyork.us/Social-Services/311-Service-Requests-from-2010-to-Present/erm2-nwe9


Note: The final analytic code begins with the create table statements, though we have commented them out because the code won't run if the tables already exist. Just letting you know in case you would like to run those commands as well.



