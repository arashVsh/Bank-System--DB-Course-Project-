-- Create the database
CREATE DATABASE BankDB2;
USE BankDB2;
SET SQL_SAFE_UPDATES = 0;

-- --------------------------------------------------------------------------

CREATE TABLE Users (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(50),
    LastName VARCHAR(50),
    Username VARCHAR(30) UNIQUE,
    HashedPassword VARCHAR(255),
    Salt VARCHAR(50),
    PhoneNumber CHAR(11),
    Email VARCHAR(255),
    IsAdmin BOOLEAN DEFAULT FALSE
);

Select * from Users;

-- --------------------------------------------------------------------------

CREATE TABLE Accounts (
    AccountNumber CHAR(10) PRIMARY KEY,
    UserID INT,
    Blocked BOOLEAN DEFAULT FALSE,
    CreatedDate DATETIME,
    FOREIGN KEY (UserID) REFERENCES Users(ID) ON DELETE CASCADE
);

Select * from Accounts;

-- --------------------------------------------------------------------------

CREATE TABLE Transactions (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    OriginAccountNumber CHAR(10),
    DestAccountNumber CHAR(10),
    Amount DECIMAL(15, 2),
    TransactionDate DATETIME,
    FOREIGN KEY (OriginAccountNumber) REFERENCES Accounts(AccountNumber),
    FOREIGN KEY (DestAccountNumber) REFERENCES Accounts(AccountNumber)
);

Select * from Transactions;

-- --------------------------------------------------------------------------

CREATE TABLE Loans (
    LoanID INT PRIMARY KEY AUTO_INCREMENT,
    AccountNumber CHAR(10),
    FOREIGN KEY (AccountNumber) REFERENCES Accounts(AccountNumber)
);

Select * from Loans;

-- --------------------------------------------------------------------------

CREATE TABLE Installments (
    InstallmentID INT PRIMARY KEY AUTO_INCREMENT,
    LoanID INT,
    DueDate DATETIME,
    Amount DECIMAL(15, 2),
    PaidAmount DECIMAL(15, 2) DEFAULT 0,
    FOREIGN KEY (LoanID) REFERENCES Loans(LoanID)
);

Select * from Installments;

-- --------------------------------------------------------------------------

CREATE TABLE Balance (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    AccountNumber CHAR(10),
    Amount DECIMAL(15, 2),
    BalanceDate DATETIME,
    FOREIGN KEY (AccountNumber) REFERENCES Accounts(AccountNumber)
);

-- Constraints on the tables

ALTER TABLE Accounts
MODIFY COLUMN AccountNumber CHAR(10) CHECK (LENGTH(AccountNumber) = 10),
MODIFY COLUMN CreatedDate DATETIME NOT NULL;

ALTER TABLE Transactions
MODIFY COLUMN Amount DECIMAL(15, 2) CHECK (Amount >= 0);

ALTER TABLE Balance
MODIFY COLUMN Amount DECIMAL(15, 2) CHECK (Amount >= 0);

-- Add index on the Date column in Transactions table
CREATE INDEX idx_Transactions_Date ON Transactions (TransactionDate);

-- Add index on the Date column in Balance table
CREATE INDEX idx_Balance_Date ON Balance (BalanceDate);