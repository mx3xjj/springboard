/* aspects to consider to verifying the result of the A/B test
1. metric and math part of the test
	- metric used to measure the performance of A/B test does not trully reflect the concerning problem
	- the way the statistics used to validate the test has some problems
2. influence from the confouding factor
	- whether the users sample is biased or not equally random to introduce confounding factor (e.g.new vs old user)
	- other interaction effects: e.g. device type, use type uneven in sample

this sql file will test most of these hypotheses one by one
*/

-- query to show the A/B test result using average message sent measurements (the setting of this case)
SELECT c.experiment,
       c.experiment_group,
       c.users,
       c.total_treated_users,
       ROUND(c.users/c.total_treated_users,4) AS treatment_percent,
       c.total,
       ROUND(c.average,4)::FLOAT AS average,
       ROUND(c.average - c.control_average,4) AS rate_difference,
       ROUND((c.average - c.control_average)/c.control_average,4) AS rate_lift,
       ROUND(c.stdev,4) AS stdev,
       ROUND((c.average - c.control_average) /
          SQRT((c.variance/c.users) + (c.control_variance/c.control_users))
        ,4) AS t_stat,
       (1 - COALESCE(nd.value,1))*2 AS p_value
  FROM (
SELECT *,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.users ELSE NULL END) OVER () AS control_users,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.average ELSE NULL END) OVER () AS control_average,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.total ELSE NULL END) OVER () AS control_total,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.variance ELSE NULL END) OVER () AS control_variance,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.stdev ELSE NULL END) OVER () AS control_stdev,
       SUM(b.users) OVER () AS total_treated_users
  FROM (
SELECT a.experiment,
       a.experiment_group,
       COUNT(a.user_id) AS users,
       AVG(a.metric) AS average,
       SUM(a.metric) AS total,
       STDDEV(a.metric) AS stdev,
       VARIANCE(a.metric) AS variance
  FROM (
SELECT ex.experiment,
       ex.experiment_group,
       ex.occurred_at AS treatment_start,
       u.user_id,
       u.activated_at,
       COUNT(CASE WHEN e.event_name = 'send_message' THEN e.user_id ELSE NULL END) AS metric
  FROM (SELECT user_id,
               experiment,
               experiment_group,
               occurred_at
          FROM tutorial.yammer_experiments
         WHERE experiment = 'publisher_update'
       ) ex
  JOIN tutorial.yammer_users u
    ON u.user_id = ex.user_id
  JOIN tutorial.yammer_events e
    ON e.user_id = ex.user_id
   AND e.occurred_at >= ex.occurred_at
   AND e.occurred_at < '2014-07-01'
   AND e.event_type = 'engagement'
 GROUP BY 1,2,3,4,5
       ) a
 GROUP BY 1,2
       ) b
       ) c
  LEFT JOIN benn.normal_distribution nd
    ON nd.score = ABS(ROUND((c.average - c.control_average)/SQRT((c.variance/c.users) + (c.control_variance/c.control_users)),3))

-- check whether use other metrics (login) show similar A/B test result
SELECT c.experiment,
       c.experiment_group,
       c.users,
       c.total_treated_users,
       ROUND(c.users/c.total_treated_users,4) AS treatment_percent,
       c.total,
       ROUND(c.average,4)::FLOAT AS average,
       ROUND(c.average - c.control_average,4) AS rate_difference,
       ROUND((c.average - c.control_average)/c.control_average,4) AS rate_lift,
       ROUND(c.stdev,4) AS stdev,
       ROUND((c.average - c.control_average) /
          SQRT((c.variance/c.users) + (c.control_variance/c.control_users))
        ,4) AS t_stat,
       (1 - COALESCE(nd.value,1))*2 AS p_value
  FROM (
SELECT *,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.users ELSE NULL END) OVER () AS control_users,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.average ELSE NULL END) OVER () AS control_average,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.total ELSE NULL END) OVER () AS control_total,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.variance ELSE NULL END) OVER () AS control_variance,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.stdev ELSE NULL END) OVER () AS control_stdev,
       SUM(b.users) OVER () AS total_treated_users
  FROM (
SELECT a.experiment,
       a.experiment_group,
       COUNT(a.user_id) AS users,
       AVG(a.metric) AS average,
       SUM(a.metric) AS total,
       STDDEV(a.metric) AS stdev,
       VARIANCE(a.metric) AS variance
  FROM (
SELECT ex.experiment,
       ex.experiment_group,
       ex.occurred_at AS treatment_start,
       u.user_id,
       u.activated_at,
       COUNT(CASE WHEN e.event_name = 'login' THEN e.user_id ELSE NULL END) AS metric
  FROM (SELECT user_id,
               experiment,
               experiment_group,
               occurred_at
          FROM tutorial.yammer_experiments
         WHERE experiment = 'publisher_update'
       ) ex
  JOIN tutorial.yammer_users u
    ON u.user_id = ex.user_id
  JOIN tutorial.yammer_events e
    ON e.user_id = ex.user_id
   AND e.occurred_at >= ex.occurred_at
   AND e.occurred_at < '2014-07-01'
   AND e.event_type = 'engagement'
 GROUP BY 1,2,3,4,5
       ) a
 GROUP BY 1,2
       ) b
       ) c
  LEFT JOIN benn.normal_distribution nd
    ON nd.score = ABS(ROUND((c.average - c.control_average)/SQRT((c.variance/c.users) + (c.control_variance/c.control_users)),3))

