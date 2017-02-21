# code taken from Kristian Mandrup's geo_calc and haversine gems
# http://github.com/kristianmandrup/{geo_calc,haversine}
# Note that Landon Cox' original website has ceased to exist

'''
Copyright (c) 2011 Kristian Mandrup

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
'''

module GeoDist

#
# haversine formula to compute the great circle distance between two points given their latitude and longitudes
#
# Copyright (C) 2008, 360VL, Inc
# Copyright (C) 2008, Landon Cox
#
# http://www.esawdust.com (Landon Cox)
# contact:
# http://www.esawdust.com/blog/businesscard/businesscard.html
#
# LICENSE: GNU Affero GPL v3
# The ruby implementation of the Haversine formula is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
# License version 3 for more details.  http://www.gnu.org/licenses/
#
# Landon Cox - 9/25/08
#
# Notes:
#
# translated into Ruby based on information contained in:
#   http://mathforum.org/library/drmath/view/51879.html  Doctors Rick and Peterson - 4/20/99
#   http://www.movable-type.co.uk/scripts/latlong.html
#   http://en.wikipedia.org/wiki/Haversine_formula
#
# This formula can compute accurate distances between two points given latitude and longitude, even for
# short distances.

    GREAT_CIRCLE_RADIUS_MILES = 3956
    GREAT_CIRCLE_RADIUS_KILOMETERS = 6371 # some algorithms use 6367
    GREAT_CIRCLE_RADIUS_FEET = GREAT_CIRCLE_RADIUS_MILES * 5280
    GREAT_CIRCLE_RADIUS_METERS = GREAT_CIRCLE_RADIUS_KILOMETERS * 1000
    GREAT_CIRCLE_RADIUS_NAUTICAL_MILES = GREAT_CIRCLE_RADIUS_MILES / 1.15078

    RAD_PER_DEG = Math::PI / 180

  # given two lat/lon points, compute the distance between the two points using the haversine formula
  def haversine_miles(lat1, lon1, lat2=nil, lon2=nil)
    if lat2.nil? or lon2.nil?
      raise ArgumentError
    end

    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = haversine_calc(dlat, lat1, lat2, dlon)
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    return c * GREAT_CIRCLE_RADIUS_MILES
  end

  def haversine_calc(dlat, lat1, lat2, dlon)
    (Math.sin(rpd(dlat)/2))**2 + Math.cos(rpd(lat1)) * Math.cos((rpd(lat2))) * (Math.sin(rpd(dlon)/2))**2
  end

  # Radians per degree
  def rpd(num)
    num * RAD_PER_DEG
  end
  def dpr(num)
    num / RAD_PER_DEG
  end

  def geoBearing(lat1, lon1, lat2, lon2)
    lat1 = rpd(lat1.to_f)
    lon1 = rpd(lon1.to_f)
    lat2 = rpd(lat2.to_f)
    lon2 = rpd(lon2.to_f)
    # use spherical approximation
    #dlat = lat2 - lat1
    dlon = lon2 - lon1
    y = Math.sin(dlon) * Math.cos(lat2)
    x = Math.cos(lat1) * Math.sin(lat2) -
        Math.sin(lat1) * Math.cos(lat2) * Math.cos(dlon)
    # convert counterclockwise radians into wind-rose degrees
    bearing = (90 - dpr(Math.atan2(x,y)) + 360) % 360
    # assign wind-rose directions
    ["N","NE","E","SE","S","SW","W","NW","N"][((bearing.to_f+22.5)/45.0).to_i]
  end

  def geoDistDir(lat1, lon1, lat2, lon2)
    # no home location given (cover nil case)
    if (lat1.to_f == 0.0) and (lon1.to_f == 0.0)
      return [nil, nil]
    end
    # target location doesn't exist (nil)
    if lat2.nil? or lon2.nil?
      return [nil, nil]
    end
    # Haversine takes degrees, not radians
    return [haversine_miles(lat1.to_f, lon1.to_f, lat2.to_f, lon2.to_f),
            geoBearing(lat1.to_f, lon1.to_f, lat2.to_f, lon2.to_f)]
  end

end
