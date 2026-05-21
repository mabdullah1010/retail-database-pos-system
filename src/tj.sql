# Trader Joe's DATABASE

drop database if exists trader_joe;
create database trader_joe;
use trader_joe;

-- TABLE creation

create table brand (
    brand_id int auto_increment,
    brand_name varchar(255) not null,
    primary key (brand_id)
);

create table vendor (
    vendor_id int auto_increment,
    vendor_name varchar(255) not null,
    primary key (vendor_id)
);

create table shipment (
    shipment_id int auto_increment,
    delivery_date date not null,
    primary key (shipment_id)
);

create table store (
    store_id int auto_increment,
    primary key (store_id)
);

create table physical_store (
    store_id int not null,
    street varchar(255) not null,
    city varchar(100) not null,
    state char(2) not null,
    zip varchar(20) not null,
    operating_hours varchar(100),
    primary key (store_id),
    foreign key (store_id) references store(store_id)
);

create table web_store (
    store_id int not null,
    website_url varchar(255) not null,
    support_email varchar(255) not null,
    primary key (store_id),
    foreign key (store_id) references store(store_id)
);

create table customer (
    customer_id int auto_increment,
    first_name varchar(100),
    last_name varchar(100),
    email varchar(255),
    street varchar(255),
    city varchar(100),
    state char(2),
    zip varchar(20),
    primary key (customer_id)
);

create table category (
    category_id int auto_increment,
    category_name varchar(255) not null,
    parent_category_id int,
    primary key (category_id),
    foreign key (parent_category_id) references category(category_id)
);

create table product (
    upc varchar(15) not null,
    product_name varchar(255) not null,
    size decimal(10,2),
    unit_of_measure varchar(50),
    brand_id int not null,
    primary key (upc),
    foreign key (brand_id) references brand(brand_id)
);

create table edible_product (
    upc varchar(15) not null,
    serving_size varchar(100),
    calories_per_serving int,
    dietary_certifications varchar(255),
    primary key (upc),
    foreign key (upc) references product(upc)
);

create table non_edible_product (
    upc varchar(15) not null,
    hazmat_warning_required boolean default false,
    requires_assembly boolean default false,
    primary key (upc),
    foreign key (upc) references product(upc)
);

create table produce (
    upc varchar(15) not null,
    produce_type varchar(50),
    variety varchar(100),
    is_organic boolean default false,
    primary key (upc),
    foreign key (upc) references edible_product(upc)
);

create table dairy (
    upc varchar(15) not null,
    fat_percentage decimal(5,2),
    pasteurization_type varchar(100),
    primary key (upc),
    foreign key (upc) references edible_product(upc)
);

create table frozen_food (
    upc varchar(15) not null,
    defrost_instructions varchar(255),
    primary key (upc),
    foreign key (upc) references edible_product(upc)
);

create table meat_seafood (
    upc varchar(15) not null,
    animal_species varchar(100),
    cut_name varchar(100),
    primary key (upc),
    foreign key (upc) references edible_product(upc)
);

create table beverage (
    upc varchar(15) not null,
    packaging_type varchar(50),
    is_carbonated boolean default false,
    primary key (upc),
    foreign key (upc) references edible_product(upc)
);

create table snack (
    upc varchar(15) not null,
    snack_type varchar(100),
    primary_flavor varchar(100),
    primary key (upc),
    foreign key (upc) references edible_product(upc)
);

create table premade_meal (
    upc varchar(15) not null,
    cuisine_type varchar(100),
    prep_method varchar(255),
    primary key (upc),
    foreign key (upc) references edible_product(upc)
);

create table pantry_goods (
    upc varchar(15) not null,
    regional_origin varchar(100),
    primary key (upc),
    foreign key (upc) references edible_product(upc)
);

create table personal_care (
    upc varchar(15) not null,
    target_skin_type varchar(100),
    scent varchar(100),
    primary key (upc),
    foreign key (upc) references non_edible_product(upc)
);

create table floral (
    upc varchar(15) not null,
    bloom_stage varchar(100),
    toxicity_to_pets varchar(255),
    primary key (upc),
    foreign key (upc) references non_edible_product(upc)
);

create table cleaning_supply (
    upc varchar(15) not null,
    chemical_base varchar(100),
    surface_type varchar(100),
    primary key (upc),
    foreign key (upc) references non_edible_product(upc)
);

create table aisle (
    aisle_id int auto_increment,
    store_id int not null,
    aisle_identifier varchar(50) not null,
    primary key (aisle_id),
    foreign key (store_id) references physical_store(store_id)
);

create table product_placement_map (
    aisle_id int not null,
    upc varchar(15) not null,
    primary key (aisle_id, upc),
    foreign key (aisle_id) references aisle(aisle_id),
    foreign key (upc) references product(upc)
);

create table product_category_map (
    upc varchar(15) not null,
    category_id int not null,
    primary key (upc, category_id),
    foreign key (upc) references product(upc),
    foreign key (category_id) references category(category_id)
);

create table vendor_brand_map (
    vendor_id int not null,
    brand_id int not null,
    primary key (vendor_id, brand_id),
    foreign key (vendor_id) references vendor(vendor_id),
    foreign key (brand_id) references brand(brand_id)
);

create table inventory (
    store_id int not null,
    upc varchar(15) not null,
    quantity_on_hand int unsigned not null default 0,
    current_price decimal(10,2) not null,
    reorder_threshold int not null default 10,
    target_stock_level int not null default 50,
    primary key (store_id, upc),
    foreign key (store_id) references store(store_id),
    foreign key (upc) references product(upc)
);

create table shopping_cart (
    cart_id int auto_increment,
    store_id int not null,
    customer_id int null,
    created_timestamp datetime default current_timestamp,
    primary key (cart_id),
    foreign key (store_id) references store(store_id),
    foreign key (customer_id) references customer(customer_id)
);

create table cart_item (
    cart_id int not null,
    upc varchar(15) not null,
    quantity int not null,
    primary key (cart_id, upc),
    foreign key (cart_id) references shopping_cart(cart_id),
    foreign key (upc) references product(upc)
);

