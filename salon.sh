#!/bin/bash

PSQL="psql -U freecodecamp -d salon -t -c"

echo "~~~~~ MY SALON ~~~~~"
echo ""
echo "Welcome to My Salon, how can I help you?"
echo ""

# Get the list of services from the database
SERVICES=$($PSQL "SELECT service_id, TRIM(name) FROM services;")

# Display the list of services
echo "$SERVICES" | while IFS='|' read -r service_id name; do
    echo "$(echo -n "$service_id" | tr -d '[:space:]')) ${name#"${name%%[![:space:]]*}"}"
done
echo ""

while true; do
    echo -e "\nEnter the service number you'd like:"
    read SERVICE_ID_SELECTED

    # Check if the selected service_id is valid
   VALID_SERVICE=$(echo "$($PSQL "SELECT EXISTS(SELECT 1 FROM services WHERE service_id = $SERVICE_ID_SELECTED);")" | tr -d '[:space:]')
    # echo "DEBUG: Valid service: "$VALID_SERVICE""
    if [ "$VALID_SERVICE" = "t" ]; then
        break
    else
        echo "I could not find that service. What would you like today?"
        echo ""
        echo "$SERVICES" | while IFS='|' read -r service_id name; do
            echo "$(echo -n "$service_id" | tr -d '[:space:]')) ${name#"${name%%[![:space:]]*}"}"
        done
        echo ""
    fi
done

echo -e "\nWhat's your phone number?"
read CUSTOMER_PHONE

CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")

if [ -z "$CUSTOMER_ID" ]; then
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    CUSTOMER_INERT_RESULT=$($PSQL "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE');")
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
fi

CUSTOMER_NAME=$($PSQL "SELECT trim(name) FROM customers WHERE phone = '$CUSTOMER_PHONE';")
CUSTOMER_NAME=$(echo "$CUSTOMER_NAME" | tr -d '[:space:]')
# Fetch the service name based on the selected service_id
SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
SERVICE_NAME=$(echo "$SERVICE_NAME" | tr -d '[:space:]')

echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME

$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME');")

echo ""
echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
