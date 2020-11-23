-- Create the table of 311 Data

-- create external table data_311(unique_key string, created_date string, agency string, agency_name string, complaint_type string, descriptor string, borough string, open_data_channel_type string, latitude double, longitude double)
--   row format delimited fields terminated by ','
--   location '/user/dr2675/311/';

-- Create the table of NYPD Data

-- create external table data_nypd(cmplnt_num int, addr_pct_cd int, borough string, juris_desc string, law_cat_cd string, ofns_desc string, reported_date string, latitude double, longitude double)
--   row format delimited fields terminated by ','
--   location '/user/dr2675/nypd/';


-- Group By Complaint Type and Descriptor for 311 Table and order by Count

SELECT complaint_type,
         count(*)
FROM data_311
GROUP BY  complaint_type
ORDER BY  count(*) desc;


-- Displays in each line the precinct number and the count of each level of crime

SELECT a.addr_pct_cd,
         a.law_cat_cd,
         a.count,
         b.law_cat_cd,
         b.count,
         c.law_cat_cd,
         c.count
FROM 
    (SELECT addr_pct_cd,
         law_cat_cd,
         count
    FROM 
        (SELECT addr_pct_cd,
         law_cat_cd,
         count(*) AS count
        FROM data_nypd
        GROUP BY  addr_pct_cd, law_cat_cd
        ORDER BY  addr_pct_cd, count(*) desc) AS b
        WHERE b.law_cat_cd = "MISDEMEANOR") AS a
    INNER JOIN 
    (SELECT addr_pct_cd,
         law_cat_cd,
         count
    FROM 
        (SELECT addr_pct_cd,
         law_cat_cd,
         count(*) AS count
        FROM data_nypd
        GROUP BY  addr_pct_cd, law_cat_cd
        ORDER BY  addr_pct_cd, count(*) desc) AS b
        WHERE b.law_cat_cd = "FELONY") AS b
        ON a.addr_pct_cd = b.addr_pct_cd
INNER JOIN 
    (SELECT addr_pct_cd,
         law_cat_cd,
         count
    FROM 
        (SELECT addr_pct_cd,
         law_cat_cd,
         count(*) AS count
        FROM data_nypd
        GROUP BY  addr_pct_cd, law_cat_cd
        ORDER BY  addr_pct_cd, count(*) desc) AS b
        WHERE b.law_cat_cd = "VIOLATION") AS c
        ON b.addr_pct_cd = c.addr_pct_cd
ORDER BY  a.addr_pct_cd;


-- Displays in each line the precinct number, borough and the percentage of felonies out of total crime, ordered by percentage

SELECT a.addr_pct_cd,
         a.borough,
         round(b.count/(a.count + b.count + c.count),
         3) AS crime_felony,
         a.count + b.count + c.count AS total_crime
FROM 
    (SELECT addr_pct_cd,
         borough,
         law_cat_cd,
         count
    FROM 
        (SELECT addr_pct_cd,
         borough,
         law_cat_cd,
         count(*) AS count
        FROM data_nypd
        GROUP BY  addr_pct_cd, borough, law_cat_cd
        HAVING count > 100
        ORDER BY  addr_pct_cd, count(*) desc) AS d
        WHERE d.law_cat_cd = "MISDEMEANOR"
        ORDER BY  addr_pct_cd) AS a
    INNER JOIN 
    (SELECT addr_pct_cd,
         borough,
         law_cat_cd,
         count
    FROM 
        (SELECT addr_pct_cd,
         borough,
         law_cat_cd,
         count(*) AS count
        FROM data_nypd
        GROUP BY  addr_pct_cd, borough, law_cat_cd
        HAVING count > 100
        ORDER BY  addr_pct_cd, count(*) desc) AS e
        WHERE e.law_cat_cd = "FELONY"
        ORDER BY  addr_pct_cd) AS b
        ON a.addr_pct_cd = b.addr_pct_cd
INNER JOIN 
    (SELECT addr_pct_cd,
         borough,
         law_cat_cd,
         count
    FROM 
        (SELECT addr_pct_cd,
         borough,
         law_cat_cd,
         count(*) AS count
        FROM data_nypd
        GROUP BY  addr_pct_cd, borough, law_cat_cd
        HAVING count > 100
        ORDER BY  addr_pct_cd, count(*) desc) AS f
        WHERE f.law_cat_cd = "VIOLATION"
        ORDER BY  addr_pct_cd) AS c
        ON b.addr_pct_cd = c.addr_pct_cd
ORDER BY  crime_felony desc;

-- Gives the total number of crimes in each precinct multiplied by each crime's respective prison sentencing in years in order to show the crime level for each precinct

SELECT grand_lar.addr_pct_cd ,
         c_grand_lar + isnull(c_arson,
        0) + isnull(c_hom_neg,
        0) + isnull(c_burg,
        0) + isnull(c_child,
        0) + isnull(c_crim_mis,
        0) + isnull(c_drugs,
        0) + isnull(c_weapons,
        0) + isnull(c_endan,
        0) + isnull(c_assault,
        0) + isnull(c_sex_crimes,
        0) + isnull(c_forgery,
        0) + isnull(c_gambling,
        0) + isnull(c_grand_vehicle,
        0) + isnull(c_hom_vehicle,
        0) + isnull(c_intox,
        0) + isnull(c_kid,
        0) + isnull(c_kid_rel,
        0) + isnull(c_kid_rel2,
        0) + isnull(c_misc,
        0) + isnull(c_murder,
        0) + isnull(c_uncl,
        0) + isnull(c_other,
        0) + isnull(c_poss,
        0) + isnull(c_pros,
        0) + isnull(c_rape,
        0) + isnull(c_rob,
        0) + isnull(c_s_crimes,
        0) + isnull(c_theft,
        0) AS sum
FROM 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 2 AS c_grand_lar
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "GRAND LARCENY") AS grand_lar
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 22.5 AS c_arson
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "ARSON") AS arson
    ON grand_lar.addr_pct_cd = arson.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 9.25 AS c_hom_neg
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "\"HOMICIDE-NEGLIGENT") AS hom_neg
    ON hom_neg.addr_pct_cd = grand_lar.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 15 AS c_burg
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "BURGLARY") AS burg
    ON grand_lar.addr_pct_cd = burg.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) AS c_child
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "CHILD ABANDONMENT/NON SUPPORT") AS child
    ON grand_lar.addr_pct_cd = child.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 2 AS c_crim_mis
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "CRIMINAL MISCHIEF & RELATED OF"
            AND law_cat_cd = "FELONY") AS crim_mis
    ON grand_lar.addr_pct_cd = crim_mis.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) AS c_drugs
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "DANGEROUS DRUGS"
            AND law_cat_cd = "FELONY") AS drugs
    ON grand_lar.addr_pct_cd = drugs.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 15 AS c_weapons
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "DANGEROUS WEAPONS"
            AND law_cat_cd = "FELONY") AS weapons
    ON grand_lar.addr_pct_cd = weapons.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) AS c_endan
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "ENDAN WELFARE INCOMP"
            AND law_cat_cd = "FELONY") AS endan
    ON grand_lar.addr_pct_cd = endan.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 15 AS c_assault
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "FELONY ASSAULT"
            AND law_cat_cd = "FELONY") AS assault
    ON grand_lar.addr_pct_cd = assault.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 15 AS c_sex_crimes
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "FELONY SEX CRIMES"
            AND law_cat_cd = "FELONY") AS sex_crimes
    ON grand_lar.addr_pct_cd = sex_crimes.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) AS c_forgery
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "FORGERY"
            AND law_cat_cd = "FELONY") AS forgery
    ON grand_lar.addr_pct_cd = forgery.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) AS c_gambling
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "GAMBLING"
            AND law_cat_cd = "FELONY") AS gambling
    ON grand_lar.addr_pct_cd = gambling.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 2 AS c_grand_vehicle
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "GRAND LARCENY OF MOTOR VEHICLE"
            AND law_cat_cd = "FELONY") AS grand_vehicle
    ON grand_lar.addr_pct_cd = grand_vehicle.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 9.25 AS c_hom_vehicle
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "HOMICIDE-NEGLIGENT-VEHICLE"
            AND law_cat_cd = "FELONY") AS hom_vehicle
    ON grand_lar.addr_pct_cd = hom_vehicle.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) AS c_intox
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "INTOXICATED/IMPAIRED DRIVING"
            AND law_cat_cd = "FELONY") AS intox
    ON grand_lar.addr_pct_cd = intox.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 22.5 AS c_kid
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "KIDNAPPING"
            AND law_cat_cd = "FELONY") AS kid
    ON grand_lar.addr_pct_cd = kid.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 15 AS c_kid_rel
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "KIDNAPPING & RELATED OFFENSES"
            AND law_cat_cd = "FELONY") AS kid_rel
    ON grand_lar.addr_pct_cd = kid_rel.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 15 AS c_kid_rel2
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "KIDNAPPING
            AND RELATED OFFENSES"
            AND law_cat_cd = "FELONY") AS kid_rel2
    ON grand_lar.addr_pct_cd = kid_rel2.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 8.3 AS c_misc
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "MISCELLANEOUS PENAL LAW"
            AND law_cat_cd = "FELONY") AS misc
    ON grand_lar.addr_pct_cd = misc.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 22.5 AS c_murder
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "MURDER & NON-NEGL. MANSLAUGHTER"
            AND law_cat_cd = "FELONY") AS murder
    ON grand_lar.addr_pct_cd = murder.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 8.3 AS c_uncl
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "NYS LAWS-UNCLASSIFIED FELONY"
            AND law_cat_cd = "FELONY") AS uncl
    ON grand_lar.addr_pct_cd = uncl.addr_pct_cd
LEFT JOIN 
    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 8.3 AS c_other
    FROM data_nypd
    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
    HAVING ofns_desc = "OTHER STATE LAWS (NON PENAL LA"
            AND law_cat_cd = "FELONY") AS other
        ON grand_lar.addr_pct_cd = other.addr_pct_cd
    LEFT JOIN 
        (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 2 AS c_poss
        FROM data_nypd
        GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
        HAVING ofns_desc = " POSSESSION OF STOLEN PROPERTY"
                AND law_cat_cd = "FELONY") AS poss
            ON grand_lar.addr_pct_cd = poss.addr_pct_cd
        LEFT JOIN 
            (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 2 AS c_pros
            FROM data_nypd
            GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
            HAVING ofns_desc = "PROSTITUTION & RELATED OFFENSES"
                    AND law_cat_cd = "FELONY") AS pros
                ON grand_lar.addr_pct_cd = pros.addr_pct_cd
            LEFT JOIN 
                (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 15 AS c_rape
                FROM data_nypd
                GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
                HAVING ofns_desc = "RAPE"
                        AND law_cat_cd = "FELONY") AS rape
                    ON grand_lar.addr_pct_cd = rape.addr_pct_cd
                LEFT JOIN 
                    (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 15 AS c_rob
                    FROM data_nypd
                    GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
                    HAVING ofns_desc = "ROBBERY"
                            AND law_cat_cd = "FELONY") AS rob
                        ON grand_lar.addr_pct_cd = rob.addr_pct_cd
                    LEFT JOIN 
                        (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 15 AS c_s_crimes
                        FROM data_nypd
                        GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
                        HAVING ofns_desc = "SEX CRIMES"
                                AND law_cat_cd = "FELONY") AS s_crimes
                            ON grand_lar.addr_pct_cd = s_crimes.addr_pct_cd
                        LEFT JOIN 
                            (SELECT addr_pct_cd,
         ofns_desc,
         count(*) * 2 AS c_theft
                            FROM data_nypd
                            GROUP BY  addr_pct_cd, law_cat_cd, ofns_desc
                            HAVING ofns_desc = "THEFT FRAUD"
                                    AND law_cat_cd = "FELONY") AS theft
                                ON grand_lar.addr_pct_cd = theft.addr_pct_cd
                            ORDER BY  sum;


-- Gives the total number of crimes in each location, which is latitude and longitude rounded to 2 decimal points multiplied by each crime's respective prison sentencing in years in order to show the crime level at each location

