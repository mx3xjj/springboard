/* major concerns for search
1. autocomplete vs full search
	- which is used more often
	- whether autocomplete & full search achieve effective result for user (runs of search per session)
	- are users satisfied with autocomplete & full search (whether come back to use search or not)
2. click through features
	- whether the users use click through
	- whether more search per session leads to more click through
	- whether the search result listed in effective order 

this sql file will test most of these hypotheses one by one
*/

-- gets searches count for with_autocomplet and with_runs
SELECT DATE_TRUNC('week',z.session_start) AS week,
       COUNT(*) AS sessions,
       COUNT(CASE WHEN z.autocompletes > 0 THEN z.session ELSE NULL END) AS with_autocompletes,
       COUNT(CASE WHEN z.runs > 0 THEN z.session ELSE NULL END) AS with_runs
  FROM (
SELECT x.session_start,
       x.session,
       x.user_id,
       COUNT(CASE WHEN x.event_name = 'search_autocomplete' THEN x.user_id ELSE NULL END) AS autocompletes,
       COUNT(CASE WHEN x.event_name = 'search_run' THEN x.user_id ELSE NULL END) AS runs,
       COUNT(CASE WHEN x.event_name LIKE 'search_click_%' THEN x.user_id ELSE NULL END) AS clicks
  FROM (
SELECT e.*,
       session.session,
       session.session_start
  FROM tutorial.yammer_events e
  LEFT JOIN (
       SELECT user_id,
              session,
              MIN(occurred_at) AS session_start,
              MAX(occurred_at) AS session_end
         FROM (
              SELECT bounds.*,
              		    CASE WHEN last_event >= INTERVAL '10 MINUTE' THEN id
              		         WHEN last_event IS NULL THEN id
              		         ELSE LAG(id,1) OVER (PARTITION BY user_id ORDER BY occurred_at) END AS session
                FROM (
                     SELECT user_id,
                            event_type,
                            event_name,
                            occurred_at,
                            occurred_at - LAG(occurred_at,1) OVER (PARTITION BY user_id ORDER BY occurred_at) AS last_event,
                            LEAD(occurred_at,1) OVER (PARTITION BY user_id ORDER BY occurred_at) - occurred_at AS next_event,
                            ROW_NUMBER() OVER () AS id
                       FROM tutorial.yammer_events e
                      WHERE e.event_type = 'engagement'
                      ORDER BY user_id,occurred_at
                     ) bounds
               WHERE last_event >= INTERVAL '10 MINUTE'
                  OR next_event >= INTERVAL '10 MINUTE'
               	 OR last_event IS NULL
              	 	 OR next_event IS NULL   
              ) final
        GROUP BY 1,2
       ) session
    ON e.user_id = session.user_id
   AND e.occurred_at >= session.session_start
   AND e.occurred_at <= session.session_end
 WHERE e.event_type = 'engagement'
       ) x
 GROUP BY 1,2,3
       ) z
 GROUP BY 1
 ORDER BY 1

-- get how often autocompletes is used (search count group by number of autocompletes per session)
SELECT autocompletes,
       COUNT(*) AS sessions
  FROM (
SELECT x.session_start,
       x.session,
       x.user_id,
       COUNT(CASE WHEN x.event_name = 'search_autocomplete' THEN x.user_id ELSE NULL END) AS autocompletes,
       COUNT(CASE WHEN x.event_name = 'search_run' THEN x.user_id ELSE NULL END) AS runs,
       COUNT(CASE WHEN x.event_name LIKE 'search_click_%' THEN x.user_id ELSE NULL END) AS clicks
  FROM (
SELECT e.*,
       session.session,
       session.session_start
  FROM tutorial.yammer_events e
  LEFT JOIN (
       SELECT user_id,
              session,
              MIN(occurred_at) AS session_start,
              MAX(occurred_at) AS session_end
         FROM (
              SELECT bounds.*,
              		    CASE WHEN last_event >= INTERVAL '10 MINUTE' THEN id
              		         WHEN last_event IS NULL THEN id
              		         ELSE LAG(id,1) OVER (PARTITION BY user_id ORDER BY occurred_at) END AS session
                FROM (
                     SELECT user_id,
                            event_type,
                            event_name,
                            occurred_at,
                            occurred_at - LAG(occurred_at,1) OVER (PARTITION BY user_id ORDER BY occurred_at) AS last_event,
                            LEAD(occurred_at,1) OVER (PARTITION BY user_id ORDER BY occurred_at) - occurred_at AS next_event,
                            ROW_NUMBER() OVER () AS id
                       FROM tutorial.yammer_events e
                      WHERE e.event_type = 'engagement'
                      ORDER BY user_id,occurred_at
                     ) bounds
               WHERE last_event >= INTERVAL '10 MINUTE'
                  OR next_event >= INTERVAL '10 MINUTE'
               	 OR last_event IS NULL
              	 	 OR next_event IS NULL   
              ) final
        GROUP BY 1,2
       ) session
    ON e.user_id = session.user_id
   AND e.occurred_at >= session.session_start
   AND e.occurred_at <= session.session_end
 WHERE e.event_type = 'engagement'
       ) x
 GROUP BY 1,2,3
       ) z
 WHERE autocompletes > 0
 GROUP BY 1
 ORDER BY 1

 -- get how often full search runs is used (search count group by number of full search run per session)
