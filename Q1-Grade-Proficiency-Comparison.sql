/*Data Cleaning*/
CREATE TEMP TABLE t1 AS
SELECT
  Student_First_Name,
  CAST(TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LEFT(Student_Grade_Level,2),'s',''),'t',''),'Ki','0'),'n',''),'r','')) AS INT64) AS Grade_Level,
  Class_Name,
  CASE
    WHEN Class_Name LIKE '%ELA%' OR class_name LIKE '%Lit%' OR class_name LIKE '%Eng%' OR class_name = '%Writ%' THEN 'ELA' 
    WHEN Class_Name LIKE '%Alg%' OR Class_Name LIKE '%Geo%' OR Class_Name LIKE '%Math%' OR Class_Name LIKE '%Calc%' THEN 'Math'
    ELSE Class_Name
    END AS Subject,
  Q1_Grade,
  CASE 
    WHEN Q1_Grade > 79.9 THEN 'Grade Level' ELSE 'Not Grade Level' END AS Grade_Level_Proficiency -- condition for proficiency 79.9 or above
FROM `my-data-project-36654.Term1_Grades_Q1_2324.FA_Q1_Grades` 
WHERE Q1_Grade IS NOT NULL;

WITH Ovr_Gr_Pro AS
/*Overall Q1 Grade Proficiency*/
(SELECT
  DISTINCT sub.Grade_Level,
  sub.Grade_Level_Proficiency,
  ROUND(sub.Grade_Level_Proficiency_Cnt/sub.Total,2) AS Ovr_Q1_Grade_Proficiency
FROM
(SELECT 
  DISTINCT t1.Grade_Level,
  t1.Grade_Level_Proficiency,
  COUNT(*) OVER (PARTITION BY t1.Grade_Level, t1.Grade_Level_Proficiency) AS Grade_Level_Proficiency_Cnt,
  COUNT(*) OVER (PARTITION BY t1.Grade_Level) AS Total,
  t1.subject
FROM t1
ORDER BY t1.Grade_Level) AS sub
WHERE sub.Grade_Level_Proficiency = 'Grade Level'
ORDER BY sub.Grade_Level),

/*ELA Q1 Grade Proficiency*/
ELA_Gr_Pro AS
(SELECT
  DISTINCT sub.Grade_Level,
  sub.Grade_Level_Proficiency,
  ROUND(sub.Grade_Level_Proficiency_Cnt/sub.Total,2) AS ELA_Q1_Grade_Proficiency
FROM
(SELECT 
  DISTINCT t1.Grade_Level,
  t1.Grade_Level_Proficiency,
  COUNT(*) OVER (PARTITION BY t1.Grade_Level, t1.Grade_Level_Proficiency) AS Grade_Level_Proficiency_Cnt,
  COUNT(*) OVER (PARTITION BY t1.Grade_Level) AS Total,
  t1.subject
FROM t1
WHERE t1.subject = 'ELA'
ORDER BY t1.Grade_Level) AS sub
WHERE sub.Grade_Level_Proficiency = 'Grade Level'
ORDER BY sub.Grade_Level),

/*Math Q1 Grade Proficiency*/
MATH_Gr_Pro AS 
(SELECT
  DISTINCT sub.Grade_Level,
  sub.Grade_Level_Proficiency,
  ROUND(sub.Grade_Level_Proficiency_Cnt/sub.Total,2) AS Math_Q1_Grade_Proficiency
FROM
(SELECT 
  DISTINCT t1.Grade_Level,
  t1.Grade_Level_Proficiency,
  COUNT(*) OVER (PARTITION BY t1.Grade_Level, t1.Grade_Level_Proficiency) AS Grade_Level_Proficiency_Cnt,
  COUNT(*) OVER (PARTITION BY t1.Grade_Level) AS Total,
  t1.subject
FROM t1
WHERE t1.subject = 'Math'
ORDER BY t1.Grade_Level) AS sub
WHERE sub.Grade_Level_Proficiency = 'Grade Level'
ORDER BY sub.Grade_Level),

/*iReady 1 Math Proficiency*/
ir1_Math AS 
(SELECT
 DISTINCT sub.Grade,
 sub.Proficiency,
  ROUND(COUNT(sub.Proficiency) OVER (PARTITION BY sub.Proficiency,sub.Grade)/ sub.Grade_Count,2) AS iReady_1_Math_Proficiency_Pct,
  sub.Grade_Count
FROM 
(SELECT  
  COUNT(*) OVER (PARTITION BY Student_Grade) AS Grade_Count,
  CAST(REPLACE(Student_Grade,'K','0') AS int64) AS Grade,
  Overall_Relative_Placement,
  CASE 
    WHEN Overall_Relative_Placement IN ('Early On Grade Level','Mid or Above Grade Level') THEN 'Proficient'
ELSE 'Not Proficient' END AS Proficiency
FROM `my-data-project-36654.Term1_Grades_Q1_2324.iReady1_Math_363`) AS sub
ORDER BY sub.Grade),

/*iReady 1 ELA Proficiency*/
ir1_ELA AS (SELECT
 DISTINCT sub.Grade,
 sub.Proficiency,
  ROUND(COUNT(sub.Proficiency) OVER (PARTITION BY sub.Proficiency,sub.Grade)/ sub.Grade_Count,2) AS iReady_1_ELA_Proficiency_Pct,
  sub.Grade_Count
FROM 
(SELECT  
  COUNT(*) OVER (PARTITION BY Student_Grade) AS Grade_Count,
  CAST(REPLACE(Student_Grade,'K','0') AS int64) AS Grade,
  Overall_Relative_Placement,
  CASE 
    WHEN Overall_Relative_Placement IN ('Early On Grade Level','Mid or Above Grade Level') THEN 'Proficient'
ELSE 'Not Proficient' END AS Proficiency
FROM `my-data-project-36654.Term1_Grades_Q1_2324.iReady1_ELA_363`) AS sub
ORDER BY sub.Grade)

