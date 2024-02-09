
-- Add Users
CALL AddUser('Arash', 'Vashagh', 'Arash_Vsh', '1234', '09910402740', 'arash.vashagh@gmail.com', FALSE);
CALL AddUser('Ali', 'Khodami', 'aliK', '2345', '09307879209', 'ali.khodami@gmail.com', FALSE);

-- Add Accounts
CALL AddBankAccount(1, '1234567890', 1000.00);
CALL AddBankAccount(2, '9876543210', 500.00);

-- Test GetAccountsInfo Procedure
CALL GetAccountsInfo(1);

-- Test MoneyTransfer Procedure
CALL MoneyTransfer('1234567890', '9876543210', 30.00, @success);
SELECT @success;

-- Test GetRecentTransactions Procedure
CALL GetRecentTransactions('1234567890', 5);

-- Test GetLoan Procedure
CALL GetLoan('1234567890');

-- Test ListOfLoans Procedure
CALL ListOfLoans(1);

-- Test AvailableLoanCalculator Procedure
CALL AvailableLoanCalculator('1234567890', @min_balance);
SELECT @min_balance;

-- Test ListOfInstallments Procedure
CALL ListOfInstallments(1);

-- Test PayInstallment Procedure
CALL PayInstallment(1);

-- Display updated tables
SELECT * FROM Users;
SELECT * FROM Accounts;
SELECT * FROM Transactions;
SELECT * FROM Loans;
SELECT * FROM Installments;
SELECT * FROM Balance;