SELECT runs,
       COUNT(*) AS sessions
  FROM (
SELECT x.session_start,
       x.session,
       x.user_id,
       COUNT(CASE WHEN x.event_name = 'search_autocomplete' THEN x.user_id ELSE NULL END) AS autocompletes,
       COUNT(CASE WHEN x.event_name = 'search_run' THEN x.user_id ELSE NULL END) AS runs,
       COUNT(CASE WHEN x.event_name LIKE 'search_click_%' THEN x.user_id ELSE NULL END) AS clicks
  FROM (
SELECT e.*,
       session.session,
       session.session_start
  FROM tutorial.yammer_events e
  LEFT JOIN (
       SELECT user_id,
              session,
              MIN(occurred_at) AS session_start,
              MAX(occurred_at) AS session_end
         FROM (
              SELECT bounds.*,
              		    CASE WHEN last_event >= INTERVAL '10 MINUTE' THEN id
              		         WHEN last_event IS NULL THEN id
              		         ELSE LAG(id,1) OVER (PARTITION BY user_id ORDER BY occurred_at) END AS session
                FROM (
                     SELECT user_id,
                            event_type,
                            event_name,
                            occurred_at,
                            occurred_at - LAG(occurred_at,1) OVER (PARTITION BY user_id ORDER BY occurred_at) AS last_event,
                            LEAD(occurred_at,1) OVER (PARTITION BY user_id ORDER BY occurred_at) - occurred_at AS next_event,
                            ROW_NUMBER() OVER () AS id
                       FROM tutorial.yammer_events e
                      WHERE e.event_type = 'engagement'
                      ORDER BY user_id,occurred_at
                     ) bounds
               WHERE last_event >= INTERVAL '10 MINUTE'
                  OR next_event >= INTERVAL '10 MINUTE'
               	 OR last_event IS NULL
              	 	 OR next_event IS NULL   
              ) final
        GROUP BY 1,2
       ) session
    ON e.user_id = session.user_id
   AND e.occurred_at >= session.session_start
   AND e.occurred_at <= session.session_end
 WHERE e.event_type = 'engagement'
       ) x
 GROUP BY 1,2,3
       ) z
 WHERE runs > 0
 GROUP BY 1
 ORDER BY 1

-- get how frequent click search result is used (based on count of seesion group by clicks in session)
SELECT clicks,
       COUNT(*) AS sessions
  FROM (
SELECT x.session_start,
       x.session,
       x.user_id,
       COUNT(CASE WHEN x.event_name = 'search_autocomplete' THEN x.user_id ELSE NULL END) AS autocompletes,
       COUNT(CASE WHEN x.event_name = 'search_run' THEN x.user_id ELSE NULL END) AS runs,
       COUNT(CASE WHEN x.event_name LIKE 'search_click_%' THEN x.user_id ELSE NULL END) AS clicks
  FROM (
SELECT e.*,
       session.session,
       session.session_start
  FROM tutorial.yammer_events e
  LEFT JOIN (
       SELECT user_id,
              session,
              MIN(occurred_at) AS session_start,
              MAX(occurred_at) AS session_end
         FROM (
              SELECT bounds.*,
              		    CASE WHEN last_event >= INTERVAL '10 MINUTE' THEN id
              		         WHEN last_event IS NULL THEN id
              		         ELSE LAG(id,1) OVER (PARTITION BY user_id ORDER BY occurred_at) END AS session
                FROM (
                     SELECT user_id,
                            event_type,
                            event_name,
                            occurred_at,
                            occurred_at - LAG(occurred_at,1) OVER (PARTITION BY user_id ORDER BY occurred_at) AS last_event,
                            LEAD(occurred_at,1) OVER (PARTITION BY user_id ORDER BY occurred_at) - occurred_at AS next_event,
                            ROW_NUMBER() OVER () AS id
                       FROM tutorial.yammer_events e
                      WHERE e.event_type = 'engagement'
                      ORDER BY user_id,occurred_at
                     ) bounds
               WHERE last_event >= INTERVAL '10 MINUTE'
                  OR next_event >= INTERVAL '10 MINUTE'
               	 OR last_event IS NULL
              	 	 OR next_event IS NULL   
              ) final
        GROUP BY 1,2
       ) session
    ON e.user_id = session.user_id
   AND e.occurred_at >= session.session_start
   AND e.occurred_at <= session.session_end
 WHERE e.event_type = 'engagement'
       ) x
 GROUP BY 1,2,3
       ) z
 WHERE runs > 0
 GROUP BY 1
 ORDER BY 1

