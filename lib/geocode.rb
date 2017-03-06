# A library for automatic location searches, using the Google Geocoding API v3
# see documentation https://developers.google.com/maps/documentation/geocoding/

require 'cgi'
require 'lib/common'
require 'lib/messages'
require 'lib/shadowget'

class GeoCode

  @@maps_base = 'http://maps.googleapis.com/maps/api/geocode/xml?sensor=false'

  include Common
  include Messages

  def lookup_location(location)
    debug "geocode looking up address #{location.inspect}"
    data = get_url(create_url(location, 'address'))
    status, accuracy, lat, lon, location0, count = parse_data(data)
    if status == "OK"
      return_data = [decode_accuracy(accuracy), lat, lon, location0, count]
    else
      return_data = [nil, nil, nil, "", 0]
    end
    debug "returning: #{return_data}"
    return return_data
  end

  def lookup_coords(lat, lon)
    coords = sprintf("%.6f,%.6f", lat.to_f, lon.to_f)
    debug "geocode looking up coords #{coords.inspect}"
    data = get_url(create_url(coords, 'latlng'))
    status, accuracy, lat0, lon0, location, count = parse_data(data)
    if status == "OK"
      return_data = location
    else
      return_data = "Unknown location"
    end
    debug "returning: #{return_data}"
    return return_data
  end

  def create_url(location, type)
    q = CGI.escape(location)
    url = @@maps_base + "&#{type}=#{q}"
    debug2 "geocode url: #{url}"
    return url
  end

  def get_url(url)
    http = ShadowFetch.new(url)
    http.localExpiry = 30 * $DAY
    http.maxFailures = 5
    http.useCookie = false
    results = http.fetch
    debug3 "geocode data: #{results.inspect}"
    return results
  end

  def decode_accuracy(value)
    # dummy: no need to translate strings
    return value
  end

  # Simple XML parser, returns
  # status, accuracy, lat, lon, location, result count
  def parse_data(data)
    status = "NO_DATA"
    accuracy = "UNKNOWN"
    lat = 0.0
    lon = 0.0
    location = "Unknown location"
    # handle nil data
    return [ status, accuracy, 0.0, 0.0, "Empty response", 0 ] if not data
    if data =~ /<status>(.*?)<\/status>/m
      status = $1
    else
      return [ status, accuracy, 0.0, 0.0, "Unknown response", 0 ]
    end
    return [ status, accuracy, 0.0, 0.0, "No match", 0 ] if status != 'OK'
    results = data.split(/<\/result>/)
    count = results.length - 1
    debug "Number of results: #{count}"
    results[0].split("\n").each{ |line|
      case line
      when /<formatted_address>(.*?)<\/formatted_address>/
        location = $1
      when /<location_type>(.*?)<\/location_type>/
        accuracy = $1
      end
    }
    if data =~ /<location>\s*<lat>(.*?)<\/lat>\s*<lng>(.*?)<\/lng>\s*<\/location>/
      lat = $1
      lon = $2
    end
    return [ status, accuracy, lat, lon, location, count ]
  end

end
