DROP TABLE IF EXISTS Player_Details;
DROP TABLE IF EXISTS Level_Details;


CREATE TABLE Player_Details (
	P_ID INT PRIMARY KEY,
	PName VARCHAR(255),
	L1_status VARCHAR(30),
	L2_status VARCHAR(30),
	L1_code VARCHAR(30),
	L2_code VARCHAR(30)
);
CREATE TABLE Level_Details (
	P_ID INT NOT NULL,
	Dev_ID VARCHAR(255),
	start_time TIMESTAMP,
	stages_crossed INT,
	level VARCHAR(5),
	difficulty VARCHAR(15),
	kill_count INT,
	headshots_count INT,
	score INT,
	lives_earned INT,
	FOREIGN KEY (P_ID) REFERENCES Player_Details(P_ID)
);

SELECT * FROM Player_Details;
SELECT * FROM Level_Details;


-- 1. Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0.

SELECT ld.P_ID, ld.Dev_ID, pd.PName, ld.Difficulty
FROM Player_Details pd
JOIN Level_Details ld ON pd.P_ID = ld.P_ID
WHERE ld.level = 'L0';


-- 2. Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3
--    stages are crossed.

--WITHOUT ROUND
SELECT pd.L1_code, AVG(ld.kill_count) AS Avg_kill_count
FROM Player_Details pd
JOIN Level_Details ld ON pd.P_ID = ld.P_ID
WHERE ld.lives_earned = 2 AND ld.stages_crossed >= 3
GROUP BY pd.L1_code;

--WITH ROUND
SELECT pd.L1_code, ROUND(AVG(ld.kill_count), 2) AS Avg_kill_count
FROM Player_Details pd
JOIN Level_Details ld ON pd.P_ID = ld.P_ID
WHERE ld.lives_earned = 2 AND ld.stages_crossed >= 3
GROUP BY pd.L1_code;


-- 3. Find the total number of stages crossed at each difficulty level for Level 2 with players
--    using `zm_series` devices. Arrange the result in decreasing order of the total number of
--    stages crossed.

--SIMPLE
SELECT difficulty, SUM(stages_crossed) AS Total_Stages_Crossed
FROM Level_Details
WHERE level = 'L2' AND Dev_ID LIKE 'zm_%'
GROUP BY difficulty
ORDER BY Total_Stages_Crossed DESC;

--COMPLEX
SELECT ld.difficulty, SUM(ld.stages_crossed) AS Total_Stages_Crossed
FROM Level_Details ld
JOIN Player_Details pd ON pd.P_ID = ld.P_ID
WHERE ld.level = 'L2' AND ld.Dev_ID LIKE 'zm_%'
GROUP BY ld.difficulty
ORDER BY Total_Stages_Crossed DESC;


-- 4. Extract `P_ID` and the total number of unique dates for those players who have played
--    games on multiple days.

SELECT P_ID, COUNT(DISTINCT DATE(start_time)) AS Total_Unique_Dates
FROM Level_Details
GROUP BY P_ID
HAVING COUNT(DISTINCT DATE (start_time)) > 1;


-- 5. Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the
--    average kill count for Medium difficulty.

SELECT P_ID, level, SUM(kill_count) AS Total_kill_counts
FROM Level_Details
WHERE kill_count > (
	SELECT AVG(kill_count)
	FROM Level_Details
	WHERE difficulty = 'Medium'
) AND difficulty = 'Medium'
GROUP BY P_ID, level;


-- 6. Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level
--    0. Arrange in ascending order of level.

SELECT ld.level, pd.L1_code, SUM(ld.lives_earned) AS Total_Lives_Earned
FROM Player_Details pd
JOIN Level_Details ld ON pd.P_ID = ld.P_ID
WHERE ld.level <> 'L0'
GROUP BY ld.level, pd.L1_code
ORDER BY ld.level;


-- 7. Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using
--    `Row_Number`. Display the difficulty as well.

WITH RankedScores AS (
	SELECT Dev_ID, difficulty, score,
	   	   ROW_NUMBER() OVER(PARTITION BY Dev_ID ORDER BY score DESC) AS Rank
	FROM Level_Details
)
SELECT Dev_ID, difficulty, score--, Rank
FROM RankedScores
WHERE Rank <= 3;


-- 8. Find the `first_login` datetime for each device ID.

SELECT Dev_ID, MIN(start_time) AS first_login_datetime
FROM Level_Details
GROUP BY Dev_ID;


