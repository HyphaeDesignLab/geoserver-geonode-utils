# to be used for Geonode OAuth application of type "client credentials"
import base64
import sys
user=sys.argv[1]
pass=sys.argv[2]
credential = "{0}:{1}".format(user, pass)
auth_string_encoded = base64.b64encode(credential.encode("utf-8"))
print(auth_string_encoded)