/*Pivoting Grade Level Proficiency with iReady Proficiency*/
SELECT
  DISTINCT Ovr_Gr_Pro.Grade_Level,
  Ovr_Gr_Pro.Ovr_Q1_Grade_Proficiency,
  ELA_Gr_Pro.ELA_Q1_Grade_Proficiency,
  ir1_ELA.iReady_1_ELA_Proficiency_Pct,
  MATH_Gr_Pro.Math_Q1_Grade_Proficiency,
  ir1_Math.iReady_1_Math_Proficiency_Pct
FROM Ovr_Gr_Pro
LEFT JOIN ELA_Gr_Pro ON  Ovr_Gr_Pro.Grade_Level = ELA_Gr_Pro.Grade_Level 
LEFT JOIN MATH_Gr_Pro ON Ovr_Gr_Pro.Grade_Level = MATH_Gr_Pro.Grade_Level
LEFT JOIN ir1_Math ON Ovr_Gr_Pro.Grade_Level = ir1_Math.Grade
LEFT JOIN ir1_ELA ON Ovr_Gr_Pro.Grade_Level = ir1_ELA.Grade
WHERE ir1_Math.Proficiency = 'Proficient' AND ir1_ELA.Proficiency = 'Proficient'
ORDER BY Ovr_Gr_Pro.Grade_Level;



WITH Ovr AS
/*Q1 Overall Grade Calculations*/
(SELECT 
  DISTINCT t1.Grade_Level,
  ROUND(AVG(t1.Q1_Grade) OVER (PARTITION BY t1.Grade_Level),2) AS Overall_Q1_Grade_Avg
FROM t1
ORDER BY t1.Grade_Level),

/*Q1 ELA Grade Calculations*/
ELA AS (SELECT 
  DISTINCT t1.Subject,
  t1.Grade_Level,
  ROUND(AVG(t1.Q1_Grade) OVER (PARTITION BY t1.subject,t1.Grade_Level),2) AS ELA_Q1_Grade_Avg
FROM t1
WHERE t1.subject = 'ELA'
ORDER BY t1.Grade_Level),

/*Q1 Math Grade Calculations*/
Math AS (SELECT 
  DISTINCT t1.Subject,
  t1.Grade_Level,
  ROUND(AVG(t1.Q1_Grade) OVER (PARTITION BY t1.subject,t1.Grade_Level),2) AS Math_Q1_Grade_Avg
FROM t1 
WHERE t1.subject = 'Math'
ORDER BY t1.Grade_Level),

/*iReady 1 Math Proficiency*/
ir1_Math AS 
(SELECT
 DISTINCT sub.Grade,
 sub.Proficiency,
  ROUND(COUNT(sub.Proficiency) OVER (PARTITION BY sub.Proficiency,sub.Grade)/ sub.Grade_Count,2) AS iReady_1_Math_Proficiency_Pct,
  sub.Grade_Count
FROM 
(SELECT  
  COUNT(*) OVER (PARTITION BY Student_Grade) AS Grade_Count,
  CAST(REPLACE(Student_Grade,'K','0') AS int64) AS Grade,
  Overall_Relative_Placement,
  CASE 
    WHEN Overall_Relative_Placement IN ('Early On Grade Level','Mid or Above Grade Level') THEN 'Proficient'
ELSE 'Not Proficient' END AS Proficiency
FROM `my-data-project-36654.Term1_Grades_Q1_2324.iReady1_Math_363`) AS sub
ORDER BY sub.Grade),

/*iReady 1 ELA Proficiency*/
ir1_ELA AS (SELECT
 DISTINCT sub.Grade,
 sub.Proficiency,
  ROUND(COUNT(sub.Proficiency) OVER (PARTITION BY sub.Proficiency,sub.Grade)/ sub.Grade_Count,2) AS iReady_1_ELA_Proficiency_Pct,
  sub.Grade_Count
FROM 
(SELECT  
  COUNT(*) OVER (PARTITION BY Student_Grade) AS Grade_Count,
  CAST(REPLACE(Student_Grade,'K','0') AS int64) AS Grade,
  Overall_Relative_Placement,
  CASE 
    WHEN Overall_Relative_Placement IN ('Early On Grade Level','Mid or Above Grade Level') THEN 'Proficient'
ELSE 'Not Proficient' END AS Proficiency
FROM `my-data-project-36654.Term1_Grades_Q1_2324.iReady1_ELA_363`) AS sub
ORDER BY sub.Grade)

/*Pivoting Results Grade Avgs v iReady 1 Proficiency*/
SELECT 
  Ovr.Grade_Level,
  Ovr.Overall_Q1_Grade_Avg,
  ELA.ELA_Q1_Grade_Avg,
  ir1_ELA.iReady_1_ELA_Proficiency_Pct,
  Math.Math_Q1_Grade_Avg,
  ir1_Math.iReady_1_Math_Proficiency_Pct,
FROM Ovr
LEFT JOIN ELA ON Ovr.grade_level = ELA.grade_level
LEFT JOIN Math ON Ovr.Grade_Level = Math.Grade_Level
LEFT JOIN ir1_Math ON Ovr.Grade_Level = ir1_Math.Grade
LEFT JOIN ir1_ELA ON Ovr.Grade_Level = ir1_ELA.Grade
WHERE ir1_Math.Proficiency = 'Proficient' AND ir1_ELA.Proficiency = 'Proficient' -- Filtering to return proficient values.
ORDER BY Ovr.Grade_Level