SELECT grand_lar.lat,
         grand_lar.long,
         c_grand_lar + isnull(c_arson,
        0) + isnull(c_hom_neg,
        0) + isnull(c_burg,
        0) + isnull(c_child,
        0) + isnull(c_crim_mis,
        0) + isnull(c_drugs,
        0) + isnull(c_weapons,
        0) + isnull(c_endan,
        0) + isnull(c_assault,
        0) + isnull(c_sex_crimes,
        0) + isnull(c_forgery,
        0) + isnull(c_gambling,
        0) + isnull(c_grand_vehicle,
        0) + isnull(c_hom_vehicle,
        0) + isnull(c_intox,
        0) + isnull(c_kid,
        0) + isnull(c_kid_rel,
        0) + isnull(c_kid_rel2,
        0) + isnull(c_misc,
        0) + isnull(c_murder,
        0) + isnull(c_uncl,
        0) + isnull(c_other,
        0) + isnull(c_poss,
        0) + isnull(c_pros,
        0) + isnull(c_rape,
        0) + isnull(c_rob,
        0) + isnull(c_s_crimes,
        0) + isnull(c_theft,
        0) AS sum
FROM 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_grand_lar
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "GRAND LARCENY") AS grand_lar
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_arson
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "ARSON") AS arson
    ON grand_lar.lat = arson.lat
        AND grand_lar.long = arson.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 9.25 AS c_hom_neg
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "\"HOMICIDE-NEGLIGENT") AS hom_neg
    ON hom_neg.lat = grand_lar.lat
        AND grand_lar.long = hom_neg.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_burg
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "BURGLARY") AS burg
    ON grand_lar.lat = burg.lat
        AND grand_lar.long = burg.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_child
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "CHILD ABANDONMENT/NON SUPPORT") AS child
    ON grand_lar.lat = child.lat
        AND grand_lar.long = child.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_crim_mis
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "CRIMINAL MISCHIEF & RELATED OF"
            AND law_cat_cd = "FELONY") AS crim_mis
    ON grand_lar.lat = crim_mis.lat
        AND grand_lar.long = crim_mis.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_drugs
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "DANGEROUS DRUGS"
            AND law_cat_cd = "FELONY") AS drugs
    ON grand_lar.lat = drugs.lat
        AND grand_lar.long = drugs.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_weapons
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "DANGEROUS WEAPONS"
            AND law_cat_cd = "FELONY") AS weapons
    ON grand_lar.lat = weapons.lat
        AND grand_lar.long = weapons.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_endan
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "ENDAN WELFARE INCOMP"
            AND law_cat_cd = "FELONY") AS endan
    ON grand_lar.lat = endan.lat
        AND grand_lar.long = endan.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_assault
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "FELONY ASSAULT"
            AND law_cat_cd = "FELONY") AS assault
    ON grand_lar.lat = assault.lat
        AND grand_lar.long = assault.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_sex_crimes
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "FELONY SEX CRIMES"
            AND law_cat_cd = "FELONY") AS sex_crimes
    ON grand_lar.lat = sex_crimes.lat
        AND grand_lar.long = sex_crimes.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_forgery
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "FORGERY"
            AND law_cat_cd = "FELONY") AS forgery
    ON grand_lar.lat = forgery.lat
        AND grand_lar.long = forgery.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_gambling
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "GAMBLING"
            AND law_cat_cd = "FELONY") AS gambling
    ON grand_lar.lat = gambling.lat
        AND grand_lar.long = gambling.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_grand_vehicle
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "GRAND LARCENY OF MOTOR VEHICLE"
            AND law_cat_cd = "FELONY") AS grand_vehicle
    ON grand_lar.lat = grand_vehicle.lat
        AND grand_lar.long = grand_vehicle.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 9.25 AS c_hom_vehicle
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "HOMICIDE-NEGLIGENT-VEHICLE"
            AND law_cat_cd = "FELONY") AS hom_vehicle
    ON grand_lar.lat = hom_vehicle.lat
        AND grand_lar.long = hom_vehicle.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_intox
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "INTOXICATED/IMPAIRED DRIVING"
            AND law_cat_cd = "FELONY") AS intox
    ON grand_lar.lat = intox.lat
        AND grand_lar.long = intox.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_kid
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "KIDNAPPING"
            AND law_cat_cd = "FELONY") AS kid
    ON grand_lar.lat = kid.lat
        AND grand_lar.long = kid.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_kid_rel
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "KIDNAPPING & RELATED OFFENSES"
            AND law_cat_cd = "FELONY") AS kid_rel
    ON grand_lar.lat = kid_rel.lat
        AND grand_lar.long = kid_rel.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_kid_rel2
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "KIDNAPPING
            AND RELATED OFFENSES"
            AND law_cat_cd = "FELONY") AS kid_rel2
    ON grand_lar.lat = kid_rel2.lat
        AND grand_lar.long = kid_rel2.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_misc
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "MISCELLANEOUS PENAL LAW"
            AND law_cat_cd = "FELONY") AS misc
    ON grand_lar.lat = misc.lat
        AND grand_lar.long = misc.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_murder
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "MURDER & NON-NEGL. MANSLAUGHTER"
            AND law_cat_cd = "FELONY") AS murder
    ON grand_lar.lat = murder.lat
        AND grand_lar.long = murder.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_uncl
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "NYS LAWS-UNCLASSIFIED FELONY"
            AND law_cat_cd = "FELONY") AS uncl
    ON grand_lar.lat = uncl.lat
        AND grand_lar.long = uncl.long
LEFT JOIN 
    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_other
    FROM data_nypd
    GROUP BY  lat, long, law_cat_cd, ofns_desc
    HAVING ofns_desc = "OTHER STATE LAWS (NON PENAL LA"
            AND law_cat_cd = "FELONY") AS other
        ON grand_lar.lat = other.lat
            AND grand_lar.long = other.long
    LEFT JOIN 
        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_poss
        FROM data_nypd
        GROUP BY  lat, long, law_cat_cd, ofns_desc
        HAVING ofns_desc = " POSSESSION OF STOLEN PROPERTY"
                AND law_cat_cd = "FELONY") AS poss
            ON grand_lar.lat = poss.lat
                AND grand_lar.long = poss.long
        LEFT JOIN 
            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_pros
            FROM data_nypd
            GROUP BY  lat, long, law_cat_cd, ofns_desc
            HAVING ofns_desc = "PROSTITUTION & RELATED OFFENSES"
                    AND law_cat_cd = "FELONY") AS pros
                ON grand_lar.lat = pros.lat
                    AND grand_lar.long = pros.long
            LEFT JOIN 
                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_rape
                FROM data_nypd
                GROUP BY  lat, long, law_cat_cd, ofns_desc
                HAVING ofns_desc = "RAPE"
                        AND law_cat_cd = "FELONY") AS rape
                    ON grand_lar.lat = rape.lat
                        AND grand_lar.long = rape.long
                LEFT JOIN 
                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_rob
                    FROM data_nypd
                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                    HAVING ofns_desc = "ROBBERY"
                            AND law_cat_cd = "FELONY") AS rob
                        ON grand_lar.lat = rob.lat
                            AND grand_lar.long = rob.long
                    LEFT JOIN 
                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_s_crimes
                        FROM data_nypd
                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                        HAVING ofns_desc = "SEX CRIMES"
                                AND law_cat_cd = "FELONY") AS s_crimes
                            ON grand_lar.lat = s_crimes.lat
                                AND grand_lar.long = s_crimes.long
                        LEFT JOIN 
                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_theft
                            FROM data_nypd
                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                            HAVING ofns_desc = "THEFT FRAUD"
                                    AND law_cat_cd = "FELONY") AS theft
                                ON grand_lar.lat = theft.lat
                                    AND grand_lar.long = theft.long
                            ORDER BY  sum;

-- Join the 311 and NYPD data together on location, represented by latitude and longitude rounded to 2 decimal points. Shows the crime level of each location alongside the number of 311 calls for that location

SELECT nypd.lat,
         nypd.long,
         sum,
         c_complaints
