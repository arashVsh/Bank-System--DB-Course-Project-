import pymysql
from prettytable import PrettyTable

# Replace these values with your database connection details
db_host = 'localhost'
db_user = 'root'
db_password = '3354'
db_name = 'BankDB2'

# Connect to the database
connection = pymysql.connect(host=db_host, user=db_user, password=db_password, database=db_name)
cursor = connection.cursor()
USER_ID = 0
accountNumber = ""


def show_accounts():
    global USER_ID
    try:
        # Create a new cursor

        # Call the procedure to get account information
        cursor.callproc('GetAccountsInfo', (USER_ID,))

        # Fetch all the results
        results = cursor.fetchall()

        # Create a PrettyTable instance
        table = PrettyTable()

        # Define table columns
        table.field_names = ["Account Number", "Blocked", "Current Balance"]

        # Add data to the table
        for result in results:
            table.add_row(result)

        # Set alignment for columns
        table.align["Account Number"] = "l"
        table.align["Blocked"] = "r"
        table.align["Current Balance"] = "r"

        # Print the table
        print(table)

    except Exception as e:
        print(f"Error: {e}")



def transfer_money():
    global USER_ID
    source_account = input("Enter your account number: ")
    dest_account = input("Enter the destination account number: ")
    amount = float(input("Enter the amount to transfer: "))

    try:
        # Call the moneyTransfer stored procedure
        cursor.callproc('moneyTransfer', (source_account, dest_account, amount, False))

        # Fetch the result
        cursor.execute('SELECT @_moneyTransfer_3')  # Use the correct OUT parameter index
        result = cursor.fetchone()

        if result:
            success = result[0]
            if success:
                print("Money transfer successful.")
            else:
                print("Money transfer failed. Check if the source account is not blocked and has enough balance.")
        else:
            print("Error fetching result.")

    except Exception as e:
        print(f"Error: {e}")


def list_recent_transactions():
    global USER_ID
    account_number = input("Enter your account number: ")
    n = int(input("Enter the number of recent transactions to display: "))

    try:
        cursor.callproc('GetRecentTransactions', (account_number, n))
        result = cursor.fetchall()

        if result:
            table = PrettyTable()
            table.field_names = ["Transaction ID", "Origin Account", "Destination Account", "Amount", "Transaction Date"]
            for row in result:
                table.add_row(row)
            print(table)
        else:
            print(f"No recent transactions found for account {account_number}.")

    except Exception as e:
        print(f"Error: {e}")


def list_transactions_between_dates():
    global USER_ID
    account_number = input("Enter your account number: ")
    start_date = input("Enter the start date (YYYY-MM-DD): ")
    end_date = input("Enter the end date (YYYY-MM-DD): ")

    try:
        cursor.callproc('getTransactionsByDate', (account_number, start_date, end_date))
        result = cursor.fetchall()

        if result:
            table = PrettyTable()
            table.field_names = ["Transaction ID", "Origin Account", "Destination Account", "Amount", "Transaction Date"]
            for row in result:
                table.add_row(row)
            print(table)
        else:
            print(f"No transactions found for account {account_number} between {start_date} and {end_date}.")

    except Exception as e:
        print(f"Error: {e}")


def blockAccount():
    global connection, cursor
    account_number = input("Enter the account number to block: ")

    try:
        cursor.callproc('BlockAccount', (account_number, 0))
        connection.commit()

        # Fetch the result parameter
        cursor.execute("SELECT @p_success")
        print(f"Account {account_number} blocked successfully.")


    except Exception as e:
        print(f"Error: {e}")


def unblockAccount():
    global connection, cursor
    account_number = input("Enter the account number to unblock: ")

    try:
        cursor.callproc('UnblockAccount', (account_number, 0))
        connection.commit()

        # Fetch the result parameter
        cursor.execute("SELECT @p_success")
        print(f"Account {account_number} unblocked successfully.")

    except Exception as e:
        print(f"Error: {e}")


def list_loans():
    global USER_ID
    try:
        cursor.callproc('ListOfLoans', (USER_ID,))
        result = cursor.fetchall()

        if result:
            table = PrettyTable()
            table.field_names = ["Loan ID"]
            for row in result:
                table.add_row(row)
            print(table)
        else:
            print(f"No loans found for user {USER_ID}.")

    except Exception as e:
        print(f"Error: {e}")


def list_loan_installments():
    global USER_ID
    loan_id = input("Enter the loan ID: ")

    try:
        cursor.callproc('ListOfInstallments', (loan_id))
        result = cursor.fetchall()

        if result:
            table = PrettyTable()
            table.field_names = ["Installment ID", "Loan ID", "Due Date", "Amount", "Paid Amount", "Paid Count", "Unpaid Count", "Total Paid Amount", "Remaining Unpaid Amount"]
            for row in result:
                table.add_row(row)
            print(table)
        else:
            print(f"No installments found for loan {loan_id}.")

    except Exception as e:
        print(f"Error: {e}")


def payInstallment():
    global USER_ID
    loan_id = input("Enter the loan ID: ")

    try:
        cursor.callproc('payInstallment', (int(loan_id),))
        connection.commit()
        print("Installment paid successfully.")
    except Exception as e:
        print(f"Error: {e}")


def getLoan():
    global connection, cursor
    account_number = input("Enter the account number to get a loan: ")

    try:
        # Call the GetLoan stored procedure
        cursor.callproc('GetLoan', (account_number,))

        # Commit the transaction
        connection.commit()

        print(f"Request sent.")

    except Exception as e:
        # Rollback the transaction in case of an error
        connection.rollback()
        print(f"Error: {e}")

# Call the function


def login():
    global USER_ID
    while True:
        entered_username = ""
        entered_password = ""

        entered_username = input("Username: ")
        entered_password = input("Password: ")

        # entered_username = "Arash_Vsh"
        # entered_password = "1234"

        try:
            # Call the login stored procedure
            cursor.callproc('Login', (entered_username, entered_password))

            # Fetch the result
            result = cursor.fetchone()

            if result:
                USER_ID = result[0]
                if USER_ID > 0:
                    print("Logged in as {}, User ID: {}".format(entered_username, USER_ID))
                    break
                else:
                    print("Login failed. User not found or incorrect password.")
            else:
                print("Login failed. User not found or incorrect password.")

        except Exception as e:
            print(f"Error: {e}")


def menu():
    global USER_ID
    while True:
        print("\n1- Show Accounts")
        print("2- Transfer money")
        print("3- List of the last N transactions")
        print("4- List of transactions between two dates")
        print("5- Block Account")
        print("6- List of Loans: ")
        print("7- Loan Installments")
        print("8- Pay one installment")
        print("9- Unblock Account")
        print("10- Request Loan")
        print("11- Exit\n")

        choice = input("Your choice: ")
        while choice == '':
            choice = input("Your choice: ")

        choice = int(choice)
        if choice == 1:
            show_accounts()
        elif choice == 2:
            transfer_money()
        elif choice == 3:
            list_recent_transactions()
        elif choice == 4:
            list_transactions_between_dates()
        elif choice == 5:
            blockAccount()
        elif choice == 6:
            list_loans()
        elif choice == 7:
            list_loan_installments()
        elif choice == 8:
            payInstallment()
        elif choice == 9:
            unblockAccount()
        elif choice == 10:
            getLoan()
        elif choice == 11:
            break
        else:
            print("Invalid choice.")


if __name__ == "__main__":
    login()
    menu()
