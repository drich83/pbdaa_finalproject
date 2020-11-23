-- Create the table of 311 Data

create external table data_311(unique_key string, created_date string, agency string, agency_name string, complaint_type string, descriptor string, borough string, open_data_channel_type string, latitude double, longitude double)
   row format delimited fields terminated by ','
   location '/user/dr2675/311/';

-- Create the table of NYPD Data

create external table data_nypd(cmplnt_num int, addr_pct_cd int, borough string, juris_desc string, law_cat_cd string, ofns_desc string, reported_date string, latitude double, longitude double)
   row format delimited fields terminated by ','
   location '/user/dr2675/nypd/';


-- Group By Complaint Type and Descriptor for 311 Table and order by Count

select complaint_type, count(*) from data_311 group by complaint_type order by count(*) desc;


-- Displays in each line the precinct number and the count of each level of crime

select a.addr_pct_cd, a.law_cat_cd, a.count, b.law_cat_cd, b.count, c.law_cat_cd, c.count from (select addr_pct_cd, law_cat_cd, count from (select addr_pct_cd, law_cat_cd, count(*) as count from data_nypd group by addr_pct_cd, law_cat_cd order by addr_pct_cd, count(*) desc) as b where b.law_cat_cd = "MISDEMEANOR") as a inner join (select addr_pct_cd, law_cat_cd, count from (select addr_pct_cd, law_cat_cd, count(*) as count from data_nypd group by addr_pct_cd, law_cat_cd order by addr_pct_cd, count(*) desc) as b where b.law_cat_cd = "FELONY") as b on a.addr_pct_cd = b.addr_pct_cd inner join (select addr_pct_cd, law_cat_cd, count from (select addr_pct_cd, law_cat_cd, count(*) as count from data_nypd group by addr_pct_cd, law_cat_cd order by addr_pct_cd, count(*) desc) as b where b.law_cat_cd = "VIOLATION") as c on b.addr_pct_cd = c.addr_pct_cd order by a.addr_pct_cd;


-- Displays in each line the precinct number, borough and the percentage of felonies out of total crime, ordered by percentage

select a.addr_pct_cd, a.borough, round(b.count/(a.count + b.count + c.count), 3) as crime_felony, a.count + b.count + c.count as total_crime from (select addr_pct_cd, borough, law_cat_cd, count from (select addr_pct_cd, borough, law_cat_cd, count(*) as count from data_nypd group by addr_pct_cd, borough, law_cat_cd having count > 100 order by addr_pct_cd, count(*) desc) as d where d.law_cat_cd = "MISDEMEANOR" order by addr_pct_cd) as a inner join (select addr_pct_cd, borough, law_cat_cd, count from (select addr_pct_cd, borough, law_cat_cd, count(*) as count from data_nypd group by addr_pct_cd, borough, law_cat_cd having count > 100 order by addr_pct_cd, count(*) desc) as e where e.law_cat_cd = "FELONY" order by addr_pct_cd) as b on a.addr_pct_cd = b.addr_pct_cd inner join (select addr_pct_cd, borough, law_cat_cd, count from (select addr_pct_cd, borough, law_cat_cd, count(*) as count from data_nypd group by addr_pct_cd, borough, law_cat_cd having count > 100 order by addr_pct_cd, count(*) desc) as f where f.law_cat_cd = "VIOLATION" order by addr_pct_cd) as c on b.addr_pct_cd = c.addr_pct_cd order by crime_felony desc;



