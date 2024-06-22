# AdvancedBettingDBQueries
This repository contains advanced MS SQL scripts for managing a betting site's customer database. It includes complex queries, functions, procedures, and triggers for efficient data management.

----- Contents :
Tables:

Customers: 

	Stores customer information.,
 
Bets:

		Stores betting information.

Transactions: 

		Stores customer transaction details.

Functions:

	fn_DailyTotalBets: Calculates the total bet amount for a given date.
	fn_CustomerTotalWinnings: Calculates a customer's total winnings.
	fn_CustomerBalance: Calculates a customer's balance.
 
Procedures:

	sp_AddBet: Adds a new bet and checks the daily betting limit and customer balance.
 
Triggers:

	trg_UpdateCustomerWinnings: Updates customer winnings and transactions when the bet outcome is updated.

Queries:

	Retrieves a summary of bets and winnings for the last 30 days.
	Retrieves inactive customers (those who haven't placed a bet in the last 6 months).
	Retrieves the top-winning customer.
 
Usage

	Create the database and tables using the provided SQL scripts.
	Insert sample data into the Customers, Bets, and Transactions tables.
	Create functions, procedures, and triggers in your database.
	Run the queries to analyze customer and betting data.
 
Notes to be Readed !!!

This is a sample database structure and should be thoroughly tested before use in a real system.
Business rules like the daily betting limit and customer balance checks are defined in the sp_AddBet procedure and can be customized as needed.
Use triggers and procedures carefully as they may impact performance.