FROM 
    (SELECT grand_lar.lat,
         grand_lar.long,
         c_grand_lar + isnull(c_arson,
        0) + isnull(c_hom_neg,
        0) + isnull(c_burg,
        0) + isnull(c_child,
        0) + isnull(c_crim_mis,
        0) + isnull(c_drugs,
        0) + isnull(c_weapons,
        0) + isnull(c_endan,
        0) + isnull(c_assault,
        0) + isnull(c_sex_crimes,
        0) + isnull(c_forgery,
        0) + isnull(c_gambling,
        0) + isnull(c_grand_vehicle,
        0) + isnull(c_hom_vehicle,
        0) + isnull(c_intox,
        0) + isnull(c_kid,
        0) + isnull(c_kid_rel,
        0) + isnull(c_kid_rel2,
        0) + isnull(c_misc,
        0) + isnull(c_murder,
        0) + isnull(c_uncl,
        0) + isnull(c_other,
        0) + isnull(c_poss,
        0) + isnull(c_pros,
        0) + isnull(c_rape,
        0) + isnull(c_rob,
        0) + isnull(c_s_crimes,
        0) + isnull(c_theft,
        0) AS sum
    FROM 
        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_grand_lar
        FROM data_nypd
        GROUP BY  lat, long, law_cat_cd, ofns_desc
        HAVING ofns_desc = "GRAND LARCENY") AS grand_lar
        LEFT JOIN 
            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_arson
            FROM data_nypd
            GROUP BY  lat, long, law_cat_cd, ofns_desc
            HAVING ofns_desc = "ARSON") AS arson
                ON grand_lar.lat = arson.lat
                    AND grand_lar.long = arson.long
            LEFT JOIN 
                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 9.25 AS c_hom_neg
                FROM data_nypd
                GROUP BY  lat, long, law_cat_cd, ofns_desc
                HAVING ofns_desc = "\"HOMICIDE-NEGLIGENT") AS hom_neg
                    ON hom_neg.lat = grand_lar.lat
                        AND grand_lar.long = hom_neg.long
                LEFT JOIN 
                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_burg
                    FROM data_nypd
                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                    HAVING ofns_desc = "BURGLARY") AS burg
                        ON grand_lar.lat = burg.lat
                            AND grand_lar.long = burg.long
                    LEFT JOIN 
                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_child
                        FROM data_nypd
                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                        HAVING ofns_desc = "CHILD ABANDONMENT/NON SUPPORT") AS child
                            ON grand_lar.lat = child.lat
                                AND grand_lar.long = child.long
                        LEFT JOIN 
                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_crim_mis
                            FROM data_nypd
                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                            HAVING ofns_desc = "CRIMINAL MISCHIEF & RELATED OF"
                                    AND law_cat_cd = "FELONY") AS crim_mis
                                ON grand_lar.lat = crim_mis.lat
                                    AND grand_lar.long = crim_mis.long
                            LEFT JOIN 
                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_drugs
                                FROM data_nypd
                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                HAVING ofns_desc = "DANGEROUS DRUGS"
                                        AND law_cat_cd = "FELONY") AS drugs
                                    ON grand_lar.lat = drugs.lat
                                        AND grand_lar.long = drugs.long
                                LEFT JOIN 
                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_weapons
                                    FROM data_nypd
                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                    HAVING ofns_desc = "DANGEROUS WEAPONS"
                                            AND law_cat_cd = "FELONY") AS weapons
                                        ON grand_lar.lat = weapons.lat
                                            AND grand_lar.long = weapons.long
                                    LEFT JOIN 
                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_endan
                                        FROM data_nypd
                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                        HAVING ofns_desc = "ENDAN WELFARE INCOMP"
                                                AND law_cat_cd = "FELONY") AS endan
                                            ON grand_lar.lat = endan.lat
                                                AND grand_lar.long = endan.long
                                        LEFT JOIN 
                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_assault
                                            FROM data_nypd
                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                            HAVING ofns_desc = "FELONY ASSAULT"
                                                    AND law_cat_cd = "FELONY") AS assault
                                                ON grand_lar.lat = assault.lat
                                                    AND grand_lar.long = assault.long
                                            LEFT JOIN 
                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_sex_crimes
                                                FROM data_nypd
                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                HAVING ofns_desc = "FELONY SEX CRIMES"
                                                        AND law_cat_cd = "FELONY") AS sex_crimes
                                                    ON grand_lar.lat = sex_crimes.lat
                                                        AND grand_lar.long = sex_crimes.long
                                                LEFT JOIN 
                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_forgery
                                                    FROM data_nypd
                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                    HAVING ofns_desc = "FORGERY"
                                                            AND law_cat_cd = "FELONY") AS forgery
                                                        ON grand_lar.lat = forgery.lat
                                                            AND grand_lar.long = forgery.long
                                                    LEFT JOIN 
                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_gambling
                                                        FROM data_nypd
                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                        HAVING ofns_desc = "GAMBLING"
                                                                AND law_cat_cd = "FELONY") AS gambling
                                                            ON grand_lar.lat = gambling.lat
                                                                AND grand_lar.long = gambling.long
                                                        LEFT JOIN 
                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_grand_vehicle
                                                            FROM data_nypd
                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                            HAVING ofns_desc = "GRAND LARCENY OF MOTOR VEHICLE"
                                                                    AND law_cat_cd = "FELONY") AS grand_vehicle
                                                                ON grand_lar.lat = grand_vehicle.lat
                                                                    AND grand_lar.long = grand_vehicle.long
                                                            LEFT JOIN 
                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 9.25 AS c_hom_vehicle
                                                                FROM data_nypd
                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                HAVING ofns_desc = "HOMICIDE-NEGLIGENT-VEHICLE"
                                                                        AND law_cat_cd = "FELONY") AS hom_vehicle
                                                                    ON grand_lar.lat = hom_vehicle.lat
                                                                        AND grand_lar.long = hom_vehicle.long
                                                                LEFT JOIN 
                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_intox
                                                                    FROM data_nypd
                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                    HAVING ofns_desc = "INTOXICATED/IMPAIRED DRIVING"
                                                                            AND law_cat_cd = "FELONY") AS intox
                                                                        ON grand_lar.lat = intox.lat
                                                                            AND grand_lar.long = intox.long
                                                                    LEFT JOIN 
                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_kid
                                                                        FROM data_nypd
                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                        HAVING ofns_desc = "KIDNAPPING"
                                                                                AND law_cat_cd = "FELONY") AS kid
                                                                            ON grand_lar.lat = kid.lat
                                                                                AND grand_lar.long = kid.long
                                                                        LEFT JOIN 
                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_kid_rel
                                                                            FROM data_nypd
                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                            HAVING ofns_desc = "KIDNAPPING & RELATED OFFENSES"
                                                                                    AND law_cat_cd = "FELONY") AS kid_rel
                                                                                ON grand_lar.lat = kid_rel.lat
                                                                                    AND grand_lar.long = kid_rel.long
                                                                            LEFT JOIN 
                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_kid_rel2
                                                                                FROM data_nypd
                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                HAVING ofns_desc = "KIDNAPPING
                                                                                        AND RELATED OFFENSES"
                                                                                        AND law_cat_cd = "FELONY") AS kid_rel2
                                                                                    ON grand_lar.lat = kid_rel2.lat
                                                                                        AND grand_lar.long = kid_rel2.long
                                                                                LEFT JOIN 
                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_misc
                                                                                    FROM data_nypd
                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                    HAVING ofns_desc = "MISCELLANEOUS PENAL LAW"
                                                                                            AND law_cat_cd = "FELONY") AS misc
                                                                                        ON grand_lar.lat = misc.lat
                                                                                            AND grand_lar.long = misc.long
                                                                                    LEFT JOIN 
                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_murder
                                                                                        FROM data_nypd
                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                        HAVING ofns_desc = "MURDER & NON-NEGL. MANSLAUGHTER"
                                                                                                AND law_cat_cd = "FELONY") AS murder
                                                                                            ON grand_lar.lat = murder.lat
                                                                                                AND grand_lar.long = murder.long
                                                                                        LEFT JOIN 
                                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_uncl
                                                                                            FROM data_nypd
                                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                            HAVING ofns_desc = "NYS LAWS-UNCLASSIFIED FELONY"
                                                                                                    AND law_cat_cd = "FELONY") AS uncl
                                                                                                ON grand_lar.lat = uncl.lat
                                                                                                    AND grand_lar.long = uncl.long
                                                                                            LEFT JOIN 
                                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_other
                                                                                                FROM data_nypd
                                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                HAVING ofns_desc = "OTHER STATE LAWS (NON PENAL LA"
                                                                                                        AND law_cat_cd = "FELONY") AS other
                                                                                                    ON grand_lar.lat = other.lat
                                                                                                        AND grand_lar.long = other.long
                                                                                                LEFT JOIN 
                                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_poss
                                                                                                    FROM data_nypd
                                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                    HAVING ofns_desc = " POSSESSION OF STOLEN PROPERTY"
                                                                                                            AND law_cat_cd = "FELONY") AS poss
                                                                                                        ON grand_lar.lat = poss.lat
                                                                                                            AND grand_lar.long = poss.long
                                                                                                    LEFT JOIN 
                                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_pros
                                                                                                        FROM data_nypd
                                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                        HAVING ofns_desc = "PROSTITUTION & RELATED OFFENSES"
                                                                                                                AND law_cat_cd = "FELONY") AS pros
                                                                                                            ON grand_lar.lat = pros.lat
                                                                                                                AND grand_lar.long = pros.long
                                                                                                        LEFT JOIN 
                                                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_rape
                                                                                                            FROM data_nypd
                                                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                            HAVING ofns_desc = "RAPE"
                                                                                                                    AND law_cat_cd = "FELONY") AS rape
                                                                                                                ON grand_lar.lat = rape.lat
                                                                                                                    AND grand_lar.long = rape.long
                                                                                                            LEFT JOIN 
                                                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_rob
                                                                                                                FROM data_nypd
                                                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                HAVING ofns_desc = "ROBBERY"
                                                                                                                        AND law_cat_cd = "FELONY") AS rob
                                                                                                                    ON grand_lar.lat = rob.lat
                                                                                                                        AND grand_lar.long = rob.long
                                                                                                                LEFT JOIN 
                                                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_s_crimes
                                                                                                                    FROM data_nypd
                                                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                    HAVING ofns_desc = "SEX CRIMES"
                                                                                                                            AND law_cat_cd = "FELONY") AS s_crimes
                                                                                                                        ON grand_lar.lat = s_crimes.lat
                                                                                                                            AND grand_lar.long = s_crimes.long
                                                                                                                    LEFT JOIN 
                                                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_theft
                                                                                                                        FROM data_nypd
                                                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                        HAVING ofns_desc = "THEFT FRAUD"
                                                                                                                                AND law_cat_cd = "FELONY") AS theft
                                                                                                                            ON grand_lar.lat = theft.lat
                                                                                                                                AND grand_lar.long = theft.long
                                                                                                                        ORDER BY  sum) AS nypd
                                                                                                                        INNER JOIN 
                                                                                                                            (SELECT round(latitude,
         2) AS lat,
         round(longitude,
        2) AS long,
         count(*) AS c_complaints
                                                                                                                            FROM data_311
                                                                                                                            GROUP BY  lat, long) AS complaints
                                                                                                                                ON nypd.lat = complaints.lat
                                                                                                                                    AND nypd.long = complaints.long
                                                                                                                            ORDER BY  sum; 

-- Join the 311 and NYPD data together on location, represented by latitude and longitude rounded to 2 decimal points. Shows the crime level of each location alongside the number of 311 calls for that location, broken down by the open data channel type (reported by phone, mobile, online or other)

select nypd.lat, nypd.long, sum, c_phone/(c_mobile + c_online + c_other + c_phone) * 100 as c_phone, c_mobile/(c_mobile + c_online + c_other + c_phone) * 100 as c_mobile, c_online/(c_mobile + c_online + c_other + c_phone) * 100 as c_online, c_other/(c_mobile + c_online + c_other + c_phone) * 100 as c_other from (select grand_lar.lat, grand_lar.long, c_grand_lar + isnull(c_arson,0) + isnull(c_hom_neg,0) + isnull(c_burg,0) + isnull(c_child,0) + isnull(c_crim_mis,0) + isnull(c_drugs,0) + isnull(c_weapons,0) + isnull(c_endan,0) + isnull(c_assault,0) + isnull(c_sex_crimes,0) + isnull(c_forgery,0) + isnull(c_gambling,0) + isnull(c_grand_vehicle,0) + isnull(c_hom_vehicle,0) + isnull(c_intox,0) + isnull(c_kid,0) + isnull(c_kid_rel,0) + isnull(c_kid_rel2,0) + isnull(c_misc,0) + isnull(c_murder,0) + isnull(c_uncl,0) + isnull(c_other,0) + isnull(c_poss,0) + isnull(c_pros,0) + isnull(c_rape,0) + isnull(c_rob,0) + isnull(c_s_crimes,0) + isnull(c_theft,0) as sum from (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 2 as c_grand_lar from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "GRAND LARCENY") as grand_lar left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 22.5 as c_arson from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "ARSON") as arson on grand_lar.lat = arson.lat and grand_lar.long = arson.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 9.25 as c_hom_neg from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "\"HOMICIDE-NEGLIGENT") as hom_neg on hom_neg.lat = grand_lar.lat and grand_lar.long = hom_neg.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_burg from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "BURGLARY") as burg on grand_lar.lat = burg.lat and grand_lar.long = burg.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) as c_child from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "CHILD ABANDONMENT/NON SUPPORT") as child on grand_lar.lat = child.lat and grand_lar.long = child.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 2 as c_crim_mis from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "CRIMINAL MISCHIEF & RELATED OF" and law_cat_cd = "FELONY") as crim_mis on grand_lar.lat = crim_mis.lat and grand_lar.long = crim_mis.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) as c_drugs from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "DANGEROUS DRUGS" and law_cat_cd = "FELONY") as drugs on grand_lar.lat = drugs.lat and grand_lar.long = drugs.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_weapons from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "DANGEROUS WEAPONS" and law_cat_cd = "FELONY") as weapons on grand_lar.lat = weapons.lat and grand_lar.long = weapons.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) as c_endan from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "ENDAN WELFARE INCOMP" and law_cat_cd = "FELONY") as endan on grand_lar.lat = endan.lat and grand_lar.long = endan.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_assault from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "FELONY ASSAULT" and law_cat_cd = "FELONY") as assault on grand_lar.lat = assault.lat and grand_lar.long = assault.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_sex_crimes from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "FELONY SEX CRIMES" and law_cat_cd = "FELONY") as sex_crimes on grand_lar.lat = sex_crimes.lat and grand_lar.long = sex_crimes.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) as c_forgery from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "FORGERY" and law_cat_cd = "FELONY") as forgery on grand_lar.lat = forgery.lat and grand_lar.long = forgery.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) as c_gambling from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "GAMBLING" and law_cat_cd = "FELONY") as gambling on grand_lar.lat = gambling.lat and grand_lar.long = gambling.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 2 as c_grand_vehicle from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "GRAND LARCENY OF MOTOR VEHICLE" and law_cat_cd = "FELONY") as grand_vehicle on grand_lar.lat = grand_vehicle.lat and grand_lar.long = grand_vehicle.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 9.25 as c_hom_vehicle from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "HOMICIDE-NEGLIGENT-VEHICLE" and law_cat_cd = "FELONY") as hom_vehicle on grand_lar.lat = hom_vehicle.lat and grand_lar.long = hom_vehicle.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) as c_intox from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "INTOXICATED/IMPAIRED DRIVING" and law_cat_cd = "FELONY") as intox on grand_lar.lat = intox.lat and grand_lar.long = intox.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 22.5 as c_kid from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "KIDNAPPING" and law_cat_cd = "FELONY") as kid on grand_lar.lat = kid.lat and grand_lar.long = kid.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_kid_rel from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "KIDNAPPING & RELATED OFFENSES" and law_cat_cd = "FELONY") as kid_rel on grand_lar.lat = kid_rel.lat and grand_lar.long = kid_rel.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_kid_rel2 from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "KIDNAPPING AND RELATED OFFENSES" and law_cat_cd = "FELONY") as kid_rel2 on grand_lar.lat = kid_rel2.lat and grand_lar.long = kid_rel2.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 8.3 as c_misc from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "MISCELLANEOUS PENAL LAW" and law_cat_cd = "FELONY") as misc on grand_lar.lat = misc.lat and grand_lar.long = misc.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 22.5 as c_murder from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "MURDER & NON-NEGL. MANSLAUGHTER" and law_cat_cd = "FELONY") as murder on grand_lar.lat = murder.lat and grand_lar.long = murder.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 8.3 as c_uncl from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "NYS LAWS-UNCLASSIFIED FELONY" and law_cat_cd = "FELONY") as uncl on grand_lar.lat = uncl.lat and grand_lar.long = uncl.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 8.3 as c_other from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "OTHER STATE LAWS (NON PENAL LA" and law_cat_cd = "FELONY") as other on grand_lar.lat = other.lat and grand_lar.long = other.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 2 as c_poss from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = " POSSESSION OF STOLEN PROPERTY" and law_cat_cd = "FELONY") as poss on grand_lar.lat = poss.lat and grand_lar.long = poss.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 2 as c_pros from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "PROSTITUTION & RELATED OFFENSES" and law_cat_cd = "FELONY") as pros on grand_lar.lat = pros.lat and grand_lar.long = pros.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_rape from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "RAPE" and law_cat_cd = "FELONY") as rape on grand_lar.lat = rape.lat and grand_lar.long = rape.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_rob from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "ROBBERY" and law_cat_cd = "FELONY") as rob on grand_lar.lat = rob.lat and grand_lar.long = rob.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_s_crimes from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "SEX CRIMES" and law_cat_cd = "FELONY") as s_crimes on grand_lar.lat = s_crimes.lat and grand_lar.long = s_crimes.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 2 as c_theft from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "THEFT FRAUD" and law_cat_cd = "FELONY") as theft on grand_lar.lat = theft.lat and grand_lar.long = theft.long order by sum) as nypd inner join (select online.lat, online.long, c_online, c_phone, c_mobile, c_other from (select round(latitude,2) as lat, round(longitude,2) as long, count(*) as c_online, open_data_channel_type from data_311 group by lat, long, open_data_channel_type having open_data_channel_type = "ONLINE") as online inner join (select round(latitude,2) as lat, round(longitude,2) as long, count(*) as c_phone, open_data_channel_type from data_311 group by lat, long, open_data_channel_type having open_data_channel_type = "PHONE") as phone on online.lat = phone.lat and online.long = phone.long inner join (select round(latitude,2) as lat, round(longitude,2) as long, count(*) as c_mobile, open_data_channel_type from data_311 group by lat, long, open_data_channel_type having open_data_channel_type = "MOBILE") as mobile on online.lat = mobile.lat and online.long = mobile.long inner join (select round(latitude,2) as lat, round(longitude,2) as long, count(*) as c_other, open_data_channel_type from data_311 group by lat, long, open_data_channel_type having open_data_channel_type = "OTHER") as other on online.lat = other.lat and online.long = other.long) as complaints on nypd.lat = complaints.lat and nypd.long = complaints.long order by sum;

