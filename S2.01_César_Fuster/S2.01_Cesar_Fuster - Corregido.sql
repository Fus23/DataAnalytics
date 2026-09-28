-- Nivell 1

-- Exercici 1
-- A partir dels documents adjunts (estructura_dades i dades_introduir), importa les dues taules.
-- Mostra les característiques principals de l'esquema creat i explica les diferents taules i variables que existeixen.
-- Assegura't d'incloure un diagrama que il·lustri la relació entre les diferents taules i variables.

-- Se crean la base de datos y las tablas mediante el sql estructura_dades:

-- Creamos la base de datos
DROP DATABASE IF EXISTS transactions;
CREATE DATABASE IF NOT EXISTS transactions;
USE transactions;

-- Creamos la tabla company
CREATE TABLE IF NOT EXISTS company (
    id VARCHAR(15) PRIMARY KEY,
    company_name VARCHAR(255),
    phone VARCHAR(15),
    email VARCHAR(100),
    country VARCHAR(100),
    website VARCHAR(255)
);

-- Creamos la tabla transaction
CREATE TABLE IF NOT EXISTS transaction (
    id VARCHAR(255) PRIMARY KEY,
    credit_card_id VARCHAR(15) REFERENCES credit_card(id),
    company_id VARCHAR(20), 
    user_id INT REFERENCES user(id),
    lat FLOAT,
    longitude FLOAT,
    timestamp TIMESTAMP,
    amount DECIMAL(10, 2),
    declined BOOLEAN,
    FOREIGN KEY (company_id) REFERENCES company(id) 
);

-- Se insertan los datos mediante el sql dades_introduir



-- Exercici 2
-- Utilitzant JOIN realitzaràs les següents consultes:
-- Llistat dels països que estan generant vendes.
SELECT c.country
FROM transactions.company AS c
JOIN transactions.transaction AS t
ON c.id = t.company_id
WHERE t.declined = 0
GROUP BY c.country;

-- Des de quants països es generen les vendes.
SELECT COUNT(DISTINCT c.country) AS SellerCountries
FROM transactions.company AS c
JOIN transactions.transaction AS t
ON c.id = t.company_id
WHERE t.declined = 0;

-- Identifica la companyia amb la mitjana més gran de vendes.
SELECT c.id, c.company_name, ROUND(AVG(t.amount),2) AS avg_amount
FROM transactions.company AS c
JOIN transactions.transaction AS t
ON c.id = t.company_id
WHERE t.declined = 0
GROUP BY c.id, c.company_name
ORDER BY avg_amount DESC
LIMIT 1;



-- Exercici 3
-- Utilitzant només subconsultes (sense utilitzar JOIN):
-- Mostra totes les transaccions realitzades per empreses d'Alemanya.
SELECT *
FROM transactions.transaction AS t
WHERE t.declined = 0
AND EXISTS (
	SELECT 1
    FROM transactions.company AS c
	WHERE c.id = t.company_id
    AND country = 'Germany'
	);

-- Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.
SELECT DISTINCT id, company_name
FROM transactions.company AS c
WHERE EXISTS (
	SELECT 1
    FROM transactions.transaction AS t
    WHERE declined = 0
    AND c.id = t.company_id
    AND amount > (
		SELECT AVG(amount)
        FROM transactions.transaction
        WHERE declined = 0
        )
    );

-- Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.
SELECT * FROM transactions.company AS c
WHERE NOT EXISTS (
	SELECT 1
    FROM transactions.transaction AS t
    WHERE c.id = t.company_id
    );
-- No existe ninguna empresa sin transacciones registradas por lo que al mostar el listado éste sale vacío
"""Se ha corregido el uso de DELETE, y sustituído por SELECT."""


-- Exercici 4
-- La teva tasca és dissenyar i crear una taula anomenada "credit_card" que emmagatzemi
-- detalls crucials sobre les targetes de crèdit. La nova taula ha de ser capaç d'identificar
-- de manera única cada targeta i establir una relació adequada amb les altres dues taules ("transaction" i "company").
-- Després de crear la taula serà necessari que ingressis la informació del document denominat "dades_introduir_credit".
-- Recorda mostrar el diagrama i realitzar una breu descripció d'aquest.

-- Creación de la tabla credit_card
CREATE TABLE IF NOT EXISTS credit_card (
	id VARCHAR(50) PRIMARY KEY,
    iban VARCHAR(50),
    pan VARCHAR(50),
    pin VARCHAR(4),
    cvv VARCHAR(3),
    expiring_date VARCHAR(8)
	);
-- Inserción de datos de credit_card mediante el archivo N1-Ex.4__ datos_introducir_credit

