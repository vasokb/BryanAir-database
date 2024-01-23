# Database Technology (732A57) - Lab 4

SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS passenger;
DROP TABLE IF EXISTS contact;
DROP TABLE IF EXISTS reservation;
DROP TABLE IF EXISTS booking;
DROP TABLE IF EXISTS bankcard;
DROP TABLE IF EXISTS ticket;
DROP TABLE IF EXISTS unpaidreservation;
DROP TABLE IF EXISTS airport;
DROP TABLE IF EXISTS year;
DROP TABLE IF EXISTS weekday;
DROP TABLE IF EXISTS route;
DROP TABLE IF EXISTS weeklyschedule;
DROP TABLE IF EXISTS flight;

DROP PROCEDURE IF EXISTS addDay;
DROP PROCEDURE IF EXISTS addDestination;
DROP PROCEDURE IF EXISTS addFlight;
DROP PROCEDURE IF EXISTS addRoute;
DROP PROCEDURE IF EXISTS addYear;
DROP PROCEDURE IF EXISTS addReservation;
DROP PROCEDURE IF EXISTS addPassenger;
DROP PROCEDURE IF EXISTS addContact;
DROP PROCEDURE IF EXISTS addPayment;

DROP FUNCTION IF EXISTS calculateFreeSeats;
DROP FUNCTION IF EXISTS calculatePrice;

DROP TRIGGER IF EXISTS generateTicketID;

DROP VIEW IF EXISTS allFlights;
SET FOREIGN_KEY_CHECKS=1;

-- QUESTION 2 - Tables and foreign keys
CREATE TABLE passenger (
    passportNr INT NOT NULL,
    passenger_name VARCHAR(30),
    CONSTRAINT pk_passenger PRIMARY KEY(passportNr)
);

CREATE TABLE contact (
    passportNr INT NOT NULL,
    email VARCHAR(30),
    phone_no BIGINT,
    CONSTRAINT pk_contact PRIMARY KEY(passportNr)
);

CREATE TABLE reservation (
    reservationID INT NOT NULL AUTO_INCREMENT,
    contact_passportNr INT,
    flightID INT NOT NULL,
    numberOfSeats INT,
    CONSTRAINT pk_reservation PRIMARY KEY(reservationID)
);

CREATE TABLE booking (
    reservationID INT NOT NULL,
    cardNr BIGINT NOT NULL,
    total_price DOUBLE,
    CONSTRAINT pk_booking PRIMARY KEY(reservationID)
);

CREATE TABLE bankcard (
    cardNr BIGINT NOT NULL,
    cardHolder VARCHAR(30),
    CONSTRAINT pk_bankcard PRIMARY KEY(cardNr)
);

CREATE TABLE ticket (
	ticketID INT DEFAULT 0 NOT NULL,
    passportNr INT NOT NULL,
    booked_reservation_id INT NOT NULL,
    CONSTRAINT pk_ticket PRIMARY KEY(passportNr, booked_reservation_id)
);

CREATE TABLE unpaidreservation (
	passportNr INT NOT NULL,
    reservationID INT NOT NULL,
    CONSTRAINT pk_unpaid_reservation PRIMARY KEY(passportNr, reservationID)
);

CREATE TABLE airport (
    airport_code VARCHAR(3) NOT NULL,
    airport_name VARCHAR(30),
    country VARCHAR(30),
    CONSTRAINT pk_airport PRIMARY KEY(airport_code)
);

CREATE TABLE year (
    year INT NOT NULL,
    profit_factor DOUBLE,
    CONSTRAINT pk_year PRIMARY KEY(year)
);

CREATE TABLE weekday (
    day_name VARCHAR(10) NOT NULL,
    year INT NOT NULL,
    weekday_factor DOUBLE,
    CONSTRAINT pk_weekday PRIMARY KEY(day_name, year)
);

CREATE TABLE route (
    routeID INT NOT NULL AUTO_INCREMENT,
    departure VARCHAR(30) NOT NULL,
    arrival VARCHAR(30) NOT NULL,
    year INT NOT NULL,
    route_price DOUBLE,
    CONSTRAINT pk_route PRIMARY KEY(routeID)
);

CREATE TABLE weeklyschedule (
    scheduleID INT NOT NULL AUTO_INCREMENT,
    day VARCHAR(10) NOT NULL,
    year INT NOT NULL,
    route INT NOT NULL,
    departure_time TIME NOT NULL,
    CONSTRAINT pk_weekly_schedule PRIMARY KEY(scheduleID)
);