-- Show the "crime level" for each location (latitude and longitude rouned to 2 decimal places) alongside the percentage of "Noise - Residential" complaints out of the total 311 complaints for that location

SELECT nypd.lat,
         nypd.long,
         sum,
         c_complaints,
         c_noise,
         c_noise/c_complaints * 100 AS p_noise
FROM 
    (SELECT grand_lar.lat,
         grand_lar.long,
         c_grand_lar + isnull(c_arson,
        0) + isnull(c_hom_neg,
        0) + isnull(c_burg,
        0) + isnull(c_child,
        0) + isnull(c_crim_mis,
        0) + isnull(c_drugs,
        0) + isnull(c_weapons,
        0) + isnull(c_endan,
        0) + isnull(c_assault,
        0) + isnull(c_sex_crimes,
        0) + isnull(c_forgery,
        0) + isnull(c_gambling,
        0) + isnull(c_grand_vehicle,
        0) + isnull(c_hom_vehicle,
        0) + isnull(c_intox,
        0) + isnull(c_kid,
        0) + isnull(c_kid_rel,
        0) + isnull(c_kid_rel2,
        0) + isnull(c_misc,
        0) + isnull(c_murder,
        0) + isnull(c_uncl,
        0) + isnull(c_other,
        0) + isnull(c_poss,
        0) + isnull(c_pros,
        0) + isnull(c_rape,
        0) + isnull(c_rob,
        0) + isnull(c_s_crimes,
        0) + isnull(c_theft,
        0) AS sum
    FROM 
        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_grand_lar
        FROM data_nypd
        GROUP BY  lat, long, law_cat_cd, ofns_desc
        HAVING ofns_desc = "GRAND LARCENY") AS grand_lar
        LEFT JOIN 
            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_arson
            FROM data_nypd
            GROUP BY  lat, long, law_cat_cd, ofns_desc
            HAVING ofns_desc = "ARSON") AS arson
                ON grand_lar.lat = arson.lat
                    AND grand_lar.long = arson.long
            LEFT JOIN 
                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 9.25 AS c_hom_neg
                FROM data_nypd
                GROUP BY  lat, long, law_cat_cd, ofns_desc
                HAVING ofns_desc = "\"HOMICIDE-NEGLIGENT") AS hom_neg
                    ON hom_neg.lat = grand_lar.lat
                        AND grand_lar.long = hom_neg.long
                LEFT JOIN 
                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_burg
                    FROM data_nypd
                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                    HAVING ofns_desc = "BURGLARY") AS burg
                        ON grand_lar.lat = burg.lat
                            AND grand_lar.long = burg.long
                    LEFT JOIN 
                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_child
                        FROM data_nypd
                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                        HAVING ofns_desc = "CHILD ABANDONMENT/NON SUPPORT") AS child
                            ON grand_lar.lat = child.lat
                                AND grand_lar.long = child.long
                        LEFT JOIN 
                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_crim_mis
                            FROM data_nypd
                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                            HAVING ofns_desc = "CRIMINAL MISCHIEF & RELATED OF"
                                    AND law_cat_cd = "FELONY") AS crim_mis
                                ON grand_lar.lat = crim_mis.lat
                                    AND grand_lar.long = crim_mis.long
                            LEFT JOIN 
                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_drugs
                                FROM data_nypd
                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                HAVING ofns_desc = "DANGEROUS DRUGS"
                                        AND law_cat_cd = "FELONY") AS drugs
                                    ON grand_lar.lat = drugs.lat
                                        AND grand_lar.long = drugs.long
                                LEFT JOIN 
                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_weapons
                                    FROM data_nypd
                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                    HAVING ofns_desc = "DANGEROUS WEAPONS"
                                            AND law_cat_cd = "FELONY") AS weapons
                                        ON grand_lar.lat = weapons.lat
                                            AND grand_lar.long = weapons.long
                                    LEFT JOIN 
                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_endan
                                        FROM data_nypd
                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                        HAVING ofns_desc = "ENDAN WELFARE INCOMP"
                                                AND law_cat_cd = "FELONY") AS endan
                                            ON grand_lar.lat = endan.lat
                                                AND grand_lar.long = endan.long
                                        LEFT JOIN 
                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_assault
                                            FROM data_nypd
                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                            HAVING ofns_desc = "FELONY ASSAULT"
                                                    AND law_cat_cd = "FELONY") AS assault
                                                ON grand_lar.lat = assault.lat
                                                    AND grand_lar.long = assault.long
                                            LEFT JOIN 
                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_sex_crimes
                                                FROM data_nypd
                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                HAVING ofns_desc = "FELONY SEX CRIMES"
                                                        AND law_cat_cd = "FELONY") AS sex_crimes
                                                    ON grand_lar.lat = sex_crimes.lat
                                                        AND grand_lar.long = sex_crimes.long
                                                LEFT JOIN 
                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_forgery
                                                    FROM data_nypd
                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                    HAVING ofns_desc = "FORGERY"
                                                            AND law_cat_cd = "FELONY") AS forgery
                                                        ON grand_lar.lat = forgery.lat
                                                            AND grand_lar.long = forgery.long
                                                    LEFT JOIN 
                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_gambling
                                                        FROM data_nypd
                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                        HAVING ofns_desc = "GAMBLING"
                                                                AND law_cat_cd = "FELONY") AS gambling
                                                            ON grand_lar.lat = gambling.lat
                                                                AND grand_lar.long = gambling.long
                                                        LEFT JOIN 
                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_grand_vehicle
                                                            FROM data_nypd
                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                            HAVING ofns_desc = "GRAND LARCENY OF MOTOR VEHICLE"
                                                                    AND law_cat_cd = "FELONY") AS grand_vehicle
                                                                ON grand_lar.lat = grand_vehicle.lat
                                                                    AND grand_lar.long = grand_vehicle.long
                                                            LEFT JOIN 
                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 9.25 AS c_hom_vehicle
                                                                FROM data_nypd
                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                HAVING ofns_desc = "HOMICIDE-NEGLIGENT-VEHICLE"
                                                                        AND law_cat_cd = "FELONY") AS hom_vehicle
                                                                    ON grand_lar.lat = hom_vehicle.lat
                                                                        AND grand_lar.long = hom_vehicle.long
                                                                LEFT JOIN 
                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_intox
                                                                    FROM data_nypd
                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                    HAVING ofns_desc = "INTOXICATED/IMPAIRED DRIVING"
                                                                            AND law_cat_cd = "FELONY") AS intox
                                                                        ON grand_lar.lat = intox.lat
                                                                            AND grand_lar.long = intox.long
                                                                    LEFT JOIN 
                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_kid
                                                                        FROM data_nypd
                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                        HAVING ofns_desc = "KIDNAPPING"
                                                                                AND law_cat_cd = "FELONY") AS kid
                                                                            ON grand_lar.lat = kid.lat
                                                                                AND grand_lar.long = kid.long
                                                                        LEFT JOIN 
                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_kid_rel
                                                                            FROM data_nypd
                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                            HAVING ofns_desc = "KIDNAPPING & RELATED OFFENSES"
                                                                                    AND law_cat_cd = "FELONY") AS kid_rel
                                                                                ON grand_lar.lat = kid_rel.lat
                                                                                    AND grand_lar.long = kid_rel.long
                                                                            LEFT JOIN 
                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_kid_rel2
                                                                                FROM data_nypd
                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                HAVING ofns_desc = "KIDNAPPING
                                                                                        AND RELATED OFFENSES"
                                                                                        AND law_cat_cd = "FELONY") AS kid_rel2
                                                                                    ON grand_lar.lat = kid_rel2.lat
                                                                                        AND grand_lar.long = kid_rel2.long
                                                                                LEFT JOIN 
                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_misc
                                                                                    FROM data_nypd
                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                    HAVING ofns_desc = "MISCELLANEOUS PENAL LAW"
                                                                                            AND law_cat_cd = "FELONY") AS misc
                                                                                        ON grand_lar.lat = misc.lat
                                                                                            AND grand_lar.long = misc.long
                                                                                    LEFT JOIN 
                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_murder
                                                                                        FROM data_nypd
                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                        HAVING ofns_desc = "MURDER & NON-NEGL. MANSLAUGHTER"
                                                                                                AND law_cat_cd = "FELONY") AS murder
                                                                                            ON grand_lar.lat = murder.lat
                                                                                                AND grand_lar.long = murder.long
                                                                                        LEFT JOIN 
                                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_uncl
                                                                                            FROM data_nypd
                                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                            HAVING ofns_desc = "NYS LAWS-UNCLASSIFIED FELONY"
                                                                                                    AND law_cat_cd = "FELONY") AS uncl
                                                                                                ON grand_lar.lat = uncl.lat
                                                                                                    AND grand_lar.long = uncl.long
                                                                                            LEFT JOIN 
                                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_other
                                                                                                FROM data_nypd
                                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                HAVING ofns_desc = "OTHER STATE LAWS (NON PENAL LA"
                                                                                                        AND law_cat_cd = "FELONY") AS other
                                                                                                    ON grand_lar.lat = other.lat
                                                                                                        AND grand_lar.long = other.long
                                                                                                LEFT JOIN 
                                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_poss
                                                                                                    FROM data_nypd
                                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                    HAVING ofns_desc = " POSSESSION OF STOLEN PROPERTY"
                                                                                                            AND law_cat_cd = "FELONY") AS poss
                                                                                                        ON grand_lar.lat = poss.lat
                                                                                                            AND grand_lar.long = poss.long
                                                                                                    LEFT JOIN 
                                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_pros
                                                                                                        FROM data_nypd
                                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                        HAVING ofns_desc = "PROSTITUTION & RELATED OFFENSES"
                                                                                                                AND law_cat_cd = "FELONY") AS pros
                                                                                                            ON grand_lar.lat = pros.lat
                                                                                                                AND grand_lar.long = pros.long
                                                                                                        LEFT JOIN 
                                                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_rape
                                                                                                            FROM data_nypd
                                                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                            HAVING ofns_desc = "RAPE"
                                                                                                                    AND law_cat_cd = "FELONY") AS rape
                                                                                                                ON grand_lar.lat = rape.lat
                                                                                                                    AND grand_lar.long = rape.long
                                                                                                            LEFT JOIN 
                                                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_rob
                                                                                                                FROM data_nypd
                                                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                HAVING ofns_desc = "ROBBERY"
                                                                                                                        AND law_cat_cd = "FELONY") AS rob
                                                                                                                    ON grand_lar.lat = rob.lat
                                                                                                                        AND grand_lar.long = rob.long
                                                                                                                LEFT JOIN 
                                                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_s_crimes
                                                                                                                    FROM data_nypd
                                                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                    HAVING ofns_desc = "SEX CRIMES"
                                                                                                                            AND law_cat_cd = "FELONY") AS s_crimes
                                                                                                                        ON grand_lar.lat = s_crimes.lat
                                                                                                                            AND grand_lar.long = s_crimes.long
                                                                                                                    LEFT JOIN 
                                                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_theft
                                                                                                                        FROM data_nypd
                                                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                        HAVING ofns_desc = "THEFT FRAUD"
                                                                                                                                AND law_cat_cd = "FELONY") AS theft
                                                                                                                            ON grand_lar.lat = theft.lat
                                                                                                                                AND grand_lar.long = theft.long
                                                                                                                        ORDER BY  sum) AS nypd
                                                                                                                        INNER JOIN 
                                                                                                                            (SELECT round(latitude,
         2) AS lat,
         round(longitude,
        2) AS long,
         count(*) AS c_complaints
                                                                                                                            FROM data_311
                                                                                                                            GROUP BY  lat, long) AS complaints
                                                                                                                                ON nypd.lat = complaints.lat
                                                                                                                                    AND nypd.long = complaints.long
                                                                                                                            INNER JOIN 
                                                                                                                                (SELECT round(latitude,
         2) AS lat,
         round(longitude,
        2) AS long,
         complaint_type,
         count(*) AS c_noise
                                                                                                                                FROM data_311
                                                                                                                                GROUP BY  complaint_type, lat, long
                                                                                                                                HAVING complaint_type = "Noise - Residential"
                                                                                                                                ORDER BY  lat, long, count(*)) AS noise
                                                                                                                                    ON nypd.lat = noise.lat
                                                                                                                                        AND nypd.long = noise.long
                                                                                                                                ORDER BY  sum; 


