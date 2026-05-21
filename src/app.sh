#!/bin/bash

clear
echo "====================================="
echo "    SYSTEM INITIALIZATION            "
echo "====================================="


source .env


echo "connecting to $DB_NAME as $DB_USER..."
export MYSQL_PWD="$DB_PASS"

run_query() {
    mysql -u "$DB_USER" -D "$DB_NAME" -t -e "$1"
}


# customer interface (webstore)

customer_menu() {
    clear
    echo "====================================="
    echo "    TRADER JOE'S ONLINE DELIVERY     "
    echo "====================================="
    
    session_cust_id=""
    cust_name=""
    
    while [ -z "$cust_name" ]; do
        read -p "Enter your Customer ID (Hint: Try 5002 or 5004): " session_cust_id
        session_cust_id=$(echo "$session_cust_id" | tr -d '\r' | xargs)
        
        cust_name=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select concat(first_name, ' ', last_name) from customer where customer_id = '$session_cust_id';")
        
        if [ -z "$cust_name" ]; then
            echo "Invalid customer ID. Try again."
        fi
    done
    
    cust_street=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select street from customer where customer_id = '$session_cust_id';")
    cust_city_state=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select concat(city, ', ', state, ' ', zip) from customer where customer_id = '$session_cust_id';")
    
    cust_greeting="Welcome back, $cust_name!"
    run_query "delete from cart_item where cart_id = 888;"
    run_query "insert ignore into shopping_cart (cart_id, store_id, customer_id) values (888, 4, $session_cust_id);"
    
    while true; do
        clear
        echo "====================================="
        echo "   WEBSTORE (Welcome, $cust_greeting)  "
        echo "====================================="
        echo "1. Browse Catalog & Add items to cart"
        echo "2. View cart & checkout (Tip & Tax)"
        echo "3. View my order history"
        echo "4. Logout"
        echo "====================================="
        read -p "Select an option (1-4): " web_choice
        web_choice=$(echo "$web_choice" | tr -d '\r' | xargs)

        case $web_choice in
            1)
                echo -e "\n--- STORE DEPARTMENTS ---"

                run_query "select category_id, category_name from category where parent_category_id is not null order by category_name;"
                
                while true; do
                    read -p "Enter department ID to browse (or press Enter to view all) - (Try option: 12): " dept_id
                    dept_id=$(echo "$dept_id" | tr -d '\r' | xargs)
                    if [ -z "$dept_id" ]; then
                        break
                    elif [[ "$dept_id" =~ ^[0-9]+$ ]]; then
                        break
                    else
                        echo "ERROR: department ID must be a number."
                    fi
                done
                
                echo -e "\n--- ONLINE CATALOG ---"
                if [ -n "$dept_id" ]; then
                    run_query "select p.upc, p.product_name, concat(p.size, ' ', p.unit_of_measure) as unit_size, 
                               i.current_price as price, coalesce(ep.dietary_certifications, 'N/A') as diet_certs, 
                               case when pr.is_organic = 1 then 'Yes' when pr.is_organic = 0 then 'No' else 'N/A' end as organic
                               from inventory i join product p on i.upc = p.upc 
                               join product_category_map pcm on p.upc = pcm.upc
                               left join edible_product ep on p.upc = ep.upc
                               left join produce pr on p.upc = pr.upc
                               where i.store_id = 4 and i.quantity_on_hand > 0 and pcm.category_id = $dept_id;"
                else
                    run_query "select p.upc, p.product_name, concat(p.size, ' ', p.unit_of_measure) as unit_size, 
                               i.current_price as price, coalesce(ep.dietary_certifications, 'N/A') as diet_certs, 
                               case when pr.is_organic = 1 then 'Yes' when pr.is_organic = 0 then 'No' else 'N/A' end as organic
                               from inventory i join product p on i.upc = p.upc 
                               left join edible_product ep on p.upc = ep.upc
                               left join produce pr on p.upc = pr.upc
                               where i.store_id = 4 and i.quantity_on_hand > 0 limit 15;"
                fi
                
                read -p "Enter UPC to add to cart (or press Enter to cancel): " input_upc
                input_upc=$(echo "$input_upc" | tr -d '\r' | xargs)
                
                if [ -n "$input_upc" ]; then
                    while true; do
                        read -p "Enter Quantity: " input_qty
                        input_qty=$(echo "$input_qty" | tr -d '\r' | xargs)
                        
                        if [[ "$input_qty" =~ ^[1-9][0-9]*$ ]]; then
                            break
                        else
                            echo "ERROR: Quantity must be a whole number greater than zero"
                        fi
                    done
                    
                    # prevent overselling
                    avail_qty=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select quantity_on_hand from inventory where upc = '$input_upc' and store_id = 4;")
                    in_cart=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select coalesce(sum(quantity), 0) from cart_item where cart_id = 888 and upc = '$input_upc';")
                    total_requested=$((input_qty + in_cart))
                    
                    if [ -z "$avail_qty" ]; then
                        echo "ERROR: UPC '$input_upc' not found in inventory."
                    elif [ "$total_requested" -gt "$avail_qty" ]; then
                        echo "ERROR: Insufficient stock. Only $avail_qty available (you already have $in_cart in your cart)."
                    else
                        query="insert into cart_item (cart_id, upc, quantity) 
                               values (888, '$input_upc', $input_qty) 
                               on duplicate key update quantity = quantity + $input_qty;"
                        run_query "$query"
                        echo "Added to cart..."
                    fi
                fi
                read -p "Press [Enter] to continue..."
                ;;
            2)
                echo -e "\n--- YOUR SHOPPING CART ---"
                
                #empty the cart
                cart_count=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select count(*) from cart_item where cart_id = 888;")
                if [ "$cart_count" -eq 0 ]; then
                    echo "Your cart is empty!"
                    read -p "Press [Enter] to return to menu..."
                    continue
                fi
                
                run_query "select p.product_name, c.quantity, i.current_price, (c.quantity * i.current_price) as line_total 
                           from cart_item c join product p on c.upc = p.upc join inventory i on c.upc = i.upc 
                           where c.cart_id = 888 and i.store_id = 4;"


                echo -e "\n--- SELECT DRIVER TIP ---"

                echo "1. 0%  (No Tip)"
                echo "2. 10% (Good)"
                echo "3. 15% (Great)"
                echo "4. 20% (Excellent)"
                
                read -p "Choose tip amount (1-4): " tip_choice

                tip_choice=$(echo "$tip_choice" | tr -d '\r' | xargs)
                
                case $tip_choice in
                    1) tip_pct=0.00 ;;
                    2) tip_pct=0.10 ;;
                    3) tip_pct=0.15 ;;
                    4) tip_pct=0.20 ;;
                    *) tip_pct=0.15 ;;

                esac
                
                echo -e "\n========================================="
                echo "           FINAL RECEIPT                 "
                echo "========================================="
                echo "SHIPPING TO:"

                echo "$cust_name"
                echo "$cust_street"
                echo "$cust_city_state"

                echo "-----------------------------------------"
                
                query="select 
                       sum(c.quantity * i.current_price) as 'Subtotal',
                       round(sum(c.quantity * i.current_price) * 0.075, 2) as 'Tax (7.5%)',
                       3.99 as 'Delivery Fee',
                       round(sum(c.quantity * i.current_price) * $tip_pct, 2) as 'Driver Tip',
                       round(sum(c.quantity * i.current_price) * 1.075 + 3.99 + (sum(c.quantity * i.current_price) * $tip_pct), 2) as 'GRAND TOTAL'
                       from cart_item c join inventory i on c.upc = i.upc 
                       where c.cart_id = 888 and i.store_id = 4;"

                run_query "$query"

                echo "========================================="
                


                read -p "Type 'PAY' to checkout, or press Enter to go back: " checkout_cmd
                checkout_cmd=$(echo "$checkout_cmd" | tr -d '\r' | xargs)

                
                if [ "$checkout_cmd" = "PAY" ] || [ "$checkout_cmd" = "pay" ]; then
                    
                    #checkout validation
                    oversold=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select count(*) from cart_item c join inventory i on c.upc = i.upc and i.store_id = 4 where c.cart_id = 888 and c.quantity > i.quantity_on_hand;")
                    if [ "$oversold" -gt 0 ]; then
                        echo "ERROR: checkout failed! another customer just bought the last of an item in your cart."
                        echo "Please remove out-of-stock items before paying."
                    else
                        echo "Processing credit card..."
                        sleep 1
                        
                        checkout_query="set sql_safe_updates = 0;
                        start transaction;
                        insert into sale_transaction (store_id, customer_id, transaction_date, transaction_time, total_amount, payment_method, tax_amount, delivery_fee, service_fee, gratuity)
                        select 4, $session_cust_id, curdate(), curtime(), 
                        round(sum(c.quantity * i.current_price) * 1.075 + 3.99 + (sum(c.quantity * i.current_price) * $tip_pct), 2), 
                        'Credit Card', round(sum(c.quantity * i.current_price) * 0.075, 2), 3.99, 0.00, round(sum(c.quantity * i.current_price) * $tip_pct, 2)
                        from cart_item c join inventory i on c.upc = i.upc where c.cart_id = 888 and i.store_id = 4;
                        
                        set @new_tx = last_insert_id();
                        
                        insert into line_item (transaction_id, upc, quantity_purchased, unit_price_sold)
                        select @new_tx, c.upc, c.quantity, i.current_price 
                        from cart_item c join inventory i on c.upc = i.upc where c.cart_id = 888 and i.store_id = 4;
                        
                        update inventory i join cart_item c on i.upc = c.upc 
                        set i.quantity_on_hand = i.quantity_on_hand - c.quantity where c.cart_id = 888 and i.store_id = 4;
                        
                        delete from cart_item where cart_id = 888;
                        commit;
                        set sql_safe_updates = 1;"
                        

                        run_query "$checkout_query"

                        echo "Order Confirmed! Your items are on the way and have been added to your order history."
                    fi
                fi
                read -p "Press [Enter] to continue..."
                ;;
            3)

                echo -e "\n--- YOUR ORDER HISTORY ---"

                query="select st.transaction_date, p.product_name, li.quantity_purchased, li.unit_price_sold 
                       from sale_transaction st join line_item li on st.transaction_id = li.transaction_id 
                       join product p on li.upc = p.upc 
                       where st.customer_id = $session_cust_id order by st.transaction_date desc;"
                run_query "$query"

                read -p "Press [Enter] to continue..."
                ;;
            4)
                run_query "delete from cart_item where cart_id = 888;"
                return
                ;;
            *)
                echo "Invalid option."
                sleep 1
                ;;
        esac
    done
}