create table sale_transaction (
    transaction_id int auto_increment,
    store_id int not null,
    customer_id int null,
    transaction_date date not null,
    transaction_time time not null,
    total_amount decimal(10,2) not null,
    payment_method varchar(50) not null,
    tax_amount decimal(10,2) not null default 0.00,
    delivery_fee decimal(10,2) not null default 0.00,
    service_fee decimal(10,2) not null default 0.00,
    gratuity decimal(10,2) not null default 0.00,
    primary key (transaction_id),
    foreign key (store_id) references store(store_id),
    foreign key (customer_id) references customer(customer_id)
);

create table line_item (
    transaction_id int not null,
    upc varchar(15) not null,
    quantity_purchased int not null,
    unit_price_sold decimal(10,2) not null,
    primary key (transaction_id, upc),
    foreign key (transaction_id) references sale_transaction(transaction_id),
    foreign key (upc) references product(upc)
);

create table purchase_order (
    po_number int auto_increment,
    store_id int not null,
    vendor_id int not null,
    shipment_id int,
    order_date date not null,
    status varchar(50) not null,
    primary key (po_number),
    foreign key (store_id) references store(store_id),
    foreign key (vendor_id) references vendor(vendor_id),
    foreign key (shipment_id) references shipment(shipment_id)
);

create table po_line_item (
    po_number int not null,
    upc varchar(15) not null,
    quantity_ordered int not null,
    unit_cost decimal(10,2) not null,
    primary key (po_number, upc),
    foreign key (po_number) references purchase_order(po_number),
    foreign key (upc) references product(upc)
);

-- indexes
create index idx_sale_transaction_store on sale_transaction(store_id);
create index idx_sale_transaction_customer on sale_transaction(customer_id);
create index idx_sale_transaction_date on sale_transaction(transaction_date);
create index idx_line_item_upc on line_item(upc);
create index idx_inventory_upc on inventory(upc);
create index idx_physical_store_state on physical_store(state);
create index idx_shopping_cart_store on shopping_cart(store_id);
create index idx_shopping_cart_customer on shopping_cart(customer_id);

insert into brand (brand_id, brand_name) values
(1, 'Trader Joe''s Store Brand'),
(2, 'Coke'),
(3, 'Pepsi'),
(4, 'DairyPure'),
(5, 'Clorox'),
(6, 'Windex'),
(7, 'Chobani'),
(8, 'Tropicana'),
(9, 'Kind'),
(10, 'Dole');

insert into vendor (vendor_id, vendor_name) values
(100, 'National Fresh Produce Co.'),
(101, 'Global Household Supplies'),
(102, 'Beverage Distribution Inc.'),
(103, 'Dairy and Cold Chain Supply'),
(104, 'Frozen Foods Wholesale'),
(105, 'Snack Partners LLC');

insert into store (store_id) values (1), (2), (3), (4);

insert into physical_store (store_id, street, city, state, zip, operating_hours) values
(1, '405 E 59th Street', 'New York', 'NY', '10022', '8:00AM-9:00PM Daily'),
(2, '270 Mohegan Ave', 'New London', 'CT', '06320', '8:00AM-9:00PM Daily'),
(3, '1317 Beacon Street', 'Boston', 'MA', '02446', '8:00AM-9:00PM Daily');

insert into web_store (store_id, website_url, support_email) values
(4, 'https://www.traderjoes.com', 'support@traderjoes.com');

insert into customer (customer_id, first_name, last_name, email, street, city, state, zip) values
(5001, 'Muhammad', 'Abdullah', 'm.abdullah@email.com', '270 Mohegan Ave', 'New London', 'CT', '06320'),
(5002, 'Sammy', 'Smith', 'sammy.s@email.com', '405 E 59th St', 'New York', 'NY', '10022'),
(5003, 'Melanie', 'Fernandez', 'melanie.f@email.com', '123 Williams St', 'New London', 'CT', '06320'),
(5004, 'Jordan', 'Lee', 'jordan.lee@email.com', '77 Beacon St', 'Boston', 'MA', '02108'),
(5005, 'Avery', 'Patel', 'avery.patel@email.com', '14 Main St', 'Providence', 'RI', '02903');

insert into category (category_id, category_name, parent_category_id) values
(10, 'Food', null),
(11, 'Produce', 10),
(12, 'Beverage', 10),
(13, 'Dairy', 10),
(14, 'Frozen Food', 10),
(15, 'Snack', 10),
(16, 'Premade Meal', 10),
(17, 'Pantry Goods', 10),
(20, 'Non-Food', null),
(21, 'Cleaning Supplies', 20),
(22, 'Personal Care', 20),
(23, 'Floral', 20);

insert into product (upc, product_name, size, unit_of_measure, brand_id) values
('000000000000001', 'Whole Milk', 1.00, 'gallon', 4),
('000000000000002', 'Organic Bananas', 2.00, 'lb', 1),
('000000000000003', 'Honeycrisp Apples', 3.00, 'lb', 10),
('000000000000004', 'Coke Bottle', 2.00, 'liter', 2),
('000000000000005', 'Pepsi Bottle', 2.00, 'liter', 3),
('000000000000006', 'Greek Yogurt', 5.30, 'oz', 7),
('000000000000007', 'Orange Juice', 52.00, 'fl oz', 8),
('000000000000008', 'Frozen Mandarin Chicken', 22.00, 'oz', 1),
('000000000000009', 'Dark Chocolate Peanut Butter Cups', 16.00, 'oz', 1),
('000000000000010', 'Granola Bars', 6.00, 'bars', 9),
('000000000000011', 'Pasta Sauce', 24.00, 'oz', 1),
('000000000000012', 'Chicken Wrap', 1.00, 'each', 1),
('000000000000013', 'Glass Cleaner', 23.00, 'fl oz', 6),
('000000000000014', 'Disinfecting Wipes', 75.00, 'count', 5),
('000000000000015', 'Hand Soap', 12.00, 'fl oz', 1),
('000000000000016', 'Tulip Bouquet', 1.00, 'bunch', 1);