-- Show the "crime level" for each location (latitude and longitude rouned to 2 decimal places) alongside the percentage of "loud music/party" complaints out of the total 311 complaints for that location

SELECT nypd.lat,
         nypd.long,
         sum,
         c_complaints,
         c_music,
         c_music/c_complaints * 100 AS p_noise
FROM 
    (SELECT grand_lar.lat,
         grand_lar.long,
         c_grand_lar + isnull(c_arson,
        0) + isnull(c_hom_neg,
        0) + isnull(c_burg,
        0) + isnull(c_child,
        0) + isnull(c_crim_mis,
        0) + isnull(c_drugs,
        0) + isnull(c_weapons,
        0) + isnull(c_endan,
        0) + isnull(c_assault,
        0) + isnull(c_sex_crimes,
        0) + isnull(c_forgery,
        0) + isnull(c_gambling,
        0) + isnull(c_grand_vehicle,
        0) + isnull(c_hom_vehicle,
        0) + isnull(c_intox,
        0) + isnull(c_kid,
        0) + isnull(c_kid_rel,
        0) + isnull(c_kid_rel2,
        0) + isnull(c_misc,
        0) + isnull(c_murder,
        0) + isnull(c_uncl,
        0) + isnull(c_other,
        0) + isnull(c_poss,
        0) + isnull(c_pros,
        0) + isnull(c_rape,
        0) + isnull(c_rob,
        0) + isnull(c_s_crimes,
        0) + isnull(c_theft,
        0) AS sum
    FROM 
        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_grand_lar
        FROM data_nypd
        GROUP BY  lat, long, law_cat_cd, ofns_desc
        HAVING ofns_desc = "GRAND LARCENY") AS grand_lar
        LEFT JOIN 
            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_arson
            FROM data_nypd
            GROUP BY  lat, long, law_cat_cd, ofns_desc
            HAVING ofns_desc = "ARSON") AS arson
                ON grand_lar.lat = arson.lat
                    AND grand_lar.long = arson.long
            LEFT JOIN 
                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 9.25 AS c_hom_neg
                FROM data_nypd
                GROUP BY  lat, long, law_cat_cd, ofns_desc
                HAVING ofns_desc = "\"HOMICIDE-NEGLIGENT") AS hom_neg
                    ON hom_neg.lat = grand_lar.lat
                        AND grand_lar.long = hom_neg.long
                LEFT JOIN 
                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_burg
                    FROM data_nypd
                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                    HAVING ofns_desc = "BURGLARY") AS burg
                        ON grand_lar.lat = burg.lat
                            AND grand_lar.long = burg.long
                    LEFT JOIN 
                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_child
                        FROM data_nypd
                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                        HAVING ofns_desc = "CHILD ABANDONMENT/NON SUPPORT") AS child
                            ON grand_lar.lat = child.lat
                                AND grand_lar.long = child.long
                        LEFT JOIN 
                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_crim_mis
                            FROM data_nypd
                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                            HAVING ofns_desc = "CRIMINAL MISCHIEF & RELATED OF"
                                    AND law_cat_cd = "FELONY") AS crim_mis
                                ON grand_lar.lat = crim_mis.lat
                                    AND grand_lar.long = crim_mis.long
                            LEFT JOIN 
                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_drugs
                                FROM data_nypd
                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                HAVING ofns_desc = "DANGEROUS DRUGS"
                                        AND law_cat_cd = "FELONY") AS drugs
                                    ON grand_lar.lat = drugs.lat
                                        AND grand_lar.long = drugs.long
                                LEFT JOIN 
                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_weapons
                                    FROM data_nypd
                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                    HAVING ofns_desc = "DANGEROUS WEAPONS"
                                            AND law_cat_cd = "FELONY") AS weapons
                                        ON grand_lar.lat = weapons.lat
                                            AND grand_lar.long = weapons.long
                                    LEFT JOIN 
                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_endan
                                        FROM data_nypd
                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                        HAVING ofns_desc = "ENDAN WELFARE INCOMP"
                                                AND law_cat_cd = "FELONY") AS endan
                                            ON grand_lar.lat = endan.lat
                                                AND grand_lar.long = endan.long
                                        LEFT JOIN 
                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_assault
                                            FROM data_nypd
                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                            HAVING ofns_desc = "FELONY ASSAULT"
                                                    AND law_cat_cd = "FELONY") AS assault
                                                ON grand_lar.lat = assault.lat
                                                    AND grand_lar.long = assault.long
                                            LEFT JOIN 
                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_sex_crimes
                                                FROM data_nypd
                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                HAVING ofns_desc = "FELONY SEX CRIMES"
                                                        AND law_cat_cd = "FELONY") AS sex_crimes
                                                    ON grand_lar.lat = sex_crimes.lat
                                                        AND grand_lar.long = sex_crimes.long
                                                LEFT JOIN 
                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_forgery
                                                    FROM data_nypd
                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                    HAVING ofns_desc = "FORGERY"
                                                            AND law_cat_cd = "FELONY") AS forgery
                                                        ON grand_lar.lat = forgery.lat
                                                            AND grand_lar.long = forgery.long
                                                    LEFT JOIN 
                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_gambling
                                                        FROM data_nypd
                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                        HAVING ofns_desc = "GAMBLING"
                                                                AND law_cat_cd = "FELONY") AS gambling
                                                            ON grand_lar.lat = gambling.lat
                                                                AND grand_lar.long = gambling.long
                                                        LEFT JOIN 
                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_grand_vehicle
                                                            FROM data_nypd
                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                            HAVING ofns_desc = "GRAND LARCENY OF MOTOR VEHICLE"
                                                                    AND law_cat_cd = "FELONY") AS grand_vehicle
                                                                ON grand_lar.lat = grand_vehicle.lat
                                                                    AND grand_lar.long = grand_vehicle.long
                                                            LEFT JOIN 
                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 9.25 AS c_hom_vehicle
                                                                FROM data_nypd
                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                HAVING ofns_desc = "HOMICIDE-NEGLIGENT-VEHICLE"
                                                                        AND law_cat_cd = "FELONY") AS hom_vehicle
                                                                    ON grand_lar.lat = hom_vehicle.lat
                                                                        AND grand_lar.long = hom_vehicle.long
                                                                LEFT JOIN 
                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_intox
                                                                    FROM data_nypd
                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                    HAVING ofns_desc = "INTOXICATED/IMPAIRED DRIVING"
                                                                            AND law_cat_cd = "FELONY") AS intox
                                                                        ON grand_lar.lat = intox.lat
                                                                            AND grand_lar.long = intox.long
                                                                    LEFT JOIN 
                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_kid
                                                                        FROM data_nypd
                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                        HAVING ofns_desc = "KIDNAPPING"
                                                                                AND law_cat_cd = "FELONY") AS kid
                                                                            ON grand_lar.lat = kid.lat
                                                                                AND grand_lar.long = kid.long
                                                                        LEFT JOIN 
                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_kid_rel
                                                                            FROM data_nypd
                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                            HAVING ofns_desc = "KIDNAPPING & RELATED OFFENSES"
                                                                                    AND law_cat_cd = "FELONY") AS kid_rel
                                                                                ON grand_lar.lat = kid_rel.lat
                                                                                    AND grand_lar.long = kid_rel.long
                                                                            LEFT JOIN 
                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_kid_rel2
                                                                                FROM data_nypd
                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                HAVING ofns_desc = "KIDNAPPING
                                                                                        AND RELATED OFFENSES"
                                                                                        AND law_cat_cd = "FELONY") AS kid_rel2
                                                                                    ON grand_lar.lat = kid_rel2.lat
                                                                                        AND grand_lar.long = kid_rel2.long
                                                                                LEFT JOIN 
                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_misc
                                                                                    FROM data_nypd
                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                    HAVING ofns_desc = "MISCELLANEOUS PENAL LAW"
                                                                                            AND law_cat_cd = "FELONY") AS misc
                                                                                        ON grand_lar.lat = misc.lat
                                                                                            AND grand_lar.long = misc.long
                                                                                    LEFT JOIN 
                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_murder
                                                                                        FROM data_nypd
                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                        HAVING ofns_desc = "MURDER & NON-NEGL. MANSLAUGHTER"
                                                                                                AND law_cat_cd = "FELONY") AS murder
                                                                                            ON grand_lar.lat = murder.lat
                                                                                                AND grand_lar.long = murder.long
                                                                                        LEFT JOIN 
                                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_uncl
                                                                                            FROM data_nypd
                                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                            HAVING ofns_desc = "NYS LAWS-UNCLASSIFIED FELONY"
                                                                                                    AND law_cat_cd = "FELONY") AS uncl
                                                                                                ON grand_lar.lat = uncl.lat
                                                                                                    AND grand_lar.long = uncl.long
                                                                                            LEFT JOIN 
                                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_other
                                                                                                FROM data_nypd
                                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                HAVING ofns_desc = "OTHER STATE LAWS (NON PENAL LA"
                                                                                                        AND law_cat_cd = "FELONY") AS other
                                                                                                    ON grand_lar.lat = other.lat
                                                                                                        AND grand_lar.long = other.long
                                                                                                LEFT JOIN 
                                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_poss
                                                                                                    FROM data_nypd
                                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                    HAVING ofns_desc = " POSSESSION OF STOLEN PROPERTY"
                                                                                                            AND law_cat_cd = "FELONY") AS poss
                                                                                                        ON grand_lar.lat = poss.lat
                                                                                                            AND grand_lar.long = poss.long
                                                                                                    LEFT JOIN 
                                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_pros
                                                                                                        FROM data_nypd
                                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                        HAVING ofns_desc = "PROSTITUTION & RELATED OFFENSES"
                                                                                                                AND law_cat_cd = "FELONY") AS pros
                                                                                                            ON grand_lar.lat = pros.lat
                                                                                                                AND grand_lar.long = pros.long
                                                                                                        LEFT JOIN 
                                                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_rape
                                                                                                            FROM data_nypd
                                                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                            HAVING ofns_desc = "RAPE"
                                                                                                                    AND law_cat_cd = "FELONY") AS rape
                                                                                                                ON grand_lar.lat = rape.lat
                                                                                                                    AND grand_lar.long = rape.long
                                                                                                            LEFT JOIN 
                                                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_rob
                                                                                                                FROM data_nypd
                                                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                HAVING ofns_desc = "ROBBERY"
                                                                                                                        AND law_cat_cd = "FELONY") AS rob
                                                                                                                    ON grand_lar.lat = rob.lat
                                                                                                                        AND grand_lar.long = rob.long
                                                                                                                LEFT JOIN 
                                                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_s_crimes
                                                                                                                    FROM data_nypd
                                                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                    HAVING ofns_desc = "SEX CRIMES"
                                                                                                                            AND law_cat_cd = "FELONY") AS s_crimes
                                                                                                                        ON grand_lar.lat = s_crimes.lat
                                                                                                                            AND grand_lar.long = s_crimes.long
                                                                                                                    LEFT JOIN 
                                                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_theft
                                                                                                                        FROM data_nypd
                                                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                        HAVING ofns_desc = "THEFT FRAUD"
                                                                                                                                AND law_cat_cd = "FELONY") AS theft
                                                                                                                            ON grand_lar.lat = theft.lat
                                                                                                                                AND grand_lar.long = theft.long
                                                                                                                        ORDER BY  sum) AS nypd
                                                                                                                        INNER JOIN 
                                                                                                                            (SELECT round(latitude,
         2) AS lat,
         round(longitude,
        2) AS long,
         count(*) AS c_complaints
                                                                                                                            FROM data_311
                                                                                                                            GROUP BY  lat, long) AS complaints
                                                                                                                                ON nypd.lat = complaints.lat
                                                                                                                                    AND nypd.long = complaints.long
                                                                                                                            INNER JOIN 
                                                                                                                                (SELECT round(latitude,
         2) AS lat,
         round(longitude,
        2) AS long,
         descriptor,
         count(*) AS c_music
                                                                                                                                FROM data_311
                                                                                                                                GROUP BY  descriptor, lat, long
                                                                                                                                HAVING descriptor = "Loud Music/Party"
                                                                                                                                ORDER BY  lat, long, count(*)) AS music
                                                                                                                                    ON nypd.lat = music.lat
                                                                                                                                        AND nypd.long = music.long
                                                                                                                                ORDER BY  sum; 