-- check whether more searches in a session more likely click through results happens
-- => based on average clicks per seesion group by searches per session
SELECT runs,
       AVG(clicks)::FLOAT AS average_clicks
  FROM (
SELECT x.session_start,
       x.session,
       x.user_id,
       COUNT(CASE WHEN x.event_name = 'search_autocomplete' THEN x.user_id ELSE NULL END) AS autocompletes,
       COUNT(CASE WHEN x.event_name = 'search_run' THEN x.user_id ELSE NULL END) AS runs,
       COUNT(CASE WHEN x.event_name LIKE 'search_click_%' THEN x.user_id ELSE NULL END) AS clicks
  FROM (
SELECT e.*,
       session.session,
       session.session_start
  FROM tutorial.yammer_events e
  LEFT JOIN (
       SELECT user_id,
              session,
              MIN(occurred_at) AS session_start,
              MAX(occurred_at) AS session_end
         FROM (
              SELECT bounds.*,
              		    CASE WHEN last_event >= INTERVAL '10 MINUTE' THEN id
              		         WHEN last_event IS NULL THEN id
              		         ELSE LAG(id,1) OVER (PARTITION BY user_id ORDER BY occurred_at) END AS session
                FROM (
                     SELECT user_id,
                            event_type,
                            event_name,
                            occurred_at,
                            occurred_at - LAG(occurred_at,1) OVER (PARTITION BY user_id ORDER BY occurred_at) AS last_event,
                            LEAD(occurred_at,1) OVER (PARTITION BY user_id ORDER BY occurred_at) - occurred_at AS next_event,
                            ROW_NUMBER() OVER () AS id
                       FROM tutorial.yammer_events e
                      WHERE e.event_type = 'engagement'
                      ORDER BY user_id,occurred_at
                     ) bounds
               WHERE last_event >= INTERVAL '10 MINUTE'
                  OR next_event >= INTERVAL '10 MINUTE'
               	 OR last_event IS NULL
              	 	 OR next_event IS NULL   
              ) final
        GROUP BY 1,2
       ) session
    ON e.user_id = session.user_id
   AND e.occurred_at >= session.session_start
   AND e.occurred_at <= session.session_end
 WHERE e.event_type = 'engagement'
       ) x
 GROUP BY 1,2,3
       ) z
 WHERE runs > 0
 GROUP BY 1
 ORDER BY 1

-- check whether the rank of search result is effetive
-- => based on click counts group by search result order
SELECT TRIM('search_click_result_' FROM event_name)::INT AS search_result,
       COUNT(*) AS clicks
  FROM tutorial.yammer_events
 WHERE event_name LIKE 'search_click_%'
 GROUP BY 1
 ORDER BY 1

