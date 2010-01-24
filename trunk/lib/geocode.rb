# A library for automatic location searches, using the Google Geocoding API

require 'common'
require 'cgi'
require 'shadowget'

MAPS_URL = 'http://maps.google.com/maps/geo'
KEY = 'ABQIAAAAfYtme_pyDnFOuJLGZiXvPxRuVmV2GDBxlUzS4Tl93rTyZWZiOBRL-7BgtHIJc12HxIcS5teMAlIPzw'

class GeoCode
  include Common
  include Messages
  
  def lookup(location)
    data = get_url(create_url(location))
    code, accuracy, lat, lon = parse_data(data)
    if code == "200":
      return_data = [decode_accuracy(accuracy), lat, lon]
    else
      return_data = [nil, nil, nil]
    end
    debug "returning: #{return_data}"
    return return_data
  end

  def create_url(location)
    q = CGI.escape(location)
    url = "#{MAPS_URL}?q=#{q}&output=csv&oe=utf8&sensor=false&key=#{KEY}"
    debug 'url: #{url}'
    return url
  end

  def get_url(url)
    http = ShadowFetch.new(url)
    http.localExpiry=86400 * 30
    http.maxFailures = 5
    results = http.fetch
    debug "geocode data: #{results}"
    return results
  end

  def decode_accuracy(value)
    table = [nil, 'Country', 'Region (state, province)',
             'Sub-region (county, municipality)', 'Town', 'Post code', 'Street',
             'Intersection', 'Address', 'Premise (building-name)']
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
    return data.chomp.split(',')
  end

end