insert into edible_product (upc, serving_size, calories_per_serving, dietary_certifications) values
('000000000000001', '1 cup', 150, 'None'),
('000000000000002', '1 banana', 105, 'Organic'),
('000000000000003', '1 apple', 95, 'None'),
('000000000000004', '12 fl oz', 140, 'None'),
('000000000000005', '12 fl oz', 150, 'None'),
('000000000000006', '1 container', 120, 'Kosher'),
('000000000000007', '8 fl oz', 110, 'None'),
('000000000000008', '1 cup', 320, 'None'),
('000000000000009', '2 pieces', 190, 'None'),
('000000000000010', '1 bar', 180, 'Gluten Free'),
('000000000000011', '1/2 cup', 80, 'Vegan'),
('000000000000012', '1 wrap', 420, 'None');

insert into non_edible_product (upc, hazmat_warning_required, requires_assembly) values
('000000000000013', true, false),
('000000000000014', true, false),
('000000000000015', false, false),
('000000000000016', false, false);

insert into produce (upc, produce_type, variety, is_organic) values
('000000000000002', 'Fruit', 'Banana', true),
('000000000000003', 'Fruit', 'Honeycrisp', false);

insert into dairy (upc, fat_percentage, pasteurization_type) values
('000000000000001', 3.25, 'Pasteurized'),
('000000000000006', 2.00, 'Pasteurized');

insert into beverage (upc, packaging_type, is_carbonated) values
('000000000000004', 'Bottle', true),
('000000000000005', 'Bottle', true),
('000000000000007', 'Carton', false);

insert into frozen_food (upc, defrost_instructions) values
('000000000000008', 'Cook from frozen in oven or skillet');

insert into snack (upc, snack_type, primary_flavor) values
('000000000000009', 'Candy', 'Chocolate Peanut Butter'),
('000000000000010', 'Bar', 'Almond');

insert into pantry_goods (upc, regional_origin) values
('000000000000011', 'Italy');

insert into premade_meal (upc, cuisine_type, prep_method) values
('000000000000012', 'American', 'Ready to eat');

insert into cleaning_supply (upc, chemical_base, surface_type) values
('000000000000013', 'Ammonia', 'Glass and Window'),
('000000000000014', 'Bleach-free disinfectant', 'Multi-surface');

insert into personal_care (upc, target_skin_type, scent) values
('000000000000015', 'All skin types', 'Lavender');

insert into floral (upc, bloom_stage, toxicity_to_pets) values
('000000000000016', 'Fresh cut', 'Toxic to cats');

insert into product_category_map (upc, category_id) values
('000000000000001', 13), ('000000000000002', 11), ('000000000000003', 11),
('000000000000004', 12), ('000000000000005', 12), ('000000000000006', 13),
('000000000000007', 12), ('000000000000008', 14), ('000000000000009', 15),
('000000000000010', 15), ('000000000000011', 17), ('000000000000012', 16),
('000000000000013', 21), ('000000000000014', 21), ('000000000000015', 22),
('000000000000016', 23);

insert into vendor_brand_map (vendor_id, brand_id) values
(100, 1), (100, 10), (101, 5), (101, 6), (102, 2),
(102, 3), (102, 8), (103, 4), (103, 7), (104, 1),
(105, 1), (105, 9);

insert into aisle (aisle_id, store_id, aisle_identifier) values
(1, 1, 'Produce - Front'), (2, 1, 'Dairy and Beverages'), (3, 1, 'Frozen Food'), (4, 1, 'Snacks and Pantry'), (5, 1, 'Cleaning and Household'),
(6, 2, 'Produce - Front'), (7, 2, 'Dairy and Beverages'), (8, 2, 'Frozen Food'), (9, 2, 'Snacks and Pantry'), (10, 2, 'Cleaning and Household'),
(11, 3, 'Produce - Front'), (12, 3, 'Dairy and Beverages'), (13, 3, 'Frozen Food'), (14, 3, 'Snacks and Pantry'), (15, 3, 'Cleaning and Household');

insert into product_placement_map (aisle_id, upc) values
(1, '000000000000002'), (1, '000000000000003'),
(2, '000000000000001'), (2, '000000000000004'), (2, '000000000000005'), (2, '000000000000006'), (2, '000000000000007'),
(3, '000000000000008'),
(4, '000000000000009'), (4, '000000000000010'), (4, '000000000000011'), (4, '000000000000012'),
(5, '000000000000013'), (5, '000000000000014'), (5, '000000000000015'), (5, '000000000000016'),
(6, '000000000000002'), (6, '000000000000003'),
(7, '000000000000001'), (7, '000000000000004'), (7, '000000000000005'), (7, '000000000000006'), (7, '000000000000007'),
(8, '000000000000008'),
(9, '000000000000009'), (9, '000000000000010'), (9, '000000000000011'), (9, '000000000000012'),
(10, '000000000000013'), (10, '000000000000014'), (10, '000000000000015'), (10, '000000000000016'),
(11, '000000000000002'), (11, '000000000000003'),
(12, '000000000000001'), (12, '000000000000004'), (12, '000000000000005'), (12, '000000000000006'), (12, '000000000000007'),
(13, '000000000000008'),
(14, '000000000000009'), (14, '000000000000010'), (14, '000000000000011'), (14, '000000000000012'),
(15, '000000000000013'), (15, '000000000000014'), (15, '000000000000015'), (15, '000000000000016');

insert into inventory (store_id, upc, quantity_on_hand, current_price, reorder_threshold, target_stock_level) values
(1, '000000000000001', 42, 4.29, 15, 80), (1, '000000000000002', 120, 0.29, 30, 200), (1, '000000000000003', 65, 1.29, 25, 120),
(1, '000000000000004', 80, 2.49, 20, 150), (1, '000000000000005', 60, 2.39, 20, 150), (1, '000000000000006', 48, 1.49, 15, 80),
(1, '000000000000007', 35, 3.99, 15, 70), (1, '000000000000008', 20, 5.99, 10, 45), (1, '000000000000009', 90, 4.49, 20, 130),
(1, '000000000000010', 12, 5.99, 15, 60), (1, '000000000000011', 55, 2.99, 15, 80), (1, '000000000000012', 8, 4.99, 10, 35),
(1, '000000000000013', 18, 4.35, 10, 40), (1, '000000000000014', 9, 5.49, 10, 40), (1, '000000000000015', 22, 3.99, 10, 50),
(1, '000000000000016', 14, 6.99, 8, 30),