-- Alteración de la tabla para definir el constraint de la variable id de la tabla credit_card con la variable credit_card_id de la tabla transaction
ALTER TABLE transactions.transaction
ADD CONSTRAINT credit_card_id_fk
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id);



-- Exercici 5
-- El departament de Recursos Humans ha identificat un error en el número de compte associat a la targeta de crèdit
-- amb ID CcU-2938. La informació que ha de mostrar-se per a aquest registre és: TR323456312213576817699999.
-- Recorda mostrar que el canvi es va realitzar.
UPDATE transactions.credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

SELECT * FROM transactions.credit_card
WHERE id = 'CcU-2938';
-- Para mostrar que el cambio se ha realizado



-- Exercici 6
-- En la taula "transaction" ingressa una nova transacció amb la següent informació:
-- Id/108B1D1D-5B23-A76C-55EF-C568E49A99DD, credit_card_id/CcU-9999, company_id/b-9999,
-- user_id/9999, lat/829.999, longitude/-117.999, amount/111.11, declined/0

-- Dado que no existe previamente ni una empresa con el id b-9999, ni una tarjeta de crédito con id CcU-9999,
-- se deben crear ambas para poder insertar esta nueva transacción posteriormente:

-- Crea la empresa con id b-9999, dejando el resto de variables como NULL
INSERT INTO transactions.company (id) VALUES ('b-9999');

-- Crea la tarjeta de crédito con id CcU-9999, dejando el resto de variables como NULL
INSERT INTO transactions.credit_card (id) VALUES ('CcU-9999');

-- Crea la transacción ahora que ya existen la empresa y tarjeta de crédito correspondiente
INSERT INTO transactions.transaction (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined)
VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', 9999, 829.999, -117.999, 111.11, 0);



-- Exercici 7
-- Des de recursos humans et sol·liciten eliminar la columna "pan" de la taula credit_card.
-- Recorda mostrar el canvi realitzat.
ALTER TABLE transactions.credit_card
DROP COLUMN pan;

SELECT * FROM transactions.credit_card;



-- Exercici 8
-- Descarrega els arxius CSV que trobaràs a l'apartat de recursos:
-- american_users.csv, european_users.csv, companies.csv, credit_cards.csv, transactions.csv
-- Estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui,
-- almenys 4 taules de les quals puguis realitzar les següents consultes:
-- La taula de products.csv l'utilitzarem més endavant.

-- Primero se crea la base de datos y las tablas con las variables y sus tipos establecidas
-- Seguidamente se carga el .csv desde la carpeta Uploads y se indica el formato para que los valores se ajusten al lenguaje SQL
-- (Se repite el proceso para todas las tablas y archivos .csv)

DROP DATABASE IF EXISTS ex8_transactions;
CREATE DATABASE IF NOT EXISTS ex8_transactions;
USE ex8_transactions;

-- Tabla credit_cards:
CREATE TABLE IF NOT EXISTS credit_cards (
    id VARCHAR(50) PRIMARY KEY,
    user_id INT,
    iban VARCHAR(50),
    pan VARCHAR(50),
    pin VARCHAR(4),
    cvv VARCHAR(3),
    track1 VARCHAR(300),
    track2 VARCHAR(300),
    expiring_date VARCHAR(50),
    card_type VARCHAR(50),
    card_renewal_flag INT
);

LOAD DATA
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Tabla companies:
CREATE TABLE IF NOT EXISTS companies (
    company_id VARCHAR(50) PRIMARY KEY,
    company_name VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(200),
    country VARCHAR(50),
    website VARCHAR(300),
    merchant_category VARCHAR(50),
    merchant_price_position VARCHAR(50)
);

LOAD DATA
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Tabla transactions:
CREATE TABLE IF NOT EXISTS transactions (
    id VARCHAR(50) PRIMARY KEY,
    card_id VARCHAR(50),
    business_id VARCHAR(50),
    timestamp DATETIME,
    amount DECIMAL(10,2),
    declined INT,
    product_ids VARCHAR(255),
    user_id INT,
    lat FLOAT,
    longitude FLOAT,
    discount_amount DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    shipping_amount DECIMAL(10,2),
    channel VARCHAR(50),
    campaign_id VARCHAR(100),
    device_type VARCHAR(50),
    is_international INT,
    decline_reason VARCHAR(100),
    distance_km DECIMAL(10,2)
);

LOAD DATA
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Para poder crear el constraint de transactions tanto a american_users como a european_users, al usar el mismo Foreign Key,
-- se crea una tabla users y se cargan los datos de ambos .csv european_users y american_users en ella
CREATE TABLE IF NOT EXISTS users (
	id INT PRIMARY KEY,
    name VARCHAR(50),
    surname VARCHAR(50),
    phone VARCHAR(50),
    email VARCHAR(200),
    birth_date VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(100),
    postal_code VARCHAR(50),
    address VARCHAR(200),
    signup_date DATE,
    user_segment VARCHAR(50),
    income_band VARCHAR(50)
    );
    
