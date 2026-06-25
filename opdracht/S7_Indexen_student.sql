-- ------------------------------------------------------------------------
-- Data & Persistency
-- Opdracht S7: Indexen
--
-- (c) 2020 Hogeschool Utrecht
-- Tijmen Muller (tijmen.muller@hu.nl)
-- André Donk (andre.donk@hu.nl)
-- ------------------------------------------------------------------------
-- LET OP, zoals in de opdracht op Canvas ook gezegd kun je informatie over
-- het query plan vinden op: https://www.postgresql.org/docs/current/using-explain.html


-- S7.1.
--
-- Je maakt alle opdrachten in de 'sales' database die je hebt aangemaakt en gevuld met
-- de aangeleverde data (zie de opdracht op Canvas).
--
-- Voer het voorbeeld uit wat in de les behandeld is:
-- 1. Voer het volgende EXPLAIN statement uit:
--    EXPLAIN SELECT * FROM order_lines WHERE stock_item_id = 9;
--    Bekijk of je het resultaat begrijpt. Kopieer het explain plan onderaan de opdracht
-- 2. Voeg een index op stock_item_id toe:
--    CREATE INDEX ord_lines_si_id_idx ON order_lines (stock_item_id);
-- 3. Analyseer opnieuw met EXPLAIN hoe de query nu uitgevoerd wordt
--    Kopieer het explain plan onderaan de opdracht
-- 4. Verklaar de verschillen. Schrijf deze hieronder op.

-- 1. Zonder index:
EXPLAIN SELECT * FROM order_lines WHERE stock_item_id = 9;
--    >>> PLAK HIER JOUW EXPLAIN-PLAN (zonder index) <<<
--    Verwacht: een 'Seq Scan on order_lines' met een filter op stock_item_id.
--    De hele tabel wordt rij voor rij doorlopen.

-- 2. Index aanmaken:
CREATE INDEX ord_lines_si_id_idx ON order_lines (stock_item_id);

-- 3. Met index:
EXPLAIN SELECT * FROM order_lines WHERE stock_item_id = 9;
--    >>> PLAK HIER JOUW EXPLAIN-PLAN (met index) <<<
--    Verwacht: een 'Bitmap Index Scan' / 'Index Scan' op ord_lines_si_id_idx.

-- 4. Verklaring:
--    Zonder index moet PostgreSQL een Sequential Scan doen: élke rij van order_lines
--    wordt gelezen en vergeleken met stock_item_id = 9. Bij een grote tabel is dat duur.
--    Met de index kan de database via de index direct de paar matchende rijen opzoeken
--    (Index/Bitmap Scan) zonder de hele tabel te lezen. Daardoor dalen de geschatte
--    cost en het aantal gelezen rijen flink. De index kost wel extra opslag en maakt
--    INSERT/UPDATE/DELETE iets trager (de index moet ook bijgewerkt worden).


-- S7.2.
--
-- 1. Maak de volgende twee query’s:
-- 	  A. Toon uit de order tabel de order met order_id = 73590
-- 	  B. Toon uit de order tabel de order met customer_id = 1028
-- 2. Analyseer met EXPLAIN hoe de query’s uitgevoerd worden en kopieer het explain plan onderaan de opdracht
-- 3. Verklaar de verschillen en schrijf deze op
-- 4. Voeg een index toe, waarmee query B versneld kan worden
-- 5. Analyseer met EXPLAIN en kopieer het explain plan onder de opdracht
-- 6. Verklaar de verschillen en schrijf hieronder op

-- 1. De twee query's:
-- A.
EXPLAIN SELECT * FROM orders WHERE order_id = 73590;
--    >>> PLAK HIER JOUW EXPLAIN-PLAN van A <<<
--    Verwacht: 'Index Scan using pk_sales_orders' - order_id is de primary key en
--    heeft dus al automatisch een (unieke) index.

-- B.
EXPLAIN SELECT * FROM orders WHERE customer_id = 1028;
--    >>> PLAK HIER JOUW EXPLAIN-PLAN van B (vóór index) <<<
--    Verwacht: een 'Seq Scan on orders' - op customer_id staat (nog) geen index.

-- 3. Verklaring verschil:
--    Query A zoekt op de primary key order_id; daarop bestaat automatisch een index,
--    dus PostgreSQL gebruikt een snelle Index Scan. Query B zoekt op customer_id,
--    waarop geen index staat, dus moet de hele tabel sequentieel doorzocht worden.

-- 4. Index om query B te versnellen:
CREATE INDEX orders_customer_id_idx ON orders (customer_id);

-- 5. Opnieuw analyseren:
EXPLAIN SELECT * FROM orders WHERE customer_id = 1028;
--    >>> PLAK HIER JOUW EXPLAIN-PLAN van B (na index) <<<
--    Verwacht: 'Index Scan' / 'Bitmap Index Scan' op orders_customer_id_idx.

-- 6. Verklaring:
--    Na het aanmaken van de index op customer_id hoeft de database niet meer alle
--    rijen te lezen, maar vindt hij de bijpassende orders direct via de index.
--    De Seq Scan verandert in een Index Scan en de geschatte cost daalt sterk.