-- count all logins from the same user one day as one to ensure the increased login is not due to login failure
SELECT c.experiment,
       c.experiment_group,
       c.users,
       c.total_treated_users,
       ROUND(c.users/c.total_treated_users,4) AS treatment_percent,
       c.total,
       ROUND(c.average,4)::FLOAT AS average,
       ROUND(c.average - c.control_average,4) AS rate_difference,
       ROUND((c.average - c.control_average)/c.control_average,4) AS rate_lift,
       ROUND(c.stdev,4) AS stdev,
       ROUND((c.average - c.control_average) /
          SQRT((c.variance/c.users) + (c.control_variance/c.control_users))
        ,4) AS t_stat,
       (1 - COALESCE(nd.value,1))*2 AS p_value
  FROM (
SELECT *,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.users ELSE NULL END) OVER () AS control_users,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.average ELSE NULL END) OVER () AS control_average,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.total ELSE NULL END) OVER () AS control_total,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.variance ELSE NULL END) OVER () AS control_variance,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.stdev ELSE NULL END) OVER () AS control_stdev,
       SUM(b.users) OVER () AS total_treated_users
  FROM (
SELECT a.experiment,
       a.experiment_group,
       COUNT(a.user_id) AS users,
       AVG(a.metric) AS average,
       SUM(a.metric) AS total,
       STDDEV(a.metric) AS stdev,
       VARIANCE(a.metric) AS variance
  FROM (
SELECT ex.experiment,
       ex.experiment_group,
       ex.occurred_at AS treatment_start,
       u.user_id,
       u.activated_at,
       COUNT(DISTINCT DATE_TRUNC('day',e.occurred_at)) AS metric
  FROM (SELECT user_id,
               experiment,
               experiment_group,
               occurred_at
          FROM tutorial.yammer_experiments
         WHERE experiment = 'publisher_update'
       ) ex
  JOIN tutorial.yammer_users u
    ON u.user_id = ex.user_id
  JOIN tutorial.yammer_events e
    ON e.user_id = ex.user_id
   AND e.occurred_at >= ex.occurred_at
   AND e.occurred_at < '2014-07-01'
   AND e.event_type = 'engagement'
 GROUP BY 1,2,3,4,5
       ) a
 GROUP BY 1,2
       ) b
       ) c
  LEFT JOIN benn.normal_distribution nd
    ON nd.score = ABS(ROUND((c.average - c.control_average)/SQRT((c.variance/c.users) + (c.control_variance/c.control_users)),3))

-- check whether treatment introduce new user in the test, and how much is the influence
-- => check for possible confounding factor
SELECT DATE_TRUNC('month',u.activated_at) AS month_activated,
       COUNT(CASE WHEN e.experiment_group = 'control_group' THEN u.user_id ELSE NULL END) AS control_users,
       COUNT(CASE WHEN e.experiment_group = 'test_group' THEN u.user_id ELSE NULL END) AS test_users
  FROM tutorial.yammer_experiments e
  JOIN tutorial.yammer_users u
    ON u.user_id = e.user_id
 GROUP BY 1
 ORDER BY 1

 -- as new user do contirbute to the test result
 -- => only compare the existing user to see whether get the same A/B test result
 SELECT c.experiment,
       c.experiment_group,
       c.users,
       c.total_treated_users,
       ROUND(c.users/c.total_treated_users,4) AS treatment_percent,
       c.total,
       ROUND(c.average,4)::FLOAT AS average,
       ROUND(c.average - c.control_average,4) AS rate_difference,
       ROUND((c.average - c.control_average)/c.average,4) AS rate_lift,
       ROUND(c.stdev,4) AS stdev,
       ROUND((c.average - c.control_average) /
          SQRT((c.variance/c.users) + (c.control_variance/c.control_users))
        ,4) AS t_stat,
       (1 - COALESCE(nd.value,1))*2 AS p_value
  FROM (
SELECT *,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.users ELSE NULL END) OVER () AS control_users,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.average ELSE NULL END) OVER () AS control_average,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.total ELSE NULL END) OVER () AS control_total,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.variance ELSE NULL END) OVER () AS control_variance,
       MAX(CASE WHEN b.experiment_group = 'control_group' THEN b.stdev ELSE NULL END) OVER () AS control_stdev,
       SUM(b.users) OVER () AS total_treated_users
  FROM (
SELECT a.experiment,
       a.experiment_group,
       COUNT(a.user_id) AS users,
       AVG(a.metric) AS average,
       SUM(a.metric) AS total,
       STDDEV(a.metric) AS stdev,
       VARIANCE(a.metric) AS variance
  FROM (
SELECT ex.experiment,
       ex.experiment_group,
       ex.occurred_at AS treatment_start,
       u.user_id,
       u.activated_at,
       COUNT(CASE WHEN e.event_name = 'send_message' THEN e.user_id ELSE NULL END) AS metric
  FROM (SELECT user_id,
               experiment,
               experiment_group,
               occurred_at
          FROM tutorial.yammer_experiments
         WHERE experiment = 'publisher_update'
       ) ex
  JOIN tutorial.yammer_users u
    ON u.user_id = ex.user_id
   AND u.activated_at < '2014-06-01'
  JOIN tutorial.yammer_events e
    ON e.user_id = ex.user_id
   AND e.occurred_at >= ex.occurred_at
   AND e.occurred_at <= '2014-07-01'
   AND e.event_type = 'engagement'
 GROUP BY 1,2,3,4,5
       ) a
 GROUP BY 1,2
       ) b
       ) c
  LEFT JOIN benn.normal_distribution nd
    ON nd.score = ABS(ROUND((c.average - c.control_average)/SQRT((c.variance/c.users) + (c.control_variance/c.control_users)),3))

-- check other confouding factor for the test, e.g device