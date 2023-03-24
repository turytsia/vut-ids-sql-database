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

/

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
    admin_position VARCHAR(255) NOT NULL CHECK (admin_position IN ('manager','owner'))
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

/

-- SEKCE INSERT

---- Vkladání zboží do obchodu
INSERT INTO products (product_name, product_desc, product_img, category, unit_price, stock, total_sold, is_instock) VALUES
('Apple', 'quite healthy food', './fruit/apple.jpeg', 'fruit', 11.99, 50000, 12000, 1);

INSERT INTO products (product_name, product_desc, product_img, category, unit_price, stock, total_sold, is_instock) VALUES
('Orange', 'it is like a color but it is not', './fruit/orange.jpeg', 'fruit', 13.99, 23571, 673, 1);

INSERT INTO products (product_name, product_desc, product_img, category, unit_price, stock, total_sold, is_instock) VALUES
('Banana', 'Minions would love it', './fruit/banana.jpeg', 'fruit', 7.99, 31000, 9714, 1);

---- Registrace prvního uživatele
INSERT INTO carts (total_price) VALUES (0);
INSERT INTO guests (cart_id) VALUES (1);
INSERT INTO customers (customer_login, customer_password, first_name, last_name, email,phonenumber, cart_id, created_by) 
VALUES ('xbrown00','password123456','Roy','Brown','roy.brown@vutbr.cz', 4201234567890, 1, 1);
UPDATE guests SET logged_as = 'xbrown00' WHERE guest_id = 1;

---- Registrace druhého uživatele
INSERT INTO carts (total_price) VALUES (0);
INSERT INTO guests (cart_id) VALUES (2);
INSERT INTO customers (customer_login, customer_password, first_name, last_name, email,phonenumber, cart_id, created_by) 
VALUES ('xcash00','hard_password1234','Johnny','Cash','jognny.cash@vutbr.cz', 4200987654321, 2, 2);
UPDATE guests SET logged_as = 'xcash00' WHERE guest_id = 2;

---- První uživatel vkladá zboží do košíku
INSERT INTO items (product_id, cart_id, quantity, quantity_price)
VALUES (1,1,5, 5 * (SELECT unit_price FROM products WHERE product_id = 1));
INSERT INTO items (product_id, cart_id, quantity, quantity_price)
VALUES (2,1,12, 12 * (SELECT unit_price FROM products WHERE product_id = 2));

---- Druhý uživatel vkladá zboží do košíku
INSERT INTO items (product_id, cart_id, quantity, quantity_price)
VALUES (3,2,7, 7 * (SELECT unit_price FROM products WHERE product_id = 3));


---- První uživatel vyplnil kontaktní udaje (chce si objednat zboží)
INSERT INTO addresses (country, city_name, street, postal_code, customer_login)
VALUES ('Czech Republic', 'Brno','Bozetechova' ,'61200', 'xbrown00');
UPDATE customers SET address_id = 1;

---- Druhý uživatel píše review pro zboží
INSERT INTO feedbacks (customer_login, content, rating, product_id)
VALUES ('xcash00', 'Tasty apples I found here. I will have to make this feedback bigger in order to fit my constraint.', 4, 1);

---- První uživatel vytvořil objednávku
INSERT INTO orders (customer_login, address_id, status, total_price)
VALUES ('xbrown00', 1, 'pending', (SELECT SUM(quantity_price) FROM items WHERE cart_id = 1));

---- Po vytvoření objednávky vytvoří se platba kterou první uživatel musí uhradit
INSERT INTO payments (assigned_to,account_number, is_paid,order_id, total_price)
VALUES ('xbrown00','1234 3456 3456 3454',0, 1, (SELECT total_price FROM orders WHERE order_id = 1));

-- Príklad generalizace

INSERT INTO employees (employee_login,password, first_name, last_name, email) 
VALUES ('xwaits00', 'password123456', 'Tom', 'Waits', 'tom.waits@vutbr.cz');

INSERT INTO admins (admin_login, admin_position)
VALUES ('xwaits00','owner');

SELECT * FROM employees;

/