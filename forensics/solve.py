import requests

url = 'http://94.237.58.196:35923/ec285935b46229d40b95438707a7efb2282f2f02.xml'

r = requests.get(url)

print(r.text)

# HTB{mSc_1s_b31n9_s3r10u5ly_4buSed}