CREATE TABLE flight (
    flightID INT NOT NULL AUTO_INCREMENT,
    scheduleID INT NOT NULL,
    week_no INT,
    CONSTRAINT pk_flight PRIMARY KEY(flightID)
);

ALTER TABLE contact ADD CONSTRAINT fk_contact_passenger FOREIGN KEY (passportNr) REFERENCES passenger(passportNr);

ALTER TABLE reservation ADD CONSTRAINT fk_reservation_contact FOREIGN KEY (contact_passportNr) REFERENCES contact(passportNr);
ALTER TABLE reservation ADD CONSTRAINT fk_reservation_flight FOREIGN KEY (flightID) REFERENCES flight(flightID);

ALTER TABLE booking ADD CONSTRAINT fk_booking_reservation FOREIGN KEY (reservationID) REFERENCES reservation(reservationID);
ALTER TABLE booking ADD CONSTRAINT fk_booking_bankcard FOREIGN KEY (cardNr) REFERENCES bankcard(cardNr);

ALTER TABLE ticket ADD CONSTRAINT fk_ticket_passenger FOREIGN KEY (passportNr) REFERENCES passenger(passportNr);
ALTER TABLE ticket ADD CONSTRAINT fk_ticket_booking FOREIGN KEY (booked_reservation_id) REFERENCES booking(reservationID);

ALTER TABLE unpaidreservation ADD CONSTRAINT fk_ur_passenger FOREIGN KEY (passportNr) REFERENCES passenger(passportNr);
ALTER TABLE unpaidreservation ADD CONSTRAINT fk_ur_reservation FOREIGN KEY (reservationID) REFERENCES reservation(reservationID);

ALTER TABLE route ADD CONSTRAINT fk_route_departure FOREIGN KEY (departure) REFERENCES airport(airport_code);
ALTER TABLE route ADD CONSTRAINT fk_route_arrival FOREIGN KEY (arrival) REFERENCES airport(airport_code);
ALTER TABLE route ADD CONSTRAINT fk_route_year FOREIGN KEY (year) REFERENCES year(year);

ALTER TABLE flight ADD CONSTRAINT fk_flight_schedule FOREIGN KEY (scheduleID) REFERENCES weeklyschedule(scheduleID);

ALTER TABLE weekday ADD CONSTRAINT fk_weekday_year FOREIGN KEY (year) REFERENCES year(year);

ALTER TABLE weeklyschedule ADD CONSTRAINT fk_schedule_route FOREIGN KEY (route) REFERENCES route(routeID);
#ALTER TABLE weeklyschedule ADD CONSTRAINT fk_schedule_year FOREIGN KEY (year) REFERENCES year(year);
ALTER TABLE weeklyschedule ADD CONSTRAINT fk_schedule_weekday FOREIGN KEY (day, year) REFERENCES weekday(day_name, year);

-- QUESTION 3 - Procedures
# a)
DELIMITER $$
CREATE PROCEDURE addYear(year INT, factor DOUBLE)
BEGIN
	INSERT INTO year(year, profit_factor)
	VALUES (year, factor);
END; $$
DELIMITER ;

# b)
DELIMITER $$
CREATE PROCEDURE addDay(year INT, day VARCHAR(10), factor DOUBLE)
BEGIN
	INSERT INTO weekday(day_name, year, weekday_factor)
	VALUES (day, year, factor);
END; $$
DELIMITER ;

# c)
DELIMITER $$
CREATE PROCEDURE addDestination(airport_code VARCHAR(3), name VARCHAR(30), country VARCHAR(30))
BEGIN
	INSERT INTO airport(airport_code, airport_name, country)
	VALUES (airport_code, name, country);
END; $$
DELIMITER ;

# d)
DELIMITER $$
CREATE PROCEDURE addRoute(departure_airport_code VARCHAR(3), arrival_airport_code VARCHAR(3), year INT, routeprice DOUBLE)
BEGIN
	INSERT INTO route(departure, arrival, year, route_price)
	VALUES (departure_airport_code, arrival_airport_code, year, routeprice);
END; $$
DELIMITER ;

# e)
DELIMITER $$
CREATE PROCEDURE addFlight(departure_airport_code VARCHAR(3), arrival_airport_code VARCHAR(3), 
							year INT, day VARCHAR(10), departure_time TIME)
