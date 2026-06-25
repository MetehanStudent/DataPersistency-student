-- ------------------------------------------------------------------------
-- Data & Persistency
-- Opdracht S8: Extra (uitdagende) queries
--
-- (c) 2020 Hogeschool Utrecht
-- Tijmen Muller (tijmen.muller@hu.nl)
-- André Donk (andre.donk@hu.nl)
--
--
-- Opdracht: schrijf SQL-queries om onderstaande resultaten op te vragen,
-- aan te maken, verwijderen of aan te passen in de database van de
-- bedrijfscasus.
-- ------------------------------------------------------------------------


-- S8.1.
-- Geef naam en voorletters van iedereen die ooit bij Nico Smit
-- een cursus heeft gevolgd.
SELECT DISTINCT m.naam, m.voorl
FROM inschrijvingen i
JOIN uitvoeringen u  ON i.cursus = u.cursus AND i.begindatum = u.begindatum
JOIN medewerkers m   ON i.cursist = m.mnr
WHERE u.docent = (SELECT mnr FROM medewerkers WHERE naam = 'SMIT' AND voorl = 'N');


-- S8.2.
-- Geef van iedere medewerker: achternaam en het jaarsalaris
-- inclusief toelage en commissie (alias `jaarsalaris`).
-- Jaarsalaris = 12 * (maandsalaris + maandtoelage) + commissie (NULL telt als 0).
SELECT m.naam,
       12 * (m.maandsal + s.toelage) + COALESCE(m.comm, 0) AS jaarsalaris
FROM medewerkers m
JOIN schalen s ON m.maandsal BETWEEN s.ondergrens AND s.bovengrens;


-- S8.3.
-- Geef van alle docenten: naam en voorletters, het aantal
-- cursussen dat ze hebben gegeven (`aantal_cursussen`),
-- het aantal cursisten dat ze hebben opgeleid (`aantal_cursisten`),
-- en het gemiddelde evaluatiecijfer (`score`). Rond de laatste
-- af op één decimaal.
SELECT d.naam, d.voorl,
       COUNT(DISTINCT (u.cursus, u.begindatum)) AS aantal_cursussen,
       COUNT(i.cursist)                          AS aantal_cursisten,
       ROUND(AVG(i.evaluatie), 1)                AS score
FROM medewerkers d
JOIN uitvoeringen u    ON u.docent = d.mnr
LEFT JOIN inschrijvingen i ON i.cursus = u.cursus AND i.begindatum = u.begindatum
GROUP BY d.mnr, d.naam, d.voorl;


-- S8.4.
-- Geef de locatie waar op een bepaald moment twee cursussen tegelijk werd
-- gegeven.
-- Twee uitvoeringen op dezelfde locatie waarvan de periodes (begindatum t/m
-- begindatum + lengte in dagen) elkaar overlappen.
SELECT DISTINCT u1.locatie
FROM uitvoeringen u1
JOIN cursussen   c1 ON u1.cursus = c1.code
JOIN uitvoeringen u2 ON u1.locatie = u2.locatie
                    AND (u1.cursus, u1.begindatum) < (u2.cursus, u2.begindatum)
JOIN cursussen   c2 ON u2.cursus = c2.code
WHERE u1.begindatum <= u2.begindatum + c2.lengte
  AND u2.begindatum <= u1.begindatum + c1.lengte;


-- S8.5.
-- Geef docent en cursus waarvoor geldt dat de docent de cursus éérst bij een
-- collega heeft gevolgd vóór hij de cursus zelf heeft gegeven.
SELECT DISTINCT m.naam AS docent, u.cursus
FROM uitvoeringen u
JOIN medewerkers   m ON u.docent = m.mnr
JOIN inschrijvingen i ON i.cursist = u.docent AND i.cursus = u.cursus
WHERE i.begindatum < u.begindatum;


-- S8.6.
-- Geef de achternaam van alle werknemers die álle bouwcursussen ('BLD') hebben
-- gevolgd.
SELECT m.naam
FROM medewerkers m
JOIN inschrijvingen i ON i.cursist = m.mnr
JOIN cursussen     c ON i.cursus = c.code AND c.type = 'BLD'
GROUP BY m.mnr, m.naam
HAVING COUNT(DISTINCT i.cursus) = (SELECT COUNT(*) FROM cursussen WHERE type = 'BLD');