(2, '000000000000001', 55, 4.19, 15, 80), (2, '000000000000002', 140, 0.29, 30, 200), (2, '000000000000003', 70, 1.19, 25, 120),
(2, '000000000000004', 45, 2.49, 20, 150), (2, '000000000000005', 95, 2.39, 20, 150), (2, '000000000000006', 30, 1.49, 15, 80),
(2, '000000000000007', 40, 3.89, 15, 70), (2, '000000000000008', 25, 5.99, 10, 45), (2, '000000000000009', 100, 4.49, 20, 130),
(2, '000000000000010', 50, 5.99, 15, 60), (2, '000000000000011', 49, 2.99, 15, 80), (2, '000000000000012', 16, 4.99, 10, 35),
(2, '000000000000013', 11, 4.35, 10, 40), (2, '000000000000014', 15, 5.49, 10, 40), (2, '000000000000015', 23, 3.99, 10, 50),
(2, '000000000000016', 10, 6.99, 8, 30),

(3, '000000000000001', 35, 4.39, 15, 80), (3, '000000000000002', 110, 0.29, 30, 200), (3, '000000000000003', 85, 1.39, 25, 120),
(3, '000000000000004', 75, 2.59, 20, 150), (3, '000000000000005', 50, 2.49, 20, 150), (3, '000000000000006', 20, 1.59, 15, 80),
(3, '000000000000007', 12, 3.99, 15, 70), (3, '000000000000008', 18, 6.19, 10, 45), (3, '000000000000009', 88, 4.59, 20, 130),
(3, '000000000000010', 42, 6.09, 15, 60), (3, '000000000000011', 60, 3.09, 15, 80), (3, '000000000000012', 11, 5.09, 10, 35),
(3, '000000000000013', 20, 4.45, 10, 40), (3, '000000000000014', 7, 5.59, 10, 40), (3, '000000000000015', 30, 4.09, 10, 50),
(3, '000000000000016', 13, 7.09, 8, 30),

(4, '000000000000001', 500, 4.09, 100, 800), (4, '000000000000004', 650, 2.29, 100, 900), (4, '000000000000005', 620, 2.29, 100, 900),
(4, '000000000000008', 300, 5.79, 75, 500), (4, '000000000000009', 420, 4.29, 75, 600), (4, '000000000000010', 350, 5.79, 75, 500),
(4, '000000000000011', 410, 2.79, 75, 500), (4, '000000000000013', 260, 4.15, 60, 350), (4, '000000000000014', 300, 5.29, 60, 350),
(4, '000000000000015', 250, 3.79, 60, 350);

insert into shopping_cart (cart_id, store_id, customer_id) values
(1, 1, 5002), (2, 2, null);

insert into cart_item (cart_id, upc, quantity) values
(1, '000000000000001', 1), (1, '000000000000003', 2), (2, '000000000000004', 1);

insert into sale_transaction (transaction_id, store_id, customer_id, transaction_date, transaction_time, total_amount, payment_method, tax_amount, delivery_fee, service_fee, gratuity) values
(1001, 1, null, '2026-01-10', '09:15:00', 15.36, 'Cash', 0.89, 0.00, 0.00, 0.00),
(1002, 1, 5002, '2026-01-11', '13:20:00', 25.42, 'Visa Debit', 1.47, 0.00, 0.00, 0.00),
(1003, 1, 5003, '2026-02-03', '17:45:00', 31.95, 'Credit Card', 1.85, 0.00, 0.00, 0.00),
(1004, 1, null, '2026-02-19', '11:30:00', 18.72, 'Cash', 1.08, 0.00, 0.00, 0.00),
(1005, 1, 5001, '2026-03-07', '15:10:00', 38.26, 'Visa', 2.21, 0.00, 0.00, 0.00),
(1006, 1, null, '2026-03-21', '10:05:00', 13.82, 'Cash', 0.80, 0.00, 0.00, 0.00),
(1007, 1, 5004, '2026-04-02', '19:10:00', 45.12, 'Credit Card', 2.61, 0.00, 0.00, 0.00),
(1008, 1, null, '2026-04-08', '12:00:00', 21.71, 'Cash', 1.25, 0.00, 0.00, 0.00),
(2001, 2, 5001, '2026-01-12', '10:25:00', 22.30, 'Visa', 1.29, 0.00, 0.00, 0.00),
(2002, 2, null, '2026-01-18', '14:50:00', 17.06, 'Cash', 0.99, 0.00, 0.00, 0.00),
(2003, 2, 5003, '2026-02-09', '16:15:00', 28.88, 'Credit Card', 1.67, 0.00, 0.00, 0.00),
(2004, 2, null, '2026-02-25', '18:30:00', 19.39, 'Cash', 1.12, 0.00, 0.00, 0.00),
(2005, 2, 5005, '2026-03-10', '09:45:00', 42.51, 'Visa Debit', 2.46, 0.00, 0.00, 0.00),
(2006, 2, null, '2026-03-27', '13:05:00', 16.24, 'Cash', 0.94, 0.00, 0.00, 0.00),
(2007, 2, 5002, '2026-04-04', '17:20:00', 36.88, 'Credit Card', 2.13, 0.00, 0.00, 0.00),
(2008, 2, null, '2026-04-12', '11:35:00', 24.03, 'Cash', 1.39, 0.00, 0.00, 0.00),
(3001, 3, 5004, '2026-01-08', '08:55:00', 27.34, 'Visa', 1.58, 0.00, 0.00, 0.00),
(3002, 3, null, '2026-01-22', '12:40:00', 14.95, 'Cash', 0.86, 0.00, 0.00, 0.00),
(3003, 3, 5005, '2026-02-11', '18:05:00', 39.99, 'Credit Card', 2.31, 0.00, 0.00, 0.00),
(3004, 3, null, '2026-02-28', '15:30:00', 22.47, 'Cash', 1.30, 0.00, 0.00, 0.00),
(3005, 3, 5003, '2026-03-09', '11:20:00', 44.18, 'Visa Debit', 2.55, 0.00, 0.00, 0.00),
(3006, 3, null, '2026-03-30', '19:45:00', 17.92, 'Cash', 1.04, 0.00, 0.00, 0.00),
(3007, 3, 5002, '2026-04-05', '13:15:00', 34.75, 'Credit Card', 2.01, 0.00, 0.00, 0.00),
(3008, 3, null, '2026-04-15', '10:10:00', 20.61, 'Cash', 1.19, 0.00, 0.00, 0.00),
(4001, 4, 5001, '2026-02-10', '09:15:00', 65.30, 'Visa', 0.00, 3.99, 3.64, 5.64),
(4002, 4, 5003, '2026-03-22', '20:05:00', 58.40, 'Credit Card', 0.00, 3.99, 2.75, 4.50),
(4003, 4, 5005, '2026-04-11', '16:35:00', 73.25, 'Visa Debit', 0.00, 3.99, 3.50, 6.00);