# ==========================================
# instore self checkout kiosk
# ==========================================
instore_kiosk_menu() {
    clear
    echo "====================================="
    echo "       INSTORE KIOSK TERMINAL       "
    echo "====================================="
    
    while true; do
        read -p "Enter the Store ID for this Kiosk (e.g., 1, 2, or 3): " kiosk_store_id
        kiosk_store_id=$(echo "$kiosk_store_id" | tr -d '\r' | xargs)
        if [[ "$kiosk_store_id" =~ ^[1-9][0-9]*$ ]]; then
            break
        else
            echo "ERROR: Store ID must be a valid positive number."
        fi
    done
    
    read -p "Enter your Customer ID (or press Enter to shop as Guest): " session_cust_id
    session_cust_id=$(echo "$session_cust_id" | tr -d '\r' | xargs)
    
    if [ -z "$session_cust_id" ]; then
        session_cust_id="NULL"
        cust_greeting="Guest Shopper"
        receipt_name="Guest"
    else
        # Validate the ID and get the name
        cust_name=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select concat(first_name, ' ', last_name) from customer where customer_id = '$session_cust_id';")
        
        if [ -z "$cust_name" ]; then
            session_cust_id="NULL"
            cust_greeting="Guest Shopper (Invalid ID)"
            receipt_name="Guest"
        else
            cust_greeting="$cust_name"
            receipt_name="$cust_name"
        fi
    fi
    
    run_query "delete from cart_item where cart_id = 777;"
    run_query "insert ignore into shopping_cart (cart_id, store_id, customer_id) values (777, $kiosk_store_id, $session_cust_id);"

    while true; do
        clear
        echo "====================================="
        echo "   TRADER JOE'S KIOSK (STORE $kiosk_store_id) "
        echo "   Welcome, $cust_greeting!"
        echo "====================================="
        echo "1. View Store Catalog & Item Locator"
        echo "2. Scan Item (Add to Cart)"
        echo "3. View Current Cart"
        echo "4. Checkout, Pay & Print Receipt"
        echo "5. Cancel & Walk Away"
        echo "====================================="
        read -p "Select an option (1-5): " kiosk_choice
        kiosk_choice=$(echo "$kiosk_choice" | tr -d '\r' | xargs)

        case $kiosk_choice in
            1)
                echo -e "\n--- STORE DEPARTMENTS ---"
                run_query "select category_id, category_name from category where parent_category_id is not null order by category_name;"
                
                while true; do
                    read -p "Enter Department ID to browse (or press Enter to view all): " dept_id
                    dept_id=$(echo "$dept_id" | tr -d '\r' | xargs)
                    if [ -z "$dept_id" ]; then
                        break
                    elif [[ "$dept_id" =~ ^[0-9]+$ ]]; then
                        break
                    else
                        echo "ERROR: Department ID must be a number."
                    fi
                done
                
                echo -e "\n--- LOCAL STORE CATALOG & MAP ---"


                if [ -n "$dept_id" ]; then

                    query="select p.upc, p.product_name, concat(p.size, ' ', p.unit_of_measure) as unit_size, 
                           i.current_price as price, coalesce(ep.dietary_certifications, 'N/A') as diet_certs, 
                           group_concat(distinct a.aisle_identifier separator ' & ') as located_in 
                           from inventory i join product p on i.upc = p.upc 
                           join product_category_map pcm on p.upc = pcm.upc
                           left join edible_product ep on p.upc = ep.upc
                           join product_placement_map ppm on p.upc = ppm.upc 
                           join aisle a on ppm.aisle_id = a.aisle_id 
                           where i.store_id = $kiosk_store_id and a.store_id = $kiosk_store_id and i.quantity_on_hand > 0 and pcm.category_id = $dept_id
                           group by p.upc, p.product_name, p.size, p.unit_of_measure, ep.dietary_certifications, i.current_price;"
                else

                    query="select p.upc, p.product_name, concat(p.size, ' ', p.unit_of_measure) as unit_size, 
                           i.current_price as price, coalesce(ep.dietary_certifications, 'N/A') as diet_certs, 
                           group_concat(distinct a.aisle_identifier separator ' & ') as located_in 
                           from inventory i join product p on i.upc = p.upc 
                           left join edible_product ep on p.upc = ep.upc
                           join product_placement_map ppm on p.upc = ppm.upc 
                           join aisle a on ppm.aisle_id = a.aisle_id 
                           where i.store_id = $kiosk_store_id and a.store_id = $kiosk_store_id and i.quantity_on_hand > 0 
                           group by p.upc, p.product_name, p.size, p.unit_of_measure, ep.dietary_certifications, i.current_price limit 15;"
                fi
                run_query "$query"
                read -p "Press [Enter] to return to menu..."
                ;;
            2)

                echo -e "\n--- SCAN ITEM ---"
                read -p "Enter Product UPC: " input_upc
                input_upc=$(echo "$input_upc" | tr -d '\r' | xargs)
                
                if [ -n "$input_upc" ]; then

                    avail_qty=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select quantity_on_hand from inventory where upc = '$input_upc' and store_id = $kiosk_store_id;")
                    in_cart=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select coalesce(sum(quantity), 0) from cart_item where cart_id = 777 and upc = '$input_upc';")
                    total_requested=$((1 + in_cart))
                    

                    if [ -z "$avail_qty" ]; then
                        echo "ERROR: UPC '$input_upc' not found in this store's inventory."

                    elif [ "$total_requested" -gt "$avail_qty" ]; then
                        echo "ERROR: Insufficient stock! only $avail_qty available."
                    else

                        query="insert into cart_item (cart_id, upc, quantity) 
                               values (777, '$input_upc', 1) 
                               on duplicate key update quantity = quantity + 1;"
                        run_query "$query"
                        
                        echo -e "\nItem Scanned successfully!"
                        run_query "select p.product_name, i.current_price 
                                   from product p join inventory i on p.upc = i.upc 
                                   where p.upc = '$input_upc' and i.store_id = $kiosk_store_id;"
                    fi
                fi
                read -p "Press [Enter] to continue..."
                ;;
            3)
                echo -e "\n--- ITEMS IN CART ---"
                query="select p.product_name, c.quantity, i.current_price, (c.quantity * i.current_price) as line_total 
                       from cart_item c join product p on c.upc = p.upc join inventory i on c.upc = i.upc 
                       where c.cart_id = 777 and i.store_id = $kiosk_store_id;"
                run_query "$query"
                
                echo -e "\n--- SUBTOTAL ---"
                run_query "select sum(c.quantity * i.current_price) as SUBTOTAL 
                           from cart_item c join inventory i on c.upc = i.upc 
                           where c.cart_id = 777 and i.store_id = $kiosk_store_id;"
                read -p "Press [Enter] to return..."
                ;;
            4)
                echo -e "\n========================================="
                echo "           FINAL RECEIPT                 "
                echo "========================================="
                
                # check empty cart
                cart_count=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select count(*) from cart_item where cart_id = 777;")
                if [ "$cart_count" -eq 0 ]; then
                    echo "Your cart is empty. please scan items first."
                    read -p "Press [Enter] to return..."


                    continue
                fi

                if [ "$receipt_name" != "Guest" ]; then
                    echo "Customer: $receipt_name"

                    echo "-----------------------------------------"
                fi

                query="select 
                       sum(c.quantity * i.current_price) as 'Subtotal',
                       round(sum(c.quantity * i.current_price) * ps.tax_rate, 2) as 'State Tax',
                       round(sum(c.quantity * i.current_price) * (1 + ps.tax_rate), 2) as 'GRAND TOTAL'
                       from cart_item c join inventory i on c.upc = i.upc join physical_store ps on i.store_id = ps.store_id
                       where c.cart_id = 777 and i.store_id = $kiosk_store_id group by ps.tax_rate;"
                
                run_query "$query"
                
                echo "========================================="
                
                read -p "Type 'PAY' to insert card, or press Enter to go back: " checkout_cmd
               
                checkout_cmd=$(echo "$checkout_cmd" | tr -d '\r' | xargs)
                
                if [ "$checkout_cmd" = "PAY" ] || [ "$checkout_cmd" = "pay" ]; then
                    oversold=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select count(*) from cart_item c join inventory i on c.upc = i.upc and i.store_id = $kiosk_store_id where c.cart_id = 777 and c.quantity > i.quantity_on_hand;")
                    if [ "$oversold" -gt 0 ]; then
                 
                        echo "ERROR: Checkout failed! An item in your cart exceeds current inventory limits."
                    else
                        echo "Processing card..."
                        sleep 1
                  
                        checkout_query="set sql_safe_updates = 0;
                        start transaction;
                        insert into sale_transaction (store_id, customer_id, transaction_date, transaction_time, total_amount, payment_method, tax_amount)
                        select $kiosk_store_id, $session_cust_id, curdate(), curtime(), 
                        round(sum(c.quantity * i.current_price) * (1 + ps.tax_rate), 2), 
                        'Credit Card', round(sum(c.quantity * i.current_price) * ps.tax_rate, 2)
                        from cart_item c join inventory i on c.upc = i.upc join physical_store ps on i.store_id = ps.store_id 
                        where c.cart_id = 777 and i.store_id = $kiosk_store_id group by ps.tax_rate;
                        
                        set @new_tx = last_insert_id();
                        
                        insert into line_item (transaction_id, upc, quantity_purchased, unit_price_sold)
                        select @new_tx, c.upc, c.quantity, i.current_price 
                        from cart_item c join inventory i on c.upc = i.upc where c.cart_id = 777 and i.store_id = $kiosk_store_id;
                        
                        update inventory i join cart_item c on i.upc = c.upc 
                        set i.quantity_on_hand = i.quantity_on_hand - c.quantity where c.cart_id = 777 and i.store_id = $kiosk_store_id;
                        
                        delete from cart_item where cart_id = 777;
                        commit;
                        set sql_safe_updates = 1;"
                        
                        run_query "$checkout_query"
                        echo "Approved! Your receipt has been logged. Thank you for shopping!"
                    fi
                fi

                read -p "Press [Enter] to finish..."
                ;;


            5)
                echo "Transaction canceled. Have a nice day!"
                run_query "delete from cart_item where cart_id = 777;"
                return
                ;;
            *)
                echo "Invalid option."
                sleep 1
                ;;
        esac
    done
}

