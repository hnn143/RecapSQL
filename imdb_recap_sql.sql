USE imdb_ijs;

SELECT * FROM movies;
DESCRIBE movies;

# the big picture
# how many...
SELECT COUNT(*) FROM movies; # 388269 movies
SELECT COUNT(*) FROM actors; # 817718 actors
SELECT COUNT(*) FROM directors; # 86880 directors

# exploring the movies
SELECT	name, year FROM	movies ORDER BY year ASC LIMIT 1; # oldest movie Roundhay Garden Scene (1888)
SELECT	name, year FROM	movies ORDER BY year DESC LIMIT 1; # newest movie Harry Potter and teh Half-Blood Prince (2008)
SELECT	name, movies.rank FROM movies ORDER BY movies.rank DESC LIMIT 1; # highest ranking 'Atunci i-am condamnat pe toti la moarte'
SELECT	name, movies.rank as ranking FROM movies WHERE movies.rank IS NOT NULL ORDER BY ranking ASC LIMIT 1; # lowest ranking 'Alarium'
#SELECT MIN(movies.rank), MAX(movies.rank) FROM movies WHERE movies.rank IS NOT NULL;
SELECT name, COUNT(name)  AS `title_occurrence` FROM movies GROUP BY name ORDER BY title_occurrence DESC LIMIT 1; # most frequent title 'Eurovision Song Contest, The'

# understanding the database
SELECT * FROM movies_directors;
SELECT COUNT(*) FROM
	(SELECT movie_id, count(director_id) AS n_directors
    FROM movies_directors GROUP BY movie_id HAVING n_directors>1) num_dir; # 26303 movies have more than 1 director

SELECT a.movie_id, count(a.director_id) AS n_directors, b.id, b.name
FROM movies_directors a
LEFT JOIN movies b ON a.movie_id = b.id
GROUP BY a.movie_id
ORDER BY n_directors DESC
LIMIT 1; # The Bill, 87 directors
#SELECT * FROM movies_directors WHERE movie_id=382052;

SELECT AVG(n_actors)
FROM
(SELECT a.movie_id, b.id, COUNT(a.actor_id) AS n_actors
FROM roles a
	LEFT JOIN movies b ON a.movie_id = b.id
GROUP BY movie_id) sum_movies; # on average 11.4303 actors listed
SELECT a.movie_id, b.id, COUNT(a.actor_id) AS n_actors
FROM roles a
	LEFT JOIN movies b ON a.movie_id = b.id
GROUP BY movie_id
ORDER BY n_actors DESC; # movie with most actors listed 1274 actors

SELECT COUNT(genre) as n_genre 
FROM movies_genres
GROUP BY movie_id
ORDER BY n_genre DESC; # there are movies with up to 11 genres

# looking for specific movies
# Pulp Fiction
SELECT a.name, c.first_name, c.last_name, d.role, e.first_name, e.last_name
FROM movies a
	LEFT JOIN movies_directors b ON a.id=b.movie_id
    LEFT JOIN directors c ON b.director_id=c.id
    LEFT JOIN roles d ON d.movie_id=a.id
    LEFT JOIN actors e ON d.actor_id = e.id
WHERE LOWER(a.name) LIKE LOWER('Pulp Fiction');

# La Dolce Vita
SELECT *
FROM movies a
WHERE LOWER(a.name) LIKE LOWER('%Dolce Vita%'); # 5 versions
SELECT a.name, c.first_name AS director_name, c.last_name AS director_surname, d.role, e.first_name AS actor_name, e.last_name AS actor_surname
FROM movies a
	LEFT JOIN movies_directors b ON a.id=b.movie_id
    LEFT JOIN directors c ON b.director_id=c.id
    LEFT JOIN roles d ON d.movie_id=a.id
    LEFT JOIN actors e ON d.actor_id = e.id
WHERE LOWER(a.name) LIKE LOWER('%Dolce Vita%') AND a.year=1960;

# Titanic
SELECT *
FROM movies a
	LEFT JOIN movies_directors b ON a.id=b.movie_id
    LEFT JOIN directors c ON b.director_id=c.id
WHERE LOWER(a.name) LIKE 'titanic' AND LOWER(c.last_name)='cameron' AND LOWER(c.first_name) LIKE LOWER('%james%'); # year 1997

# Actors and Directors
# acting as "himself"
SELECT c.first_name AS actor_name, c.last_name AS actor_surname, COUNT(c.id) AS n_plays
FROM movies a
	LEFT JOIN roles b ON b.movie_id=a.id
    LEFT JOIN actors c ON b.actor_id = c.id
WHERE LOWER(b.role) LIKE LOWER('%himself%')
GROUP BY c.id
ORDER BY n_plays DESC
LIMIT 1; # Adolf Hitler... 263 times

# most common name for actors
SELECT *, COUNT(first_name) AS n_name
FROM actors
GROUP BY first_name
ORDER BY n_name DESC
LIMIT 1; # John 4371 times
SELECT COUNT( CONCAT(first_name, " ", last_name)) AS n_name,  CONCAT(first_name, last_name) AS full_name
FROM actors
GROUP BY full_name
ORDER BY n_name DESC
LIMIT 1; # 'ShaunaMacDonald' 7 times
SELECT *
FROM actors
WHERE first_name LIKE 'Shauna' AND last_name LIKE 'MacDonald'; # 7 different ids

