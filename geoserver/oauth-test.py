import requests
import base64
url = "https://geo.domain/prefixpath/gwc/service/wmts?REQUEST=GetTile&SERVICE=WMTS&VERSION=1.0.0&LAYER=geonode:phm_us_shp_fixed&STYLE=&TILEMATRIX=EPSG:4326:8&TILEMATRIXSET=EPSG:4326&FORMAT=application/vnd.mapbox-vector-tile&TILECOL=98&TILEROW=67"
auth_creds_encoded = base64.b64encode('user:base64pass'.encode('utf-8'))
headers = {
    f"Authorization": "Basic {auth_creds_encoded}",  # Replace with your credentials
}

# response = requests.get(url)
response = requests.get(url, headers=headers)

if response.status_code == 200:
    print (200)
else:
    print('error', response)
    # Handle the error
