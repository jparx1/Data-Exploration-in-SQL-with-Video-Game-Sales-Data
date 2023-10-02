/*Setting search path to video_games schema for ease*/

ALTER ROLE postgres SET search_path TO video_games;

/*Design comments from data source: "The release year applies to a combination of game, platform, and publisher, not just for a game.
The sales are captured overall as at a point in time and are not broken down by years.
A game can have different publishers for different platforms."*/


-- DATA EXPLORATION

/*How many unique game titles are included in this data set?*/

SELECT COUNT(DISTINCT game_name) AS number_of_game_titles
FROM game;
-- 11360

/*What sales regions are included in this dataset?*/

SELECT region_name 
FROM region;
-- North America, Europe, Japan, "Other"


/*What is the range of years in my data set?*/

SELECT
	MIN(gplat.release_year) AS oldest_game,
	MAX(gplat.release_year) AS newest_game
FROM game_platform AS gplat;
-- 1980 to 2020

/*Of the 11630 titles, how many are sports-related titles?*/

SELECT COUNT(*) AS number_of_sports_titles
FROM game
WHERE genre_id = (
    SELECT id
    FROM genre
    WHERE genre_name = 'Sports'
);
-- 1366

/*Obtain list of all game publishers*/

SELECT publisher_name
FROM publisher;

/*Who are the top selling publishers (100)?*/

SELECT 
	pub.publisher_name, 
	SUM(rs.num_sales) AS total_sales
FROM publisher AS pub
JOIN game_publisher AS gpub ON pub.id = gpub.publisher_id
JOIN game_platform AS gplat ON gpub.publisher_id = gplat.game_publisher_id
JOIN region_sales AS rs ON gplat.id = rs.game_platform_id
GROUP BY pub.publisher_name
ORDER BY total_sales DESC
LIMIT 100;
-- Recognize names like Activision, Atari, Sega, etc.

/*See list of all platforms included in dataset*/

SELECT platform_name
FROM platform;
-- All major platforms seem to be included with the exception of some newer consoles such as the XBOX Series X (most likely a date issue)

/*What is the average length of a video game title in this dataset?*/

SELECT ROUND(AVG(LENGTH(game_name))) AS average_game_title_length
FROM game;
-- 25

/*What are the top 100 best-selling games and their release years?*/

SELECT 
	g.game_name, 
	gplat.release_year, 
	SUM(rs.num_sales) AS total_sales
FROM region_sales AS rs
JOIN region AS r ON rs.region_id = r.id
JOIN game_platform AS gplat ON rs.game_platform_id = gplat.id
JOIN game_publisher AS gpub ON gplat.game_publisher_id = gpub.id
JOIN game AS g ON gpub.game_id = g.id
GROUP BY g.game_name, gplat.release_year
ORDER BY total_sales DESC
LIMIT 100;
-- Wii Sports top selling (2006)

/*What are total video game sales by region?*/

SELECT 
	r.region_name, 
	SUM(rs.num_sales) AS total_sales
FROM region_sales AS rs
JOIN region AS r ON rs.region_id = r.id
GROUP BY r.region_name
ORDER BY total_sales DESC;
-- In millions, North America (4335.07), Europe (2410.37), Japan (1284.33), Other (789.33)

/*What games were released between 2010 and 2020?*/

SELECT 
	g.game_name, 
	gplat.release_year
FROM game_platform AS gplat
JOIN game_publisher AS gpub ON gplat.game_publisher_id = gpub.id
JOIN game AS g ON gpub.game_id = g.id
WHERE gplat.release_year BETWEEN 2010 AND 2020
ORDER BY gplat.release_year DESC;

/*What is the prevalence of each genre in the dataset?*/

SELECT 
	gen.genre_name, 
	COUNT(g.id) AS game_count
FROM genre AS gen
LEFT JOIN game AS g ON gen.id = g.genre_id
GROUP BY gen.genre_name
ORDER BY game_count DESC;
-- Action and Sports genres lead this dataset with 1900 and 1366 titles respectively

/*What genres have the most sales?*/

SELECT 
	gen.genre_name, 
	SUM(rs.num_sales) AS total_sales
FROM genre AS gen
JOIN game AS g ON gen.id = g.genre_id
JOIN game_publisher AS gpub ON g.id = gpub.game_id
JOIN game_platform AS gplat ON gpub.publisher_id = gplat.game_publisher_id
JOIN region_sales AS rs ON gplat.id = rs.game_platform_id
GROUP BY gen.genre_name
ORDER BY total_sales DESC;
-- Action genre has the most sales with Sports and "Misc" following