LOAD DATA
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__european_users.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

LOAD DATA
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__american_users.csv'
INTO TABLE users 
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Una vez creadas todas las tablas se establecen los constraints
ALTER TABLE ex8_transactions.transactions
ADD CONSTRAINT transaction_credit_card_fk
FOREIGN KEY (card_id)
REFERENCES credit_cards(id);

ALTER TABLE ex8_transactions.transactions
ADD CONSTRAINT transaction_company_fk
FOREIGN KEY (business_id)
REFERENCES companies(company_id);

ALTER TABLE ex8_transactions.transactions
ADD CONSTRAINT transaction_user_fk
FOREIGN KEY (user_id)
REFERENCES users(id);



-- Exercici 9
-- Realitza una subconsulta que mostri tots els usuaris amb més de 80 transaccions utilitzant almenys 2 taules.
SELECT * FROM ex8_transactions.users AS u
WHERE EXISTS (
	SELECT 1
    FROM ex8_transactions.transactions AS t
    WHERE u.id = t.user_id
    GROUP BY t.user_id
    HAVING COUNT(*) > 80
    );



-- Exercici 10
-- Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules.
SELECT c.company_name, cc.iban, ROUND(AVG(t.amount),2) AS avg_amount
FROM credit_cards AS cc
JOIN transactions AS t
ON cc.id = t.card_id
JOIN companies AS c
ON c.company_id = t.business_id
WHERE c.company_name = 'Donec Ltd'
GROUP BY cc.iban, c.company_name;



-- Nivell 2

-- Exercici 1
-- Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes.
-- Mostra la data de cada transacció juntament amb el total de les vendes.
SELECT DATE(timestamp) AS transaction_date, SUM(amount) AS total_amount
FROM ex8_transactions.transactions
WHERE declined = 0
GROUP BY transaction_date
ORDER BY total_amount DESC
LIMIT 5;



