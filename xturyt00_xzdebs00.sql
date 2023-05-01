BEGIN
 -- smazat již vytvořené tabulky
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE guests CASCADE CONSTRAINTS';
        EXECUTE IMMEDIATE 'DROP TABLE carts CASCADE CONSTRAINTS';
        EXECUTE IMMEDIATE 'DROP TABLE items CASCADE CONSTRAINTS';
        EXECUTE IMMEDIATE 'DROP TABLE products CASCADE CONSTRAINTS';
        EXECUTE IMMEDIATE 'DROP TABLE orders CASCADE CONSTRAINTS';
        EXECUTE IMMEDIATE 'DROP TABLE payments CASCADE CONSTRAINTS';
        EXECUTE IMMEDIATE 'DROP TABLE admins CASCADE CONSTRAINTS';
        EXECUTE IMMEDIATE 'DROP TABLE employees CASCADE CONSTRAINTS';
        EXECUTE IMMEDIATE 'DROP TABLE addresses CASCADE CONSTRAINTS';
        EXECUTE IMMEDIATE 'DROP TABLE customers CASCADE CONSTRAINTS';
        EXECUTE IMMEDIATE 'DROP TABLE feedbacks CASCADE CONSTRAINTS';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -942 THEN
                RAISE;
            END IF;
    END;

-- smazat vytvořené procedury
    BEGIN
        EXECUTE IMMEDIATE 'DROP PROCEDURE AVERAGE_PRODUCT_RATING';
        EXECUTE IMMEDIATE 'DROP PROCEDURE SHIP_ORDER';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

-- smazat vytvořený index
    BEGIN
        EXECUTE IMMEDIATE 'DROP INDEX PAYMENT_INDEX';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -1418 THEN
                RAISE;
            END IF;
    END;

-- smazat vytvořený materializovaný pohled
    BEGIN
        EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW PRODUCT_CATEGORY_COUNT';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -12003 THEN
                RAISE;
            END IF;
    END;

 -- smazat sekvence
    BEGIN
        EXECUTE IMMEDIATE 'DROP SEQUENCE guests_sequence';
        EXECUTE IMMEDIATE 'DROP SEQUENCE carts_sequence';
        EXECUTE IMMEDIATE 'DROP SEQUENCE address_sequence';
        EXECUTE IMMEDIATE 'DROP SEQUENCE items_sequence';
        EXECUTE IMMEDIATE 'DROP SEQUENCE products_sequence';
        EXECUTE IMMEDIATE 'DROP SEQUENCE feedbacks_sequence';
        EXECUTE IMMEDIATE 'DROP SEQUENCE orders_sequence';
        EXECUTE IMMEDIATE 'DROP SEQUENCE payments_sequence';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -2289 THEN
                RAISE;
            END IF;
    END;
END;
/

-- Zapnout výstup konzoly
SET SERVEROUTPUT ON;

-- Nastavuje se sekvence pro primarní klíče
CREATE SEQUENCE GUESTS_SEQUENCE START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE SEQUENCE CARTS_SEQUENCE START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE SEQUENCE ADDRESS_SEQUENCE START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE SEQUENCE ITEMS_SEQUENCE START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE SEQUENCE PRODUCTS_SEQUENCE START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE SEQUENCE FEEDBACKS_SEQUENCE START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE SEQUENCE ORDERS_SEQUENCE START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE SEQUENCE PAYMENTS_SEQUENCE START WITH 1 INCREMENT BY 1 NOCACHE;

-- DEFINICE ENTIT

---- GUEST
CREATE TABLE GUESTS (
    GUEST_ID INT DEFAULT GUESTS_SEQUENCE.NEXTVAL,
    CART_ID INT UNIQUE NOT NULL,
    LOGGED_AS VARCHAR(255) DEFAULT NULL,
    CONSTRAINT GUEST_PK PRIMARY KEY (GUEST_ID)
);