-- Show the "crime level" for each location (latitude and longitude rouned to 2 decimal places) alongside the percentage of "General Construction/Plumbing" complaints out of the total 311 complaints for that location

SELECT nypd.lat,
         nypd.long,
         sum,
         c_complaints,
         c_con,
         c_con/c_complaints * 100 AS p_con
FROM 
    (SELECT grand_lar.lat,
         grand_lar.long,
         c_grand_lar + isnull(c_arson,
        0) + isnull(c_hom_neg,
        0) + isnull(c_burg,
        0) + isnull(c_child,
        0) + isnull(c_crim_mis,
        0) + isnull(c_drugs,
        0) + isnull(c_weapons,
        0) + isnull(c_endan,
        0) + isnull(c_assault,
        0) + isnull(c_sex_crimes,
        0) + isnull(c_forgery,
        0) + isnull(c_gambling,
        0) + isnull(c_grand_vehicle,
        0) + isnull(c_hom_vehicle,
        0) + isnull(c_intox,
        0) + isnull(c_kid,
        0) + isnull(c_kid_rel,
        0) + isnull(c_kid_rel2,
        0) + isnull(c_misc,
        0) + isnull(c_murder,
        0) + isnull(c_uncl,
        0) + isnull(c_other,
        0) + isnull(c_poss,
        0) + isnull(c_pros,
        0) + isnull(c_rape,
        0) + isnull(c_rob,
        0) + isnull(c_s_crimes,
        0) + isnull(c_theft,
        0) AS sum
    FROM 
        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_grand_lar
        FROM data_nypd
        GROUP BY  lat, long, law_cat_cd, ofns_desc
        HAVING ofns_desc = "GRAND LARCENY") AS grand_lar
        LEFT JOIN 
            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_arson
            FROM data_nypd
            GROUP BY  lat, long, law_cat_cd, ofns_desc
            HAVING ofns_desc = "ARSON") AS arson
                ON grand_lar.lat = arson.lat
                    AND grand_lar.long = arson.long
            LEFT JOIN 
                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 9.25 AS c_hom_neg
                FROM data_nypd
                GROUP BY  lat, long, law_cat_cd, ofns_desc
                HAVING ofns_desc = "\"HOMICIDE-NEGLIGENT") AS hom_neg
                    ON hom_neg.lat = grand_lar.lat
                        AND grand_lar.long = hom_neg.long
                LEFT JOIN 
                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_burg
                    FROM data_nypd
                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                    HAVING ofns_desc = "BURGLARY") AS burg
                        ON grand_lar.lat = burg.lat
                            AND grand_lar.long = burg.long
                    LEFT JOIN 
                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_child
                        FROM data_nypd
                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                        HAVING ofns_desc = "CHILD ABANDONMENT/NON SUPPORT") AS child
                            ON grand_lar.lat = child.lat
                                AND grand_lar.long = child.long
                        LEFT JOIN 
                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_crim_mis
                            FROM data_nypd
                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                            HAVING ofns_desc = "CRIMINAL MISCHIEF & RELATED OF"
                                    AND law_cat_cd = "FELONY") AS crim_mis
                                ON grand_lar.lat = crim_mis.lat
                                    AND grand_lar.long = crim_mis.long
                            LEFT JOIN 
                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_drugs
                                FROM data_nypd
                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                HAVING ofns_desc = "DANGEROUS DRUGS"
                                        AND law_cat_cd = "FELONY") AS drugs
                                    ON grand_lar.lat = drugs.lat
                                        AND grand_lar.long = drugs.long
                                LEFT JOIN 
                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_weapons
                                    FROM data_nypd
                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                    HAVING ofns_desc = "DANGEROUS WEAPONS"
                                            AND law_cat_cd = "FELONY") AS weapons
                                        ON grand_lar.lat = weapons.lat
                                            AND grand_lar.long = weapons.long
                                    LEFT JOIN 
                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_endan
                                        FROM data_nypd
                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                        HAVING ofns_desc = "ENDAN WELFARE INCOMP"
                                                AND law_cat_cd = "FELONY") AS endan
                                            ON grand_lar.lat = endan.lat
                                                AND grand_lar.long = endan.long
                                        LEFT JOIN 
                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_assault
                                            FROM data_nypd
                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                            HAVING ofns_desc = "FELONY ASSAULT"
                                                    AND law_cat_cd = "FELONY") AS assault
                                                ON grand_lar.lat = assault.lat
                                                    AND grand_lar.long = assault.long
                                            LEFT JOIN 
                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_sex_crimes
                                                FROM data_nypd
                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                HAVING ofns_desc = "FELONY SEX CRIMES"
                                                        AND law_cat_cd = "FELONY") AS sex_crimes
                                                    ON grand_lar.lat = sex_crimes.lat
                                                        AND grand_lar.long = sex_crimes.long
                                                LEFT JOIN 
                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_forgery
                                                    FROM data_nypd
                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                    HAVING ofns_desc = "FORGERY"
                                                            AND law_cat_cd = "FELONY") AS forgery
                                                        ON grand_lar.lat = forgery.lat
                                                            AND grand_lar.long = forgery.long
                                                    LEFT JOIN 
                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_gambling
                                                        FROM data_nypd
                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                        HAVING ofns_desc = "GAMBLING"
                                                                AND law_cat_cd = "FELONY") AS gambling
                                                            ON grand_lar.lat = gambling.lat
                                                                AND grand_lar.long = gambling.long
                                                        LEFT JOIN 
                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_grand_vehicle
                                                            FROM data_nypd
                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                            HAVING ofns_desc = "GRAND LARCENY OF MOTOR VEHICLE"
                                                                    AND law_cat_cd = "FELONY") AS grand_vehicle
                                                                ON grand_lar.lat = grand_vehicle.lat
                                                                    AND grand_lar.long = grand_vehicle.long
                                                            LEFT JOIN 
                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 9.25 AS c_hom_vehicle
                                                                FROM data_nypd
                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                HAVING ofns_desc = "HOMICIDE-NEGLIGENT-VEHICLE"
                                                                        AND law_cat_cd = "FELONY") AS hom_vehicle
                                                                    ON grand_lar.lat = hom_vehicle.lat
                                                                        AND grand_lar.long = hom_vehicle.long
                                                                LEFT JOIN 
                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_intox
                                                                    FROM data_nypd
                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                    HAVING ofns_desc = "INTOXICATED/IMPAIRED DRIVING"
                                                                            AND law_cat_cd = "FELONY") AS intox
                                                                        ON grand_lar.lat = intox.lat
                                                                            AND grand_lar.long = intox.long
                                                                    LEFT JOIN 
                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_kid
                                                                        FROM data_nypd
                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                        HAVING ofns_desc = "KIDNAPPING"
                                                                                AND law_cat_cd = "FELONY") AS kid
                                                                            ON grand_lar.lat = kid.lat
                                                                                AND grand_lar.long = kid.long
                                                                        LEFT JOIN 
                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_kid_rel
                                                                            FROM data_nypd
                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                            HAVING ofns_desc = "KIDNAPPING & RELATED OFFENSES"
                                                                                    AND law_cat_cd = "FELONY") AS kid_rel
                                                                                ON grand_lar.lat = kid_rel.lat
                                                                                    AND grand_lar.long = kid_rel.long
                                                                            LEFT JOIN 
                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_kid_rel2
                                                                                FROM data_nypd
                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                HAVING ofns_desc = "KIDNAPPING
                                                                                        AND RELATED OFFENSES"
                                                                                        AND law_cat_cd = "FELONY") AS kid_rel2
                                                                                    ON grand_lar.lat = kid_rel2.lat
                                                                                        AND grand_lar.long = kid_rel2.long
                                                                                LEFT JOIN 
                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_misc
                                                                                    FROM data_nypd
                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                    HAVING ofns_desc = "MISCELLANEOUS PENAL LAW"
                                                                                            AND law_cat_cd = "FELONY") AS misc
                                                                                        ON grand_lar.lat = misc.lat
                                                                                            AND grand_lar.long = misc.long
                                                                                    LEFT JOIN 
                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_murder
                                                                                        FROM data_nypd
                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                        HAVING ofns_desc = "MURDER & NON-NEGL. MANSLAUGHTER"
                                                                                                AND law_cat_cd = "FELONY") AS murder
                                                                                            ON grand_lar.lat = murder.lat
                                                                                                AND grand_lar.long = murder.long
                                                                                        LEFT JOIN 
                                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_uncl
                                                                                            FROM data_nypd
                                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                            HAVING ofns_desc = "NYS LAWS-UNCLASSIFIED FELONY"
                                                                                                    AND law_cat_cd = "FELONY") AS uncl
                                                                                                ON grand_lar.lat = uncl.lat
                                                                                                    AND grand_lar.long = uncl.long
                                                                                            LEFT JOIN 
                                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_other
                                                                                                FROM data_nypd
                                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                HAVING ofns_desc = "OTHER STATE LAWS (NON PENAL LA"
                                                                                                        AND law_cat_cd = "FELONY") AS other
                                                                                                    ON grand_lar.lat = other.lat
                                                                                                        AND grand_lar.long = other.long
                                                                                                LEFT JOIN 
                                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_poss
                                                                                                    FROM data_nypd
                                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                    HAVING ofns_desc = " POSSESSION OF STOLEN PROPERTY"
                                                                                                            AND law_cat_cd = "FELONY") AS poss
                                                                                                        ON grand_lar.lat = poss.lat
                                                                                                            AND grand_lar.long = poss.long
                                                                                                    LEFT JOIN 
                                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_pros
                                                                                                        FROM data_nypd
                                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                        HAVING ofns_desc = "PROSTITUTION & RELATED OFFENSES"
                                                                                                                AND law_cat_cd = "FELONY") AS pros
                                                                                                            ON grand_lar.lat = pros.lat
                                                                                                                AND grand_lar.long = pros.long
                                                                                                        LEFT JOIN 
                                                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_rape
                                                                                                            FROM data_nypd
                                                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                            HAVING ofns_desc = "RAPE"
                                                                                                                    AND law_cat_cd = "FELONY") AS rape
                                                                                                                ON grand_lar.lat = rape.lat
                                                                                                                    AND grand_lar.long = rape.long
                                                                                                            LEFT JOIN 
                                                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_rob
                                                                                                                FROM data_nypd
                                                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                HAVING ofns_desc = "ROBBERY"
                                                                                                                        AND law_cat_cd = "FELONY") AS rob
                                                                                                                    ON grand_lar.lat = rob.lat
                                                                                                                        AND grand_lar.long = rob.long
                                                                                                                LEFT JOIN 
                                                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_s_crimes
                                                                                                                    FROM data_nypd
                                                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                    HAVING ofns_desc = "SEX CRIMES"
                                                                                                                            AND law_cat_cd = "FELONY") AS s_crimes
                                                                                                                        ON grand_lar.lat = s_crimes.lat
                                                                                                                            AND grand_lar.long = s_crimes.long
                                                                                                                    LEFT JOIN 
                                                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_theft
                                                                                                                        FROM data_nypd
                                                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                        HAVING ofns_desc = "THEFT FRAUD"
                                                                                                                                AND law_cat_cd = "FELONY") AS theft
                                                                                                                            ON grand_lar.lat = theft.lat
                                                                                                                                AND grand_lar.long = theft.long
                                                                                                                        ORDER BY  sum) AS nypd
                                                                                                                        INNER JOIN 
                                                                                                                            (SELECT round(latitude,
         2) AS lat,
         round(longitude,
        2) AS long,
         count(*) AS c_complaints
                                                                                                                            FROM data_311
                                                                                                                            GROUP BY  lat, long) AS complaints
                                                                                                                                ON nypd.lat = complaints.lat
                                                                                                                                    AND nypd.long = complaints.long
                                                                                                                            INNER JOIN 
                                                                                                                                (SELECT round(latitude,
         2) AS lat,
         round(longitude,
        2) AS long,
         complaint_type,
         count(*) AS c_con
                                                                                                                                FROM data_311
                                                                                                                                GROUP BY  complaint_type, lat, long
                                                                                                                                HAVING complaint_type = "General Construction/Plumbing"
                                                                                                                                ORDER BY  lat, long, count(*)) AS constr
                                                                                                                                    ON nypd.lat = constr.lat
                                                                                                                                        AND nypd.long = constr.long
                                                                                                                                ORDER BY  sum; 