insert into line_item (transaction_id, upc, quantity_purchased, unit_price_sold) values
(1001, '000000000000001', 2, 4.29), (1001, '000000000000004', 2, 2.49), (1001, '000000000000010', 1, 5.99),
(1002, '000000000000001', 1, 4.29), (1002, '000000000000003', 4, 1.29), (1002, '000000000000009', 2, 4.49), (1002, '000000000000013', 1, 4.35),
(1003, '000000000000004', 5, 2.49), (1003, '000000000000005', 1, 2.39), (1003, '000000000000008', 2, 5.99), (1003, '000000000000012', 1, 4.99),
(1004, '000000000000001', 1, 4.29), (1004, '000000000000002', 6, 0.29), (1004, '000000000000006', 3, 1.49), (1004, '000000000000009', 1, 4.49),
(1005, '000000000000004', 6, 2.49), (1005, '000000000000011', 3, 2.99), (1005, '000000000000014', 2, 5.49), (1005, '000000000000016', 1, 6.99),
(1006, '000000000000001', 1, 4.29), (1006, '000000000000010', 1, 5.99), (1006, '000000000000015', 1, 3.99),
(1007, '000000000000004', 7, 2.49), (1007, '000000000000005', 2, 2.39), (1007, '000000000000008', 2, 5.99), (1007, '000000000000009', 2, 4.49),
(1008, '000000000000001', 2, 4.29), (1008, '000000000000003', 3, 1.29), (1008, '000000000000012', 1, 4.99), (1008, '000000000000013', 1, 4.35),
(2001, '000000000000001', 2, 4.19), (2001, '000000000000005', 4, 2.39), (2001, '000000000000006', 2, 1.49),
(2002, '000000000000001', 1, 4.19), (2002, '000000000000004', 1, 2.49), (2002, '000000000000005', 3, 2.39), (2002, '000000000000010', 1, 5.99),
(2003, '000000000000005', 7, 2.39), (2003, '000000000000009', 2, 4.49), (2003, '000000000000011', 1, 2.99),
(2004, '000000000000001', 1, 4.19), (2004, '000000000000002', 8, 0.29), (2004, '000000000000007', 2, 3.89), (2004, '000000000000013', 1, 4.35),
(2005, '000000000000005', 8, 2.39), (2005, '000000000000008', 2, 5.99), (2005, '000000000000014', 1, 5.49), (2005, '000000000000016', 1, 6.99),
(2006, '000000000000001', 2, 4.19), (2006, '000000000000006', 2, 1.49), (2006, '000000000000010', 1, 5.99),
(2007, '000000000000004', 2, 2.49), (2007, '000000000000005', 7, 2.39), (2007, '000000000000009', 2, 4.49), (2007, '000000000000012', 1, 4.99),
(2008, '000000000000001', 1, 4.19), (2008, '000000000000003', 5, 1.19), (2008, '000000000000011', 2, 2.99), (2008, '000000000000015', 1, 3.99),
(3001, '000000000000001', 2, 4.39), (3001, '000000000000004', 3, 2.59), (3001, '000000000000007', 1, 3.99), (3001, '000000000000010', 1, 6.09),
(3002, '000000000000001', 1, 4.39), (3002, '000000000000005', 2, 2.49), (3002, '000000000000006', 2, 1.59),
(3003, '000000000000004', 6, 2.59), (3003, '000000000000008', 2, 6.19), (3003, '000000000000009', 2, 4.59),
(3004, '000000000000001', 2, 4.39), (3004, '000000000000002', 5, 0.29), (3004, '000000000000011', 2, 3.09), (3004, '000000000000013', 1, 4.45),
(3005, '000000000000004', 8, 2.59), (3005, '000000000000005', 1, 2.49), (3005, '000000000000014', 2, 5.59), (3005, '000000000000016', 1, 7.09),
(3006, '000000000000001', 1, 4.39), (3006, '000000000000003', 4, 1.39), (3006, '000000000000010', 1, 6.09),
(3007, '000000000000004', 5, 2.59), (3007, '000000000000008', 2, 6.19), (3007, '000000000000012', 1, 5.09),
(3008, '000000000000001', 2, 4.39), (3008, '000000000000006', 2, 1.59), (3008, '000000000000015', 1, 4.09),
(4001, '000000000000001', 4, 4.09), (4001, '000000000000004', 6, 2.29), (4001, '000000000000008', 3, 5.79), (4001, '000000000000010', 2, 5.79),
(4002, '000000000000005', 8, 2.29), (4002, '000000000000009', 4, 4.29), (4002, '000000000000011', 3, 2.79), (4002, '000000000000013', 2, 4.15),
(4003, '000000000000001', 3, 4.09), (4003, '000000000000004', 4, 2.29), (4003, '000000000000005', 3, 2.29), (4003, '000000000000014', 3, 5.29), (4003, '000000000000015', 2, 3.79);

insert into shipment (shipment_id, delivery_date) values
(8801, '2026-04-20'), (8802, '2026-04-22'), (8803, '2026-04-25');

insert into purchase_order (po_number, store_id, vendor_id, shipment_id, order_date, status) values
(9001, 1, 100, 8801, '2026-04-15', 'Delivered'),
(9002, 1, 105, null, '2026-04-24', 'Pending'),
(9003, 2, 102, 8802, '2026-04-17', 'Delivered'),
(9004, 3, 101, 8803, '2026-04-18', 'Shipped'),
(9005, 4, 103, null, '2026-04-24', 'Pending');

