# Debezium POC

This Debezium/Kafka Connect/Kafka demo is borrowed from: https://debezium.io/documentation/reference/stable/tutorial.html

## Overview
The purpose of this project is to prove a change data capture (CDC) configuration of MySQL using Debezium as a plug-in to Kafka Connect.

Ultimately this should feed CDC events into Azure Event Hub. This initial implementation will be self-contained using Kafka.

## Environment variables

To create and populate the `.env.db` file, you can use the provided `.env.db.sample` as a template. Follow the steps below:

1. Copy the `.env.db.sample` file and rename the copy to `.env.db`.
2. Open the `.env.db` file in a text editor.
3. Replace the empty values with your MySQL root password, user, and password. For example:
   ```bash
   MYSQL_ROOT_PASSWORD=your_root_password
   MYSQL_USER=your_username
   MYSQL_PASSWORD=your_password
   ```
4. Save and close the `.env.db` file.

Please ensure that the `.env.db` file is in the same directory as your `docker-compose.yml` file.

## Build docker environment

To build the Docker environment, follow the steps below:

1. Open a terminal.
2. Navigate to the directory containing the `docker-compose.yml` file.
3. Run the following command to build and start the Docker environment:
   ```
   docker-compose up -d
   ```
This command will download the necessary Docker images (if not already downloaded), build the Docker containers, and start them in the background.

To stop the Docker environment, you can use the following command:
   ```bash
   docker-compose down
   ```
This command will stop and remove the Docker containers.

## Verify database

To verify the database, you can open a MySQL CLI using the following command:
   ```bash
   docker-compose run --rm mysqlterm
   ```
This command will start a new container from the `mysqlterm` service defined in the `docker-compose.yml` file, run it, and remove the container after it exits. You will be connected to sample inventory database on the MySQL server running in the `db` service.

Try these commands to verify a successful installation:
   ```sql
   SHOW TABLES;
   SELECT * FROM customers;
   ```

## Verify Kafka Connect

To verify that Kafka Connect is running, you can use the following command:
   ```bash
   curl -H "Accept:application/json" localhost:8083/
   ```
This command will return a JSON response. You should expect an output similar to the following:
   ```json
   {"version":"3.4.0","commit":"cb8625948210849f"}
   ```

## Add the MySQL connector to Kafka Connect and verify

Before running the scripts, ensure that you have the following system dependencies installed:

1. Bash shell
2. curl
3. jq

To add the MySQL connector to Kafka Connect, run the following command:
   ```bash
   ./register_connector.sh
   ```
This command will register the MySQL connector with Kafka Connect.

To verify that the MySQL connector has been added successfully, run the following command:
   ```bash
   ./verify_connector.sh
   ```
This command will list all connectors registered with Kafka Connect and show the configuration of the `inventory-connector`.

## Viewing events

### Create events

To watch the `dbserver1.inventory.customers` topic, including all events and the primary key fields, run the following command:
   ```bash
   docker-compose exec kafka /kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic dbserver1.inventory.customers --from-beginning | jq
   ```
This command will start another instance of the Kafka service and pretty-print the output.

You can verify the data collected by debezium against the data in the customers table (see "Verify database").

### Update events

To observe an update event, keep the topic consumer running in one terminal. Open a new terminal and run the following command to open the database client:
   ```bash
   docker-compose run --rm mysqlterm
   ```
In the database client, run the following SQL command to update a customer's first name where the customer ID is 1004:
   ```sql
   UPDATE customers SET first_name = 'NewName' WHERE id = 1004;
   ```
You can view the updated row in the database with the following command:
   ```sql
   SELECT * FROM customers WHERE id = 1004;
   ```
After running the above command, switch back to the first terminal where the topic consumer is running. You should see the update captured in the topic stream.

### Delete events

Similarly for deletions, keep one terminal open to observe the topic consumer and another to execute SQL queries.

Delete a customer address to resolve a foreign key constraint, then delete the customer.

   ```sql
   DELETE FROM addresses WHERE customer_id = 1004;
   DELETE FROM customers WHERE id = 1004;
   ```

## Restart Kafka Connect

The Debezium connector should sync with the binlog after a service restart. Even if the database has been modified while Kafka Connect is stopped, those events are not lost.

Keep a window running the Kafta topic watcher during this whole procedure.

   ```sql
   docker-compose stop connect
   docker-compose run --rm mysqlterm
   ```

Add some customers while Debezium isn't looking.
   ```sql
   INSERT INTO customers VALUES (default, "Sarah", "Thompson", "kitt@acme.com");
   INSERT INTO customers VALUES (default, "Kenneth", "Anderson", "kander@acme.com");
   ```
Restart connect:
   ```bash
   docker-compose start connect
   ```
Switch back to the topic consumer terminal window. The two events should be discovered by Debezium and streamed to Kafka.

## Shutdown
To stop all services and remove your containers when you are finished, run:
   ```
   docker-compose down
   ```
If you want to clean up all of the images used to build the containers and reclaim your drive space, use:
   ```
   docker image prune -a
   ```