-- 9. Find the top 5 scores based on each difficulty level and rank them in increasing order
--    using `Rank`. Display `Dev_ID` as well.

WITH RankedScores AS (
	 SELECT Dev_ID, difficulty, score,
			Rank() OVER(PARTITION BY difficulty ORDER BY score DESC) AS Rank
	 FROM Level_Details
)
SELECT Dev_ID, difficulty, score--, Rank
FROM RankedScores
WHERE Rank <= 5;


-- 10. Find the device ID that is first logged in (based on `start_datetime`) for each player
--     (`P_ID`). Output should contain player ID, device ID, and first login datetime.


SELECT ld.P_ID, ld.Dev_ID, ld.start_time AS first_login_datetime
FROM Level_Details ld
INNER JOIN (
    SELECT P_ID, MIN(start_time) AS min_start_time
    FROM Level_Details
    GROUP BY P_ID
) AS first_login ON ld.P_ID = first_login.P_ID AND ld.start_time = first_login.min_start_time;



--WITH CLAUSE

WITH first_login AS(
	SELECT P_ID, MIN(start_time) AS min_start_time
	FROM Level_Details
	GROUP BY P_ID
)
SELECT ld.P_ID, ld.Dev_ID, ld.start_time AS first_login_datetime
FROM Level_Details ld
INNER JOIN first_login ON ld.P_ID = first_login.P_ID AND ld.start_time = first_login.min_start_time;



-- 11. For each player and date, determine how many `kill_counts` were played by the player
--     so far.
--     a) Using window functions
--     b) Without window functions

-- a) Using window functions:-

SELECT P_ID, DATE(start_time) AS Date, SUM(kill_count) OVER(PARTITION BY P_ID ORDER BY start_time) AS Total_Kill_Count
FROM Level_Details;

-- b) Without window functions:-

SELECT P_ID, DATE(start_time) AS Date, SUM(kill_count) AS Total_Kill_Count
FROM Level_Details
GROUP BY P_ID, Date(start_time);


-- 12. Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`,
--     excluding the most recent `start_datetime`.

SELECT P_ID, start_time, SUM(stages_crossed) OVER(PARTITION BY P_ID ORDER BY start_time) AS Cumulative_Stages_Crossed
FROM Level_Details;

-- excluding the most recent `start_datetime`.

SELECT P_ID, start_time, SUM(stages_crossed) OVER(PARTITION BY P_ID ORDER BY start_time ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS Cumulative_Stages_Crossed
FROM Level_Details;


-- 13. Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`.

SELECT Dev_ID, P_ID, SUM(score) AS Total_Score
FROM Level_Details
GROUP BY Dev_ID, P_ID
ORDER BY Total_Score DESC
LIMIT 3;


-- 14. Find players who scored more than 50% of the average score, scored by the sum of
--     scores for each `P_ID`.

WITH TotalScores AS (
    SELECT P_ID, SUM(score) AS Total_Score
    FROM Level_Details
    GROUP BY P_ID
)
SELECT ld.P_ID, pd.PName, ld.score
FROM Level_Details ld
JOIN TotalScores ts ON ld.P_ID = ts.P_ID
JOIN Player_Details pd ON ld.P_ID = pd.P_ID
WHERE ld.score > 0.5 * ts.Total_Score;



-- 15. Create a stored procedure to find the top `n` `headshots_count` based on each `Dev_ID`
--     and rank them in increasing order using `Row_Number`. Display the difficulty as well.

CREATE OR REPLACE FUNCTION find_top_headshots_count(n INTEGER) RETURNS TABLE (
    dev_id VARCHAR,
    difficulty VARCHAR,
    headshots_count INTEGER,
    rank INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT Level_Details.dev_id, Level_Details.difficulty, Level_Details.headshots_count,
           ROW_NUMBER() OVER (PARTITION BY Level_Details.dev_id ORDER BY Level_Details.headshots_count)::INTEGER AS rank
    FROM Level_Details
    ORDER BY Level_Details.dev_id, Level_Details.headshots_count DESC
    LIMIT n;
END;
$$ LANGUAGE plpgsql;


-- For Call
SELECT * FROM find_top_headshots_count(5);









--CASCADE

DROP TABLE IF EXISTS Player_Details CASCADE;
DROP TABLE IF EXISTS Level_Details CASCADE;