insert into po_line_item (po_number, upc, quantity_ordered, unit_cost) values
(9001, '000000000000002', 200, 0.12), (9001, '000000000000003', 100, 0.60),
(9002, '000000000000010', 80, 2.50),
(9003, '000000000000004', 120, 1.05), (9003, '000000000000005', 120, 1.00),
(9004, '000000000000014', 90, 2.20),
(9005, '000000000000001', 300, 2.10), (9005, '000000000000006', 150, 0.75);

alter table physical_store add column tax_rate decimal(5,4) not null default 0.0000;
update physical_store set tax_rate = 0.0887 where state = 'NY';
update physical_store set tax_rate = 0.0635 where state = 'CT'; 
update physical_store set tax_rate = 0.0625 where state = 'MA'; 

insert ignore into category (category_id, category_name, parent_category_id) values 
(18, 'meat & seafood', 10), (19, 'bakery', 10);

insert ignore into brand (brand_id, brand_name) values 
(12, 'frito-lay'), (13, 'general mills'), (14, 'ben & jerrys'), (15, 'kelloggs');

insert ignore into vendor (vendor_id, vendor_name) values 
(106, 'national meat providers'), (107, 'sweet snacks co');

insert ignore into vendor_brand_map (vendor_id, brand_id) values 
(105, 12), (105, 13), (104, 14), (105, 15);

insert ignore into product (upc, product_name, size, unit_of_measure, brand_id) values 
('000000000000017', 'baby spinach', 10.0, 'oz', 10),
('000000000000018', 'sharp cheddar cheese', 8.0, 'oz', 4),
('000000000000019', 'diet coke 12-pack', 144.0, 'fl oz', 2),
('000000000000020', 'pepsi zero 12-pack', 144.0, 'fl oz', 3),
('000000000000021', 'cold brew coffee', 32.0, 'fl oz', 1),
('000000000000022', 'doritos nacho cheese', 9.25, 'oz', 12),
('000000000000023', 'cauliflower gnocchi', 16.0, 'oz', 1),
('000000000000024', 'half baked ice cream', 16.0, 'oz', 14),
('000000000000025', 'honey nut cheerios', 10.8, 'oz', 13),
('000000000000026', 'frosted flakes', 13.5, 'oz', 15),
('000000000000027', 'organic marinara sauce', 24.0, 'oz', 1),
('000000000000028', 'penne pasta', 16.0, 'oz', 1),
('000000000000029', 'sparkling water (lime)', 12.0, 'fl oz', 1),
('000000000000030', 'avocados (bag of 4)', 4.0, 'count', 10),
('000000000000031', 'ruffles original', 8.0, 'oz', 12),
('000000000000032', 'fresh atlantic salmon', 1.0, 'lb', 1),
('000000000000033', 'ground beef 80/20', 1.0, 'lb', 1),
('000000000000034', 'chicken breast', 1.0, 'lb', 1),
('000000000000035', 'sourdough bread', 1.0, 'loaf', 1),
('000000000000036', 'mozzarella sticks', 16.0, 'oz', 1);

insert ignore into product_category_map (upc, category_id) values 
('000000000000017', 11), ('000000000000018', 13), ('000000000000019', 12),
('000000000000020', 12), ('000000000000021', 12), ('000000000000022', 15),
('000000000000023', 14), ('000000000000024', 14), ('000000000000025', 17),
('000000000000026', 17), ('000000000000027', 17), ('000000000000028', 17),
('000000000000029', 12), ('000000000000030', 11), ('000000000000031', 15),
('000000000000032', 18), ('000000000000033', 18), ('000000000000034', 18),
('000000000000035', 17), ('000000000000036', 14);

insert ignore into edible_product (upc, serving_size, calories_per_serving, dietary_certifications) values 
('000000000000017', '1 cup', 10, 'vegan'), ('000000000000018', '1 oz', 110, 'none'),
('000000000000019', '1 can', 0, 'none'), ('000000000000020', '1 can', 0, 'none'),
('000000000000021', '8 fl oz', 15, 'vegan'), ('000000000000022', '1 oz', 150, 'none'),
('000000000000023', '1 cup', 140, 'gluten free'), ('000000000000024', '2/3 cup', 270, 'none'),
('000000000000025', '1 cup', 140, 'none'), ('000000000000026', '1 cup', 130, 'none'),
('000000000000027', '1/2 cup', 70, 'organic, vegan'), ('000000000000028', '2 oz', 200, 'none'),
('000000000000029', '1 can', 0, 'none'), ('000000000000030', '1/3 avocado', 80, 'none'),
('000000000000031', '1 oz', 160, 'none'), ('000000000000032', '4 oz', 230, 'none'),
('000000000000033', '4 oz', 280, 'none'), ('000000000000034', '4 oz', 120, 'none'),
('000000000000035', '1 slice', 110, 'none'), ('000000000000036', '3 pieces', 210, 'none');

insert ignore into produce (upc, produce_type, variety, is_organic) values 
('000000000000017', 'vegetable', 'spinach', true), ('000000000000030', 'fruit', 'hass avocado', false);

insert ignore into dairy (upc, fat_percentage, pasteurization_type) values 
('000000000000018', 33.00, 'pasteurized');

insert ignore into beverage (upc, packaging_type, is_carbonated) values 
('000000000000019', 'can', true), ('000000000000020', 'can', true),
('000000000000021', 'bottle', false), ('000000000000029', 'can', true);

insert ignore into snack (upc, snack_type, primary_flavor) values 
('000000000000022', 'chips', 'nacho cheese'), ('000000000000031', 'chips', 'salt');

insert ignore into frozen_food (upc, defrost_instructions) values 
('000000000000023', 'cook from frozen in skillet'), ('000000000000024', 'keep frozen until serving'),
('000000000000036', 'bake in oven at 400f for 10 mins');

insert ignore into pantry_goods (upc, regional_origin) values 
('000000000000025', 'usa'), ('000000000000026', 'usa'), ('000000000000027', 'italy'),
('000000000000028', 'italy'), ('000000000000035', 'usa');