# ==========================================
# Cashier at POS terminal
# ==========================================
cashier_menu() {
    clear
    echo "====================================="
    echo "       CASHIER LOGIN TERMINAL        "
    echo "====================================="
    


    while true; do
        read -p "Enter your Store ID to open register (e.g. 1, 2 or 3): " pos_store_id
        pos_store_id=$(echo "$pos_store_id" | tr -d '\r' | xargs)
        
        if [[ "$pos_store_id" =~ ^[1-9][0-9]*$ ]]; then
            store_exists=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select count(*) FROM physical_store where store_id = $pos_store_id;")
            
            if [ "$store_exists" -eq 1 ]; then
                break
            else
                echo "ERROR: Store ID $pos_store_id does not exist in the database."
            fi
        else
            echo "ERROR: Store ID must be a valid positive number."
        fi
    done
    
    run_query "delete from cart_item where cart_id = 999;"
    run_query "insert ignore into shopping_cart (cart_id, store_id) values (999, $pos_store_id);"

    while true; do
        clear
        echo "====================================="
        echo "    REGISTER OPEN - STORE $pos_store_id   "
        echo "====================================="
        echo "1. View Store Catalog"
        echo "2. Scan Item (Add to Cart)"
        echo "3. Checkout, Pay & Print Receipt"
        echo "4. Void Transaction & Exit"
        echo "====================================="
        read -p "Select an option (1-4): " pos_choice

        pos_choice=$(echo "$pos_choice" | tr -d '\r' | xargs)


        case $pos_choice in
            1)
                echo -e "\n--- LOCAL STORE CATALOG ---"
                run_query "select p.upc, p.product_name, concat(p.size, ' ', p.unit_of_measure) as unit_size, 
                           i.current_price as price, coalesce(ep.dietary_certifications, 'N/A') as diet_certs
                           from inventory i join product p on i.upc = p.upc 
                           left join edible_product ep on p.upc = ep.upc
                           where i.store_id = $pos_store_id and i.quantity_on_hand > 0 limit 15;"
                read -p "Press [Enter] to return..."
                ;;
            2)
                echo -e "\n--- SCAN ITEM ---"
                read -p "Enter Product UPC (e.g., 000000000000001): " input_upc
                input_upc=$(echo "$input_upc" | tr -d '\r' | xargs)
                
                if [ -n "$input_upc" ]; then
                    while true; do
                        read -p "Enter Quantity: " input_qty
                        input_qty=$(echo "$input_qty" | tr -d '\r' | xargs)
                        
                        if [[ "$input_qty" =~ ^[1-9][0-9]*$ ]]; then
                            break
                        else
                            echo "ERROR: Quantity must be a whole number greater than zero."
                        fi
                    done
                    
                    avail_qty=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select quantity_on_hand from inventory where upc = '$input_upc' and store_id = $pos_store_id;")
                    in_cart=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select coalesce(sum(quantity), 0) from cart_item where cart_id = 999 and upc = '$input_upc';")
                    total_requested=$((input_qty + in_cart))
                    
                    if [ -z "$avail_qty" ]; then

                        echo "ERROR: UPC '$input_upc' not found in this store's inventory."
                    elif [ "$total_requested" -gt "$avail_qty" ]; then

            
                        echo "ERROR: Insufficient stock! Only $avail_qty available (You already scanned $in_cart)."
                    
                    else
                        query="insert into cart_item (cart_id, upc, quantity) 
                               values (999, '$input_upc', $input_qty) 
                               on duplicate key update quantity = quantity + $input_qty;"
                        run_query "$query"
                        
                        echo -e "\nItem Scanned:"
                        
                        run_query "select p.product_name, i.current_price 
                                   from product p join inventory i on p.upc = i.upc 
                                   where p.upc = '$input_upc' and i.store_id = $pos_store_id;"
                    fi
                fi
                read -p "Press [Enter] to continue scanning..."
                ;;
            3)
                echo -e "\n--- CHECKOUT ---"
                
                # EMPTY CART CHECK
                cart_count=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select count(*) from cart_item where cart_id = 999;")
                if [ "$cart_count" -eq 0 ]; then

                    echo "Cart is empty. Please scan items first."
                    read -p "Press [Enter] to return..."
                    continue
                fi

                read -p "Enter Customer ID for Rewards (or press Enter for Guest): " pos_cust_id
                pos_cust_id=$(echo "$pos_cust_id" | tr -d '\r' | xargs)
                
                if [ -z "$pos_cust_id" ]; then
                    pos_cust_id="NULL"
                    receipt_name="Guest"
                else
                    cust_name=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select concat(first_name, ' ', last_name) from customer where customer_id = '$pos_cust_id';")
                    if [ -z "$cust_name" ]; then
                        echo "(Invalid ID - Proceeding as Guest)"
                        pos_cust_id="NULL"
                        receipt_name="Guest"
                    else
                        receipt_name="$cust_name"
                    fi
                fi

                echo -e "\n========================================="
                echo "           CASHIER FINAL RECEIPT         "
                echo "========================================="
                if [ "$receipt_name" != "Guest" ]; then
                    echo "Customer: $receipt_name"
                    echo "-----------------------------------------"
                fi
                
                run_query "select p.product_name, c.quantity, i.current_price, (c.quantity * i.current_price) as line_total 
                           from cart_item c join product p on c.upc = p.upc join inventory i on c.upc = i.upc 
                           where c.cart_id = 999 and i.store_id = $pos_store_id;"
                           
                query="select 
                       sum(c.quantity * i.current_price) as 'Subtotal',
                       round(sum(c.quantity * i.current_price) * ps.tax_rate, 2) as 'State Tax',
                       round(sum(c.quantity * i.current_price) * (1 + ps.tax_rate), 2) as 'GRAND TOTAL'
                       from cart_item c join inventory i on c.upc = i.upc join physical_store ps on i.store_id = ps.store_id
                       where c.cart_id = 999 and i.store_id = $pos_store_id group by ps.tax_rate;"
                run_query "$query"
                echo "========================================="
                
                read -p "Type 'PAY' to collect cash/card, or press Enter to go back: " checkout_cmd
                checkout_cmd=$(echo "$checkout_cmd" | tr -d '\r' | xargs)
                
                if [ "$checkout_cmd" = "PAY" ] || [ "$checkout_cmd" = "pay" ]; then
                    oversold=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select count(*) from cart_item c join inventory i on c.upc = i.upc and i.store_id = $pos_store_id where c.cart_id = 999 and c.quantity > i.quantity_on_hand;")
                    if [ "$oversold" -gt 0 ]; then
                        echo "ERROR: Transaction aborted! Cart contains items exceeding physical stock limits."
                        echo "Please Void the transaction or return items."
                    else
                        echo "Processing payment..."
                        sleep 1
                        
                        checkout_query="set sql_safe_updates = 0;
                        start transaction;
                        insert into sale_transaction (store_id, customer_id, transaction_date, transaction_time, total_amount, payment_method, tax_amount)
                        select $pos_store_id, $pos_cust_id, curdate(), curtime(), 
                        round(sum(c.quantity * i.current_price) * (1 + ps.tax_rate), 2), 
                        'Cash', round(sum(c.quantity * i.current_price) * ps.tax_rate, 2)
                        from cart_item c join inventory i on c.upc = i.upc join physical_store ps on i.store_id = ps.store_id 
                        where c.cart_id = 999 and i.store_id = $pos_store_id group by ps.tax_rate;
                        
                        set @new_tx = last_insert_id();
                        
                        insert into line_item (transaction_id, upc, quantity_purchased, unit_price_sold)
                        select @new_tx, c.upc, c.quantity, i.current_price 
                        from cart_item c join inventory i on c.upc = i.upc where c.cart_id = 999 and i.store_id = $pos_store_id;
                        
                        update inventory i join cart_item c on i.upc = c.upc 
                        set i.quantity_on_hand = i.quantity_on_hand - c.quantity where c.cart_id = 999 and i.store_id = $pos_store_id;
                        
                        delete from cart_item where cart_id = 999;
                        commit;
                        set sql_safe_updates = 1;"
                        
                        run_query "$checkout_query"
                        echo "Payment approved! Database updated and drawer opened."
                    fi
                fi
                read -p "Press [Enter] to return to register..."
                ;;

            4)
                echo "Voiding transaction..."
                run_query "delete from cart_item where cart_id = 999;"
                return 
                ;;
            *)
                echo "Invalid option."
                sleep 1
                ;;
        esac
    done
}