BEGIN
	DECLARE week_number INT;
	DECLARE route_id INT;
	DECLARE schedule_id INT;

	SET week_number = 0;
	SET route_id = (SELECT routeID 
					FROM route 
					WHERE route.departure=departure_airport_code AND 
                    route.arrival=arrival_airport_code AND 
                    route.year=year);

	INSERT INTO weeklyschedule(day, year, route, departure_time)
	VALUES (day, year, route_id, departure_time);

	SET schedule_id = (SELECT scheduleID 
						FROM weeklyschedule ws
						WHERE ws.day=day AND 
							ws.year=year AND 
							ws.route=route_id AND
							ws.departure_time=departure_time);

	loop_label: LOOP
		SET week_number = week_number + 1;
		IF week_number > 52 THEN
			LEAVE loop_label;
		END IF;
		INSERT INTO flight(scheduleID, week_no)
		VALUES (schedule_id, week_number);
	END LOOP;
END; $$
DELIMITER ;

-- QUESTION 4 - Help functions
# a)
DELIMITER //
CREATE FUNCTION calculateFreeSeats(flightnumber INT) RETURNS INT
BEGIN
    DECLARE booked_seats INT;
    DECLARE free_seats INT;
    
    SET booked_seats = (SELECT COUNT(*)
						FROM unpaidreservation ur, reservation r, flight f
                        WHERE ur.reservationID=r.reservationID AND 
                            r.flightID=f.flightID AND 
                            f.flightID=flightnumber);
	SET free_seats = 40 - booked_seats;
    RETURN free_seats;
END; //
DELIMITER ;

# b)
DELIMITER $$
CREATE FUNCTION calculatePrice(flightnumber INT) RETURNS DOUBLE
BEGIN
    DECLARE routePrice DOUBLE;
    DECLARE weekdayFactor DOUBLE;
    DECLARE bookedPassengers INT;
    DECLARE profitFactor DOUBLE;
	DECLARE totalPrice DOUBLE;
    
    SET routePrice = (SELECT route_price 
						FROM route 
                        WHERE routeID = (SELECT route 
										FROM weeklyschedule 
                                        WHERE scheduleID = (SELECT scheduleID
															FROM flight
                                                            WHERE flightID = flightnumber)));
	
    SET weekdayFactor = (SELECT weekday_factor
						FROM weekday wd
                        JOIN weeklyschedule ws ON wd.day_name=ws.day AND wd.year=ws.year
                        WHERE scheduleID = (SELECT scheduleID
											FROM flight
                                            WHERE flightID = flightnumber));
    
    SET bookedPassengers = 40 - calculateFreeSeats(flightnumber);
    
    SET profitFactor = (SELECT profit_factor
						FROM year y
                        WHERE y.year = (SELECT year
										FROM weeklyschedule ws
										WHERE ws.scheduleID = (SELECT scheduleID
																FROM flight f
																WHERE f.flightID = flightnumber)));
    
    SET totalPrice = routePrice * weekdayFactor * ((bookedPassengers + 1)/40) * profitFactor;
	RETURN totalPrice;
END; $$
DELIMITER ;

-- QUESTION 5 - Triggers
DELIMITER $$
CREATE TRIGGER generateTicketID 
BEFORE INSERT ON ticket FOR EACH ROW
BEGIN
	SET NEW.ticketID = RAND()*(1000-1)+1;
END; $$
DELIMITER ;

-- QUESTION 6 - Reservation help functions
# a)
DELIMITER $$
CREATE PROCEDURE addReservation(IN departure_airport_code VARCHAR(3), 
								IN arrival_airport_code VARCHAR(3), 
                                IN year INT, 
                                IN week INT,
								IN day VARCHAR(10), 
                                IN time TIME, 
                                IN number_of_passengers INT, 
                                OUT output_reservation_nr INT)
BEGIN
	DECLARE flight_id INT;
    SET flight_id = (SELECT DISTINCT flightID
					FROM flight f, weeklyschedule ws, route r
					WHERE f.week_no=week AND f.scheduleID=ws.scheduleID AND 
						ws.day=day AND ws.year=year AND ws.departure_time=time AND
						ws.route=r.routeID AND r.departure=departure_airport_code AND 
						r.arrival=arrival_airport_code AND r.year=year);
	IF flight_id IS NULL THEN
		SELECT "There exist no flight for the given route, date and time" AS "Message";
	ELSE
		IF number_of_passengers > calculateFreeSeats(flight_id) THEN
			SELECT "There are not enough seats available on the chosen flight" AS "Message";
		ELSE
			INSERT INTO reservation(flightID, numberOfSeats) VALUES (flight_id, number_of_passengers);
            SET output_reservation_nr = LAST_INSERT_ID();
		END IF;
	END IF;
END; $$
DELIMITER ;