-- S7.3.A
--
-- Het blijkt dat customers regelmatig klagen over trage bezorging van hun bestelling.
-- Het idee is dat verkopers misschien te lang wachten met het invoeren van de bestelling in het systeem.
-- Daar willen we meer inzicht in krijgen.
-- We willen alle orders (order_id, order_date, salesperson_person_id (als verkoper),
--    het verschil tussen expected_delivery_date en order_date (als levertijd),  
--    en de bestelde hoeveelheid van een product zien (quantity uit order_lines).
-- Dit willen we alleen zien voor een bestelde hoeveelheid van een product > 250
--   (we zijn nl. als eerste geïnteresseerd in grote aantallen want daar lijkt het vaker mis te gaan)
-- En verder willen we ons focussen op verkopers wiens bestellingen er gemiddeld langer over doen.
-- De meeste bestellingen kunnen binnen een dag bezorgd worden, sommige binnen 2-3 dagen.
-- Het hele bestelproces is er op gericht dat de gemiddelde bestelling binnen 1.45 dagen kan worden bezorgd.
-- We willen in onze query dan ook alleen de verkopers zien wiens gemiddelde levertijd 
--  (expected_delivery_date - order_date) over al zijn/haar bestellingen groter is dan 1.45 dagen.
-- Maak om dit te bereiken een subquery in je WHERE clause.
-- Sorteer het resultaat van de hele geheel op levertijd (desc) en verkoper.
-- 1. Maak hieronder deze query (als je het goed doet zouden er 377 rijen uit moeten komen, en het kan best even duren...)

SELECT o.order_id,
       o.order_date,
       o.salesperson_person_id                      AS verkoper,
       (o.expected_delivery_date - o.order_date)     AS levertijd,
       ol.quantity
FROM orders o
JOIN order_lines ol ON o.order_id = ol.order_id
WHERE ol.quantity > 250
  AND o.salesperson_person_id IN (
        SELECT salesperson_person_id
        FROM orders
        GROUP BY salesperson_person_id
        HAVING AVG(expected_delivery_date - order_date) > 1.45
  )
ORDER BY levertijd DESC, verkoper;


-- S7.3.B
--
-- 1. Vraag het EXPLAIN plan op van je query (kopieer hier, onder de opdracht)
-- 2. Kijk of je met 1 of meer indexen de query zou kunnen versnellen
-- 3. Maak de index(en) aan en run nogmaals het EXPLAIN plan (kopieer weer onder de opdracht) 
-- 4. Wat voor verschillen zie je? Verklaar hieronder.

-- 1. EXPLAIN-plan van de query hierboven:
--    >>> PLAK HIER JOUW EXPLAIN-PLAN (vóór indexen) <<<
--    Verwacht: een Seq Scan op order_lines (filter quantity > 250) en op orders,
--    plus een dure join/aggregatie voor de subquery.

-- 2./3. Indexen die kunnen helpen:
--    - De join order_lines.order_id -> orders.order_id en het filter op quantity:
CREATE INDEX order_lines_order_id_idx ON order_lines (order_id);
CREATE INDEX order_lines_quantity_idx ON order_lines (quantity);
--    - De groepering/het filter in de subquery op salesperson_person_id:
CREATE INDEX orders_salesperson_idx ON orders (salesperson_person_id);

--    EXPLAIN-plan opnieuw:
--    >>> PLAK HIER JOUW EXPLAIN-PLAN (na indexen) <<<

-- 4. Verschillen:
--    Met de index op order_lines.quantity kan het filter quantity > 250 via de index
--    afgehandeld worden in plaats van een volledige Seq Scan. De index op order_id
--    versnelt de join tussen orders en order_lines. De index op salesperson_person_id
--    helpt de subquery bij het groeperen/filteren per verkoper. In het plan zie je
--    Seq Scans veranderen in Index(/Bitmap) Scans en dalen de geschatte kosten.
--    NB: of de optimizer een index daadwerkelijk gebruikt hangt af van de selectiviteit;
--    bij quantity > 250 (relatief weinig rijen) loont de index, bij een filter dat
--    bijna alle rijen teruggeeft kiest PostgreSQL soms toch bewust voor een Seq Scan.


-- S7.3.C
--
-- Zou je de query ook heel anders kunnen schrijven om hem te versnellen?

-- Ja. De subquery in de WHERE-clause kun je vervangen door de verkopers-aggregatie
-- als afgeleide tabel (of CTE) en die joinen. Zo wordt de gemiddelde levertijd per
-- verkoper één keer berekend in plaats van impliciet herhaald, en kan de optimizer
-- beter plannen:
--
-- WITH trage_verkopers AS (
--     SELECT salesperson_person_id
--     FROM orders
--     GROUP BY salesperson_person_id
--     HAVING AVG(expected_delivery_date - order_date) > 1.45
-- )
-- SELECT o.order_id, o.order_date, o.salesperson_person_id AS verkoper,
--        (o.expected_delivery_date - o.order_date) AS levertijd, ol.quantity
-- FROM orders o
-- JOIN trage_verkopers tv ON o.salesperson_person_id = tv.salesperson_person_id
-- JOIN order_lines ol      ON o.order_id = ol.order_id
-- WHERE ol.quantity > 250
-- ORDER BY levertijd DESC, verkoper;


