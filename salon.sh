#!/bin/bash
echo -e "\n~~~~ MY SALON ~~~~\n"

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

APPOINTMENT_MENU(){
  if [[ ! -z $1 ]]
  then
    echo -e "\n$1"
  else
    echo -e "\nWelcome to My Salon, how can I help you?\n"
  fi

  NEW_APPOINTMENT
}

NEW_APPOINTMENT(){
  AVAILABLE_SERVICES=$($PSQL "SELECT * FROM services ORDER BY service_id;")
  echo "$AVAILABLE_SERVICES" | while IFS=" | " read SERVICE_ID SERVICE_NAME
  do
    echo -e "$SERVICE_ID) $SERVICE_NAME"
  done

  read SERVICE_ID_SELECTED
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    APPOINTMENT_MENU "Select a valid service."
  else
    SERVICE_ID_SELECTED_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
    if [[ -z $SERVICE_ID_SELECTED_NAME ]]
    then
      APPOINTMENT_MENU "I could not find that service. What would you like today?"
    else
      echo -e "\nWhat's your phone number?"
      read CUSTOMER_PHONE
      CUSTOMER_NAME_SELECTED=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
      if [[ -z $CUSTOMER_NAME_SELECTED ]]
      then
        echo -e "\nI don't have a record for that phone number, what's your name?"
        read CUSTOMER_NAME
        NEW_CUSTOMER=$($PSQL "INSERT INTO customers(phone,name) VALUES('$CUSTOMER_PHONE','$CUSTOMER_NAME')")
        CUSTOMER_NAME_SELECTED=$CUSTOMER_NAME
      fi
      echo -e "\nWhat time would you like your $(echo "$SERVICE_ID_SELECTED_NAME" | sed -E 's/^ * | * $//'), $(echo "$CUSTOMER_NAME_SELECTED" | sed -E 's/^ * | * $//')?"
      read SERVICE_TIME

      CLIENT_ID_FOR_ORDER=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
      NEW_ORDER_CONFIRMATION=$($PSQL "INSERT INTO appointments(customer_id,service_id,time) VALUES($CLIENT_ID_FOR_ORDER,$SERVICE_ID_SELECTED,'$SERVICE_TIME')")

      echo -e "\nI have put you down for a $(echo "$SERVICE_ID_SELECTED_NAME" | sed -E 's/^ * | * $//') at $SERVICE_TIME, $(echo "$CUSTOMER_NAME_SELECTED" | sed -E 's/^ * | * $//').\n"
      
      APPOINTMENT_MENU
    fi
  fi
}

APPOINTMENT_MENU