# b)
DELIMITER $$
CREATE PROCEDURE addPassenger(reservation_nr INT, passport_number INT, name VARCHAR(30))
BEGIN
	DECLARE resID INT;
    DECLARE passengerID INT;
    DECLARE paid_resID INT;
    
	SET resID = (SELECT reservationID FROM reservation WHERE reservationID=reservation_nr);
    IF resID IS NOT NULL THEN
		SET paid_resID = (SELECT reservationID FROM booking WHERE reservationID=reservation_nr);
		IF paid_resID IS NULL THEN
			SET passengerID = (SELECT passportNr FROM passenger WHERE passportNr=passport_number);
			IF passengerID IS NULL THEN
				INSERT INTO passenger(passportNr, passenger_name) VALUES (passport_number, name);
			END IF;
			INSERT INTO unpaidreservation(passportNr, reservationID) VALUES (passport_number, reservation_nr);
		ELSE
			SELECT "The booking has already been payed and no futher passengers can be added" AS "Message";
		END IF;
	ELSE
		SELECT "The given reservation number does not exist" AS "Message";
    END IF;
END; $$
DELIMITER ;

# c)
DELIMITER $$
CREATE PROCEDURE addContact(reservation_nr INT, passport_number INT, email VARCHAR(30), phone BIGINT(20))
BEGIN
    DECLARE resID INT;
    DECLARE contactID INT;
    SET resID = (SELECT reservationID FROM reservation WHERE reservationID=reservation_nr);
    IF resID IS NOT NULL THEN
		SET contactID = (SELECT DISTINCT p.passportNr 
						FROM passenger p, unpaidreservation ur 
                        WHERE p.passportNr=passport_number AND ur.passportNr=passport_number AND ur.reservationID=reservation_nr);
        IF contactID IS NOT NULL THEN
			INSERT INTO contact(passportNr, email, phone_no) VALUES (passport_number, email, phone);
            UPDATE reservation SET contact_passportNr=passport_number WHERE reservationID=reservation_nr;
        ELSE
			SELECT "The person is not a passenger of the reservation" AS "Message";
        END IF;
        
    ELSE
		SELECT "The given reservation number does not exist" AS "Message";
    END IF;
END; $$
DELIMITER ;

# d)
DELIMITER $$
CREATE PROCEDURE addPayment(reservation_nr INT, cardholder_name VARCHAR(30), credit_card_number BIGINT(20))
BEGIN
	DECLARE resID INT;
    DECLARE contact_res INT;
    DECLARE flight_id INT;
    DECLARE no_of_seats INT;
    DECLARE total_price DOUBLE;
    
    SET resID = (SELECT reservationID FROM reservation WHERE reservationID=reservation_nr);
    IF resID IS NOT NULL THEN
		SET contact_res = (SELECT contact_passportNr FROM reservation WHERE reservationID=resID);
        IF contact_res IS NOT NULL THEN
			SET flight_id = (SELECT flightID FROM reservation WHERE reservationID = reservation_nr AND contact_passportNr=contact_res);
            SET no_of_seats = (SELECT numberOfSeats FROM reservation WHERE reservationID=reservation_nr AND contact_passportNr=contact_res AND flightID=flight_id);
            IF calculateFreeSeats(flight_id) > 0 THEN
				INSERT INTO bankcard(cardNr, cardHolder) VALUES (credit_card_number, cardholder_name);
                SET total_price = calculatePrice(flight_id);
                INSERT INTO booking(reservationID, cardNr, total_price) VALUES (reservation_nr, credit_card_number, total_price);
                INSERT INTO ticket(passportNr, booked_reservation_id) SELECT passportNr, reservationID FROM unpaidreservation WHERE reservationID=reservation_nr;
            ELSE
                DELETE FROM unpaidreservation WHERE reservationID=reservation_nr;
                DELETE FROM reservation WHERE reservationID=reservation_nr;
                SELECT "There are not enough seats available on the flight anymore, deleting reservation" AS "Message";
			END IF;
        ELSE
			SELECT "The reservation has no contact yet" AS "Message";
        END IF;
    ELSE
		SELECT "The given reservation number does not exist" AS "Message";
    END IF;
END; $$
DELIMITER ;

-- QUESTION 7 - allFlights view
CREATE VIEW allFlights(departure_city_name, destination_city_name, departure_time, 
departure_day, departure_week, departure_year, nr_of_free_seats, current_price_per_seat) AS
SELECT a1.airport_name, a2.airport_name, ws.departure_time, ws.day, f.week_no, ws.year,
calculateFreeSeats(f.flightID), ROUND(calculatePrice(f.flightID),3)
FROM weeklyschedule ws, flight f, route r, airport a1, airport a2
WHERE ws.scheduleID = f.scheduleID and 
		ws.route = r.routeID and 
        r.departure = a1.airport_code and 
        r.arrival = a2.airport_code
		
