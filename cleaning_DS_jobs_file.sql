-- Creating a Table in my local database to start cleaning the data
CREATE TABLE jobs_glassdoor (
      id bigint PRIMARY KEY,
      job_title text,
      salary_estimate text,
      job_description text,
      rating numeric(4,2),
      company_name text,
      location text,
      headquarters text,
      size text,
      founded smallint,
      type_of_ownership text,
      industry text,
      sector text,
      revenue text,
      Competitors text

);

COPY jobs_glassdoor FROM 'pathToFile' WITH (FORMAT CSV HEADER);

-- Creating a backup table
CREATE TABLE jobs_glassdoor_backup AS
SELECT * FROM jobs_glassdoor;


-- Changing the format of the salary estimate column and his data type to number
UPDATE jobs_glassdoor j1
SET salary_estimate =  (
    SELECT SPLIT_PART(salary_estimate, '(',1)
    FROM jobs_glassdoor j2
    WHERE j1.id = j2.id
)


-- adding two new columns to divide the estimate salary column into min and max
ALTER TABLE jobs_glassdoor ADD COLUMN min_salary_estimate int;
ALTER TABLE jobs_glassdoor ADD COLUMN max_salary_estimate int;
UPDATE jobs_glassdoor j1
SET min_salary_estimate = (
        SELECT CAST(
               CONCAT(
               SPLIT_PART(SPLIT_PART(salary_estimate, '$',2), 'K',1)    
               ,'000')
            AS int)
        FROM jobs_glassdoor j2
        WHERE j1.id = j2.id
);
UPDATE jobs_glassdoor j1
SET max_salary_estimate = (
        SELECT CAST(
               CONCAT(
               SPLIT_PART(SPLIT_PART(salary_estimate, '$',3), 'K',1)    
               ,'000')
            AS int)
        FROM jobs_glassdoor j2
        WHERE j1.id = j2.id
);


-- Trying to understand the job_title column, how we can clean it and then droping the rows that don't correspond to a Data Scientist position
SELECT job_title, count(job_title)
FROM jobs_glassdoor
GROUP BY job_title
ORDER BY count(job_title) DESC;


-- Removing the jobs that does not correspond to Data Scientist
DELETE FROM jobs_glassdoor
WHERE ( 
        job_title NOT LIKE '%Data Scientist%'
    AND job_title NOT LIKE '%Machine Learning%'
    AND job_title NOT LIKE '%Data Science%'
    AND job_Title NOT LIKE '%Deep Learning%'
      )

-- Adding a job_level column 
ALTER TABLE jobs_glassdoor ADD COLUMN job_level text;

-- Updating the job_level column with the Senior level
START TRANSACTION

UPDATE jobs_glassdoor j1
SET job_level = (
        SELECT
        CASE
            WHEN job_title LIKE ANY (array['%Sr%', '%Senior%', '%Lead%', '%Principal%','%Experienced%', '%Director%','%Manager%' ])THEN 'Senior'
			ELSE 'Unknown'
			END AS new_column
        FROM jobs_glassdoor j2
        WHERE j1.id = j2.id
)

SELECT * FROM jobs_glassdoor
ORDER BY job_level;

COMMIT; -- Only commit after checking that the data is updated in the way we want it to

-- Updating the job title column with Data Scientist for consistency
START TRANSACTION;

UPDATE jobs_glassdoor
SET job_title = 'Data Scientist';

COMMIT;

-- Updating the null values of the numeric columns to average

UPDATE jobs_glassdoor
SET rating =(
               SELECT
               avg(rating)
               FROM jobs_glassdoor 
                    )
WHERE rating =0
RETURNING job_title, rating;

-- Changing the -1  values to NULL in all the column

UPDATE jobs_glassdoor
SET size  =NULL
WHERE size = '-1';

-- Removing the rating values to the company name  column
UPDATE jobs_glassdoor as j1
SET company_name = (
                 SELECT
                 REGEXP_REPLACE(company_name, '\d\D\d', ' ')
                 FROM jobs_glassdoor as j2
                 WHERE j1.id = j2.id
)

-- Splitting the location and headquarters columns into city and state

ALTER TABLE jobs_glassdoor ADD COLUMN city_location text;
ALTER TABLE jobs_glassdoor ADD COLUMN state_location text;

ALTER TABLE jobs_glassdoor ADD COLUMN city_headquarters text;
ALTER TABLE jobs_glassdoor ADD COLUMN state_headquarters text;


UPDATE jobs_glassdoor j1
SET city_location =(
    SELECT
    SPLIT_PART(location,',',1)
    FROM jobs_glassdoor j2
    WHERE j1.id = j2.id

);

UPDATE jobs_glassdoor j1
SET state_location =(
    SELECT
    SPLIT_PART(location,',',2)
    FROM jobs_glassdoor j2
    WHERE j1.id = j2.id

);

UPDATE jobs_glassdoor j1
SET city_headquarters =(
    SELECT
    SPLIT_PART(headquarters,',',1)
    FROM jobs_glassdoor j2
    WHERE j1.id = j2.id

);

UPDATE jobs_glassdoor j1
SET state_headquarters =(
    SELECT
    SPLIT_PART(headquarters,',',2)
    FROM jobs_glassdoor j2
    WHERE j1.id = j2.id

);