insert ignore into meat_seafood (upc, animal_species, cut_name) values 
('000000000000032', 'salmon', 'fillet'), ('000000000000033', 'cow', 'ground'),
('000000000000034', 'chicken', 'breast');

insert ignore into product_placement_map (aisle_id, upc) values
(1, '000000000000017'), (1, '000000000000030'), (2, '000000000000018'), (2, '000000000000019'), (2, '000000000000020'), (2, '000000000000021'), (2, '000000000000029'), (2, '000000000000032'), (2, '000000000000033'), (2, '000000000000034'),
(3, '000000000000023'), (3, '000000000000024'), (3, '000000000000036'), (4, '000000000000022'), (4, '000000000000025'), (4, '000000000000026'), (4, '000000000000027'), (4, '000000000000028'), (4, '000000000000031'), (4, '000000000000035'),
(4, '000000000000030'), (3, '000000000000027'),
(6, '000000000000017'), (6, '000000000000030'), (7, '000000000000018'), (7, '000000000000019'), (7, '000000000000020'), (7, '000000000000021'), (7, '000000000000029'), (7, '000000000000032'), (7, '000000000000033'), (7, '000000000000034'),
(8, '000000000000023'), (8, '000000000000024'), (8, '000000000000036'), (9, '000000000000022'), (9, '000000000000025'), (9, '000000000000026'), (9, '000000000000027'), (9, '000000000000028'), (9, '000000000000031'), (9, '000000000000035'),
(9, '000000000000030'), (8, '000000000000027'),
(11, '000000000000017'), (11, '000000000000030'), (12, '000000000000018'), (12, '000000000000019'), (12, '000000000000020'), (12, '000000000000021'), (12, '000000000000029'), (12, '000000000000032'), (12, '000000000000033'), (12, '000000000000034'),
(13, '000000000000023'), (13, '000000000000024'), (13, '000000000000036'), (14, '000000000000022'), (14, '000000000000025'), (14, '000000000000026'), (14, '000000000000027'), (14, '000000000000028'), (14, '000000000000031'), (14, '000000000000035'),
(14, '000000000000030'), (13, '000000000000027');

insert ignore into inventory (store_id, upc, quantity_on_hand, current_price, reorder_threshold, target_stock_level) values
(1, '000000000000017', 80, 2.99, 20, 100), (1, '000000000000018', 45, 3.49, 15, 60), (1, '000000000000020', 60, 6.99, 20, 120),
(1, '000000000000021', 40, 4.99, 15, 80), (1, '000000000000022', 90, 4.29, 25, 150), (1, '000000000000023', 55, 3.99, 20, 100),
(1, '000000000000025', 40, 3.99, 15, 60), (1, '000000000000026', 35, 3.99, 15, 60), (1, '000000000000027', 75, 2.49, 20, 100),
(1, '000000000000028', 85, 1.49, 20, 150), (1, '000000000000029', 65, 4.99, 20, 100), (1, '000000000000030', 50, 4.99, 15, 80),
(1, '000000000000031', 80, 4.29, 25, 150), (1, '000000000000033', 30, 5.99, 10, 50), (1, '000000000000034', 40, 4.99, 15, 60),
(1, '000000000000035', 25, 3.49, 10, 40), (1, '000000000000036', 45, 4.99, 15, 80),
(1, '000000000000019', 4, 6.99, 20, 120), (1, '000000000000024', 2, 4.49, 15, 50), (1, '000000000000032', 0, 9.99, 10, 30),

(2, '000000000000017', 70, 2.99, 20, 100), (2, '000000000000018', 50, 3.49, 15, 60), (2, '000000000000019', 55, 6.99, 20, 120),
(2, '000000000000021', 45, 4.99, 15, 80), (2, '000000000000022', 85, 4.29, 25, 150), (2, '000000000000023', 60, 3.99, 20, 100),
(2, '000000000000024', 30, 4.49, 15, 50), (2, '000000000000026', 40, 3.99, 15, 60), (2, '000000000000027', 80, 2.49, 20, 100),
(2, '000000000000028', 90, 1.49, 20, 150), (2, '000000000000029', 70, 4.99, 20, 100), (2, '000000000000031', 85, 4.29, 25, 150),
(2, '000000000000032', 20, 9.99, 10, 30), (2, '000000000000033', 35, 5.99, 10, 50), (2, '000000000000034', 45, 4.99, 15, 60),
(2, '000000000000035', 30, 3.49, 10, 40), (2, '000000000000036', 50, 4.99, 15, 80),
(2, '000000000000020', 5, 6.99, 20, 120), (2, '000000000000025', 3, 3.99, 15, 60), (2, '000000000000030', 8, 4.99, 15, 80),

(3, '000000000000017', 75, 2.99, 20, 100), (3, '000000000000018', 48, 3.49, 15, 60), (3, '000000000000019', 65, 6.99, 20, 120),
(3, '000000000000020', 60, 6.99, 20, 120), (3, '000000000000021', 42, 4.99, 15, 80), (3, '000000000000023', 58, 3.99, 20, 100),
(3, '000000000000024', 35, 4.49, 15, 50), (3, '000000000000025', 45, 3.99, 15, 60), (3, '000000000000026', 38, 3.99, 15, 60),
(3, '000000000000027', 78, 2.49, 20, 100), (3, '000000000000028', 88, 1.49, 20, 150), (3, '000000000000029', 68, 4.99, 20, 100),
(3, '000000000000030', 55, 4.99, 15, 80), (3, '000000000000031', 82, 4.29, 25, 150), (3, '000000000000032', 25, 9.99, 10, 30),
(3, '000000000000033', 32, 5.99, 10, 50), (3, '000000000000034', 42, 4.99, 15, 60), (3, '000000000000036', 48, 4.99, 15, 80),
(3, '000000000000022', 12, 4.29, 25, 150), (3, '000000000000035', 1, 3.49, 10, 40),