/*What games have global sales greater than 20 million?*/

SELECT 
	game_name, 
	total_sales
FROM ( 
	SELECT g.game_name, SUM(rs.num_sales) AS total_sales
	FROM region_sales AS rs
	JOIN region AS r ON rs.region_id = r.id
	JOIN game_platform AS gplat ON rs.game_platform_id = gplat.id
	JOIN game_publisher AS gpub ON gplat.game_publisher_id = gpub.id
	JOIN game AS g ON gpub.game_id = g.id
	GROUP BY g.game_name
) AS game_sales
WHERE total_sales > 20
ORDER BY total_sales DESC;
-- Big names like Wii Sports, Grand Theft Auto V, Super Mario Bros., etc.

/*What are the top 5 platforms with the most sales?*/

SELECT 
	plat.platform_name, 
	SUM (rs.num_sales) AS total_sales
FROM region_sales AS rs
JOIN game_platform AS gplat ON rs.game_platform_id = gplat.id
JOIN platform AS plat ON gplat.platform_id = plat.id
GROUP by plat.platform_name
ORDER BY total_sales DESC
LIMIT 5;
-- PS2, Xbox 360, PS3, Wii, DS

/*What are the top 5 best selling games on PS2?*/

SELECT 
	g.game_name, 
	SUM(rs.num_sales) AS total_sales
FROM game AS g
JOIN game_publisher AS gpub ON g.id = gpub.game_id
JOIN game_platform AS gplat ON gpub.publisher_id = gplat.game_publisher_id
JOIN region_sales AS rs ON gplat.id = rs.game_platform_id
JOIN platform as plat ON gplat.platform_id = plat.id
WHERE plat.platform_name = 'PS2'
GROUP BY g.game_name
ORDER BY total_sales DESC
LIMIT 5;
-- World of Warcraft: Warloard of Draenor is number 1

/*What about Xbox 360?*/

SELECT 
	g.game_name, 
	SUM(rs.num_sales) AS total_sales
FROM game AS g
JOIN game_publisher AS gpub ON g.id = gpub.game_id
JOIN game_platform AS gplat ON gpub.publisher_id = gplat.game_publisher_id
JOIN region_sales AS rs ON gplat.id = rs.game_platform_id
JOIN platform as plat ON gplat.platform_id = plat.id
WHERE plat.platform_name = 'X360'
GROUP BY g.game_name
ORDER BY total_sales DESC
LIMIT 5;
-- Shaun Palmer's Pro Snowboard is number 1

/*What were the top 25 best selling games in Europe in the year 2010 on Wii?*/

SELECT 
	g.game_name, 
	r.region_name, 
	gplat.release_year, 
	plat.platform_name, 
	SUM(rs.num_sales) AS total_sales
FROM game AS g
JOIN game_publisher AS gpub ON g.id = gpub.game_id
JOIN game_platform AS gplat ON gpub.publisher_id = gplat.game_publisher_id
JOIN region_sales AS rs ON gplat.id = rs.game_platform_id
JOIN platform as plat ON gplat.platform_id = plat.id
JOIN region AS r ON rs.region_id = r.id
WHERE plat.platform_name = 'Wii' AND r.region_name = 'Europe' AND gplat.release_year = 2010
GROUP BY g.game_name, r.region_name, gplat.release_year, plat.platform_name
ORDER BY total_sales DESC
LIMIT 25;
-- SBK Superbike World Championship was number 1, followed by Get Fit with Mel B

/*Create a master table that includes all the info we want for further analysis*/

CREATE TABLE video_games_complete AS
SELECT 
	g.game_name, 
	gen.genre_name, 
	gplat.release_year, 
	pub.publisher_name, 
	plat.platform_name, 
	r.region_name, 
	rs.num_sales
FROM game AS g
JOIN genre AS gen ON g.genre_id = gen.id
JOIN game_publisher ON g.id = game_publisher.game_id
JOIN publisher AS pub ON game_publisher.publisher_id = pub.id
JOIN game_platform AS gplat ON game_publisher.id = gplat.game_publisher_id
JOIN platform AS plat ON gplat.platform_id = plat.id
JOIN region_sales AS rs ON gplat.id = rs.game_platform_id
JOIN region AS r ON rs.region_id = r.id;

/*Inspect new table*/

SELECT * FROM video_games_complete;