# ==========================================
# store manager
# ==========================================
manager_menu() {
    clear
    echo "====================================="
    echo "     STORE MANAGER AUTHENTICATION    "
    echo "====================================="
    
    while true; do
        read -p "Enter your Store ID to log in (e.g., 1, 2, or 3): " session_store_id
        session_store_id=$(echo "$session_store_id" | tr -d '\r' | xargs)
        
        if [[ "$session_store_id" =~ ^[1-9][0-9]*$ ]]; then
            # check if the store exists in the database
            store_exists=$(mysql -u "$DB_USER" -D "$DB_NAME" -sN -e "select count(*) from store where store_id = $session_store_id;")
            
            if [ "$store_exists" -eq 1 ]; then
                break
            else
                echo "ERROR: Store ID $session_store_id does not exist in the database."
            fi
        else
            echo "ERROR: Store ID must be a valid positive number."
        fi
    done

    
    while true; do
        clear
        echo "====================================="
        echo "   STORE MANAGER DASHBOARD (STORE $session_store_id)  "
        echo "====================================="
        echo "1. View Low Inventory Alerts"
        echo "2. Generate Purchase Order (Restock)"
        echo "3. Receive Pending Shipments"
        echo "4. Cross-Merchandising Audit"
        echo "5. Return to Main Menu"

        echo "====================================="
        read -p "Select an option (1-5): " mgr_choice
        mgr_choice=$(echo "$mgr_choice" | tr -d '\r' | xargs)

        case $mgr_choice in
            1)
                echo -e "\n--- LOW INVENTORY ALERTS (STORE $session_store_id) ---"
                query="select i.store_id, p.product_name, i.quantity_on_hand, i.reorder_threshold 
                       from inventory i join product p on i.upc = p.upc 
                       where i.store_id = $session_store_id and i.quantity_on_hand <= i.reorder_threshold
                       order by i.quantity_on_hand asc;"
                run_query "$query"
                read -p "Press [Enter] to continue..."
                ;;
            2)
                echo -e "\n--- SUGGESTED REORDER QUANTITIES ---"
                query="select p.upc, p.product_name, b.brand_name, 
                       i.quantity_on_hand, i.target_stock_level, (i.target_stock_level - i.quantity_on_hand) as suggested_order_qty
                       from inventory i join product p on i.upc = p.upc 
                       join brand b on p.brand_id = b.brand_id
                       where i.store_id = $session_store_id and i.quantity_on_hand < i.target_stock_level
                       order by suggested_order_qty desc;"
                run_query "$query"
                
                echo -e "\n--- GENERATE PURCHASE ORDER ---"
                read -p "Enter UPC to restock from the list above (or press Enter to cancel): " order_upc
                order_upc=$(echo "$order_upc" | tr -d '\r' | xargs)

                if [ -n "$order_upc" ]; then
                    while true; do
                        read -p "Enter Order Quantity: " order_qty
                        order_qty=$(echo "$order_qty" | tr -d '\r' | xargs)
                        
                        if [[ "$order_qty" =~ ^[1-9][0-9]*$ ]]; then
                            break
                        else
                            echo "ERROR: Quantity must be a whole number greater than zero."
                        fi
                    done
                    
                    po_query="start transaction;
                    select v.vendor_id into @auth_vendor from product p join vendor_brand_map vbm on p.brand_id = vbm.brand_id join vendor v on vbm.vendor_id = v.vendor_id where p.upc = '$order_upc' limit 1;
                    
                    insert into shipment (delivery_date) values (date_add(curdate(), interval 3 day));
                    set @new_shipment = last_insert_id();
                    
                    insert into purchase_order (store_id, vendor_id, shipment_id, order_date, status) values ($session_store_id, @auth_vendor, @new_shipment, curdate(), 'Pending');
                    set @new_po = last_insert_id();
                    
                    insert into po_line_item (po_number, upc, quantity_ordered, unit_cost) values (@new_po, '$order_upc', $order_qty, 1.50);
                    
                    select concat('Purchase Order #', @new_po, ' generated! Expected delivery on ', date_add(curdate(), interval 3 day), '.') as 'Logistics Status';
                    commit;"
                    
                    run_query "$po_query"
                fi
                read -p "Press [Enter] to continue..."
                ;;
            3)
                echo -e "\n--- PENDING SHIPMENTS ---"
                query="select po.po_number, po.order_date, coalesce(s.delivery_date, 'TBD') as expected_arrival, v.vendor_name, p.product_name, poli.quantity_ordered 
                       from purchase_order po 
                       join po_line_item poli on po.po_number = poli.po_number 
                       join product p on poli.upc = p.upc 
                       join vendor v on po.vendor_id = v.vendor_id 
                       left join shipment s on po.shipment_id = s.shipment_id
                       where po.store_id = $session_store_id and po.status = 'Pending';"
                run_query "$query"
                
                read -p "Enter PO Number that has arrived (or press Enter to cancel): " arrived_po
                arrived_po=$(echo "$arrived_po" | tr -d '\r' | xargs)
                
                if [[ "$arrived_po" =~ ^[0-9]+$ ]]; then
                    receive_query="set sql_safe_updates = 0;
                    start transaction;
                    update purchase_order set status = 'Delivered' where po_number = $arrived_po;
                    update inventory i join po_line_item poli on i.upc = poli.upc 
                    set i.quantity_on_hand = i.quantity_on_hand + poli.quantity_ordered 
                    where poli.po_number = $arrived_po and i.store_id = $session_store_id;
                    commit;
                    set sql_safe_updates = 1;"
                    run_query "$receive_query"
                    echo "Shipment received! Inventory levels updated."
                elif [ -n "$arrived_po" ]; then
                    echo "ERROR: PO Number must be a valid number."
                fi
                read -p "Press [Enter] to continue..."
                ;;
            4)
                echo -e "\n--- CROSS-MERCHANDISING REPORT (STORE $session_store_id) ---"
                query="select p.product_name, count(ppm.aisle_id) as number_of_aisles_placed, 
                       group_concat(a.aisle_identifier separator ' & ') as exact_aisle_locations
                       from physical_store ps join aisle a on ps.store_id = a.store_id 
                       join product_placement_map ppm on a.aisle_id = ppm.aisle_id 
                       join product p on ppm.upc = p.upc 
                       where ps.store_id = $session_store_id
                       group by p.upc, p.product_name having number_of_aisles_placed > 1;"
                run_query "$query"
                read -p "Press [Enter] to continue..."
                ;;
            5)
                return 
                ;;
            *)
                echo "Invalid option."
                sleep 1
                ;;
        esac
    done
}