# most common name for directors
SELECT *, COUNT(first_name) AS n_name
FROM directors
GROUP BY first_name
ORDER BY n_name DESC
LIMIT 1; # Micheal 670 times
SELECT COUNT( CONCAT(first_name, " ", last_name)) AS n_name,  CONCAT(first_name, last_name) AS full_name
FROM directors
GROUP BY full_name
ORDER BY n_name DESC
LIMIT 1; # 'KaoruUmeZawa' 10 times

# Analysing genders
SELECT gender, COUNT(gender)
FROM actors
GROUP BY gender; # 513306 M, 304412 F

SELECT gender, 100*COUNT(gender)/SUM(COUNT(gender)) OVER() AS gender_share
FROM actors
GROUP BY gender; # 62.77% M, 37.23% F
SELECT gender, COUNT(gender)/(SELECT COUNT(gender) FROM actors)*100 AS gender_share
FROM actors
GROUP BY gender; # 62.77% M, 37.23% F

# movies across time
# after 200
SELECT COUNT(*)
FROM movies
WHERE year>2000; # 46006 movies after 2000
# between 1990 and 2000
SELECT COUNT(*)
FROM movies
WHERE year>=1990 and year<2000; # 79495 movies btw 1990 (incl) and 2000 (excl)
# years with most movies
SELECT year, COUNT(id)
FROM movies
GROUP BY year
ORDER BY COUNT(id) DESC
LIMIT 3; # 2002 with 12056 movies, then 2003 with 11890 movies, then 2001 with 11690 movies

# top 5 movie genres
SELECT b.genre, COUNT(b.movie_id) AS n_movies
FROM movies a
LEFT JOIN movies_genres b ON a.id=b.movie_id
GROUP BY b.genre
ORDER BY n_movies DESC
LIMIT 5; # short, drama, comedy, documentary, animation
# top 5 movie genres before 1920
SELECT b.genre, COUNT(b.movie_id) AS n_movies
FROM movies a
LEFT JOIN movies_genres b ON a.id=b.movie_id
WHERE a.year<1920
GROUP BY b.genre
ORDER BY n_movies DESC
LIMIT 5; # short, comedy, drama, documentary, western

# top 5 movie genres across decades in the 20th century
SELECT genre, decade, genre_ranking
FROM
(SELECT *, RANK() OVER(PARTITION BY decade ORDER BY genre_decade DESC) genre_ranking
FROM
(SELECT a.id, b.genre, COUNT(b.genre) AS genre_decade,
	CASE
        WHEN year < 1910 THEN '00s'
        WHEN year >=1910 AND year < 1920 THEN '10s'
        WHEN year >=1920 AND year < 1930 THEN '20s'
        WHEN year >=1930 AND year < 1940 THEN '30s'
        WHEN year >=1940 AND year < 1950 THEN '40s'
        WHEN year >=1950 AND year < 1960 THEN '50s'
        WHEN year >=1960 AND year < 1970 THEN '60s'
        WHEN year >=1970 AND year < 1980 THEN '70s'
        WHEN year >=1980 AND year < 1990 THEN '80s'
        ELSE '90s'
    END AS decade
FROM movies a
INNER JOIN movies_genres b ON a.id = b.movie_id
WHERE year>=1900 AND year <2000
GROUP BY decade, genre) sub1) sub2
WHERE genre_ranking<6;

# most common name of actors over time
SELECT first_name, decade, name_ranking
FROM
(SELECT *, RANK() OVER(PARTITION BY decade ORDER BY name_decade DESC) name_ranking
FROM
(SELECT a.id, c.first_name, COUNT(c.first_name) AS name_decade,
	CASE
        WHEN year < 1910 THEN '00s'
        WHEN year >=1910 AND year < 1920 THEN '10s'
        WHEN year >=1920 AND year < 1930 THEN '20s'
        WHEN year >=1930 AND year < 1940 THEN '30s'
        WHEN year >=1940 AND year < 1950 THEN '40s'
        WHEN year >=1950 AND year < 1960 THEN '50s'
        WHEN year >=1960 AND year < 1970 THEN '60s'
        WHEN year >=1970 AND year < 1980 THEN '70s'
        WHEN year >=1980 AND year < 1990 THEN '80s'
        ELSE '90s'
    END AS decade
FROM movies a
INNER JOIN roles b ON a.id = b.movie_id
INNER JOIN actors c ON b.actor_id=c.id
WHERE year>=1900 AND year <2000
GROUP BY decade, first_name) sub1) sub2
#GROUP BY decade, gender, first_name) sub1) sub2
WHERE name_ranking<6;

#    How many movies had a majority of females among their cast?
 SELECT COUNT(*)
 FROM (
	 SELECT * , ifnull(f_count, 0)/(ifnull(f_count, 0)+ifnull(m_count, 0)) AS f_share
	 FROM (SELECT a.id, COUNT(gender) AS f_count
		FROM movies a
			LEFT JOIN roles b ON a.id = b.movie_id
			LEFT JOIN actors c ON b.actor_id = c.id
		WHERE c.gender = 'F'
		GROUP BY a.id) f_table
		INNER JOIN (SELECT a.id, COUNT(gender) AS m_count
		FROM movies a
			LEFT JOIN roles b ON a.id = b.movie_id
			LEFT JOIN actors c ON b.actor_id = c.id
		WHERE c.gender = 'M'
		GROUP BY a.id) m_table ON f_table.id=m_table.id) share_df
WHERE f_share >0.5;