/*What is the top selling game for each region*/

SELECT 
	DISTINCT ON (region_name) region_name, 
	game_name, 
	release_year
FROM video_games_complete
ORDER BY region_name, num_sales DESC;
-- (Europe, Japan, North America, "Other"); Wii Sports, Pokemon Red/Pokemon Blue, Wii Sports, Grand Theft Auto: San Andreas

/*What about for each platform?*/

SELECT 
	DISTINCT ON (platform_name) platform_name, 
	game_name, 
	release_year
FROM video_games_complete
ORDER BY platform_name, num_sales DESC;
-- PC was The Sims 3, PS4 was FIFA 16

/*Who are the top game publishers by number of games released?*/

SELECT 
	publisher_name, 
	COUNT(*) AS game_count
FROM video_games_complete
GROUP BY publisher_name
ORDER BY game_count DESC
LIMIT 25;
-- Electronic Arts (EA) was number 1, followed by Activision

/*How many game titles have above average total sales?*/

SELECT COUNT(game_name) AS count_of_games_with_above_average_sales
FROM video_games_complete
WHERE num_sales > (
	SELECT AVG(total_sales)
	FROM(
		SELECT game_name, SUM(num_sales) AS total_sales
		FROM video_games_complete
		GROUP BY game_name
	)
);
-- 2343

/*What do yearly sales trends look like?*/

SELECT 
	release_year AS game_release_year, 
	SUM(num_sales) AS yearly_game_sales
FROM video_games_complete
GROUP BY game_release_year
ORDER BY game_release_year DESC;
-- We can see from the above that this dataset definitely loses coverage starting around 2015
-- Early 2000's is when sales sky rocket, then I suspect coverage dips

/*Looks like max sales* occured in 2008 and min sales* in 2017, let's see what games were released these years*/

SELECT game_name
FROM video_games_complete
WHERE release_year = 2008
GROUP BY game_name;

SELECT game_name
FROM video_games_complete
WHERE release_year = 2017
GROUP BY game_name;
-- Min sales* query shows how few games from 2017 are included in dataset; reason for so few sales

/*Let's now analyze platform popularity over the years*/

SELECT 
	release_year AS game_release_year, 
	platform_name, 
	SUM(num_sales) AS platform_sales
FROM video_games_complete
GROUP BY game_release_year, platform_name
ORDER BY game_release_year DESC;
-- We can see from the above query that our coverage suspicions are confirmed.
-- Dataset does not include years 2018 or 2019 and coverage for each invididual platform throughout the years seems spotty.

/*Let's now see what platforms each game was released on*/

SELECT 
	game_name, 
	COUNT(DISTINCT platform_name) AS num_of_platforms,
	STRING_AGG(DISTINCT platform_name, ', ') AS platform_list
FROM video_games_complete
GROUP BY game_name
ORDER BY num_of_platforms DESC;
-- Need for Speed: Most Wanted was released on the most platforms (10)

/*Let's categorize game sales released from 1990 to 2010*/

SELECT AVG(total_sales) AS average_sales
FROM (
    SELECT SUM(num_sales) AS total_sales
    FROM video_games_complete
    WHERE release_year BETWEEN 1990 AND 2010
    GROUP BY game_name
) AS average;
--Looks like average sales for these years is about 730 thousand

SELECT
	game_name,
	SUM(num_sales) AS total_sales,
	CASE
		WHEN SUM(num_sales) >= 1 THEN 'Bestseller'
		WHEN SUM(num_sales) >= 0.728 THEN 'Above Average'
		WHEN SUM(num_sales) < 0.728 THEN 'Below Average'
	END AS sales_category
FROM video_games_complete
WHERE release_year BETWEEN 1990 AND 2010
GROUP BY game_name
ORDER BY game_name;

/*Query for table we can export and use for an interesting visual*/

SELECT 
	game_name AS game, 
	genre_name AS genre,
	release_year,
	publisher_name AS publisher,
	SUM(num_sales * 1000000) AS sales,
	STRING_AGG(DISTINCT platform_name, ', ') AS platforms
FROM video_games_complete
WHERE release_year BETWEEN 1999 AND 2000
GROUP BY game_name, genre_name, release_year, publisher_name;
-- These results (653 game titles) show the state of video game sales at the turn of the millenium 
-- Data is not as spotty for these years and includes nostalgic titles for those familiar
-- Renames columns to easier to use titles and puts sales figures in actual amount (millions) 
























