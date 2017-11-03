--Custom views for the news database

--Top Articles View
--This view reports the top articles of all time based on hits
CREATE OR REPLACE VIEW TopArticles AS
SELECT articles.title, hits.HitCount
FROM (
SELECT COUNT(log.path) as HitCount, SUBSTRING(log.path, 10) as Slug
FROM log
WHERE NOT path = '/'
GROUP BY Slug
ORDER BY HitCount DESC
) AS hits
RIGHT JOIN articles ON
hits.Slug = articles.slug
GROUP BY articles.title, hits.HitCount
ORDER BY hits.HitCount;

--Top Authors View
--This view reports the top authors of all time based on hits
CREATE OR REPLACE VIEW TopAuthors AS
SELECT  authors.name, SUM(Standings.HitCount) AuthorHits
FROM (
SELECT articles.author, articles.title, Hits.HitCount
FROM (
SELECT COUNT(log.path) as HitCount, SUBSTRING(log.path, 10) as Slug
FROM log
WHERE NOT path = '/'
GROUP BY Slug
ORDER BY HitCount DESC
) as Hits
RIGHT JOIN articles ON
Hits.Slug = articles.slug
GROUP BY articles.author, articles.title, Hits.HitCount
ORDER BY Hits.HitCount DESC) as Standings
LEFT JOIN authors
on authors.id = Standings.author
GROUP BY authors.name
ORDER BY AuthorHits DESC;

--Daily Error Percentage View
--This view reports the days in which error request accounted for more than 1% of daily requests
CREATE OR REPLACE VIEW DailyErrorRatio AS
SELECT ErrorPercent.date, concat(SUBSTRING(cast(ErrorPercent.ErrorDecimal as varchar(5)), 1, 3), ' %') as ErrorDecimal
FROM (
SELECT DailyErrors.time as date, ROUND((DailyErrors.DailyErrorCount / DailyRequestCount.requests_count), 2) * 100  as ErrorDecimal
FROM  (
SELECT SUM(ErrorByDay.count) DailyErrorCount, ErrorByDay.ErrorDate as time
FROM (
SELECT COUNT(status), DATE(time) as ErrorDate
FROM (
SELECT status, time
FROM log
WHERE status <> '200 OK'
GROUP BY status, time) as ErrorTimes
GROUP BY ErrorTimes.time, ErrorDate) as ErrorByDay
GROUP BY ErrorByDay.ErrorDate, ErrorByDay.count) as DailyErrors
LEFT JOIN (
SELECT COUNT(DATE(time)) requests_count, date(time) as ShortDate
FROM log
GROUP BY ShortDate) as DailyRequestCount
ON DailyErrors.time = DailyRequestCount.ShortDate
WHERE (DailyErrors.DailyErrorCount / DailyRequestCount.requests_count) >= .01) as ErrorPercent;