-- Exercici 2
-- Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van realitzar
-- transaccions amb un valor comprès entre 350 i 400 euros i en alguna d'aquestes dates:
-- 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 2024.
-- Ordena els resultats de major a menor quantitat.
SELECT c.company_name, c.phone, c.country, DATE(t.timestamp) AS transaction_date, t.amount
FROM ex8_transactions.companies AS c
JOIN ex8_transactions.transactions AS t
ON c.company_id = t.business_id
WHERE t.declined = 0
AND t.amount BETWEEN 350 AND 400
AND DATE(t.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
ORDER BY t.amount DESC;



-- Exercici 3
-- Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi,
-- per la qual cosa et demanen la informació sobre la quantitat de transaccions que realitzen les empreses,
-- però el departament de recursos humans és exigent i vol un llistat de les empreses on especifiquis si tenen
-- igual o més de 400 transaccions o menys.
SELECT c.company_name, COUNT(t.id) AS num_transactions,
CASE
	WHEN COUNT(t.id) >= 400 THEN '400 or more'
    ELSE 'Less than 400'
END AS classification
FROM ex8_transactions.transactions AS t
JOIN ex8_transactions.companies AS c
ON t.business_id = c.company_id
WHERE t.declined = 0
GROUP BY c.company_name;



-- Exercici 4
-- Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.
DELETE FROM ex8_transactions.transactions
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';



-- Exercici 5
-- La secció de màrqueting desitja tenir accés a informació específica per a realitzar anàlisi i estratègies efectives.
-- S'ha sol·licitat crear una vista que proporcioni detalls clau sobre les companyies i les seves transaccions.
-- Serà necessària que creïs una vista anomenada VistaMarketing que contingui la següent informació: Nom de la companyia.
-- Telèfon de contacte. País de residència. Mitjana de compra realitzat per cada companyia.
-- Presenta la vista creada, ordenant les dades de major a menor mitjana de compra.
CREATE VIEW VistaMarketing AS
SELECT c.company_name, c.phone, c.country, ROUND(AVG(t.amount),2) AS avg_amount
FROM ex8_transactions.companies AS c
JOIN ex8_transactions.transactions AS t
ON c.company_id = t.business_id
WHERE t.declined = 0
GROUP BY c.company_name, c.phone, c.country;

SELECT * FROM VistaMarketing
ORDER BY avg_amount DESC;



-- Nivell 3

-- Exercici 1
-- Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les tres últimes transaccions
-- han estat declinades aleshores és inactiu, si almenys una no és rebutjada aleshores és actiu. Partint d’aquesta taula respon:
-- Quantes targetes estan actives?
CREATE TABLE IF NOT EXISTS ex8_transactions.card_status (
	card_id VARCHAR(50) PRIMARY KEY,
    card_status VARCHAR(50)
    );
-- Creación de la nueva tabla

INSERT INTO ex8_transactions.card_status (card_id, card_status)
SELECT card_id, CASE
		WHEN SUM(declined) = 3 THEN 'Not Active'
        ELSE 'Active'
	END AS card_status -- Se asigna el status activo o inactivo según el resultado de la subquery
FROM (SELECT * FROM ex8_transactions.transactions AS t1
	  WHERE (
			SELECT COUNT(*)
			FROM ex8_transactions.transactions AS t2
            WHERE t2.card_id = t1.card_id
            AND t2.timestamp > t1.timestamp
            ) < 3 -- Esta subquery limita el SELECT a las 3 últimas transacciones
	  ) AS last_transactions
      GROUP BY card_id;
-- Inserción de los datos en la tabla creada

SELECT COUNT(*) AS num_active_cards
FROM ex8_transactions.card_status
WHERE card_status = 'Active';
-- Esto último da respuesta a la pregunta "Quantes targetes estan actives?"
-- La respuesta es 5000



-- Exercici 2
-- Crea una taula amb la qual puguem unir les dades de l'arxiu de products.csv amb la base de dades creada
-- (ja que fins ara no podíem fer-ho), tenint en compte que des de transaction tens product_ids.
-- Genera la següent consulta:
-- Necessitem conèixer el nombre de vegades que s'ha venut cada producte.
CREATE TABLE IF NOT EXISTS ex8_transactions.products
	(
	id INT PRIMARY KEY,
    product_name VARCHAR(100),
    price DECIMAL(10,2),
    colour VARCHAR(50),
    weight DECIMAL(10,2),
    warehouse_id VARCHAR(10),
    category VARCHAR(50),
    brand VARCHAR(50),
    cost DECIMAL(10,2),
    launch_date DATE
    );
-- Creación de la tabla products.

LOAD DATA
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(
    id,
    product_name,
    @price,
    colour,
    weight,
    warehouse_id,
    category,
    brand,
    @cost,
    launch_date
)
SET price = REPLACE (@price, '$', ''), cost = REPLACE (@cost, '$', '');
-- Se carga el .csv, y se crean variables temporales con @ para eliminar el símbolo '$'
-- de las variables price y cost, y poder importar el archivo sin problemas.

CREATE TABLE IF NOT EXISTS ex8_transactions.transactions_to_products
	(
    id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id VARCHAR(50),
    product_id INT
    );

ALTER TABLE ex8_transactions.transactions_to_products
ADD CONSTRAINT transaction_fk
FOREIGN KEY (transaction_id)
REFERENCES ex8_transactions.transactions(id);

ALTER TABLE ex8_transactions.transactions_to_products
ADD CONSTRAINT product_fk
FOREIGN KEY (product_id)
REFERENCES ex8_transactions.products(id);
-- Creación de una tabla que permita relacionar la tabla products con la variable product_ids de la tabla transactions

INSERT INTO ex8_transactions.transactions_to_products (transaction_id, product_id)
WITH RECURSIVE temp_products AS ( -- Recursive permite recorrer cada product_ids hasta que quede vacío
	SELECT id AS temp_transaction_id,
		SUBSTRING_INDEX(product_ids, ',', 1) AS temp_product_id,
        -- Separa los valores de product_ids y toma el primero
        SUBSTRING(product_ids, LOCATE(',', product_ids) + 1) AS remainder
        -- Guarda los valores restantes en la variable temporal remainder
	FROM ex8_transactions.transactions
    UNION ALL -- Permite repetir la operación si hay más valores en remainder
    SELECT temp_transaction_id,
		SUBSTRING_INDEX(remainder, ',', 1),
        -- Vuelve a separar los valores en remainder y toma el primero
        IF (LOCATE(',', remainder) > 0,
			-- Check para ver si quedan comas (más valores dentro de product_ids)
			SUBSTRING(remainder, LOCATE(',', remainder) + 1),
            -- En caso de que sea verdadero (que queden más valores) los separa y toma el primero
            ''
            -- En caso de que sea falso (que no queden más valores) se guarda un texto vacío en remainder
			)
	FROM temp_products
    -- Indica que si se repite, se hará usando la tabla temporal que se acaba de crear con los valores separados
    WHERE remainder > ''
    -- Indica cuando debe dejar de repetirse: cuando solo quede un texto vacío en remainder
)
SELECT temp_transaction_id, TRIM(temp_product_id)
-- Selecciona las variables de la tabla temporal resultante, y con TRIM se eliminan los espacios en blanco
FROM temp_products;
-- Se indica que los datos que se inserten sean de la tabla temporal resultante