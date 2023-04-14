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
          IF SQLCODE != -942  THEN
             RAISE;
          END IF;
    END;
    -- reset sekvence
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

-- Nastavuje se sekvence pro primarní klíče
CREATE SEQUENCE guests_sequence START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE carts_sequence START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE address_sequence START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE items_sequence START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE products_sequence START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE feedbacks_sequence START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE orders_sequence START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE payments_sequence START WITH 1 INCREMENT BY 1 NOCACHE;


-- DEFINICE ENTIT

---- GUEST
CREATE TABLE guests (
    guest_id INT DEFAULT guests_sequence.NEXTVAL,
    cart_id INT UNIQUE NOT NULL,
    logged_as VARCHAR(255) DEFAULT NULL,
    CONSTRAINT guest_pk PRIMARY KEY (guest_id)
);

---- CUSTOMER
CREATE TABLE customers (
    customer_login VARCHAR(255) NOT NULL CONSTRAINT customer_login_check CHECK (REGEXP_LIKE(customer_login, '^x[a-z0-9]*$')),
    customer_password VARCHAR(255) NOT NULL CHECK (LENGTH(customer_password) > 8),
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL CONSTRAINT customer_email_check CHECK (REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
    phonenumber VARCHAR(255) NOT NULL,
    cart_id INT UNIQUE NOT NULL,
    created_by INT NOT NULL,
    address_id INT,
    CONSTRAINT customer_pk PRIMARY KEY (customer_login)
);

---- ADDRESS
CREATE TABLE addresses (
    address_id INT DEFAULT address_sequence.NEXTVAL,
    country VARCHAR(255) NOT NULL,
    city_name VARCHAR(255) NOT NULL,
    street VARCHAR(255) NOT NULL,
    postal_code VARCHAR(255) NOT NULL,
    customer_login VARCHAR(255) UNIQUE NOT NULL,
    CONSTRAINT address_pk PRIMARY KEY (address_id)
);

---- CART
CREATE TABLE carts (
    cart_id INT DEFAULT carts_sequence.NEXTVAL,
    total_price NUMERIC(10,2) NOT NULL CHECK (total_price >= 0),
    CONSTRAINT cart_pk PRIMARY KEY (cart_id)
);

---- ITEM
CREATE TABLE items (
    item_id INT DEFAULT items_sequence.NEXTVAL,
    quantity_price NUMERIC(10,2) NOT NULL CHECK (quantity_price >= 0),
    quantity INT NOT NULL CHECK (quantity >= 0),
    cart_id INT,
    order_id INT,
    product_id INT NOT NULL,
    CONSTRAINT item_pk PRIMARY KEY(item_id)
);

---- PRODUCT
CREATE TABLE products (
    product_id INT DEFAULT products_sequence.NEXTVAL,
    product_name VARCHAR(255) NOT NULL,
    product_desc VARCHAR2(1024) NOT NULL,
    product_img VARCHAR(255) NOT NULL,
    category VARCHAR(255) NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    stock INT DEFAULT 0 NOT NULL CHECK (stock >= 0),
    total_sold INT DEFAULT 0 NOT NULL CHECK (total_sold >= 0),
    is_instock NUMBER DEFAULT 0 NOT NULL CHECK (is_instock IN (0,1)),
    total_rating INT DEFAULT 0 CHECK (total_rating >= 0 AND total_rating <= 5),
    CONSTRAINT product_pk PRIMARY KEY (product_id)
);

---- FEEDBACK
CREATE TABLE feedbacks (
    feedback_id INT DEFAULT feedbacks_sequence.NEXTVAL,
    content VARCHAR2(2048) NOT NULL CHECK (LENGTH(content) > 12),
    rating INT DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
    product_id INT NOT NULL,
    customer_login VARCHAR(255) NOT NULL,
    CONSTRAINT feedback_pk PRIMARY KEY (feedback_id)
);

---- ORDER
CREATE TABLE orders (
    order_id INT DEFAULT orders_sequence.NEXTVAL,
    total_price NUMERIC(10,2) NOT NULL,
    status VARCHAR (255) NOT NULL CHECK (status IN ('pending', 'processing', 'shipped', 'cancelled')),
    customer_login VARCHAR(255) NOT NULL,
    address_id INT NOT NULL,
    payment_id INT,
    processed_by VARCHAR(255),
    shipped_by VARCHAR(255),
    CONSTRAINT order_pk PRIMARY KEY (order_id)
);

---- PAYMENT
CREATE TABLE payments (
    payment_id INT DEFAULT payments_sequence.NEXTVAL,
    account_number VARCHAR(255) NOT NULL,
    expires_at DATE DEFAULT (SYSDATE + 1),
    is_paid NUMBER DEFAULT 0 CHECK (is_paid IN (0,1)),
    total_price NUMERIC(10,2) NOT NULL,
    assigned_to VARCHAR(255) NOT NULL,
    order_id INT NOT NULL,
    CONSTRAINT payment_pk PRIMARY KEY (payment_id)
);

---- EMPLOYEE
CREATE TABLE employees (
    employee_login VARCHAR(255) NOT NULL CONSTRAINT employee_login_check CHECK (REGEXP_LIKE(employee_login, '^x[a-z0-9]*$')),
    password VARCHAR(255) NOT NULL CHECK (LENGTH(password) > 8),
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL CONSTRAINT employee_email_check CHECK (REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
    CONSTRAINT employee_pk PRIMARY KEY (employee_login)
);

---- ADMIN
CREATE TABLE admins (
    admin_login VARCHAR(255) NOT NULL,
    admin_position VARCHAR(255) NOT NULL CHECK (admin_position IN ('manager','owner')),
    CONSTRAINT admin_pk PRIMARY KEY (admin_login)
);

-- GENERALIZACE
-- Generalizace v SQL je částo implementovana pomocí cizích klíče (FOREIGN KEY). 
-- V tomto systému použili jsme generalizace pro entity Admin a Employee, kde parent je Employee a
-- Admin je child.
-- Pokud chceme přidat do systému jednoducheho manažera, je třeba vytvořít 
-- na začátku Employee, vyplnit jeho hodnoty, pak vytvořit objekt Admin
-- přiradit mu do "admin_position" hodnotu "manager" a jako primární klíč přiradit klíč
-- nového zaměstnánce, kterého jsme vytvořili před tim. Příklad je dal v sekci INSERT
ALTER TABLE admins ADD CONSTRAINT admin_fk FOREIGN KEY (admin_login) REFERENCES employees(employee_login) ON DELETE CASCADE;


-- NASTAVENÍ VZTAHŮ

---- CUSTOMERS
ALTER TABLE customers ADD CONSTRAINT created_by_guest_fk FOREIGN KEY (created_by) REFERENCES guests(guest_id) ON DELETE SET NULL; --created by
ALTER TABLE customers ADD CONSTRAINT customer_card_fk FOREIGN KEY (cart_id) REFERENCES carts ON DELETE CASCADE; --has
ALTER TABLE customers ADD CONSTRAINT customer_address_fk FOREIGN KEY (address_id) REFERENCES addresses ON DELETE SET NULL; --located at

---- ADDRESSES
ALTER TABLE addresses ADD CONSTRAINT address_customer_fk FOREIGN KEY (customer_login) REFERENCES customers ON DELETE CASCADE;

---- GUESTS
ALTER TABLE guests ADD CONSTRAINT guest_card_fk FOREIGN KEY (cart_id) REFERENCES carts ON DELETE CASCADE; --has
ALTER TABLE guests ADD CONSTRAINT guest_logged_as_fk FOREIGN KEY (logged_as) REFERENCES customers(customer_login) ON DELETE SET NULL; --login

---- ITEMS
ALTER TABLE items ADD CONSTRAINT cart_item_fk FOREIGN KEY (cart_id) REFERENCES carts ON DELETE SET NULL; --belongs to
ALTER TABLE items ADD CONSTRAINT order_item_fk FOREIGN KEY (order_id) REFERENCES orders ON DELETE SET NULL; --belongs to
ALTER TABLE items ADD CONSTRAINT item_product_fk FOREIGN KEY (product_id) REFERENCES products ON DELETE CASCADE; --belongs to

---- FEEDBACKS
ALTER TABLE feedbacks ADD CONSTRAINT product_feedback_fk FOREIGN KEY (product_id) REFERENCES products ON DELETE CASCADE; -- <identif>
ALTER TABLE feedbacks ADD CONSTRAINT customer_feedback_fk FOREIGN KEY (customer_login) REFERENCES customers ON DELETE SET NULL; -- leaves

---- ORDERS
ALTER TABLE orders ADD CONSTRAINT customer_order_fk FOREIGN KEY (customer_login)REFERENCES customers ON DELETE SET NULL; -- makes
ALTER TABLE orders ADD CONSTRAINT order_payment_fk FOREIGN KEY (payment_id) REFERENCES payments ON DELETE SET NULL; -- <identif>
ALTER TABLE orders ADD CONSTRAINT order_processed_by_fk FOREIGN KEY (processed_by)REFERENCES employees(employee_login) ON DELETE SET NULL; -- processes
ALTER TABLE orders ADD CONSTRAINT order_shipped_by_fk FOREIGN KEY (shipped_by) REFERENCES employees(employee_login) ON DELETE SET NULL; -- ships out
ALTER TABLE orders ADD CONSTRAINT order_address_fk FOREIGN KEY (address_id) REFERENCES addresses ON DELETE SET NULL;

---- PAYMENTS
ALTER TABLE payments ADD CONSTRAINT customer_payment_fk FOREIGN KEY (assigned_to) REFERENCES customers(customer_login) ON DELETE SET NULL;
ALTER TABLE payments ADD CONSTRAINT payment_order_fk FOREIGN KEY (order_id) REFERENCES orders ON DELETE CASCADE;

-- SEKCE INSERT

---- Vkladání zboží do obchodu
INSERT INTO products (product_name, product_desc, product_img, category, unit_price, stock, total_sold, is_instock) VALUES
('Apple', 'quite healthy food', './fruit/apple.jpeg', 'fruit', 11.99, 50000, 12000, 1);

INSERT INTO products (product_name, product_desc, product_img, category, unit_price, stock, total_sold, is_instock) VALUES
('Orange', 'it is like a color but it is not', './fruit/orange.jpeg', 'fruit', 13.99, 23571, 673, 1);

INSERT INTO products (product_name, product_desc, product_img, category, unit_price, stock, total_sold, is_instock) VALUES
('Banana', 'Minions would love it', './fruit/banana.jpeg', 'fruit', 7.99, 31000, 9714, 1);

INSERT INTO products (product_name, product_desc, product_img, category, unit_price, stock, total_sold, is_instock) VALUES 
('Carrots', 'Freshly harvested from the farm', './vegetable/carrots.jpeg', 'vegetable', 3.99, 12000, 2436, 1);

INSERT INTO products (product_name, product_desc, product_img, category, unit_price, stock, total_sold, is_instock) VALUES 
('Beef', 'Premium quality beef cuts', './meat/beef.jpeg', 'meat', 14.99, 8000, 3765, 1);

INSERT INTO products (product_name, product_desc, product_img, category, unit_price, stock, total_sold, is_instock) VALUES 
('Potato Chips', 'Crunchy and delicious potato chips', './snack/chips.jpeg', 'snack', 2.99, 5000, 984, 1);

INSERT INTO products (product_name, product_desc, product_img, category, unit_price, stock, total_sold, is_instock) 
VALUES ('Milk', 'Fresh whole milk from the farm', './dairy/milk.jpeg', 'dairy', 3.49, 5000, 2873, 1);

INSERT INTO products (product_name, product_desc, product_img, category, unit_price, stock, total_sold, is_instock) VALUES 
('Cheese', 'A variety of high-quality cheese', './dairy/cheese.jpeg', 'dairy', 9.99, 10000, 2578, 1);

---- Registrace prvního zaměstnanсе
INSERT INTO employees (employee_login,password, first_name, last_name, email) 
VALUES ('xwaits00', 'password123456', 'Tom', 'Waits', 'tom.waits@vutbr.cz');

---- Registrace druhého zaměstnanсе
INSERT INTO employees (employee_login,password, first_name, last_name, email) 
VALUES ('xjohns00', 'password789101', 'David', 'Johnson', 'david.johnson@vutbr.cz');

---- Nastavení role správce pro prvního zaměstnanсе
INSERT INTO admins (admin_login, admin_position)
VALUES ('xwaits00','owner');

--- Práce s prvním uživatelem

---- Registrace prvního uživatele
INSERT INTO carts (total_price) VALUES (0);
INSERT INTO guests (cart_id) VALUES (1);
INSERT INTO customers (customer_login, customer_password, first_name, last_name, email,phonenumber, cart_id, created_by) 
VALUES ('xbrown00','password123456','Roy','Brown','roy.brown@vutbr.cz', 4201234567890, 1, 1);
UPDATE guests SET logged_as = 'xbrown00' WHERE guest_id = 1;

---- První uživatel vkladá zboží do košíku
INSERT INTO items (product_id, cart_id, quantity, quantity_price)
VALUES (1,1,5, 5 * (SELECT unit_price FROM products WHERE product_id = 1));
INSERT INTO items (product_id, cart_id, quantity, quantity_price)
VALUES (2,1,12, 12 * (SELECT unit_price FROM products WHERE product_id = 2));

---- První uživatel vyplnil kontaktní udaje (chce si objednat zboží)
INSERT INTO addresses (country, city_name, street, postal_code, customer_login)
VALUES ('Czech Republic', 'Brno','Bozetechova' ,'61200', 'xbrown00');
UPDATE customers SET address_id = 1 WHERE customer_login = 'xbrown00';

---- První uživatel vytvořil objednávku
INSERT INTO orders (customer_login, address_id, status, total_price)
VALUES ('xbrown00', 1, 'pending', (SELECT SUM(quantity_price) FROM items WHERE cart_id = 1));
UPDATE items SET order_id = 1 WHERE item_id = 1;
UPDATE items SET order_id = 1 WHERE item_id = 2;
UPDATE orders SET total_price = (SELECT SUM(quantity_price) FROM items WHERE order_id = 1) WHERE order_id = 1;

---- Po vytvoření objednávky vytvoří se platba kterou první uživatel musí uhradit
INSERT INTO payments (assigned_to,account_number, is_paid,order_id, total_price)
VALUES ('xbrown00','1234 3456 3456 3454',0, 1, (SELECT total_price FROM orders WHERE order_id = 1));

---- Uživatel zaplatil objednávku
UPDATE payments SET is_paid = 1 WHERE payment_id = 1;

---- Po zaplacení stav objednávky byl změněn
UPDATE orders SET status = 'processing' WHERE order_id = 1;

---- Po zaplacení první zaměstnanec zpracoval objednávku
UPDATE orders SET processed_by = 'xwaits00' WHERE order_id = 1;

---- Po zpracování druhý zaměstnanec odeslal objednávku
UPDATE orders SET shipped_by = 'xjohns00' WHERE order_id = 1;

---- Po odeslání stav objednávky byl změněn
UPDATE orders SET status = 'shipped' WHERE order_id = 1;

---- První uživatel píše review pro zboží
INSERT INTO feedbacks (customer_login, content, rating, product_id)
VALUES ('xbrown00', 'Stale very small apples. Do not reccomend them.', 1, 1);
UPDATE products SET total_rating = (SELECT AVG(rating) FROM feedbacks WHERE product_id = 1) where product_id = 1;

--- Práce s druhým uživatelem

---- Registrace druhého uživatele
INSERT INTO carts (total_price) VALUES (0);
INSERT INTO guests (cart_id) VALUES (2);
INSERT INTO customers (customer_login, customer_password, first_name, last_name, email,phonenumber, cart_id, created_by) 
VALUES ('xcash00','hard_password1234','Johnny','Cash','jognny.cash@vutbr.cz', 4200987654321, 2, 2);
UPDATE guests SET logged_as = 'xcash00' WHERE guest_id = 2;

---- Druhý uživatel vkladá zboží do košíku
INSERT INTO items (product_id, cart_id, quantity, quantity_price)
VALUES (3,2,7, 7 * (SELECT unit_price FROM products WHERE product_id = 3));
INSERT INTO items (product_id, cart_id, quantity, quantity_price)
VALUES (4,2,8, 8 * (SELECT unit_price FROM products WHERE product_id = 4));

---- Druhý uživatel píše review pro zboží
INSERT INTO feedbacks (customer_login, content, rating, product_id)
VALUES ('xcash00', 'Tasty apples I found here. I will have to make this feedback bigger in order to fit my constraint.', 4, 1);
UPDATE products SET total_rating = (SELECT AVG(rating) FROM feedbacks WHERE product_id = 1) where product_id = 1;
--- Práce s třetím uživatelem

---- Registrace třetího uživatele
INSERT INTO carts (total_price) VALUES (0);
INSERT INTO guests (cart_id) VALUES (3);
INSERT INTO customers (customer_login, customer_password, first_name, last_name, email,phonenumber, cart_id, created_by) 
VALUES ('xmorri00','mypassword','Jim','Morrison','jim.morrison@example.com', 4205432154321, 3, 3);
UPDATE guests SET logged_as = 'xmorri00' WHERE guest_id = 3;

---- Tretí uživatel vkladá zboží do košíku
INSERT INTO items (product_id, cart_id, quantity, quantity_price)
VALUES (4,3,10, 10 * (SELECT unit_price FROM products WHERE product_id = 4));
INSERT INTO items (product_id, cart_id, quantity, quantity_price)
VALUES (5,3,2, 2 * (SELECT unit_price FROM products WHERE product_id = 5));
INSERT INTO items (product_id, cart_id, quantity, quantity_price)
VALUES (6,3,3, 3 * (SELECT unit_price FROM products WHERE product_id = 6));

---- Tretí uživatel vyplnil kontaktní udaje (chce si objednat zboží)
INSERT INTO addresses (country, city_name, street, postal_code, customer_login)
VALUES ('Czech Republic', 'Brno','Kolejni' ,'61200', 'xmorri00');
UPDATE customers SET address_id = 2 WHERE customer_login = 'xmorri00';

---- Tretí uživatel vytvořil objednávku
INSERT INTO orders (customer_login, address_id, status, total_price)
VALUES ('xmorri00', 2, 'pending', (SELECT SUM(quantity_price) FROM items WHERE cart_id = 3));
UPDATE items SET order_id = 2 WHERE item_id = 5;
UPDATE items SET order_id = 2 WHERE item_id = 6;
UPDATE items SET order_id = 2 WHERE item_id = 7;
UPDATE orders SET total_price = (SELECT SUM(quantity_price) FROM items WHERE order_id = 2) WHERE order_id = 2;

---- Po vytvoření objednávky vytvoří se platba kterou první uživatel musí uhradit
INSERT INTO payments (assigned_to,account_number, is_paid,order_id, total_price)
VALUES ('xmorri00','5678 9101 1121 3141',0, 2, (SELECT total_price FROM orders WHERE order_id = 1));

---- Uživatel zaplatil objednávku
UPDATE payments SET is_paid = 1 WHERE payment_id = 2;

---- Po zaplacení stav objednávky byl změněn
UPDATE orders SET status = 'processing' WHERE order_id = 2;

---- Po zaplacení druhý zaměstnanec zpracoval objednávku
UPDATE orders SET processed_by = 'xjohns00' WHERE order_id = 2;

---- Po zpracování druhý zaměstnanec odeslal objednávku
UPDATE orders SET shipped_by = 'xjohns00' WHERE order_id = 1;

---- Po odeslání stav objednávky byl změněn
UPDATE orders SET status = 'shipped' WHERE order_id = 1;

---- Tretí uživatel píše review pro zboží
INSERT INTO feedbacks (customer_login, content, rating, product_id)
VALUES ('xmorri00', 'I made a good dish out of this meat. Love it.', 5, 5);
UPDATE products SET total_rating = (SELECT AVG(rating) FROM feedbacks WHERE product_id = 5) where product_id = 5;

SELECT * FROM employees;

/

-- SEKCE SELECT

--- Spojení dvou tabulek

---- 1 Tabulka, která ukazuje, kdo vyřizoval objednávky
SELECT order_id, employee_login FROM orders JOIN employees ON orders.processed_by=employees.employee_login;
---- Tabulka objednávek
SELECT * FROM orders;
---- Tabulka zaměstnanců
SELECT * FROM employees;

---- 2 Tabulka, která ukazuje hodnocení a recenze produktů
SELECT products.product_id, product_name, total_rating, feedback_id, rating, content FROM products JOIN feedbacks ON products.product_id=feedbacks.product_id;
---- Tabulka produktů
SELECT * FROM products;
---- Tabulka recenzí
SELECT * FROM feedbacks;

--- Spojení tří tabulek

---- 3 Obsah objednávek: jméno a množství produktu
SELECT orders.order_id, items.product_id, products.product_name, items.quantity FROM orders 
JOIN items ON orders.order_id=items.order_id JOIN products ON items.product_id = products.product_id ORDER BY orders.order_id ASC;
---- Tabulka objednávek
SELECT * FROM orders;
---- Tabulka položek
SELECT * FROM items;
---- Tabulka produktů
SELECT * FROM products;

--- Dotazy s klauzulí GROUP BY

---- 4 Kolik produktů každé kategorie je v obchodě
SELECT COUNT(products.product_id), products.category FROM products GROUP BY products.category;
---- Tabulka produktů
SELECT * FROM products;

---- 5 Tabulka ukazuje průměrný počet produktů vybraných zákazníky
SELECT AVG(items.quantity), items.product_id FROM items GROUP BY items.product_id;
---- Tabulka položek
SELECT * FROM items;

--- Dotaz obsahující predikát EXIST

---- 6 Tabulka ukazuje zákazníky, kteří provedli objednávku za méně než 200 korun
SELECT customers.customer_login, orders.order_id, orders.total_price FROM customers JOIN orders ON orders.customer_login = customers.customer_login WHERE EXISTS 
(SELECT orders.order_id FROM orders 
WHERE orders.customer_login = customers.customer_login AND total_price < 200);
---- Tabulka objednávek
SELECT * FROM orders;
---- Tabulka uživatelů
SELECT * FROM customers;

--- Dotaz s predikátem IN
---- 7 Tabulka ukazuje produkty, které uživatelé přidávali do košíku
SELECT * FROM products
WHERE products.product_id IN (SELECT items.product_id FROM items);
---- Tabulka produktů
SELECT * FROM products;
---- Tabulka uživatelů
SELECT * FROM customers;