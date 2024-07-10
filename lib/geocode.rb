# A library for automatic location searches, using Nominatim (OpenStreetMap)
# see documentation https://wiki.openstreetmap.org/wiki/Nominatim

require 'cgi'
require 'net/http'
require 'interface/messages'
require 'lib/common'
require 'lib/shadowget'

class GeoCode

  @@maps_base = 'https://nominatim.openstreetmap.org/'

  include Messages
  include Common

  def lookup_location(location)
    debug "geocode looking up address #{location.inspect}"
    url = create_url(location, 'address')
    data = get_url(url)
    status, importance, lat, lon, location0, license = parse_data(data)
    if status == "OK"
      return_data = [importance, lat, lon, location0, license]
      displayMessage "OpenStreetMap Nominatim search for #{location} returned"
      displayMessage " (#{lat},#{lon}) = \"#{location0}\""
      if license != nil
        displayInfo " License: #{license}"
      end
    else
      return_data = [nil, nil, nil, "", 0]
      displayMessage "OpenStreetMap Nominatim search for #{location} returned"
      displayWarning " -no- results. Status: #{status}: #{location0}."
      displayInfo "   #{url}" if location0 =~ /Use browser/
    end
    debug "returning: #{return_data}"
    # Nominatim requests: no more than one per second
    # This will delay creation of the cache a lot, but we'll randomize expiration
    return return_data
  end

  def lookup_coords(lat, lon)
    coords = sprintf("lat=%.6f&lon=%.6f", lat.to_f, lon.to_f)
    debug "geocode looking up coords #{coords.inspect}"
    url = create_url(coords, 'latlng')
    data = get_url(url)
    status, importance, lat0, lon0, location, license = parse_data(data)
    if status == "OK"
      return_data = location
    else
      return_data = "Unknown location"
    end
    debug "#{status} returning: #{return_data}"
    return return_data
  end

  def create_url(location, type)
    url = @@maps_base
    if type == 'address'
      q = CGI.escape(location.gsub(/[,:\/\+\&\?]/,' ')).gsub(/[\+ ]/,'%20')
      url += 'search?q=' + q
    elsif type == 'latlng'
      url += 'reverse?' + location
    else
      displayWarning "Geocoder type #{type} not supported?"
      url += 'error?type=' + type
    end
    url += "&format=json&limit=1"
    debug2 "geocode url: #{url}"
    return url
  end

  def get_url(url)
    # https://stackoverflow.com/questions/12883650/https-requests-in-ruby
    # Net::HTTP.get URI('https://nominatim.openstreetmap.org/search?format=json&limit=1&q=buckingham palace')
    results = Net::HTTP.get(URI(url))
    sleep 5
    debug "Querying #{url} returned #{results.inspect}"
    return results
  end
  
  def get_url_broken(url)
    # for some not yet fully understood reasons, this started to fail in July 2024
    http = ShadowFetch.new(url)
    http.localExpiry = (30 + 10*rand()) * $DAY
    http.maxFailures = 0
    # no need to present any cookies
    http.useCookie = false
    # do not check for valid HTML
    http.closingHTML = false
    http.filePattern = '"boundingbox":'
    # shorten filename
    http.localFile = url.gsub(/^https?:\/\/.*\//,'').gsub(/.format=.*/,'').gsub(/%20/,' ').gsub(/[, :.\/]/,'_') + ".json"
    # some minimum size of returned JSON
    http.minFileSize = 128
    # do not overload server: Nominatim requests 1 second minimum
    # this is only in effect for multiple lookups, i.e. old html format
    http.extraSleep = 5
    # Nominatim enforces their policy
    # the following is taken from a successful query by browser:
	#Accept			    text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8
	#Accept-Encoding		    gzip, deflate, br
	#Accept-Language		    en-GB,en;q=0.5
	#Connection		    keep-alive
	#Host			    nominatim.openstreetmap.org
	#Sec-Fetch-Dest		    document
	#Sec-Fetch-Mode		    navigate
	#Sec-Fetch-Site		    none
	#Sec-Fetch-User		    ?1
	#TE			    trailers
	#Upgrade-Insecure-Requests    1
	#User-Agent		    Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:122.0) Gecko/20100101 Firefox/122.0
    http.httpHeader = ["Accept",	"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"]
    http.httpHeader = ["Accept-Language", "en-GB,en;q=0.5"]
    http.httpHeaderDelete = "Accept-Encoding"
    http.httpHeader = ["Accept-Encoding", "gzip, deflate, br"]
#    http.httpHeaderDelete = "Accept-Charset"
#    http.httpHeader = ["Connection",	"keep-alive"]
    http.httpHeader = ["Referer",	"https://github.com/steve8x8/geotoad"]
#    http.httpHeader = ["User-Agent",	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:122.0) Gecko/20100101 Firefox/122.0"]
    http.httpHeader = ["User-Agent",	"GeoToad/3.34.2 Ruby/2.7"]
    displayInfo "using HTTP headers #{http.httpHeaders.inspect}"
    results = http.fetch
    debug3 "geocode data: #{results.inspect}"
    return results
  end

  # Simple XML parser, returns
  # status, importance, lat, lon, location, result count
  def parse_data(data)
    status = "NO_DATA"
    importance = "UNKNOWN"
    lat = 0.0
    lon = 0.0
    location = "Unknown location"
    # handle nil or empty data
    return [ status, importance, 0.0, 0.0, "Empty response", 0 ] if not data
    return [ status, importance, 0.0, 0.0, "No match", 0 ] if data == "[]"
    return [ status, importance, 0.0, 0.0, "Access blocked. Use browser", 0 ] if data =~ /<html>.*Access blocked/m
    if data =~ /"importance":([.0-9]*)/m
      importance = $1
    end
    if data =~ /"lat":"(.*?)"/m
      lat = $1
      status = "OK"
    end
    if data =~ /"lon":"(.*?)"/m
      lon = $1
      status = "OK"
    end
    if data =~ /"display_name":"(.*?)"/m
      location = $1
      status = "OK"
    end
    if data =~ /"licence":"(.*?)"/m
      license = $1
    end
    return [ status, importance, lat, lon, location, license ]
  end

end
