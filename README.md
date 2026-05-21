# Trader Joe's Retail Database & POS System

A fully normalized 31-table MySQL database and Bash CLI application simulating a complete retail supply chain. It features ACID-compliant checkouts, recursive categories, and complex SQL analytics for multiple user roles.

### Live Demo
![System Demo](assets/demo.gif)

---
### ER Diagram
Detailed ER Diagram
![ER](docs/TJ-ER-diagram.png)


## System Walkthrough 

### Main Menu
The entry point featuring role-based authentication and routing.
![Main Dashboard](assets/main-dashboard.jpg)

### 1. Customer & Checkout Experience (Web & Kiosk)
Handles active shopping carts, dynamic stock validation, and secure payment processing with historical price-locking.
* **Browsing the Webstore:**
  ![Webstore Demo](assets/webstore-demo.jpg)
* **Checkout & Payment:**
  ![Payment Demo](assets/payment-demo.jpg)
* **Customer Order History:**
  ![Order History](assets/order-history.jpg)

### 2. Store Manager Dashboard
Handles local store logistics, automated reordering, and supply chain tracking.
* **Low Inventory Alerts:**
  ![Manager Inventory](assets/store-manager-inventory.jpg)
* **Generating Purchase Orders:**
  ![Manager Reorder](assets/store-manager-reorder.jpg)
* **Receiving Pending Shipments:**
  ![Pending Shipments](assets/store-manager-receive-pending-shipments.jpg)
* **Cross-Merchandising Audit (Items in multiple aisles):**
  ![Cross Merchandising](assets/cross-merchandising.jpg)

### 3. Corporate Executive Analytics
Executes complex SQL aggregations, self-joins, and hierarchical rollups to drive business decisions.
* **Top Selling Products Overall:**
  ![Top Selling](assets/executive-analysis-top-selling.jpg)
* **Highest Performing Stores:**
  ![Highest Performing](assets/executive-analysis-highest-performing.jpg)
* **Brand Head-to-Head (e.g. Coke vs. Pepsi):**
  ![Brand Comparison](assets/brand-comparison.jpg)
* **Market Basket Analysis (Items bought together):**
  ![Market Basket Analysis](assets/market-basking.jpg)
* **Top Products by State / Store:**
  ![Top Products](assets/top-products.jpg)
* **Historical Price Variance Audit:**
  ![Historical Price Audit](assets/historical-price-audit.jpg)

---

## How to Run Locally

**1. Clone the repository:**

git clone [https://github.com/yourusername/trader-joes-pos-system.git](https://github.com/yourusername/trader-joes-pos-system.git)

2. Import the database:

mysql -u root -p < src/tj.sql

3. Configure credentials:
Rename src/.env.example to .env and insert your local MySQL root password.

4. Run the application:

chmod +x src/app.sh
./src/app.sh