-- Show the "crime level" for each location (latitude and longitude rouned to 2 decimal places) alongside the percentage of "Blocked Driveway" complaints out of the total 311 complaints for that location

SELECT nypd.lat,
         nypd.long,
         sum,
         c_complaints,
         c_block,
         c_block/c_complaints * 100 AS p_block
FROM 
    (SELECT grand_lar.lat,
         grand_lar.long,
         c_grand_lar + isnull(c_arson,
        0) + isnull(c_hom_neg,
        0) + isnull(c_burg,
        0) + isnull(c_child,
        0) + isnull(c_crim_mis,
        0) + isnull(c_drugs,
        0) + isnull(c_weapons,
        0) + isnull(c_endan,
        0) + isnull(c_assault,
        0) + isnull(c_sex_crimes,
        0) + isnull(c_forgery,
        0) + isnull(c_gambling,
        0) + isnull(c_grand_vehicle,
        0) + isnull(c_hom_vehicle,
        0) + isnull(c_intox,
        0) + isnull(c_kid,
        0) + isnull(c_kid_rel,
        0) + isnull(c_kid_rel2,
        0) + isnull(c_misc,
        0) + isnull(c_murder,
        0) + isnull(c_uncl,
        0) + isnull(c_other,
        0) + isnull(c_poss,
        0) + isnull(c_pros,
        0) + isnull(c_rape,
        0) + isnull(c_rob,
        0) + isnull(c_s_crimes,
        0) + isnull(c_theft,
        0) AS sum
    FROM 
        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_grand_lar
        FROM data_nypd
        GROUP BY  lat, long, law_cat_cd, ofns_desc
        HAVING ofns_desc = "GRAND LARCENY") AS grand_lar
        LEFT JOIN 
            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_arson
            FROM data_nypd
            GROUP BY  lat, long, law_cat_cd, ofns_desc
            HAVING ofns_desc = "ARSON") AS arson
                ON grand_lar.lat = arson.lat
                    AND grand_lar.long = arson.long
            LEFT JOIN 
                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 9.25 AS c_hom_neg
                FROM data_nypd
                GROUP BY  lat, long, law_cat_cd, ofns_desc
                HAVING ofns_desc = "\"HOMICIDE-NEGLIGENT") AS hom_neg
                    ON hom_neg.lat = grand_lar.lat
                        AND grand_lar.long = hom_neg.long
                LEFT JOIN 
                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_burg
                    FROM data_nypd
                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                    HAVING ofns_desc = "BURGLARY") AS burg
                        ON grand_lar.lat = burg.lat
                            AND grand_lar.long = burg.long
                    LEFT JOIN 
                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_child
                        FROM data_nypd
                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                        HAVING ofns_desc = "CHILD ABANDONMENT/NON SUPPORT") AS child
                            ON grand_lar.lat = child.lat
                                AND grand_lar.long = child.long
                        LEFT JOIN 
                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_crim_mis
                            FROM data_nypd
                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                            HAVING ofns_desc = "CRIMINAL MISCHIEF & RELATED OF"
                                    AND law_cat_cd = "FELONY") AS crim_mis
                                ON grand_lar.lat = crim_mis.lat
                                    AND grand_lar.long = crim_mis.long
                            LEFT JOIN 
                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_drugs
                                FROM data_nypd
                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                HAVING ofns_desc = "DANGEROUS DRUGS"
                                        AND law_cat_cd = "FELONY") AS drugs
                                    ON grand_lar.lat = drugs.lat
                                        AND grand_lar.long = drugs.long
                                LEFT JOIN 
                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_weapons
                                    FROM data_nypd
                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                    HAVING ofns_desc = "DANGEROUS WEAPONS"
                                            AND law_cat_cd = "FELONY") AS weapons
                                        ON grand_lar.lat = weapons.lat
                                            AND grand_lar.long = weapons.long
                                    LEFT JOIN 
                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_endan
                                        FROM data_nypd
                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                        HAVING ofns_desc = "ENDAN WELFARE INCOMP"
                                                AND law_cat_cd = "FELONY") AS endan
                                            ON grand_lar.lat = endan.lat
                                                AND grand_lar.long = endan.long
                                        LEFT JOIN 
                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_assault
                                            FROM data_nypd
                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                            HAVING ofns_desc = "FELONY ASSAULT"
                                                    AND law_cat_cd = "FELONY") AS assault
                                                ON grand_lar.lat = assault.lat
                                                    AND grand_lar.long = assault.long
                                            LEFT JOIN 
                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_sex_crimes
                                                FROM data_nypd
                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                HAVING ofns_desc = "FELONY SEX CRIMES"
                                                        AND law_cat_cd = "FELONY") AS sex_crimes
                                                    ON grand_lar.lat = sex_crimes.lat
                                                        AND grand_lar.long = sex_crimes.long
                                                LEFT JOIN 
                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_forgery
                                                    FROM data_nypd
                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                    HAVING ofns_desc = "FORGERY"
                                                            AND law_cat_cd = "FELONY") AS forgery
                                                        ON grand_lar.lat = forgery.lat
                                                            AND grand_lar.long = forgery.long
                                                    LEFT JOIN 
                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_gambling
                                                        FROM data_nypd
                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                        HAVING ofns_desc = "GAMBLING"
                                                                AND law_cat_cd = "FELONY") AS gambling
                                                            ON grand_lar.lat = gambling.lat
                                                                AND grand_lar.long = gambling.long
                                                        LEFT JOIN 
                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_grand_vehicle
                                                            FROM data_nypd
                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                            HAVING ofns_desc = "GRAND LARCENY OF MOTOR VEHICLE"
                                                                    AND law_cat_cd = "FELONY") AS grand_vehicle
                                                                ON grand_lar.lat = grand_vehicle.lat
                                                                    AND grand_lar.long = grand_vehicle.long
                                                            LEFT JOIN 
                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 9.25 AS c_hom_vehicle
                                                                FROM data_nypd
                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                HAVING ofns_desc = "HOMICIDE-NEGLIGENT-VEHICLE"
                                                                        AND law_cat_cd = "FELONY") AS hom_vehicle
                                                                    ON grand_lar.lat = hom_vehicle.lat
                                                                        AND grand_lar.long = hom_vehicle.long
                                                                LEFT JOIN 
                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) AS c_intox
                                                                    FROM data_nypd
                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                    HAVING ofns_desc = "INTOXICATED/IMPAIRED DRIVING"
                                                                            AND law_cat_cd = "FELONY") AS intox
                                                                        ON grand_lar.lat = intox.lat
                                                                            AND grand_lar.long = intox.long
                                                                    LEFT JOIN 
                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_kid
                                                                        FROM data_nypd
                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                        HAVING ofns_desc = "KIDNAPPING"
                                                                                AND law_cat_cd = "FELONY") AS kid
                                                                            ON grand_lar.lat = kid.lat
                                                                                AND grand_lar.long = kid.long
                                                                        LEFT JOIN 
                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_kid_rel
                                                                            FROM data_nypd
                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                            HAVING ofns_desc = "KIDNAPPING & RELATED OFFENSES"
                                                                                    AND law_cat_cd = "FELONY") AS kid_rel
                                                                                ON grand_lar.lat = kid_rel.lat
                                                                                    AND grand_lar.long = kid_rel.long
                                                                            LEFT JOIN 
                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_kid_rel2
                                                                                FROM data_nypd
                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                HAVING ofns_desc = "KIDNAPPING
                                                                                        AND RELATED OFFENSES"
                                                                                        AND law_cat_cd = "FELONY") AS kid_rel2
                                                                                    ON grand_lar.lat = kid_rel2.lat
                                                                                        AND grand_lar.long = kid_rel2.long
                                                                                LEFT JOIN 
                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_misc
                                                                                    FROM data_nypd
                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                    HAVING ofns_desc = "MISCELLANEOUS PENAL LAW"
                                                                                            AND law_cat_cd = "FELONY") AS misc
                                                                                        ON grand_lar.lat = misc.lat
                                                                                            AND grand_lar.long = misc.long
                                                                                    LEFT JOIN 
                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 22.5 AS c_murder
                                                                                        FROM data_nypd
                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                        HAVING ofns_desc = "MURDER & NON-NEGL. MANSLAUGHTER"
                                                                                                AND law_cat_cd = "FELONY") AS murder
                                                                                            ON grand_lar.lat = murder.lat
                                                                                                AND grand_lar.long = murder.long
                                                                                        LEFT JOIN 
                                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_uncl
                                                                                            FROM data_nypd
                                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                            HAVING ofns_desc = "NYS LAWS-UNCLASSIFIED FELONY"
                                                                                                    AND law_cat_cd = "FELONY") AS uncl
                                                                                                ON grand_lar.lat = uncl.lat
                                                                                                    AND grand_lar.long = uncl.long
                                                                                            LEFT JOIN 
                                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 8.3 AS c_other
                                                                                                FROM data_nypd
                                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                HAVING ofns_desc = "OTHER STATE LAWS (NON PENAL LA"
                                                                                                        AND law_cat_cd = "FELONY") AS other
                                                                                                    ON grand_lar.lat = other.lat
                                                                                                        AND grand_lar.long = other.long
                                                                                                LEFT JOIN 
                                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_poss
                                                                                                    FROM data_nypd
                                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                    HAVING ofns_desc = " POSSESSION OF STOLEN PROPERTY"
                                                                                                            AND law_cat_cd = "FELONY") AS poss
                                                                                                        ON grand_lar.lat = poss.lat
                                                                                                            AND grand_lar.long = poss.long
                                                                                                    LEFT JOIN 
                                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_pros
                                                                                                        FROM data_nypd
                                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                        HAVING ofns_desc = "PROSTITUTION & RELATED OFFENSES"
                                                                                                                AND law_cat_cd = "FELONY") AS pros
                                                                                                            ON grand_lar.lat = pros.lat
                                                                                                                AND grand_lar.long = pros.long
                                                                                                        LEFT JOIN 
                                                                                                            (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_rape
                                                                                                            FROM data_nypd
                                                                                                            GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                            HAVING ofns_desc = "RAPE"
                                                                                                                    AND law_cat_cd = "FELONY") AS rape
                                                                                                                ON grand_lar.lat = rape.lat
                                                                                                                    AND grand_lar.long = rape.long
                                                                                                            LEFT JOIN 
                                                                                                                (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_rob
                                                                                                                FROM data_nypd
                                                                                                                GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                HAVING ofns_desc = "ROBBERY"
                                                                                                                        AND law_cat_cd = "FELONY") AS rob
                                                                                                                    ON grand_lar.lat = rob.lat
                                                                                                                        AND grand_lar.long = rob.long
                                                                                                                LEFT JOIN 
                                                                                                                    (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 15 AS c_s_crimes
                                                                                                                    FROM data_nypd
                                                                                                                    GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                    HAVING ofns_desc = "SEX CRIMES"
                                                                                                                            AND law_cat_cd = "FELONY") AS s_crimes
                                                                                                                        ON grand_lar.lat = s_crimes.lat
                                                                                                                            AND grand_lar.long = s_crimes.long
                                                                                                                    LEFT JOIN 
                                                                                                                        (SELECT round(latitude,
        2) AS lat,
         round(longitude,
        2) AS long,
         ofns_desc,
         count(*) * 2 AS c_theft
                                                                                                                        FROM data_nypd
                                                                                                                        GROUP BY  lat, long, law_cat_cd, ofns_desc
                                                                                                                        HAVING ofns_desc = "THEFT FRAUD"
                                                                                                                                AND law_cat_cd = "FELONY") AS theft
                                                                                                                            ON grand_lar.lat = theft.lat
                                                                                                                                AND grand_lar.long = theft.long
                                                                                                                        ORDER BY  sum) AS nypd
                                                                                                                        INNER JOIN 
                                                                                                                            (SELECT round(latitude,
         2) AS lat,
         round(longitude,
        2) AS long,
         count(*) AS c_complaints
                                                                                                                            FROM data_311
                                                                                                                            GROUP BY  lat, long) AS complaints
                                                                                                                                ON nypd.lat = complaints.lat
                                                                                                                                    AND nypd.long = complaints.long
                                                                                                                            INNER JOIN 
                                                                                                                                (SELECT round(latitude,
         2) AS lat,
         round(longitude,
        2) AS long,
         complaint_type,
         count(*) AS c_block
                                                                                                                                FROM data_311
                                                                                                                                GROUP BY  complaint_type, lat, long
                                                                                                                                HAVING complaint_type = "Blocked Driveway"
                                                                                                                                ORDER BY  lat, long, count(*)) AS block
                                                                                                                                    ON nypd.lat = block.lat
                                                                                                                                        AND nypd.long = block.long
                                                                                                                                ORDER BY  sum; 