---- CUSTOMER
CREATE TABLE CUSTOMERS (
    CUSTOMER_LOGIN VARCHAR(255) NOT NULL CONSTRAINT CUSTOMER_LOGIN_CHECK CHECK (REGEXP_LIKE(CUSTOMER_LOGIN, '^x[a-z0-9]*$')),
    CUSTOMER_PASSWORD VARCHAR(255) NOT NULL CHECK (LENGTH(CUSTOMER_PASSWORD) > 8),
    FIRST_NAME VARCHAR(255) NOT NULL,
    LAST_NAME VARCHAR(255) NOT NULL,
    EMAIL VARCHAR(255) NOT NULL CONSTRAINT CUSTOMER_EMAIL_CHECK CHECK (REGEXP_LIKE(EMAIL, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
    PHONENUMBER VARCHAR(255) NOT NULL,
    CART_ID INT UNIQUE NOT NULL,
    CREATED_BY INT NOT NULL,
    ADDRESS_ID INT,
    CONSTRAINT CUSTOMER_PK PRIMARY KEY (CUSTOMER_LOGIN)
);

---- ADDRESS
CREATE TABLE ADDRESSES (
    ADDRESS_ID INT DEFAULT ADDRESS_SEQUENCE.NEXTVAL,
    COUNTRY VARCHAR(255) NOT NULL,
    CITY_NAME VARCHAR(255) NOT NULL,
    STREET VARCHAR(255) NOT NULL,
    POSTAL_CODE VARCHAR(255) NOT NULL,
    CUSTOMER_LOGIN VARCHAR(255) UNIQUE NOT NULL,
    CONSTRAINT ADDRESS_PK PRIMARY KEY (ADDRESS_ID)
);

---- CART 
CREATE TABLE CARTS (
    CART_ID INT DEFAULT CARTS_SEQUENCE.NEXTVAL,
    TOTAL_PRICE NUMERIC(10, 2) NOT NULL CHECK (TOTAL_PRICE >= 0),
    CONSTRAINT CART_PK PRIMARY KEY (CART_ID)
);

---- ITEM
CREATE TABLE ITEMS (
    ITEM_ID INT DEFAULT ITEMS_SEQUENCE.NEXTVAL,
    QUANTITY_PRICE NUMERIC(10, 2) NOT NULL CHECK (QUANTITY_PRICE >= 0),
    QUANTITY INT NOT NULL CHECK (QUANTITY >= 0),
    CART_ID INT,
    ORDER_ID INT,
    PRODUCT_ID INT NOT NULL,
    CONSTRAINT ITEM_PK PRIMARY KEY(ITEM_ID)
);

---- PRODUCT
CREATE TABLE PRODUCTS (
    PRODUCT_ID INT DEFAULT PRODUCTS_SEQUENCE.NEXTVAL,
    PRODUCT_NAME VARCHAR(255) NOT NULL,
    PRODUCT_DESC VARCHAR2(1024) NOT NULL,
    PRODUCT_IMG VARCHAR(255) NOT NULL,
    CATEGORY VARCHAR(255) NOT NULL,
    UNIT_PRICE NUMERIC(10, 2) NOT NULL CHECK (UNIT_PRICE >= 0),
    STOCK INT DEFAULT 0 NOT NULL CHECK (STOCK >= 0),
    TOTAL_SOLD INT DEFAULT 0 NOT NULL CHECK (TOTAL_SOLD >= 0),
    IS_INSTOCK NUMBER DEFAULT 0 NOT NULL CHECK (IS_INSTOCK IN (0, 1)),
    TOTAL_RATING INT DEFAULT 0 CHECK (TOTAL_RATING >= 0 AND TOTAL_RATING <= 5),
    CONSTRAINT PRODUCT_PK PRIMARY KEY (PRODUCT_ID)
);

---- FEEDBACK
CREATE TABLE FEEDBACKS (
    FEEDBACK_ID INT DEFAULT FEEDBACKS_SEQUENCE.NEXTVAL,
    CONTENT VARCHAR2(2048) NOT NULL CHECK (LENGTH(CONTENT) > 12),
    RATING INT DEFAULT 0 CHECK (RATING >= 0 AND RATING <= 5),
    PRODUCT_ID INT NOT NULL,
    CUSTOMER_LOGIN VARCHAR(255) NOT NULL,
    CONSTRAINT FEEDBACK_PK PRIMARY KEY (FEEDBACK_ID)
);

---- ORDER
CREATE TABLE ORDERS (
    ORDER_ID INT DEFAULT ORDERS_SEQUENCE.NEXTVAL,
    TOTAL_PRICE NUMERIC(10, 2) NOT NULL,
    STATUS VARCHAR (255) NOT NULL CHECK (STATUS IN ('pending', 'processing', 'shipped', 'cancelled')),
    CUSTOMER_LOGIN VARCHAR(255) NOT NULL,
    ADDRESS_ID INT NOT NULL,
    PAYMENT_ID INT,
    PROCESSED_BY VARCHAR(255),
    SHIPPED_BY VARCHAR(255),
    CONSTRAINT ORDER_PK PRIMARY KEY (ORDER_ID)
);

---- PAYMENT
CREATE TABLE PAYMENTS (
    PAYMENT_ID INT DEFAULT PAYMENTS_SEQUENCE.NEXTVAL,
    ACCOUNT_NUMBER VARCHAR(255) NOT NULL,
    EXPIRES_AT DATE DEFAULT (SYSDATE + 1),
    IS_PAID NUMBER DEFAULT 0 CHECK (IS_PAID IN (0, 1)),
    TOTAL_PRICE NUMERIC(10, 2) NOT NULL,
    ASSIGNED_TO VARCHAR(255) NOT NULL,
    ORDER_ID INT NOT NULL,
    CONSTRAINT PAYMENT_PK PRIMARY KEY (PAYMENT_ID)
);

---- EMPLOYEE
CREATE TABLE EMPLOYEES (
    EMPLOYEE_LOGIN VARCHAR(255) NOT NULL CONSTRAINT EMPLOYEE_LOGIN_CHECK CHECK (REGEXP_LIKE(EMPLOYEE_LOGIN, '^x[a-z0-9]*$')),
    PASSWORD VARCHAR(255) NOT NULL CHECK (LENGTH(PASSWORD) > 8),
    FIRST_NAME VARCHAR(255) NOT NULL,
    LAST_NAME VARCHAR(255) NOT NULL,
    EMAIL VARCHAR(255) NOT NULL CONSTRAINT EMPLOYEE_EMAIL_CHECK CHECK (REGEXP_LIKE(EMAIL, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
    CONSTRAINT EMPLOYEE_PK PRIMARY KEY (EMPLOYEE_LOGIN)
);

---- ADMIN
CREATE TABLE ADMINS (
    ADMIN_LOGIN VARCHAR(255) NOT NULL,
    ADMIN_POSITION VARCHAR(255) NOT NULL CHECK (ADMIN_POSITION IN ('manager', 'owner')),
    CONSTRAINT ADMIN_PK PRIMARY KEY (ADMIN_LOGIN)
);

-- GENERALIZACE
-- Generalizace v SQL je částo implementovana pomocí cizích klíče (FOREIGN KEY).
-- V tomto systému použili jsme generalizace pro entity Admin a Employee, kde parent je Employee a
-- Admin je child.
-- Pokud chceme přidat do systému jednoducheho manažera, je třeba vytvořít
-- na začátku Employee, vyplnit jeho hodnoty, pak vytvořit objekt Admin
-- přiradit mu do "admin_position" hodnotu "manager" a jako primární klíč přiradit klíč
-- nového zaměstnánce, kterého jsme vytvořili před tim. Příklad je dal v sekci INSERT
ALTER TABLE ADMINS ADD CONSTRAINT ADMIN_FK FOREIGN KEY (ADMIN_LOGIN) REFERENCES EMPLOYEES(EMPLOYEE_LOGIN) ON DELETE CASCADE;

-- NASTAVENÍ VZTAHŮ

---- CUSTOMERS
ALTER TABLE CUSTOMERS ADD CONSTRAINT CREATED_BY_GUEST_FK FOREIGN KEY (CREATED_BY) REFERENCES GUESTS(GUEST_ID) ON DELETE SET NULL;

--created by
ALTER TABLE CUSTOMERS ADD CONSTRAINT CUSTOMER_CARD_FK FOREIGN KEY (CART_ID) REFERENCES CARTS ON DELETE CASCADE;

--has
ALTER TABLE CUSTOMERS ADD CONSTRAINT CUSTOMER_ADDRESS_FK FOREIGN KEY (ADDRESS_ID) REFERENCES ADDRESSES ON DELETE SET NULL;

--located at

---- ADDRESSES
ALTER TABLE ADDRESSES ADD CONSTRAINT ADDRESS_CUSTOMER_FK FOREIGN KEY (CUSTOMER_LOGIN) REFERENCES CUSTOMERS ON DELETE CASCADE;

---- GUESTS
ALTER TABLE GUESTS ADD CONSTRAINT GUEST_CARD_FK FOREIGN KEY (CART_ID) REFERENCES CARTS ON DELETE CASCADE;

--has
ALTER TABLE GUESTS ADD CONSTRAINT GUEST_LOGGED_AS_FK FOREIGN KEY (LOGGED_AS) REFERENCES CUSTOMERS(CUSTOMER_LOGIN) ON DELETE SET NULL;

--login

---- ITEMS
ALTER TABLE ITEMS ADD CONSTRAINT CART_ITEM_FK FOREIGN KEY (CART_ID) REFERENCES CARTS ON DELETE SET NULL;

--belongs to
ALTER TABLE ITEMS ADD CONSTRAINT ORDER_ITEM_FK FOREIGN KEY (ORDER_ID) REFERENCES ORDERS ON DELETE SET NULL;

--belongs to
ALTER TABLE ITEMS ADD CONSTRAINT ITEM_PRODUCT_FK FOREIGN KEY (PRODUCT_ID) REFERENCES PRODUCTS ON DELETE CASCADE;

--belongs to

---- FEEDBACKS
ALTER TABLE FEEDBACKS ADD CONSTRAINT PRODUCT_FEEDBACK_FK FOREIGN KEY (PRODUCT_ID) REFERENCES PRODUCTS ON DELETE CASCADE;

-- <identif>
ALTER TABLE FEEDBACKS ADD CONSTRAINT CUSTOMER_FEEDBACK_FK FOREIGN KEY (CUSTOMER_LOGIN) REFERENCES CUSTOMERS ON DELETE SET NULL;

-- leaves

---- ORDERS
ALTER TABLE ORDERS ADD CONSTRAINT CUSTOMER_ORDER_FK FOREIGN KEY (CUSTOMER_LOGIN)REFERENCES CUSTOMERS ON DELETE SET NULL;

-- makes
ALTER TABLE ORDERS ADD CONSTRAINT ORDER_PAYMENT_FK FOREIGN KEY (PAYMENT_ID) REFERENCES PAYMENTS ON DELETE SET NULL;

-- <identif>
ALTER TABLE ORDERS ADD CONSTRAINT ORDER_PROCESSED_BY_FK FOREIGN KEY (PROCESSED_BY)REFERENCES EMPLOYEES(EMPLOYEE_LOGIN) ON DELETE SET NULL;

-- processes
ALTER TABLE ORDERS ADD CONSTRAINT ORDER_SHIPPED_BY_FK FOREIGN KEY (SHIPPED_BY) REFERENCES EMPLOYEES(EMPLOYEE_LOGIN) ON DELETE SET NULL;

-- ships out
ALTER TABLE ORDERS ADD CONSTRAINT ORDER_ADDRESS_FK FOREIGN KEY (ADDRESS_ID) REFERENCES ADDRESSES ON DELETE SET NULL;

---- PAYMENTS
ALTER TABLE PAYMENTS ADD CONSTRAINT CUSTOMER_PAYMENT_FK FOREIGN KEY (ASSIGNED_TO) REFERENCES CUSTOMERS(CUSTOMER_LOGIN) ON DELETE SET NULL;

ALTER TABLE PAYMENTS ADD CONSTRAINT PAYMENT_ORDER_FK FOREIGN KEY (ORDER_ID) REFERENCES ORDERS ON DELETE CASCADE;

-- TRIGGERS --

---- 1. Jakmile uživatel vytvoří obědnávku, všechny položky z jeho košíku (items) ztratí spojení
---- s košíkem a získají spojení s objednávkou. Pak se vytvoří automaticky platba která se napojí na
---- uživatele který objednávku vytvořil.
CREATE OR REPLACE TRIGGER UPDATE_ITEMS_ON_ORDER_CREATE AFTER
    INSERT ON ORDERS FOR EACH ROW
DECLARE
PAYMENT_ID PAYMENTS.PAYMENT_ID%TYPE;
BEGIN
UPDATE ITEMS
SET
    ORDER_ID = :NEW.ORDER_ID,
    CART_ID = NULL
WHERE
    ITEMS.CART_ID = (SELECT CART_ID FROM CUSTOMERS WHERE CUSTOMERS.CUSTOMER_LOGIN = :NEW.CUSTOMER_LOGIN);

    ---- Po vytvoření objednávky vytvoří se platba kterou první uživatel musí uhradit
INSERT INTO PAYMENTS (
    ASSIGNED_TO,
    ACCOUNT_NUMBER,
    IS_PAID,
    ORDER_ID,
    TOTAL_PRICE
) VALUES (
    :NEW.CUSTOMER_LOGIN,
    '1234 3456 3456 3454',
    0,
    :NEW.ORDER_ID,
    :NEW.TOTAL_PRICE
);

END;

/

---- 2. (Omezení) Jestli uživatel zaplatí za objednávku po termínu platnosti objednávky,
---- nastané chyba a platba se neprovede
CREATE OR REPLACE TRIGGER PAYMENT_EXPIRED_CHECK BEFORE
    UPDATE ON PAYMENTS FOR EACH ROW
BEGIN
    IF (:NEW.EXPIRES_AT < CURRENT_TIMESTAMP) THEN
        RAISE_APPLICATION_ERROR(-20000, 'Payment token has expired');
    END IF;
END;

/

---- 3. Pokud uživatel nezadal adresu, nelze vytvořit objednávku a dojde k chybě
CREATE OR REPLACE TRIGGER ORDER_ADRESS_CHECK BEFORE
    INSERT ON ORDERS FOR EACH ROW
BEGIN
    IF (:NEW.ADDRESS_ID is null) THEN
        RAISE_APPLICATION_ERROR(-20000, 'Address not set');
    END IF;
END;

/

-- PROCEDURES --

---- 1. Procedura vypočítá průměrné hodnocení produktu na základě jeho recenzí.
CREATE OR REPLACE PROCEDURE AVERAGE_PRODUCT_RATING (
    P_ID IN PRODUCTS.PRODUCT_ID%TYPE
) AS
    PRODUCTS_COUNT NUMBER;
    SUM_RATING PRODUCTS.TOTAL_RATING%TYPE;
    AVG_RATING PRODUCTS.TOTAL_RATING%TYPE;
    FEEDBACKS_DONT_EXIST EXCEPTION;

    CURSOR CURSOR_FEEDBACKS IS
        SELECT RATING
        FROM FEEDBACKS
        WHERE FEEDBACKS.PRODUCT_ID = P_ID;
BEGIN
    SUM_RATING := 0;
    PRODUCTS_COUNT := 0;

    FOR FEEDBACK IN CURSOR_FEEDBACKS LOOP
        SUM_RATING := SUM_RATING + FEEDBACK.RATING;
        PRODUCTS_COUNT := PRODUCTS_COUNT + 1;
    END LOOP;

    IF PRODUCTS_COUNT = 0 THEN
        RAISE FEEDBACKS_DONT_EXIST;
    END IF;

    AVG_RATING := SUM_RATING / PRODUCTS_COUNT;

    DBMS_OUTPUT.PUT_LINE('AVG rating: ' || AVG_RATING || 'of product ' || P_ID);

    EXCEPTION
        WHEN FEEDBACKS_DONT_EXIST THEN
            DBMS_OUTPUT.PUT_LINE('No feedback was found for product' || P_ID);
END;

/

---- 2. Procedura která zpracovuje objednávku po platbě uživatelem, validuje platební udaje a
---- mění status objednávky na "shipped". Automaticky nastavuje zaměstnance který použil proceduru.
CREATE OR REPLACE PROCEDURE SHIP_ORDER (
    O_ID IN ORDERS.ORDER_ID%TYPE,
    E_LOGIN IN EMPLOYEES.EMPLOYEE_LOGIN%TYPE
) AS
    STATUS ORDERS.STATUS%TYPE;
    PAYMENT_ID PAYMENTS.PAYMENT_ID%TYPE;
    IS_PAID PAYMENTS.IS_PAID%TYPE;

    INVALID_STATUS EXCEPTION;
    NOT_PAID EXCEPTION;
BEGIN

    SELECT PAYMENT_ID, STATUS
    INTO PAYMENT_ID, STATUS
    FROM ORDERS 
    WHERE ORDERS.ORDER_ID = O_ID;

    IF STATUS != 'processing' THEN
        RAISE INVALID_STATUS;
    END IF;

    SELECT IS_PAID
    INTO IS_PAID
    FROM PAYMENTS
    WHERE PAYMENTS.PAYMENT_ID = PAYMENT_ID;

    IF IS_PAID != 1 THEN
        RAISE NOT_PAID;
    END IF;

    UPDATE ORDERS SET STATUS = 'shipped', SHIPPED_BY = E_LOGIN WHERE ORDERS.ORDER_ID = O_ID;

    EXCEPTION
        WHEN INVALID_STATUS THEN
            DBMS_OUTPUT.PUT_LINE('Order has invalid status of ' || STATUS || '. Expected "processing"');
        WHEN NOT_PAID THEN
            DBMS_OUTPUT.PUT_LINE('Order is not paid');
END;

/

-- SEKCE INSERT

---- Vkladání zboží do obchodu
INSERT INTO PRODUCTS (
    PRODUCT_NAME,
    PRODUCT_DESC,
    PRODUCT_IMG,
    CATEGORY,
    UNIT_PRICE,
    STOCK,
    TOTAL_SOLD,
    IS_INSTOCK
) VALUES (
    'Apple',
    'quite healthy food',
    './fruit/apple.jpeg',
    'fruit',
    11.99,
    50000,
    12000,
    1
);

INSERT INTO PRODUCTS (
    PRODUCT_NAME,
    PRODUCT_DESC,
    PRODUCT_IMG,
    CATEGORY,
    UNIT_PRICE,
    STOCK,
    TOTAL_SOLD,
    IS_INSTOCK
) VALUES (
    'Orange',
    'it is like a color but it is not',
    './fruit/orange.jpeg',
    'fruit',
    13.99,
    23571,
    673,
    1
);

INSERT INTO PRODUCTS (
    PRODUCT_NAME,
    PRODUCT_DESC,
    PRODUCT_IMG,
    CATEGORY,
    UNIT_PRICE,
    STOCK,
    TOTAL_SOLD,
    IS_INSTOCK
) VALUES (
    'Banana',
    'Minions would love it',
    './fruit/banana.jpeg',
    'fruit',
    7.99,
    31000,
    9714,
    1
);

INSERT INTO PRODUCTS (
    PRODUCT_NAME,
    PRODUCT_DESC,
    PRODUCT_IMG,
    CATEGORY,
    UNIT_PRICE,
    STOCK,
    TOTAL_SOLD,
    IS_INSTOCK
) VALUES (
    'Carrots',
    'Freshly harvested from the farm',
    './vegetable/carrots.jpeg',
    'vegetable',
    3.99,
    12000,
    2436,
    1
);

INSERT INTO PRODUCTS (
    PRODUCT_NAME,
    PRODUCT_DESC,
    PRODUCT_IMG,
    CATEGORY,
    UNIT_PRICE,
    STOCK,
    TOTAL_SOLD,
    IS_INSTOCK
) VALUES (
    'Beef',
    'Premium quality beef cuts',
    './meat/beef.jpeg',
    'meat',
    14.99,
    8000,
    3765,
    1
);

INSERT INTO PRODUCTS (
    PRODUCT_NAME,
    PRODUCT_DESC,
    PRODUCT_IMG,
    CATEGORY,
    UNIT_PRICE,
    STOCK,
    TOTAL_SOLD,
    IS_INSTOCK
) VALUES (
    'Potato Chips',
    'Crunchy and delicious potato chips',
    './snack/chips.jpeg',
    'snack',
    2.99,
    5000,
    984,
    1
);

INSERT INTO PRODUCTS (
    PRODUCT_NAME,
    PRODUCT_DESC,
    PRODUCT_IMG,
    CATEGORY,
    UNIT_PRICE,
    STOCK,
    TOTAL_SOLD,
    IS_INSTOCK
) VALUES (
    'Milk',
    'Fresh whole milk from the farm',
    './dairy/milk.jpeg',
    'dairy',
    3.49,
    5000,
    2873,
    1
);

INSERT INTO PRODUCTS (
    PRODUCT_NAME,
    PRODUCT_DESC,
    PRODUCT_IMG,
    CATEGORY,
    UNIT_PRICE,
    STOCK,
    TOTAL_SOLD,
    IS_INSTOCK
) VALUES (
    'Cheese',
    'A variety of high-quality cheese',
    './dairy/cheese.jpeg',
    'dairy',
    9.99,
    10000,
    2578,
    1
);

---- Registrace prvního zaměstnanсе
INSERT INTO EMPLOYEES (
    EMPLOYEE_LOGIN,
    PASSWORD,
    FIRST_NAME,
    LAST_NAME,
    EMAIL
) VALUES (
    'xwaits00',
    'password123456',
    'Tom',
    'Waits',
    'tom.waits@vutbr.cz'
);

---- Registrace druhého zaměstnanсе
INSERT INTO EMPLOYEES (
    EMPLOYEE_LOGIN,
    PASSWORD,
    FIRST_NAME,
    LAST_NAME,
    EMAIL
) VALUES (
    'xjohns00',
    'password789101',
    'David',
    'Johnson',
    'david.johnson@vutbr.cz'
);

---- Nastavení role správce pro prvního zaměstnanсе
INSERT INTO ADMINS (
    ADMIN_LOGIN,
    ADMIN_POSITION
) VALUES (
    'xwaits00',
    'owner'
);

--- Práce s prvním uživatelem

---- Registrace prvního uživatele
INSERT INTO CARTS (
    TOTAL_PRICE
) VALUES (
    0
);

INSERT INTO GUESTS (
    CART_ID
) VALUES (
    1
);

INSERT INTO CUSTOMERS (
    CUSTOMER_LOGIN,
    CUSTOMER_PASSWORD,
    FIRST_NAME,
    LAST_NAME,
    EMAIL,
    PHONENUMBER,
    CART_ID,
    CREATED_BY
) VALUES (
    'xbrown00',
    'password123456',
    'Roy',
    'Brown',
    'roy.brown@vutbr.cz',
    4201234567890,
    1,
    1
);

UPDATE GUESTS
SET
    LOGGED_AS = 'xbrown00'
WHERE
    GUEST_ID = 1;

---- První uživatel vkladá zboží do košíku
INSERT INTO ITEMS (
    PRODUCT_ID,
    CART_ID,
    QUANTITY,
    QUANTITY_PRICE
) VALUES (
    1,
    1,
    5,
    5 * (SELECT UNIT_PRICE FROM PRODUCTS WHERE PRODUCT_ID = 1)
);

INSERT INTO ITEMS (
    PRODUCT_ID,
    CART_ID,
    QUANTITY,
    QUANTITY_PRICE
) VALUES (
    2,
    1,
    12,
    12 * (SELECT UNIT_PRICE FROM PRODUCTS WHERE PRODUCT_ID = 2)
);

---- První uživatel vyplnil kontaktní udaje (chce si objednat zboží)
INSERT INTO ADDRESSES (
    COUNTRY,
    CITY_NAME,
    STREET,
    POSTAL_CODE,
    CUSTOMER_LOGIN
) VALUES (
    'Czech Republic',
    'Brno',
    'Bozetechova',
    '61200',
    'xbrown00'
);

UPDATE CUSTOMERS
SET
    ADDRESS_ID = 1
WHERE
    CUSTOMER_LOGIN = 'xbrown00';

SELECT * FROM ITEMS;

---- První uživatel vytvořil objednávku
INSERT INTO ORDERS (
    CUSTOMER_LOGIN,
    ADDRESS_ID,
    STATUS,
    TOTAL_PRICE
) VALUES (
    'xbrown00',
    1,
    'pending',
    (SELECT SUM(QUANTITY_PRICE) FROM ITEMS WHERE CART_ID = 1)
);

SELECT *
FROM ITEMS;

---- Uživatel zaplatil objednávku
UPDATE PAYMENTS
SET
    IS_PAID = 1
WHERE
    PAYMENT_ID = 1;

---- Po zaplacení stav objednávky byl změněn
UPDATE ORDERS
SET
    STATUS = 'processing'
WHERE
    ORDER_ID = 1;

-- Po zaplacení první zaměstnanec zpracoval objednávku
UPDATE ORDERS
SET
    PROCESSED_BY = 'xwaits00'
WHERE
    ORDER_ID = 1;

EXECUTE SHIP_ORDER(1, 'xwaits00');

---- Po zpracování druhý zaměstnanec odeslal objednávku
-- UPDATE ORDERS
-- SET
--     SHIPPED_BY = 'xjohns00'
-- WHERE
--     ORDER_ID = 1;

---- Po odeslání stav objednávky byl změněn
UPDATE ORDERS
SET
    STATUS = 'shipped'
WHERE
    ORDER_ID = 1;

---- První uživatel píše review pro zboží
INSERT INTO FEEDBACKS (
    CUSTOMER_LOGIN,
    CONTENT,
    RATING,
    PRODUCT_ID
) VALUES (
    'xbrown00',
    'Stale very small apples. Do not reccomend them.',
    1,
    1
);

UPDATE PRODUCTS
SET
    TOTAL_RATING = (
        SELECT AVG(RATING) FROM FEEDBACKS WHERE PRODUCT_ID = 1
    )
WHERE
    PRODUCT_ID = 1;

--- První uživatel vkladá nové zboží do košíku
INSERT INTO ITEMS (
    PRODUCT_ID,
    CART_ID,
    QUANTITY,
    QUANTITY_PRICE
) VALUES (
    6,
    1,
    3,
    3 * (SELECT UNIT_PRICE FROM PRODUCTS WHERE PRODUCT_ID = 1)
);

INSERT INTO ITEMS (
    PRODUCT_ID,
    CART_ID,
    QUANTITY,
    QUANTITY_PRICE
) VALUES (
    5,
    1,
    4,
    4 * (SELECT UNIT_PRICE FROM PRODUCTS WHERE PRODUCT_ID = 2)
);

SELECT *
FROM ITEMS;

---- První uživatel vytvořil novu objednávku
INSERT INTO ORDERS (
    CUSTOMER_LOGIN,
    ADDRESS_ID,
    STATUS,
    TOTAL_PRICE
) VALUES (
    'xbrown00',
    1,
    'pending',
    (SELECT SUM(QUANTITY_PRICE) FROM ITEMS WHERE CART_ID = 1)
);

SELECT *
FROM ITEMS;

--- Práce s druhým uživatelem

---- Registrace druhého uživatele
INSERT INTO CARTS (
    TOTAL_PRICE
) VALUES (
    0
);

INSERT INTO GUESTS (
    CART_ID
) VALUES (
    2
);

INSERT INTO CUSTOMERS (
    CUSTOMER_LOGIN,
    CUSTOMER_PASSWORD,
    FIRST_NAME,
    LAST_NAME,
    EMAIL,
    PHONENUMBER,
    CART_ID,
    CREATED_BY
) VALUES (
    'xcash00',
    'hard_password1234',
    'Johnny',
    'Cash',
    'jognny.cash@vutbr.cz',
    4200987654321,
    2,
    2
);

UPDATE GUESTS
SET
    LOGGED_AS = 'xcash00'
WHERE
    GUEST_ID = 2;

---- Druhý uživatel vkladá zboží do košíku
INSERT INTO ITEMS (
    PRODUCT_ID,
    CART_ID,
    QUANTITY,
    QUANTITY_PRICE
) VALUES (
    3,
    2,
    7,
    7 * (SELECT UNIT_PRICE FROM PRODUCTS WHERE PRODUCT_ID = 3)
);

INSERT INTO ITEMS (
    PRODUCT_ID,
    CART_ID,
    QUANTITY,
    QUANTITY_PRICE
) VALUES (
    4,
    2,
    8,
    8 * (SELECT UNIT_PRICE FROM PRODUCTS WHERE PRODUCT_ID = 4)
);

---- Druhý uživatel se snaží udělat objednávku
INSERT INTO ORDERS (
    CUSTOMER_LOGIN,
    STATUS,
    TOTAL_PRICE
) VALUES (
    'xcash00',
    'pending',
    (SELECT SUM(QUANTITY_PRICE) FROM ITEMS WHERE CART_ID = 1)
);

---- Druhý uživatel píše review pro zboží
INSERT INTO FEEDBACKS (
    CUSTOMER_LOGIN,
    CONTENT,
    RATING,
    PRODUCT_ID
) VALUES (
    'xcash00',
    'Tasty apples I found here. I will have to make this feedback bigger in order to fit my constraint.',
    4,
    1
);

UPDATE PRODUCTS
SET
    TOTAL_RATING = (
        SELECT AVG(RATING) FROM FEEDBACKS WHERE PRODUCT_ID = 1
    )
WHERE
    PRODUCT_ID = 1;


--- Práce s třetím uživatelem

---- Registrace třetího uživatele
INSERT INTO CARTS (
    TOTAL_PRICE
) VALUES (
    0
);

INSERT INTO GUESTS (
    CART_ID
) VALUES (
    3
);

INSERT INTO CUSTOMERS (
    CUSTOMER_LOGIN,
    CUSTOMER_PASSWORD,
    FIRST_NAME,
    LAST_NAME,
    EMAIL,
    PHONENUMBER,
    CART_ID,
    CREATED_BY
) VALUES (
    'xmorri00',
    'mypassword',
    'Jim',
    'Morrison',
    'jim.morrison@example.com',
    4205432154321,
    3,
    3
);

UPDATE GUESTS
SET
    LOGGED_AS = 'xmorri00'
WHERE
    GUEST_ID = 3;

---- Tretí uživatel vkladá zboží do košíku
INSERT INTO ITEMS (
    PRODUCT_ID,
    CART_ID,
    QUANTITY,
    QUANTITY_PRICE
) VALUES (
    4,
    3,
    10,
    10 * (SELECT UNIT_PRICE FROM PRODUCTS WHERE PRODUCT_ID = 4)
);

INSERT INTO ITEMS (
    PRODUCT_ID,
    CART_ID,
    QUANTITY,
    QUANTITY_PRICE
) VALUES (
    5,
    3,
    2,
    2 * (SELECT UNIT_PRICE FROM PRODUCTS WHERE PRODUCT_ID = 5)
);

INSERT INTO ITEMS (
    PRODUCT_ID,
    CART_ID,
    QUANTITY,
    QUANTITY_PRICE
) VALUES (
    6,
    3,
    3,
    3 * (SELECT UNIT_PRICE FROM PRODUCTS WHERE PRODUCT_ID = 6)
);

---- Tretí uživatel vyplnil kontaktní udaje (chce si objednat zboží)
INSERT INTO ADDRESSES (
    COUNTRY,
    CITY_NAME,
    STREET,
    POSTAL_CODE,
    CUSTOMER_LOGIN
) VALUES (
    'Czech Republic',
    'Brno',
    'Kolejni',
    '61200',
    'xmorri00'
);

UPDATE CUSTOMERS
SET
    ADDRESS_ID = 2
WHERE
    CUSTOMER_LOGIN = 'xmorri00';

---- Tretí uživatel vytvořil objednávku
INSERT INTO ORDERS (
    CUSTOMER_LOGIN,
    ADDRESS_ID,
    STATUS,
    TOTAL_PRICE
) VALUES (
    'xmorri00',
    2,
    'pending',
    (SELECT SUM(QUANTITY_PRICE) FROM ITEMS WHERE CART_ID = 3)
);

---- Uživatel zaplatil objednávku
UPDATE PAYMENTS
SET
    IS_PAID = 1
WHERE
    PAYMENT_ID = 3;

UPDATE ORDERS
SET
    PAYMENT_ID = 3
WHERE
    ORDER_ID = 4;


EXECUTE SHIP_ORDER(4, 'xjohns00');
---- Po zaplacení stav objednávky byl změněn
UPDATE ORDERS
SET
    STATUS = 'processing'
WHERE
    ORDER_ID = 4;

SELECT * FROM ORDERS;
SELECT * FROM PAYMENTS;
 SELECT IS_PAID
    FROM PAYMENTS
    WHERE PAYMENTS.PAYMENT_ID = 3;

---- Tretí uživatel píše review pro zboží
INSERT INTO FEEDBACKS (
    CUSTOMER_LOGIN,
    CONTENT,
    RATING,
    PRODUCT_ID
) VALUES (
    'xmorri00',
    'I made a good dish out of this meat. Love it.',
    5,
    5
);

UPDATE PRODUCTS
SET
    TOTAL_RATING = (
        SELECT AVG(RATING) FROM FEEDBACKS WHERE PRODUCT_ID = 5
    )
WHERE
    PRODUCT_ID = 5;

/

-- WITH & CASE SELECT --

WITH PRODUCT_AMOUNT_NAME AS (
    SELECT PRODUCT_NAME, PRODUCT_DESC, PRODUCT_IMG, CATEGORY, UNIT_PRICE, TOTAL_RATING, 
        CASE
            WHEN STOCK < 10000 THEN
                'Almost Out of Stock'
            WHEN STOCK >= 10000 AND STOCK <= 20000 THEN
                'Limited Stock'
            WHEN STOCK >= 20000 AND STOCK <= 40000 THEN
                'Sufficient Stock'
            ELSE
                'HIGH STOCK'
        END AS STOCK_NAME
    FROM PRODUCTS
)
SELECT *
FROM PRODUCT_AMOUNT_NAME;

-- MATERIALIZED VIEW --

CREATE MATERIALIZED VIEW PRODUCT_CATEGORY_COUNT REFRESH ON COMMIT AS
    SELECT CATEGORY,
        COUNT(PRODUCT_ID)
    FROM PRODUCTS
    GROUP BY CATEGORY;

SELECT *
FROM PRODUCT_CATEGORY_COUNT;

-- PRIVILEGES --
GRANT ALL ON XTURYT00.ADDRESSES TO XZDEBS00;
GRANT ALL ON XTURYT00.ADMINS TO XZDEBS00;
GRANT ALL ON XTURYT00.CARTS TO XZDEBS00;
GRANT ALL ON XTURYT00.CUSTOMERS TO XZDEBS00;
GRANT ALL ON XTURYT00.EMPLOYEES TO XZDEBS00;
GRANT ALL ON XTURYT00.FEEDBACKS TO XZDEBS00;
GRANT ALL ON XTURYT00.GUESTS TO XZDEBS00;
GRANT ALL ON XTURYT00.ORDERS TO XZDEBS00;
GRANT ALL ON XTURYT00.PAYMENTS TO XZDEBS00;
GRANT ALL ON XTURYT00.PRODUCTS TO XZDEBS00;
GRANT ALL ON XTURYT00.ITEMS TO XZDEBS00;
GRANT ALL ON XTURYT00.PRODUCT_CATEGORY_COUNT TO XZDEBS00;
GRANT EXECUTE ON AVERAGE_PRODUCT_RATING TO XZDEBS00;
GRANT EXECUTE ON SHIP_ORDER TO XZDEBS00;

-- EXPLAIN PLAN & INDEXES --

-- Poskytnutý kód je příkladem použití EXPLAIN PLAN a vytvoření 
-- indexu k optimalizaci zpracování dotazu.

-- V tomto příkladu dotaz vypočítává celkovou částku, kterou každý zákazník
-- musí zaplatit v daném období. Dotaz spojuje tabulky PAYMENTS a CUSTOMERS
-- pomocí sloupců PAYMENTS.ASSIGNED_TO a CUSTOMERS.CUSTOMER_LOGIN a vybírá
-- pouze platby, které mají datum splatnosti mezi 1. lednem 2022 a 1. lednem 2024.
-- Výsledek je poté seskupen podle křestního jména zákazníka a řazen abecedně.

SELECT FIRST_NAME,
    SUM(TOTAL_PRICE)
FROM PAYMENTS
    INNER JOIN CUSTOMERS ON (PAYMENTS.ASSIGNED_TO = CUSTOMERS.CUSTOMER_LOGIN AND PAYMENTS.EXPIRES_AT BETWEEN DATE '2022-01-01' AND DATE '2024-01-01')
GROUP BY FIRST_NAME
ORDER BY FIRST_NAME;

-- Nejprve spustíme EXPLAIN PLAN, abychom viděli plán provedení původního dotazu. 
EXPLAIN PLAN FOR 
SELECT FIRST_NAME,
    SUM(TOTAL_PRICE)
FROM PAYMENTS
    INNER JOIN CUSTOMERS ON (PAYMENTS.ASSIGNED_TO = CUSTOMERS.CUSTOMER_LOGIN AND PAYMENTS.EXPIRES_AT BETWEEN DATE '2022-01-01' AND DATE '2024-01-01')
GROUP BY FIRST_NAME
ORDER BY FIRST_NAME;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY);

-- K optimalizaci tohoto dotazu vytvoříme index na sloupci PAYMENTS.EXPIRES_AT,
-- který se používá v WHERE klauzuli k filtrování plateb podle data splatnosti.
-- Index umožní databázi rychle najít relevantní řádky v tabulce PAYMENTS a zlepší
-- výkon dotazu.
CREATE INDEX PAYMENT_INDEX ON PAYMENTS(
    EXPIRES_AT
);

EXPLAIN PLAN FOR
SELECT FIRST_NAME,
    SUM(TOTAL_PRICE)
FROM PAYMENTS
    INNER JOIN CUSTOMERS ON (PAYMENTS.ASSIGNED_TO = CUSTOMERS.CUSTOMER_LOGIN AND PAYMENTS.EXPIRES_AT BETWEEN DATE '2022-01-01' AND DATE '2024-01-01')
GROUP BY FIRST_NAME
ORDER BY FIRST_NAME;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY);

-- TODO: Remove --

SELECT *
FROM FEEDBACKS;

EXECUTE AVERAGE_PRODUCT_RATING(6);
EXECUTE AVERAGE_PRODUCT_RATING(1);