/* MRT_Select-MonthlyPeopleAverage.sql 
/*
/* It returns a table containing a row for each day in the following format:
	YYYYMMDD;Amount_of_employees;Amount_of_external_collaborators;Amount_of_guests;Total_amount
For each day of the month. At the end of the month, it builds an additional row in the following format:
	Average of month YYYYMM;Monthly_averaged_employees;Monthly_averaged_external;Monthly_averaged;guests;Total_averaged
Attendances are computed depending on univocal entry transits through a specific entrance (@VARCO) starting from a specific date (@DATAORAINIZIO) */

USE MRT

/* VARIABILI */
DECLARE @VARCO nvarchar(8)
DECLARE @DATAORAINIZIO nvarchar(14)

/* PARAMETRI */
SET @VARCO='00000004' -- Insert entrance
SET @DATAORAINIZIO='20170223000000' -- Insert start date time

SELECT * FROM 
	(
	/* TOTALI PER GIORNO */
	SELECT GIORNO, 
		SUM(CASE WHEN T37TIPOMATRICOLA='0' THEN 1 ELSE 0 END) AS DIPENDENTI,
		SUM(CASE WHEN T37TIPOMATRICOLA='1' THEN 1 ELSE 0 END) AS ESTERNI,
		SUM(CASE WHEN T37TIPOMATRICOLA='2' THEN 1 ELSE 0 END) AS VISITATORI,
	COUNT(*) AS TOTALE, 
	GIORNO AS ORDINE
	FROM 
		(
		/* Dipendenti */
		SELECT DISTINCT 
			LEFT(T37DATAORA, 8) AS GIORNO, 
			T37MATRICOLA, 
			T37TIPOMATRICOLA, 
			T37CODAZIENDAINTERNA AS AZIE
		FROM T37ACCTRANSITI
		WHERE T37TIPOMATRICOLA='0' AND T37ESITO IN ('0', '2', '3') AND T37COGNOME<>'?' AND T37NOME<>'?'
			AND T37DATAORA >= @DATAORAINIZIO AND T37ENTRAESCE='1' AND T37VARCO=@VARCO
		UNION ALL
		/* Esterni */
		SELECT DISTINCT 
			LEFT(T37DATAORA, 8) AS GIORNO, 
			T37MATRICOLA, 
			T37TIPOMATRICOLA, 
			T37CODGRAZ AS AZIE
		FROM T37ACCTRANSITI
		WHERE T37TIPOMATRICOLA='1' AND T37ESITO IN ('0', '2', '3') AND T37COGNOME<>'?' AND T37NOME<>'?'
			AND T37DATAORA >= @DATAORAINIZIO AND T37ENTRAESCE='1' AND T37VARCO=@VARCO
		UNION ALL
		/* Visitatori */
		SELECT DISTINCT 
			LEFT(T37DATAORA, 8) AS GIORNO, 
			T37MATRICOLA, 
			T37TIPOMATRICOLA, 
			'*' AS AZIE
		FROM T37ACCTRANSITI
		WHERE T37TIPOMATRICOLA='2' AND T37ESITO IN ('0', '2', '3') AND T37COGNOME<>'?' AND T37NOME<>'?'
			AND T37DATAORA >= @DATAORAINIZIO AND T37ENTRAESCE='1' AND T37VARCO=@VARCO
		) AS D
		GROUP BY GIORNO
	) AS D
UNION ALL
(
	/* MEDIE MENSILI */
	SELECT 
		'Media mese '+ LEFT(GIORNO, 6) AS GIORNO, 
		AVG(DIPENDENTI) AS DIPENDENTI, 
		AVG(ESTERNI) AS ESTERNI,
		AVG(VISITATORI) AS VISITATORI, 
		0 AS TOTALE, 
		LEFT(GIORNO, 6) + '99' AS ORDINE
	FROM (
		SELECT 
			GIORNO, 
			SUM(CASE WHEN T37TIPOMATRICOLA='0' THEN 1 ELSE 0 END) AS DIPENDENTI,
			SUM(CASE WHEN T37TIPOMATRICOLA='1' THEN 1 ELSE 0 END) AS ESTERNI,
			SUM(CASE WHEN T37TIPOMATRICOLA='2' THEN 1 ELSE 0 END) AS VISITATORI,
			COUNT(*) AS TOTALE 
		FROM 
			(
			/* Dipendenti */
			SELECT DISTINCT 
				LEFT(T37DATAORA, 8) AS GIORNO, 
				T37MATRICOLA, 
				T37TIPOMATRICOLA, 
				T37CODAZIENDAINTERNA AS AZIE
			FROM T37ACCTRANSITI
			WHERE T37TIPOMATRICOLA='0' AND T37ESITO IN ('0', '2', '3') AND T37COGNOME<>'?' AND T37NOME<>'?'
				AND T37DATAORA >= @DATAORAINIZIO AND T37ENTRAESCE='1' AND T37VARCO=@VARCO
			UNION ALL
			/* Esterni */
			SELECT DISTINCT 
				LEFT(T37DATAORA, 8) AS GIORNO, 
				T37MATRICOLA, 
				T37TIPOMATRICOLA, 
				T37CODGRAZ AS AZIE
			FROM T37ACCTRANSITI
			WHERE T37TIPOMATRICOLA='1' AND T37ESITO IN ('0', '2', '3') AND T37COGNOME<>'?' AND T37NOME<>'?'
				AND T37DATAORA >= @DATAORAINIZIO AND T37ENTRAESCE='1' AND T37VARCO=@VARCO
			UNION ALL
			/* Visitatori */
			SELECT DISTINCT 
				LEFT(T37DATAORA, 8) AS GIORNO, 
				T37MATRICOLA, 
				T37TIPOMATRICOLA, 
				'*' AS AZIE
			FROM T37ACCTRANSITI
			WHERE T37TIPOMATRICOLA='2' AND T37ESITO IN ('0', '2', '3') AND T37COGNOME<>'?' AND T37NOME<>'?'
					AND T37DATAORA >= @DATAORAINIZIO AND T37ENTRAESCE='1' AND T37VARCO=@VARCO
			) AS D
			GROUP BY GIORNO
		) AS M
	GROUP BY LEFT(GIORNO, 6)
)
ORDER BY ORDINE
