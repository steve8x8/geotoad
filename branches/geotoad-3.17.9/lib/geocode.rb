# A library for automatic location searches, using the Google Geocoding API
require 'csv'

require 'common'
require 'cgi'
require 'shadowget'

MAPS_URL = 'http://maps.google.com/maps/geo'
KEY = 'ABQIAAAAfYtme_pyDnFOuJLGZiXvPxRuVmV2GDBxlUzS4Tl93rTyZWZiOBRL-7BgtHIJc12HxIcS5teMAlIPzw'
CACHE_SECONDS = 86400 * 180

class GeoCode
  include Common
  include Messages

  def lookup_location(location)
    data = get_url(create_url(location))
    code, accuracy, lat, lon = parse_data(data)
    if code == "200"
      return_data = [decode_accuracy(accuracy), lat, lon]
    else
      return_data = [nil, nil, nil]
    end
    debug "returning: #{return_data}"
    return return_data
  end

  def lookup_coords(lat, lon)
    coords = "#{lat},#{lon}"
    debug "geocode looking up #{coords}"
    data = get_url(create_url(coords))
    code, accuracy, location = parse_data(data)
    if code == "200"
      return location
    else
      return "Unknown"
    end
  end

  def create_url(location)
    q = CGI.escape(location)
    url = "#{MAPS_URL}?q=#{q}&output=csv&oe=utf8&sensor=false&key=#{KEY}"
    debug "geocode url: #{url}"
    return url
  end

  def get_url(url)
    http = ShadowFetch.new(url)
    http.localExpiry = CACHE_SECONDS
    http.maxFailures = 5
    results = http.fetch
    debug "geocode data: #{results.inspect}"
    return results
  end

  def decode_accuracy(value)
    table = ['Continent', 'Country', 'Region (state, province)',
             'Sub-region (county, municipality)', 'Town', 'Post code', 'Street',
             'Intersection', 'Address', 'Area']
    if value
      desc = table[value.to_i]
    else
      desc = nil
    end
    debug "accuracy: #{value} maps to #{desc}"
    return desc
  end

  # Parse the CSV returned by http://code.google.com/apis/maps/documentation/geocoding/
  def parse_data(data)
    # handle nil data
    return CSV.parse_line(data) if (data)
    return [ "999", "999", "no data" ]
  end

end