(4, '000000000000017', 500, 2.99, 100, 1000), (4, '000000000000018', 400, 3.49, 100, 800), (4, '000000000000019', 600, 6.99, 150, 1200),
(4, '000000000000020', 600, 6.99, 150, 1200), (4, '000000000000021', 300, 4.99, 80, 500), (4, '000000000000022', 800, 4.29, 200, 1500),
(4, '000000000000023', 450, 3.99, 100, 800), (4, '000000000000024', 350, 4.49, 80, 600), (4, '000000000000025', 400, 3.99, 100, 800),
(4, '000000000000026', 400, 3.99, 100, 800), (4, '000000000000027', 600, 2.49, 150, 1000), (4, '000000000000028', 700, 1.49, 150, 1200),
(4, '000000000000029', 500, 4.99, 100, 800), (4, '000000000000030', 300, 4.99, 80, 600), (4, '000000000000031', 800, 4.29, 200, 1500),
(4, '000000000000032', 150, 9.99, 50, 300), (4, '000000000000033', 250, 5.99, 80, 500), (4, '000000000000034', 350, 4.99, 100, 700),
(4, '000000000000035', 200, 3.49, 50, 400), (4, '000000000000036', 400, 4.99, 100, 800);

insert ignore into sale_transaction (transaction_id, store_id, customer_id, transaction_date, transaction_time, total_amount, payment_method, tax_amount, delivery_fee) values 
(50001, 1, null, '2024-03-15', '14:30:00', 45.20, 'credit card', 3.20, 0.00), (50002, 2, 5001, '2024-06-22', '09:15:00', 112.50, 'visa', 8.50, 0.00),
(50003, 3, null, '2024-08-10', '18:45:00', 38.75, 'cash', 2.75, 0.00), (50004, 4, 5002, '2024-11-05', '11:20:00', 215.80, 'credit card', 15.80, 3.99),
(50005, 1, 5005, '2024-12-20', '16:05:00', 89.90, 'debit', 6.90, 0.00), (60001, 1, null, '2025-02-14', '17:30:00', 68.45, 'credit card', 4.85, 0.00),
(60002, 1, 5004, '2025-04-18', '12:10:00', 135.60, 'visa', 9.60, 0.00), (60003, 2, null, '2025-07-04', '08:45:00', 95.20, 'cash', 6.20, 0.00),
(60004, 3, 5003, '2025-09-12', '19:25:00', 142.30, 'credit card', 9.80, 0.00), (60005, 4, 5001, '2025-10-31', '22:15:00', 310.45, 'credit card', 22.45, 3.99),
(60006, 4, 5005, '2025-11-25', '14:50:00', 425.99, 'visa', 31.00, 3.99), (60007, 3, null, '2025-12-24', '16:40:00', 210.00, 'cash', 14.00, 0.00),
(70001, 1, 5002, '2026-01-05', '10:30:00', 185.50, 'credit card', 13.50, 0.00), (70002, 1, null, '2026-01-18', '13:15:00', 92.40, 'cash', 6.40, 0.00),
(70003, 2, 5005, '2026-02-14', '17:45:00', 215.60, 'visa', 15.60, 0.00), (70004, 3, 5004, '2026-02-28', '09:20:00', 340.20, 'credit card', 24.20, 0.00),
(70005, 4, 5001, '2026-03-10', '21:05:00', 510.75, 'credit card', 36.75, 3.99), (70006, 4, 5003, '2026-03-22', '11:50:00', 480.90, 'visa', 34.90, 3.99),
(70007, 3, null, '2026-04-05', '15:30:00', 125.00, 'cash', 9.00, 0.00), (70008, 1, 5002, '2026-04-12', '18:10:00', 275.30, 'debit', 19.30, 0.00),
(70009, 2, null, '2026-04-25', '14:40:00', 155.80, 'cash', 10.80, 0.00), (70010, 4, 5005, '2026-05-01', '08:15:00', 620.00, 'credit card', 45.00, 3.99);

insert ignore into line_item (transaction_id, upc, quantity_purchased, unit_price_sold) values 
(50001, '000000000000019', 4, 6.99), (50001, '000000000000031', 2, 4.29),
(50002, '000000000000032', 5, 9.99), (50002, '000000000000017', 4, 2.99),
(50003, '000000000000020', 3, 6.99), (50003, '000000000000022', 2, 4.29),
(50004, '000000000000033', 10, 5.99), (50004, '000000000000027', 10, 2.49),
(50005, '000000000000024', 5, 4.49), (50005, '000000000000025', 4, 3.99),
(60001, '000000000000019', 6, 6.99), (60001, '000000000000036', 3, 4.99),
(60002, '000000000000032', 8, 9.99),
(60003, '000000000000034', 10, 4.99), (60003, '000000000000028', 5, 1.49),
(60004, '000000000000020', 8, 6.99), (60004, '000000000000023', 5, 3.99),
(60005, '000000000000018', 20, 3.49), (60005, '000000000000030', 15, 4.99),
(60006, '000000000000033', 25, 5.99), (60006, '000000000000035', 10, 3.49),
(60007, '000000000000020', 12, 6.99), (60007, '000000000000024', 6, 4.49),
(70001, '000000000000019', 10, 6.99), (70001, '000000000000032', 5, 9.99),
(70002, '000000000000026', 8, 3.99), (70002, '000000000000027', 6, 2.49),
(70003, '000000000000033', 15, 5.99), (70003, '000000000000030', 10, 4.99),
(70004, '000000000000020', 15, 6.99), (70004, '000000000000034', 20, 4.99),
(70005, '000000000000017', 30, 2.99), (70005, '000000000000018', 25, 3.49),
(70006, '000000000000022', 40, 4.29), (70006, '000000000000029', 20, 4.99),
(70007, '000000000000020', 5, 6.99), (70007, '000000000000023', 8, 3.99),
(70008, '000000000000019', 12, 6.99), (70008, '000000000000036', 15, 4.99),
(70009, '000000000000024', 10, 4.49), (70009, '000000000000031', 12, 4.29),
(70010, '000000000000032', 30, 9.99), (70010, '000000000000035', 20, 3.49);

-- Fixes all receipts
update sale_transaction st
join (
    select transaction_id, sum(quantity_purchased * unit_price_sold) as actual_product_total
    from line_item
    group by transaction_id
) li_totals on st.transaction_id = li_totals.transaction_id
set st.total_amount = li_totals.actual_product_total + st.tax_amount + st.delivery_fee + st.service_fee + st.gratuity;