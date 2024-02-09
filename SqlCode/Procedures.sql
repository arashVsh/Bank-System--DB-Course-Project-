
DELIMITER //
CREATE PROCEDURE Login(
    IN p_username VARCHAR(30),
    IN p_hashed_password VARCHAR(255)
)
BEGIN
    DECLARE user_id INT;

    -- Check if username and hashed password match a record in the Users table
    SELECT ID INTO user_id
    FROM Users
    WHERE Username = p_username AND HashedPassword = p_hashed_password;

    -- Return the user ID or 0 if there is no match
    IF user_id IS NULL THEN
        SELECT 0 AS UserID;
    ELSE
        SELECT user_id AS UserID;
    END IF;
END //

DELIMITER ;

-- CALL Login('arashv', SHA2(CONCAT('password123', (SELECT Salt FROM Users WHERE Username = 'arashv')), 256));

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE ChangePassword(
    IN p_user_id INT,
    IN p_hashed_prev_password VARCHAR(255),
    IN p_hashed_new_password VARCHAR(255)
)
BEGIN
    -- Check if the user and previous hashed password match
    IF EXISTS (
        SELECT 1
        FROM Users
        WHERE ID = p_user_id AND HashedPassword = p_hashed_prev_password
    ) THEN
        -- Update the password with the new hashed password
        UPDATE Users
        SET HashedPassword = p_hashed_new_password
        WHERE ID = p_user_id;

        SELECT 'Password changed successfully' AS Result;
    ELSE
        SELECT 'Invalid user or previous password' AS Result;
    END IF;
END //

DELIMITER ;

-- CALL ChangePassword(
--     1, -- User ID
--     SHA2(CONCAT('password123', (SELECT Salt FROM Users WHERE ID = 1)), 256), -- Hashed Previous Password
--     SHA2(CONCAT('newpassword456', (SELECT Salt FROM Users WHERE ID = 1)), 256) -- Hashed New Password
-- );

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE GetAccountsInfo(
    IN p_user_id INT
)
BEGIN
    -- Retrieve account information and current balance for the given user
    SELECT DISTINCT A.AccountNumber, A.Blocked, B.Amount AS CurrentBalance
    FROM Accounts A
    LEFT JOIN Balance B ON A.AccountNumber = B.AccountNumber
    WHERE A.UserID = p_user_id
      AND B.BalanceDate = (
            SELECT MAX(BalanceDate) 
            FROM Balance 
            WHERE AccountNumber = A.AccountNumber
        );
END //

DELIMITER ;


--  CALL GetAccountsInfo(1); -- Replace 1 with the actual user ID

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE GetRecentTransactions(
    IN p_account_number CHAR(10),
    IN p_last_n_transactions INT
)
BEGIN
    -- Retrieve the last N transactions related to the specified account
    SELECT ID, OriginAccountNumber, DestAccountNumber, Amount, TransactionDate
    FROM Transactions
    WHERE OriginAccountNumber = p_account_number OR DestAccountNumber = p_account_number
    ORDER BY TransactionDate DESC
    LIMIT p_last_n_transactions;
END //

DELIMITER ;