-- Show the "crime level" for each location (latitude and longitude rouned to 2 decimal places) alongside the percentage of "Request Large Bulky Item Collection" complaints out of the total 311 complaints for that location

select nypd.lat, nypd.long, sum, c_complaints, c_bulk, c_bulk/c_complaints * 100 as p_bulk from (select grand_lar.lat, grand_lar.long, c_grand_lar + isnull(c_arson,0) + isnull(c_hom_neg,0) + isnull(c_burg,0) + isnull(c_child,0) + isnull(c_crim_mis,0) + isnull(c_drugs,0) + isnull(c_weapons,0) + isnull(c_endan,0) + isnull(c_assault,0) + isnull(c_sex_crimes,0) + isnull(c_forgery,0) + isnull(c_gambling,0) + isnull(c_grand_vehicle,0) + isnull(c_hom_vehicle,0) + isnull(c_intox,0) + isnull(c_kid,0) + isnull(c_kid_rel,0) + isnull(c_kid_rel2,0) + isnull(c_misc,0) + isnull(c_murder,0) + isnull(c_uncl,0) + isnull(c_other,0) + isnull(c_poss,0) + isnull(c_pros,0) + isnull(c_rape,0) + isnull(c_rob,0) + isnull(c_s_crimes,0) + isnull(c_theft,0) as sum from (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 2 as c_grand_lar from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "GRAND LARCENY") as grand_lar left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 22.5 as c_arson from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "ARSON") as arson on grand_lar.lat = arson.lat and grand_lar.long = arson.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 9.25 as c_hom_neg from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "\"HOMICIDE-NEGLIGENT") as hom_neg on hom_neg.lat = grand_lar.lat and grand_lar.long = hom_neg.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_burg from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "BURGLARY") as burg on grand_lar.lat = burg.lat and grand_lar.long = burg.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) as c_child from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "CHILD ABANDONMENT/NON SUPPORT") as child on grand_lar.lat = child.lat and grand_lar.long = child.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 2 as c_crim_mis from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "CRIMINAL MISCHIEF & RELATED OF" and law_cat_cd = "FELONY") as crim_mis on grand_lar.lat = crim_mis.lat and grand_lar.long = crim_mis.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) as c_drugs from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "DANGEROUS DRUGS" and law_cat_cd = "FELONY") as drugs on grand_lar.lat = drugs.lat and grand_lar.long = drugs.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_weapons from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "DANGEROUS WEAPONS" and law_cat_cd = "FELONY") as weapons on grand_lar.lat = weapons.lat and grand_lar.long = weapons.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) as c_endan from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "ENDAN WELFARE INCOMP" and law_cat_cd = "FELONY") as endan on grand_lar.lat = endan.lat and grand_lar.long = endan.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_assault from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "FELONY ASSAULT" and law_cat_cd = "FELONY") as assault on grand_lar.lat = assault.lat and grand_lar.long = assault.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_sex_crimes from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "FELONY SEX CRIMES" and law_cat_cd = "FELONY") as sex_crimes on grand_lar.lat = sex_crimes.lat and grand_lar.long = sex_crimes.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) as c_forgery from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "FORGERY" and law_cat_cd = "FELONY") as forgery on grand_lar.lat = forgery.lat and grand_lar.long = forgery.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) as c_gambling from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "GAMBLING" and law_cat_cd = "FELONY") as gambling on grand_lar.lat = gambling.lat and grand_lar.long = gambling.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 2 as c_grand_vehicle from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "GRAND LARCENY OF MOTOR VEHICLE" and law_cat_cd = "FELONY") as grand_vehicle on grand_lar.lat = grand_vehicle.lat and grand_lar.long = grand_vehicle.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 9.25 as c_hom_vehicle from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "HOMICIDE-NEGLIGENT-VEHICLE" and law_cat_cd = "FELONY") as hom_vehicle on grand_lar.lat = hom_vehicle.lat and grand_lar.long = hom_vehicle.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) as c_intox from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "INTOXICATED/IMPAIRED DRIVING" and law_cat_cd = "FELONY") as intox on grand_lar.lat = intox.lat and grand_lar.long = intox.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 22.5 as c_kid from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "KIDNAPPING" and law_cat_cd = "FELONY") as kid on grand_lar.lat = kid.lat and grand_lar.long = kid.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_kid_rel from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "KIDNAPPING & RELATED OFFENSES" and law_cat_cd = "FELONY") as kid_rel on grand_lar.lat = kid_rel.lat and grand_lar.long = kid_rel.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_kid_rel2 from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "KIDNAPPING AND RELATED OFFENSES" and law_cat_cd = "FELONY") as kid_rel2 on grand_lar.lat = kid_rel2.lat and grand_lar.long = kid_rel2.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 8.3 as c_misc from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "MISCELLANEOUS PENAL LAW" and law_cat_cd = "FELONY") as misc on grand_lar.lat = misc.lat and grand_lar.long = misc.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 22.5 as c_murder from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "MURDER & NON-NEGL. MANSLAUGHTER" and law_cat_cd = "FELONY") as murder on grand_lar.lat = murder.lat and grand_lar.long = murder.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 8.3 as c_uncl from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "NYS LAWS-UNCLASSIFIED FELONY" and law_cat_cd = "FELONY") as uncl on grand_lar.lat = uncl.lat and grand_lar.long = uncl.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 8.3 as c_other from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "OTHER STATE LAWS (NON PENAL LA" and law_cat_cd = "FELONY") as other on grand_lar.lat = other.lat and grand_lar.long = other.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 2 as c_poss from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = " POSSESSION OF STOLEN PROPERTY" and law_cat_cd = "FELONY") as poss on grand_lar.lat = poss.lat and grand_lar.long = poss.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 2 as c_pros from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "PROSTITUTION & RELATED OFFENSES" and law_cat_cd = "FELONY") as pros on grand_lar.lat = pros.lat and grand_lar.long = pros.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_rape from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "RAPE" and law_cat_cd = "FELONY") as rape on grand_lar.lat = rape.lat and grand_lar.long = rape.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_rob from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "ROBBERY" and law_cat_cd = "FELONY") as rob on grand_lar.lat = rob.lat and grand_lar.long = rob.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 15 as c_s_crimes from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "SEX CRIMES" and law_cat_cd = "FELONY") as s_crimes on grand_lar.lat = s_crimes.lat and grand_lar.long = s_crimes.long left join (select round(latitude,2) as lat, round(longitude,2) as long, ofns_desc, count(*) * 2 as c_theft from data_nypd group by lat, long, law_cat_cd, ofns_desc having ofns_desc = "THEFT FRAUD" and law_cat_cd = "FELONY") as theft on grand_lar.lat = theft.lat and grand_lar.long = theft.long order by sum) as nypd inner join (select round(latitude, 2) as lat, round(longitude,2) as long, count(*) as c_complaints from data_311 group by lat, long) as complaints on nypd.lat = complaints.lat and nypd.long = complaints.long inner join (select round(latitude, 2) as lat, round(longitude,2) as long, complaint_type, count(*) as c_bulk from data_311 group by complaint_type, lat, long having complaint_type = "Request Large Bulky Item Collection" order by lat, long, count(*)) as bulk on nypd.lat = bulk.lat and nypd.long = bulk.long order by sum; 