-- check user do full research satisfied with full research
-- through check whether users who run full searches rarely do so again within the following month
SELECT searches,
       COUNT(*) AS users
  FROM (
SELECT user_id,
       COUNT(*) AS searches
  FROM (
SELECT x.session_start,
       x.session,
       x.user_id,
       x.first_search,
       COUNT(CASE WHEN x.event_name = 'search_run' THEN x.user_id ELSE NULL END) AS runs
  FROM (
SELECT e.*,
       first.first_search,
       session.session,
       session.session_start
  FROM tutorial.yammer_events e
  JOIN (
       SELECT user_id,
              MIN(occurred_at) AS first_search
         FROM tutorial.yammer_events
        WHERE event_name = 'search_run'
        GROUP BY 1
       ) first
    ON first.user_id = e.user_id
   AND first.first_search <= '2014-08-01'
  LEFT JOIN (
       SELECT user_id,
              session,
              MIN(occurred_at) AS session_start,
              MAX(occurred_at) AS session_end
         FROM (
              SELECT bounds.*,
              		    CASE WHEN last_event >= INTERVAL '10 MINUTE' THEN id
              		         WHEN last_event IS NULL THEN id
              		         ELSE LAG(id,1) OVER (PARTITION BY user_id ORDER BY occurred_at) END AS session
                FROM (
                     SELECT user_id,
                            event_type,
                            event_name,
                            occurred_at,
                            occurred_at - LAG(occurred_at,1) OVER (PARTITION BY user_id ORDER BY occurred_at) AS last_event,
                            LEAD(occurred_at,1) OVER (PARTITION BY user_id ORDER BY occurred_at) - occurred_at AS next_event,
                            ROW_NUMBER() OVER () AS id
                       FROM tutorial.yammer_events e
                      WHERE e.event_type = 'engagement'
                      ORDER BY user_id,occurred_at
                     ) bounds
               WHERE last_event >= INTERVAL '10 MINUTE'
                  OR next_event >= INTERVAL '10 MINUTE'
               	 OR last_event IS NULL
              	 	 OR next_event IS NULL   
              ) final
        GROUP BY 1,2
       ) session
    ON session.user_id = e.user_id
   AND session.session_start <= e.occurred_at
   AND session.session_end >= e.occurred_at
   AND session.session_start <= first.first_search + INTERVAL '30 DAY'
 WHERE e.event_type = 'engagement'
       ) x
 GROUP BY 1,2,3,4
       ) z
 WHERE z.runs > 0
 GROUP BY 1
       ) z
 GROUP BY 1
 ORDER BY 1
LIMIT 100

-- check user do autocomplete research satisfied with autocomplete research
-- through check whether users who run autocomplete searches rarely do so again within the following month
SELECT searches,
       COUNT(*) AS users
  FROM (
SELECT user_id,
       COUNT(*) AS searches
  FROM (
SELECT x.session_start,
       x.session,
       x.user_id,
       x.first_search,
       COUNT(CASE WHEN x.event_name = 'search_autocomplete' THEN x.user_id ELSE NULL END) AS autocompletes
  FROM (
SELECT e.*,
       first.first_search,
       session.session,
       session.session_start
  FROM tutorial.yammer_events e
  JOIN (
       SELECT user_id,
              MIN(occurred_at) AS first_search
         FROM tutorial.yammer_events
        WHERE event_name = 'search_autocomplete'
        GROUP BY 1
       ) first
    ON first.user_id = e.user_id
   AND first.first_search <= '2014-08-01'
  LEFT JOIN (
       SELECT user_id,
              session,
              MIN(occurred_at) AS session_start,
              MAX(occurred_at) AS session_end
         FROM (
              SELECT bounds.*,
              		    CASE WHEN last_event >= INTERVAL '10 MINUTE' THEN id
              		         WHEN last_event IS NULL THEN id
              		         ELSE LAG(id,1) OVER (PARTITION BY user_id ORDER BY occurred_at) END AS session
                FROM (
                     SELECT user_id,
                            event_type,
                            event_name,
                            occurred_at,
                            occurred_at - LAG(occurred_at,1) OVER (PARTITION BY user_id ORDER BY occurred_at) AS last_event,
                            LEAD(occurred_at,1) OVER (PARTITION BY user_id ORDER BY occurred_at) - occurred_at AS next_event,
                            ROW_NUMBER() OVER () AS id
                       FROM tutorial.yammer_events e
                      WHERE e.event_type = 'engagement'
                      ORDER BY user_id,occurred_at
                     ) bounds
               WHERE last_event >= INTERVAL '10 MINUTE'
                  OR next_event >= INTERVAL '10 MINUTE'
               	 OR last_event IS NULL
              	 	 OR next_event IS NULL   
              ) final
        GROUP BY 1,2
       ) session
    ON session.user_id = e.user_id
   AND session.session_start <= e.occurred_at
   AND session.session_end >= e.occurred_at
   AND session.session_start <= first.first_search + INTERVAL '30 DAY'
 WHERE e.event_type = 'engagement'
       ) x
 GROUP BY 1,2,3,4
       ) z
 WHERE z.autocompletes > 0
 GROUP BY 1
       ) z
 GROUP BY 1
 ORDER BY 1
LIMIT 100