-- CALL GetRecentTransactions('1234567890', 5);

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE getTransactionsByDate(
    IN p_account_number CHAR(10),
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    -- Retrieve transactions related to the specified account between the given dates
    SELECT ID, OriginAccountNumber, DestAccountNumber, Amount, TransactionDate
    FROM Transactions
    WHERE (OriginAccountNumber = p_account_number OR DestAccountNumber = p_account_number)
      AND TransactionDate BETWEEN p_start_date AND p_end_date;
END //

DELIMITER ;

-- CALL GetTransactionsByDate('1234567890', '2023-01-01', '2023-12-31');

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE extractAccountDetails(
    IN p_account_number CHAR(10)
)
BEGIN
    DECLARE v_account_exists BOOLEAN;

    -- Check if the account exists
    SELECT EXISTS (
        SELECT 1
        FROM Accounts
        WHERE AccountNumber = p_account_number
    ) INTO v_account_exists;

    -- If the account exists, retrieve account details
    IF v_account_exists THEN
        SELECT U.Name, U.LastName, A.Blocked, B.Amount AS CurrentBalance
        FROM Users U
        INNER JOIN Accounts A ON U.ID = A.UserID
        LEFT JOIN Balance B ON A.AccountNumber = B.AccountNumber
        WHERE A.AccountNumber = p_account_number
          AND B.BalanceDate = (
                SELECT MAX(BalanceDate) 
                FROM Balance 
                WHERE AccountNumber = A.AccountNumber
            );
    ELSE
        SELECT 'Account not found' AS Result;
    END IF;
END //

DELIMITER ;

-- CALL ExtractAccountDetails('1234567890'); -- Replace with the actual account number

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE GetOwnerName(
    IN p_account_number CHAR(10)
)
BEGIN
    -- Retrieve the name and last name of the owner for the specified account
    SELECT U.Name, U.LastName
    FROM Users U
    INNER JOIN Accounts A ON U.ID = A.UserID
    WHERE A.AccountNumber = p_account_number;
END //

DELIMITER ;

-- CALL GetOwnerName('1234567890'); -- Replace with the actual account number

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE BlockAccount(
    IN p_account_number CHAR(10),
    OUT p_success BOOLEAN
)
BEGIN
    -- Block the specified account
    UPDATE Accounts
    SET Blocked = TRUE
    WHERE AccountNumber = p_account_number;

    -- Check if the update was successful
    SET p_success = ROW_COUNT() > 0;
END //

DELIMITER ;

-- CALL BlockAccount('1234567890', @success);
-- SELECT @success;
-- SELECT * FROM Accounts;


-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE UnBlockAccount(
    IN p_account_number CHAR(10),
    OUT p_success BOOLEAN
)
BEGIN
    -- Block the specified account
    UPDATE Accounts
    SET Blocked = FALSE
    WHERE AccountNumber = p_account_number;

    -- Check if the update was successful
    SET p_success = ROW_COUNT() > 0;
END //

DELIMITER ;

CALL UnBlockAccount('1234567890', @success);

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE moneyTransfer(
    IN p_source_account_number CHAR(10),
    IN p_destination_account_number CHAR(10),
    IN p_amount DECIMAL(15, 2),
    OUT p_success BOOLEAN
)
BEGIN
    DECLARE v_source_balance DECIMAL(15, 2);
    DECLARE v_destination_balance DECIMAL(15, 2);

    -- Check if the source account is not blocked
    SELECT not(Blocked) INTO p_success
    FROM Accounts
    WHERE AccountNumber = p_source_account_number AND Blocked = FALSE;

    -- If the source account is not blocked, proceed with the transfer
    IF p_success THEN
        -- Retrieve the current balances for source and destination accounts
        SELECT Amount INTO v_source_balance
        FROM Balance
        WHERE AccountNumber = p_source_account_number
        ORDER BY BalanceDate DESC
        LIMIT 1;

        SELECT Amount INTO v_destination_balance
        FROM Balance
        WHERE AccountNumber = p_destination_account_number
        ORDER BY BalanceDate DESC
        LIMIT 1;

        -- Check if the source account has enough balance for the transfer
        IF v_source_balance >= p_amount THEN
            -- Perform the money transfer
            START TRANSACTION;

            -- Update the source account balance
            INSERT INTO Balance(AccountNumber, Amount, BalanceDate)
            VALUES (p_source_account_number, v_source_balance - p_amount, NOW());

            -- Update the destination account balance
            INSERT INTO Balance(AccountNumber, Amount, BalanceDate)
            VALUES (p_destination_account_number, v_destination_balance + p_amount, NOW());

            -- Record the transaction in the Transactions table
            INSERT INTO Transactions(OriginAccountNumber, DestAccountNumber, Amount, TransactionDate)
            VALUES (p_source_account_number, p_destination_account_number, p_amount, NOW());

            COMMIT;
            SET p_success = TRUE;
        ELSE
            SET p_success = FALSE;
        END IF;
    END IF;
END //

DELIMITER ;

-- CALL MoneyTransfer('1234567890', '9876543210', 100.00, @success);
-- SELECT @success;

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE AvailableLoanCalculator(
    IN p_account_number CHAR(10),
    OUT p_min_balance DECIMAL(15, 2)
)
BEGIN
    -- Retrieve the minimum balance for the specified account in the last two months
    SELECT MIN(Amount) INTO p_min_balance
    FROM Balance
    WHERE AccountNumber = p_account_number
      AND BalanceDate >= CURDATE() - INTERVAL 2 MONTH;
END //

DELIMITER ;

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE GetLoan(
    IN p_account_number CHAR(10)
)
BEGIN
    DECLARE v_blocked BOOLEAN;
    DECLARE v_has_inuse_loan BOOLEAN;
    DECLARE v_available_loan DECIMAL(15, 2);
    DECLARE v_loan_id INT;
    DECLARE currentBalance INT;
    DECLARE v_installment_amount DECIMAL(15, 2);
    DECLARE i INT DEFAULT 0;

    -- Check if the account is blocked
    SELECT Blocked INTO v_blocked
    FROM Accounts
    WHERE AccountNumber = p_account_number;

    -- Check if the account has any in-use loan with unpaid installments
    SELECT EXISTS (
        SELECT 1
        FROM Loans L
        JOIN Installments I ON L.LoanID = I.LoanID
        WHERE L.AccountNumber = p_account_number
          AND I.PaidAmount < I.Amount
    ) INTO v_has_inuse_loan;

    -- If the account is not blocked and has no in-use loan, get the available loan
    IF NOT v_blocked AND NOT v_has_inuse_loan THEN
        -- Call AvailableLoanCalculator to get the available loan
        CALL AvailableLoanCalculator(p_account_number, v_available_loan);

        -- Start a transaction for atomicity
        START TRANSACTION;

		SELECT Amount INTO currentBalance
        FROM Balance
        WHERE AccountNumber = p_account_number
        ORDER BY BalanceDate DESC
        LIMIT 1;
        
        -- Add a new record to the Balance table with the available loan
        INSERT INTO Balance(AccountNumber, Amount, BalanceDate)
        VALUES (p_account_number, currentBalance + v_available_loan, NOW());

        -- Add a record to the Loans table and get the loan ID
        INSERT INTO Loans(AccountNumber)
        VALUES (p_account_number);

        SET v_loan_id = LAST_INSERT_ID();

        -- Calculate the installment amount
        SET v_installment_amount = (v_available_loan + 0.2 * v_available_loan) / 12;

        -- Add 12 installments associated with the loan to the Installments table
        WHILE i < 12 DO
            INSERT INTO Installments(LoanID, DueDate, Amount)
            VALUES (v_loan_id, DATE_ADD(NOW(), INTERVAL i + 1 MONTH), v_installment_amount);
            SET i = i + 1;
        END WHILE;

        -- Commit the transaction
        COMMIT;
    END IF;
END //

DELIMITER ;


CALL GetLoan('1234567890');

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE ListOfLoans(
    IN p_user_id INT
)
BEGIN
    -- Retrieve the list of Loan IDs for the given user
    SELECT L.LoanID
    FROM Loans L
    JOIN Accounts A ON L.AccountNumber = A.AccountNumber
    WHERE A.UserID = p_user_id;
END //

DELIMITER ;

-- CALL ListOfLoans(1);


-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

DELIMITER //
CREATE PROCEDURE ListOfInstallments(
    IN p_loan_id INT
)
BEGIN
    -- Declare variables
    DECLARE v_paid_count INT;
    DECLARE v_unpaid_count INT;
    DECLARE v_total_paid_amount DECIMAL(15, 2);
    DECLARE v_remaining_amount DECIMAL(15, 2);

    -- Retrieve information about installments for the given loan
    SELECT 
        I.*,
        (SELECT COUNT(*) FROM Installments WHERE LoanID = p_loan_id AND PaidAmount >= Amount) AS paid_count,
        (SELECT COUNT(*) FROM Installments WHERE LoanID = p_loan_id AND PaidAmount < Amount) AS unpaid_count,
        (SELECT SUM(PaidAmount) FROM Installments WHERE LoanID = p_loan_id) AS total_paid_amount,
        (SELECT SUM(Amount - PaidAmount) FROM Installments WHERE LoanID = p_loan_id) AS remaining_amount
    FROM Installments I
    WHERE I.LoanID = p_loan_id;
END //

DELIMITER ;

CALL ListOfInstallments(1);

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE payInstallment(
    IN p_loan_id INT
)
BEGIN
    DECLARE v_installment_id INT;
    DECLARE v_due_date DATE;
    DECLARE v_paid_amount DECIMAL(15, 2);
    DECLARE v_account_number CHAR(10);
    DECLARE v_new_balance DECIMAL(15, 2);
	DECLARE last_balance DECIMAL(15, 2);

    -- Find the account number associated with the loan
    SELECT AccountNumber
    INTO v_account_number
    FROM Loans
    WHERE LoanID = p_loan_id;

    -- Find the installment with the closest Due Date for the given loan
    SELECT InstallmentID, DueDate, Amount
    INTO v_installment_id, v_due_date, v_paid_amount
    FROM Installments
    WHERE LoanID = p_loan_id AND DueDate >= CURDATE() AND PaidAmount = 0
    ORDER BY DueDate ASC
    LIMIT 1;

    -- Check if there is a valid installment to pay
    IF v_installment_id IS NOT NULL THEN
        -- Start a transaction for atomicity
        START TRANSACTION;

        -- Update the PaidAmount for the installment
        UPDATE Installments
        SET PaidAmount = PaidAmount + v_paid_amount
        WHERE InstallmentID = v_installment_id;

        -- Retrieve the new balance after the payment
        SELECT Amount INTO last_balance
        FROM Balance
        WHERE AccountNumber = v_account_number
        ORDER BY BalanceDate DESC
        LIMIT 1;

        -- Add the new balance to the Balance table
        INSERT INTO Balance(AccountNumber, Amount, BalanceDate)
        VALUES (v_account_number, last_balance - v_paid_amount, NOW());

        -- Commit the transaction
        COMMIT;
    END IF;
END //

DELIMITER ;

-- CALL PayInstallment(1);
CALL ListOfInstallments(1);

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE AddBankAccount(
    IN p_user_id INT,
    IN p_account_number CHAR(10),
    IN p_initial_balance DECIMAL(15, 2)
)
BEGIN
    -- Start a transaction for atomicity
    START TRANSACTION;

    -- Add a record to the Accounts table
    INSERT INTO Accounts (AccountNumber, UserID, CreatedDate)
    VALUES (p_account_number, p_user_id, CURRENT_DATE);

    -- Add a record to the Balance table with the initial balance
    INSERT INTO Balance (AccountNumber, Amount, BalanceDate)
    VALUES (p_account_number, p_initial_balance, CURRENT_DATE);

    -- Commit the transaction
    COMMIT;
END //

DELIMITER ;

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE AddUser(
    IN p_name VARCHAR(50),
    IN p_last_name VARCHAR(50),
    IN p_username VARCHAR(30),
    IN p_hashed_password VARCHAR(255),
    IN p_phone_number CHAR(11),
    IN p_email VARCHAR(50),
    IN p_is_admin BOOLEAN
)
BEGIN
    -- Add a record to the Users table
    INSERT INTO Users (Name, LastName, Username, HashedPassword, PhoneNumber, Email, IsAdmin)
    VALUES (p_name, p_last_name, p_username, p_hashed_password, p_phone_number, p_email, p_is_admin);
END //

DELIMITER ;


