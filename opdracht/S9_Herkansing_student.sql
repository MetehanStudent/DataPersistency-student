-- ------------------------------------------------------------------------
-- Data & Persistency
-- Opdracht S9: Aanvullende herkansingsopdracht
--
-- (c) 2020 Hogeschool Utrecht
-- Tijmen Muller (tijmen.muller@hu.nl)
-- André Donk (andre.donk@hu.nl)
--
--
-- Opdracht: schrijf SQL-queries om onderstaande resultaten op te vragen,
-- aan te maken, verwijderen of aan te passen in de database van de
-- bedrijfscasus.
--
-- Codeer je uitwerking onder de regel 'DROP VIEW ...' (bij een SELECT)
-- of boven de regel 'ON CONFLICT DO NOTHING;' (bij een INSERT)
-- Je kunt deze eigen query selecteren en los uitvoeren, en wijzigen tot
-- je tevreden bent.
--
-- Vervolgens kun je je uitwerkingen testen door de testregels
-- (met [TEST] erachter) te activeren (haal hiervoor de commentaartekens
-- weg) en vervolgens het hele bestand uit te voeren. Hiervoor moet je de
-- testsuite in de database hebben geladen (bedrijf_postgresql_test.sql).
-- NB: niet alle opdrachten hebben testregels.
--
-- Lever je werk pas in op Canvas als alle tests slagen.
-- ------------------------------------------------------------------------


-- S9.1  Overstap
--
-- Jan-Jaap den Draaier is per 1 oktober 2020 manager van personeelszaken.
-- Hij komt direct onder de directeur te vallen en gaat 2100 euro per
-- maand verdienen.
-- Voer alle queries uit om deze wijziging door te voeren.
-- 1) Sluit de huidige historieregel van Den Draaier (7844) af per 1-10-2020.
UPDATE historie SET einddatum = '2020-10-01'
WHERE mnr = 7844 AND einddatum IS NULL;

-- 2) Werk de medewerker bij: manager, afd personeelszaken (40), onder directeur, 2100.
UPDATE medewerkers SET functie = 'MANAGER', afd = 40, chef = 7839, maandsal = 2100
WHERE mnr = 7844;

-- 3) Den Draaier wordt hoofd van personeelszaken (afd 40).
UPDATE afdelingen SET hoofd = 7844 WHERE anr = 40;

-- 4) Nieuwe (huidige) historieregel voor zijn nieuwe positie.
INSERT INTO historie (mnr, beginjaar, begindatum, einddatum, afd, maandsal, opmerkingen)
VALUES (7844, 2020, '2020-10-01', NULL, 40, 2100, '')
ON CONFLICT DO NOTHING;                                                                                         -- [TEST]


-- S9.2  Beginjaar
--
-- Voeg een beperkingsregel `h_beginjaar_chk` toe aan de historietabel
-- die controleert of een ingevoerde waarde in de kolom `beginjaar` een
-- correcte waarde heeft, met andere woorden: dat het om het huidige jaar
-- gaat of een jaar dat in het verleden ligt.
-- Test je beperkingsregel daarna met een INSERT die deze regel schendt.

ALTER TABLE historie ADD CONSTRAINT h_beginjaar_chk
CHECK (beginjaar <= EXTRACT(YEAR FROM CURRENT_DATE));

-- Test (toekomstig jaar -> schendt de regel). Laat deze INSERT in commentaar staan,
-- anders breekt hij het volledig uitvoeren van het bestand af.
--   INSERT INTO historie (mnr, beginjaar, begindatum, afd, maandsal, opmerkingen)
--   VALUES (7839, 2099, '2099-01-01', 10, 5000, '');
-- Foutmelding:
--   ERROR: new row for relation "historie" violates check constraint "h_beginjaar_chk"


-- S9.3  Opmerkingen
--
-- Geef uit de historietabel alle niet-lege opmerkingen bij de huidige posities
-- van medewerkers binnen het bedrijf. Geef ter referentie ook het medewerkersnummer
-- bij de resultaten.
DROP VIEW IF EXISTS s9_3; CREATE OR REPLACE VIEW s9_3 AS                                                     -- [TEST]
-- Huidige posities = historieregels zonder einddatum, met een niet-lege opmerking.
SELECT opmerkingen, mnr
FROM historie
WHERE einddatum IS NULL AND opmerkingen <> '';


-- S9.4  Carrièrepad
--
-- Toon van alle medewerkers die nú op het hoofdkantoor werken hun historie
-- binnen het bedrijf: geef van elke positie die ze bekleed hebben de
-- de naam van de medewerker, de begindatum, de naam van hun afdeling op dat
-- moment (`afdeling`) en hun toenmalige salarisschaal (`schaal`).
-- Sorteer eerst op naam en dan op ingangsdatum.
DROP VIEW IF EXISTS s9_4; CREATE OR REPLACE VIEW s9_4 AS                                                     -- [TEST]
-- Medewerkers die nú op het hoofdkantoor (afd 10) werken, met hun volledige historie.
-- afdeling = naam van de afdeling op dat moment, schaal = salarisschaal (snr) toen.
SELECT m.naam, h.begindatum, a.naam AS afdeling, s.snr AS schaal
FROM medewerkers m
JOIN historie  h ON h.mnr = m.mnr
JOIN afdelingen a ON h.afd = a.anr
JOIN schalen   s ON h.maandsal BETWEEN s.ondergrens AND s.bovengrens
WHERE m.afd = 10
ORDER BY m.naam, h.begindatum;


-- S9.5 Aanloop
--
-- Toon voor elke medewerker de naam en hoelang zij in andere functies hebben
-- gewerkt voordat zij op hun huidige positie kwamen (`tijdsduur`).
-- Rond naar beneden af op gehele jaren.
DROP VIEW IF EXISTS s9_5; CREATE OR REPLACE VIEW s9_5 AS                                                     -- [TEST]
-- tijdsduur = aantal hele jaren tussen de allereerste historieregel en de begindatum
-- van de huidige positie (einddatum IS NULL). Aanname: 365 dagen per jaar.
SELECT m.naam,
       FLOOR((cur.begindatum - mn.min_begin) / 365.0)::DOUBLE PRECISION AS tijdsduur
FROM medewerkers m
JOIN (SELECT mnr, begindatum FROM historie WHERE einddatum IS NULL) cur ON cur.mnr = m.mnr
JOIN (SELECT mnr, MIN(begindatum) AS min_begin FROM historie GROUP BY mnr) mn ON mn.mnr = m.mnr;


-- S9.6 Index
--
-- Maak een index `historie_afd_idx` op afdelingsnummer in de historietabel.

CREATE INDEX historie_afd_idx ON historie (afd);



-- -------------------------[ HU TESTRAAMWERK ]--------------------------------
-- Met onderstaande query kun je je code testen. Zie bovenaan dit bestand
-- voor uitleg.

SELECT * FROM test_exists('S9.1', 1) AS resultaat
UNION
SELECT 'S9.2 wordt niet getest: zelf handmatig testen.' AS resultaat
UNION
SELECT * FROM test_select('S9.3') AS resultaat
UNION
SELECT * FROM test_select('S9.4') AS resultaat
UNION
SELECT * FROM test_select('S9.5') AS resultaat
UNION
SELECT 'S9.6 wordt niet getest: geen test mogelijk.' AS resultaat
ORDER BY resultaat;
