-- ------------------------------------------------------------------------
-- Data & Persistency
-- Opdracht S6: Views
--
-- (c) 2020 Hogeschool Utrecht
-- Tijmen Muller (tijmen.muller@hu.nl)
-- André Donk (andre.donk@hu.nl)
-- ------------------------------------------------------------------------


-- S6.1.
--
-- 1. Maak een view met de naam "deelnemers" waarmee je de volgende gegevens uit de tabellen inschrijvingen en uitvoering combineert:
--    inschrijvingen.cursist, inschrijvingen.cursus, inschrijvingen.begindatum, uitvoeringen.docent, uitvoeringen.locatie
-- 2. Gebruik de view in een query waarbij je de "deelnemers" view combineert met de "personeels" view (behandeld in de les):
--     CREATE OR REPLACE VIEW personeel AS
-- 	     SELECT mnr, voorl, naam as medewerker, afd, functie
--       FROM medewerkers;
-- 3. Is de view "deelnemers" updatable ? Waarom ?

-- 1. View 'deelnemers':
CREATE OR REPLACE VIEW deelnemers AS
SELECT i.cursist, i.cursus, i.begindatum, u.docent, u.locatie
FROM inschrijvingen i
JOIN uitvoeringen u ON i.cursus = u.cursus AND i.begindatum = u.begindatum;

-- 2. Combineren met de view 'personeel':
CREATE OR REPLACE VIEW personeel AS
    SELECT mnr, voorl, naam AS medewerker, afd, functie
    FROM medewerkers;

SELECT p.medewerker, d.cursus, d.begindatum, d.locatie
FROM deelnemers d
JOIN personeel p ON d.cursist = p.mnr;

-- 3. Nee, de view 'deelnemers' is NIET updatable. In PostgreSQL is een view alleen
--    automatisch updatable als hij op precies één basistabel is gebaseerd (zonder
--    JOIN, GROUP BY, DISTINCT, aggregaties, enz.). 'deelnemers' combineert twee
--    tabellen via een JOIN, dus de database weet bij een INSERT/UPDATE/DELETE niet
--    welke onderliggende tabel(len) hij moet aanpassen. Het zou wel kunnen via een
--    INSTEAD OF-trigger, maar standaard is hij read-only.


-- S6.2.
--
-- 1. Maak een view met de naam "dagcursussen". Deze view dient de gegevens op te halen: 
--      code, omschrijving en type uit de tabel curssussen met als voorwaarde dat de lengte = 1. Toon aan dat de view werkt. 
-- 2. Maak een tweede view met de naam "daguitvoeringen". 
--    Deze view dient de uitvoeringsgegevens op te halen voor de "dagcurssussen" (gebruik ook de view "dagcursussen"). Toon aan dat de view werkt
-- 3. Verwijder de views en laat zien wat de verschillen zijn bij DROP view <viewnaam> CASCADE en bij DROP view <viewnaam> RESTRICT

-- 1. View 'dagcursussen':
CREATE OR REPLACE VIEW dagcursussen AS
SELECT code, omschrijving, type
FROM cursussen
WHERE lengte = 1;

SELECT * FROM dagcursussen;   -- toont aan dat de view werkt

-- 2. View 'daguitvoeringen' (gebruikt de view dagcursussen):
CREATE OR REPLACE VIEW daguitvoeringen AS
SELECT u.cursus, u.begindatum, u.docent, u.locatie
FROM uitvoeringen u
WHERE u.cursus IN (SELECT code FROM dagcursussen);

SELECT * FROM daguitvoeringen;   -- toont aan dat de view werkt

-- 3. Verschil tussen RESTRICT en CASCADE:
--    'daguitvoeringen' is afhankelijk van 'dagcursussen'.
--
--    DROP VIEW dagcursussen RESTRICT;   (RESTRICT is de standaard)
--      -> MISLUKT met:
--         ERROR: cannot drop view dagcursussen because other objects depend on it
--         DETAIL: view daguitvoeringen depends on view dagcursussen
--      RESTRICT weigert de drop zolang er nog objecten van afhangen.
--
--    DROP VIEW dagcursussen CASCADE;
--      -> LUKT: verwijdert dagcursussen én automatisch alle afhankelijke objecten
--         (dus ook daguitvoeringen).
--
-- Opruimen:
DROP VIEW IF EXISTS daguitvoeringen;
DROP VIEW IF EXISTS dagcursussen;