-- QUESTION 8 - Theoretical Questions
# a) Since credit card info contain confidential information it is very important to ensure safety. 
# A good approach that is very often used is to encrypt those data. Furthermore, access management 
# should be automated and generally employees should have the least interaction with the database, 
# as an employee could take advantage of its position if excesive authorization is given. 
# It's very important also to use Database firewalls that will allow only specific access to the database
# but will also keep track of all the connections made and take actions in case an attack is detected.

# b)  
# i) Reusability: Stored procedures can be used by different applications and therefore there's no need to
# write multiple times those program modules.
# ii) Security: The database maintainers can grant specific previleges to users and forbid direct access 
# to the tables. Therefore, manipulation of data can be done through stored procedures.
# iii) Faster execution: Stored procedures are inside the server and are compiled once and cached during 
# one session. Therefore, the execution is faster and higher performance is achieved. 
# After the end of that session the cached statements are discarded.

-- QUESTION 9 - Creating Transactions

-- Session A
-- START TRANSACTION;
-- CALL addYear(2010, 2.3);
-- CALL addDay(2010,"Monday",1);
-- CALL addDestination("MIT","Minas Tirith","Mordor");
-- CALL addDestination("HOB","Hobbiton","The Shire");
-- CALL addRoute("MIT","HOB",2010,2000);
-- CALL addFlight("MIT","HOB", 2010, "Monday", "09:00:00");
-- CALL addReservation("MIT","HOB",2010,1,"Monday","09:00:00",3,@a); 
-- select * from reservation;

-- Session B
-- START TRANSACTION;
-- select * from reservation;
-- UPDATE reservation SET numberOfSeats = 10 WHERE reservationID=1;

# b) 
# The reservation is not visible in session B. When starting a new transaction (session B), any changes that
# happen to the previous one (session A) must first be commited in order to make the changes permanent, thus 
# see them in the new transaction.

# c) 
# When trying to modify the added reservation from A in session B (eg. change the number of seats), 
# the query cannot run. The way this relates to the concept of isolation of transactions is that
# database transactions must complete their tasks independently from the other transactions.
# This means that any data modifications which are made in session B cannot be made, until transactions 
# in session A commit their actions first. 

-- QUESTION 10 - Testing database
# a) 
# Test message shows us that number of free seats on the flight are 19, so this means that no overbooking occured.
# Although we had two scripts adding passengers to reservations of the same flight and then try to pay the reservations
# to book the seats, there was no overbooking. 
# This happened because There was a small delay when we run the same script twice, so the first script payed for its 
# reservation, booked the seats and left 40-21=19 empty seats.
# When the second script tried to pay for a reservation of 21 people it could not do it so the reservation payment 
# was aborted and there were left 19 empty seats for the flight.

# b) 
# Theoretically, an overbooking can happen in this case, if we follow the steps below:
# 1. Create reservation1 (with reservationID=100) for flight1 (with flight_ID=1)
# 2. Add 20 passengers to reservation1
# 3. Create reservation2 (with reservationID=200) for flight1 (with flight_ID=1)
# 4. Add 21 passengers to reservation2
# 5. Pay reservation1 and reservation2 AT THE SAME TIME
# 6. Now, we have overbooking because flight1 contains 41 passengers in total (or -1 free seats)
# Comment: This can also be repeated for multiple reservations but it has to be for the same flight

# c) 
# A theoretical approach to make an overbook happen would be if we run Question10MakeBooking.sql script in two 
# separate transactions. Since we did not commit our changes before creating the second transaction, addPayment 
# successfully makes the payment for both reservations in each transaction. Now in order to make an overbook, 
# we have to commit both transactions. 
# We also tried to put a SELECT SLEEP(5) in the beginning of addPassenger to trigger an overbooking, but neither
# of the approaches worked for our implementation.

# d) In order to prevent overbookings using explicit transaction control, we should use the commands START TRANSACTION,
# LOCK TABLES, UNLOCK TABLES, COMMIT. More specifically, right before addPayment we should LOCK TABLES in order
# to prevent modifications. We start the first transaction and then addPayment of the first transaction 
# will be successfully done. Then, we UNLOCK TABLES and COMMIT changes in the first transaction. When the
# second transaction will start it will see that there are only 19 free seats and will cancel the payment. So, there
# will be no overbooking at the end.
