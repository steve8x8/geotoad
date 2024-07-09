# Get a list of countries / states for the geocaching form.

require 'interface/messages'
require 'lib/common'
require 'lib/country_state_list'
require 'lib/geocode'
require 'lib/shadowget'

class CountryState

  include Messages
  include Common
  include CountryStateList

  def initialize
    # nothing to do here
  end

  def getCountryList()
    return $COUNTRIES.map{ |y|
             "#{y[0]}=#{y[1]}" if (y[0].to_i > 1)
           }.compact
           .sort{ |a, b|
             a.split('=')[1] <=> b.split('=')[1]
           }.uniq
  end

  def findMatchingCountry(try_country)
    countries = getCountryList()
    found = []
    countries.each{ |country|
      found << country if country =~ /#{try_country}/i
    }
    return found
  end

  def getCountryName(country)
    c = country.to_i
    return $COUNTRIES.map{ |y|
             "#{y[0]}=#{y[1]}" if (y[0].to_i == c)
           }.compact[0]
  end

  def getStatesList(country)
    c = country.to_i
    return $STATES.map{ |y|
             "#{y[0]}=#{y[1]} (#{y[3]})" if ((c < 2) or (y[2].to_i == c))
           }.compact
           .sort{ |a, b|
             a.split('=')[1] <=> b.split('=')[1]
           }.uniq
  end

  def findMatchingState(try_state, country)
    states = getStatesList(country)
    found = []
    states.each{ |state|
      found << state if state =~ /#{try_state}/i
    }
    return found
  end

  def getStateName(state)
    s = state.to_i
    return $STATES.map{ |y|
             "#{y[0]}=#{y[1]} (#{y[3]})" if (y[0].to_i == s)
           }.compact[0]
  end

end
