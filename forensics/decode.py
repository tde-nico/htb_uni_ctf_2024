from Crypto.Cipher import AES
from base64 import b64decode
from hashlib import sha256


b = 'ZzfccaKJB3CrDvOnj/6io5OR7jZGL0pr0sLO/ZcRNSa1JLrHA+k2RN1QkelHxKVvhrtiCDD14Aaxc266kJOzF59MfhoI5hJjc5hx7kvGAFw='
b = b64decode(b)

KEY = b'vudzvuokmioomyialpkyydvgqdmdkdxy'
KEY = sha256(KEY).digest()

IV = b'tbbliftalildywic'

cipher = AES.new(KEY, AES.MODE_CBC, iv=IV)

print(cipher.decrypt(b))
