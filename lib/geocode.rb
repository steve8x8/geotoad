# A library for automatic location searches, using the Google Geocoding API

require 'cgi'
require 'shadowget'

BASE_URL = 'http://maps.google.com/maps/geo'
KEY = 'ABQIAAAAfYtme_pyDnFOuJLGZiXvPxRuVmV2GDBxlUzS4Tl93rTyZWZiOBRL-7BgtHIJc12HxIcS5teMAlIPzw'

class GeoCode
  
  def url(location):
    encoded_location = CGI.encode(location)
    return "#{BASE_URL}?q=%s&output=csv&oe=utf8&sensor=false&key=#{KEY}"
    
  def get(url):
    http = ShadowFetch.new(url)
    http.localExpiry=86400 * 30
    http.maxFailures = 5
    results = http.fetch
    return results.data
