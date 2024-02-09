import bcrypt

def hash_password_bcrypt(password):
    # Generate a random salt and hash the password
    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

    return hashed.decode('utf-8')

# Example usage
password = 'password123'

hashed_password = hash_password_bcrypt(password)
print(f"Original Password: {password}")
print(f"Hashed Password: {hashed_password}")