# ==========================================
# Corporate Admin (for advanced analytics and super tasks)
# ==========================================
admin_menu() {
    clear
    echo "====================================="
    echo "   CORPORATE ADMIN AUTHENTICATION    "
    echo "====================================="
    read -p "Enter Admin PIN (Hint: type 1234): " admin_pin
    admin_pin=$(echo "$admin_pin" | tr -d '\r' | xargs)

    if [ "$admin_pin" != "1234" ]; then
        echo "Access Denied."
        sleep 2
        return
    fi

    while true; do
        clear
        echo "====================================="
        echo "    EXECUTIVE ANALYTICS DASHBOARD    "
        echo "====================================="
        echo "1. Top Selling Products Overall"
        echo "2. Highest Performing Stores (Physical & Online)"
        echo "3. Brand Head-to-Head (Comparative City Analysis)"
        echo "4. Web Store Revenue Breakdown"
        echo "5. Global Price Adjuster (Trigger Inflation)"
        echo "6. Historical Price Variance Audit"
        echo "7. Master Department Revenue Rollup (Hierarchy)"
        echo "8. Top 20 Products by Specific Store"
        echo "9. Top 20 Products by State"
        echo "10. Market Basket Analysis (Bought with X)"
        echo "11. Logout"
        echo "====================================="
        read -p "Select an option (1-11): " admin_choice
        admin_choice=$(echo "$admin_choice" | tr -d '\r' | xargs)        
        
        

        case $admin_choice in
            1)
                echo -e "\n--- TOP SELLING PRODUCTS (COMPANY-WIDE) ---"
                query="select p.upc, p.product_name, sum(li.quantity_purchased) as total_units_sold, 
                       sum(li.quantity_purchased * li.unit_price_sold) as total_revenue 
                       from product p join line_item li on p.upc = li.upc 
                       group by p.upc, p.product_name order by total_units_sold desc limit 15;"
                run_query "$query"
                read -p "Press [Enter] to continue..."
                ;;
            2)
                echo -e "\n--- STORE PERFORMANCE TRACKER ---"
                echo "Available Data Years:"
                run_query "select distinct year(transaction_date) as 'Fiscal Years Available' from sale_transaction;"
                
                while true; do

                    read -p "Enter Fiscal Year: " target_year
                    target_year=$(echo "$target_year" | tr -d '\r' | xargs)
                    if [[ "$target_year" =~ ^[0-9]{4}$ ]]; then
                        break
                    else
                        echo "ERROR: Please enter a valid 4-digit year."
                    fi
                done
                
                query="select 'Physical' as store_type, ps.city as location, ps.state, sum(st.total_amount) as total_sales 
                       from sale_transaction st join physical_store ps on st.store_id = ps.store_id 
                       where year(st.transaction_date) = $target_year 
                       group by st.store_id, ps.city, ps.state 
                       union 
                       select 'Online' as store_type, 'Web Store' as location, 'N/A' as state, sum(st.total_amount) as total_sales 
                       from sale_transaction st join web_store ws on st.store_id = ws.store_id 
                       where year(st.transaction_date) = $target_year 
                       group by st.store_id, ws.website_url 
                       order by total_sales desc limit 3;"
              
                run_query "$query"
                read -p "Press [Enter] to continue..."
                ;;
            3)
                echo -e "\n--- BRAND COMPETITION ANALYSIS ---"
                echo "Available Brands in System:"
                run_query "select brand_name from brand;"
                read -p "Enter Brand 1 (e.g., Coke): " brand_one
                read -p "Enter Brand 2 (e.g., Pepsi): " brand_two
                brand_one=$(echo "$brand_one" | tr -d '\r' | xargs)
            
                brand_two=$(echo "$brand_two" | tr -d '\r' | xargs)
                
                query="select ps.city as City, 
                       sum(case when b.brand_name = '$brand_one' then li.quantity_purchased else 0 end) as '${brand_one}_sold',
                       sum(case when b.brand_name = '$brand_two' then li.quantity_purchased else 0 end) as '${brand_two}_sold',
                       case 
                           when sum(case when b.brand_name = '$brand_one' then li.quantity_purchased else 0 end) > sum(case when b.brand_name = '$brand_two' then li.quantity_purchased else 0 end) then '$brand_one Wins'
                           when sum(case when b.brand_name = '$brand_one' then li.quantity_purchased else 0 end) < sum(case when b.brand_name = '$brand_two' then li.quantity_purchased else 0 end) then '$brand_two Wins'
                           else 'Tie'
                       end as 'Market_Leader'
                       from sale_transaction st join line_item li on st.transaction_id = li.transaction_id 
                       join product p on li.upc = p.upc join brand b on p.brand_id = b.brand_id 
                       join physical_store ps on st.store_id = ps.store_id 
                       where b.brand_name in ('$brand_one', '$brand_two') 
                       group by ps.city;"
                run_query "$query"
                read -p "Press [Enter] to continue..."
                ;;
     
            4)
                echo -e "\n--- WEB STORE REVENUE SPLIT ---"
                query="select ws.website_url, 
                       sum(tx_totals.product_rev) as pure_product_revenue, 
                       sum(st.tax_amount + st.delivery_fee + st.service_fee + st.gratuity) as total_fees_collected, 
                       sum(st.total_amount) as total_gross_revenue 
                       from web_store ws join sale_transaction st on ws.store_id = st.store_id 
                       join (select transaction_id, sum(quantity_purchased * unit_price_sold) as product_rev from line_item group by transaction_id) tx_totals on st.transaction_id = tx_totals.transaction_id 
                       group by ws.store_id, ws.website_url;"
             
             
                run_query "$query"
                read -p "Press [Enter] to continue..."
                ;;
            5)
                echo -e "\n--- GLOBAL INVENTORY PRICE ADJUSTER ---"
                echo "Current Master Catalog Pricing (Showing Regional Ranges):"
                run_query "select p.upc, p.product_name, min(i.current_price) as lowest_price, max(i.current_price) as highest_price 
                           from product p join inventory i on p.upc = i.upc 
                           group by p.upc, p.product_name limit 15;"
                           
             
             
                read -p "Enter UPC to update across all stores: " upc_to_update
                upc_to_update=$(echo "$upc_to_update" | tr -d '\r' | xargs)
                
                echo -e "\nSelected Product Details:"
                run_query "select p.product_name, min(i.current_price) as 'old_price' from product p join inventory i on p.upc = i.upc where p.upc = '$upc_to_update' limit 1;"
                
             
                while true; do
                    read -p "Enter New Price for this item (e.g., 9.99) or press Enter to cancel: " new_price
                    new_price=$(echo "$new_price" | tr -d '\r' | xargs)
                    
                    if [ -z "$new_price" ]; then
                        break # Let them cancel out safely
                    elif [[ "$new_price" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
                        break # Input is valid currency
                   
                    else
                        echo "ERROR: Invalid format. Please enter a valid price (e.g., 4.99)."
                    fi
                done
                
                if [ -n "$new_price" ]; then
                    query="set sql_safe_updates = 0; update inventory set current_price = $new_price where upc = '$upc_to_update'; set sql_safe_updates = 1;"
                    run_query "$query"
                    echo "Price globally updated to \$${new_price} for UPC $upc_to_update!"
                    echo "(Note: Historical receipts have been protected)."
                fi
                read -p "Press [Enter] to continue..."
                ;;
       
       
            6)
                echo -e "\n--- HISTORICAL PRICE VARIANCE AUDIT ---"
                query="select st.transaction_date, p.product_name, 
                       li.unit_price_sold as locked_receipt_price, 
                       i.current_price as live_inventory_price, 
                       (i.current_price - li.unit_price_sold) as price_inflation_difference 
                       from sale_transaction st join line_item li on st.transaction_id = li.transaction_id 
                       join product p on li.upc = p.upc join inventory i on st.store_id = i.store_id and li.upc = i.upc 
                       where li.unit_price_sold != i.current_price order by st.transaction_date desc limit 15;"
           
                run_query "$query"
                read -p "Press [Enter] to continue..."
           
                ;;
            7)
                echo -e "\n--- MASTER DEPARTMENT REVENUE (HIERARCHICAL ROLLUP) ---"
                query="select parent.category_name as 'Master Department', 
                       concat('$', format(sum(li.quantity_purchased * li.unit_price_sold), 2)) as 'Total Pure Revenue'
                       from line_item li
                       join product p on li.upc = p.upc
                       join product_category_map pcm on p.upc = pcm.upc
                       join category child on pcm.category_id = child.category_id
                       join category parent on child.parent_category_id = parent.category_id
                       group by parent.category_name
                       order by sum(li.quantity_purchased * li.unit_price_sold) desc;"
                run_query "$query"
           
                read -p "Press [Enter] to continue..."
                ;;

            8)
                echo -e "\n--- TOP 20 PRODUCTS BY STORE ---"
                read -p "Enter Store ID to analyze: " target_store
                target_store=$(echo "$target_store" | tr -d '\r' | xargs)


                if [[ "$target_store" =~ ^[0-9]+$ ]]; then
                    query="select p.upc, p.product_name, sum(li.quantity_purchased) as total_units_sold 
                           from sale_transaction st join line_item li on st.transaction_id = li.transaction_id 
                           join product p on li.upc = p.upc 
                           where st.store_id = $target_store 
                           group by p.upc, p.product_name order by total_units_sold desc limit 20;"
                    run_query "$query"
                else
                    echo "ERROR: Invalid Store ID."
             
                fi
                read -p "Press [Enter] to continue..."
                ;;
            9)
                echo -e "\n--- TOP 20 PRODUCTS BY STATE ---"
                read -p "Enter 2-letter State Abbreviation (e.g., NY, MA, CT): " target_state
                target_state=$(echo "$target_state" | tr -d '\r' | xargs)
                
                query="select ps.state, p.upc, p.product_name, sum(li.quantity_purchased) as total_units_sold 
                       from sale_transaction st join physical_store ps on st.store_id = ps.store_id 
                       join line_item li on st.transaction_id = li.transaction_id 
                       join product p on li.upc = p.upc 
                       where ps.state = '$target_state' 
                       group by ps.state, p.upc, p.product_name order by total_units_sold desc limit 20;"
                run_query "$query"
                read -p "Press [Enter] to continue..."
                ;;
            10)
                echo -e "\n--- MARKET BASKET ANALYSIS ---"
                read -p "Enter a product name to analyze (e.g., Milk): " anchor_product
                anchor_product=$(echo "$anchor_product" | tr -d '\r' | xargs)
                
                # find items bought in the same cart
                query="select p2.product_name as 'Bought With $anchor_product', c.category_name as 'Product Type', count(*) as 'Times Bought Together'
                       from line_item li1
                       join sale_transaction st on li1.transaction_id = st.transaction_id
                       join product p1 on li1.upc = p1.upc
                       join line_item li2 on st.transaction_id = li2.transaction_id
                       join product p2 on li2.upc = p2.upc
                       join product_category_map pcm on p2.upc = pcm.upc
                       join category c on pcm.category_id = c.category_id
                       where p1.product_name like '%$anchor_product%' and p1.upc != p2.upc
                       group by p2.product_name, c.category_name
                       order by count(*) desc limit 3;"
                run_query "$query"
                read -p "Press [Enter] to continue..."
                ;;
            11)
                return
                ;;

            *)
                echo "Invalid option."
                sleep 1
                ;;
        esac
    done
}

# ==========================================
# main menu
# ==========================================
while true; do
    clear
    echo "====================================="
    echo "    TRADER JOE'S TERMINAL SYSTEM     "
    echo "====================================="
    echo "Select your Role:"
    echo "1. Web Store Customer (Online Shopping)"
    echo "2. In-Store Customer (Self-Checkout Kiosk)"
    echo "3. Cashier (Point of Sale Register)"
    echo "4. Store Manager (Inventory & Reports)"
    echo "5. Corporate Admin (Executive Dashboard)"
    echo "6. Exit Application"
    echo "====================================="
    read -p "Enter role (1-6): " main_choice
    main_choice=$(echo "$main_choice" | tr -d '\r' | xargs)

    case $main_choice in
        1)
            customer_menu
            ;;
        2)
            instore_kiosk_menu
            ;;
        3)
            cashier_menu
            ;;
        4)
            manager_menu
            ;;
        5)
            admin_menu
            ;;
        6)
            echo "Exiting system. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            sleep 1
            ;;
    esac
done