# Get a list of countries / states for the geocaching form.

require 'lib/common'
require 'lib/messages'
require 'lib/geocode'
require 'lib/shadowget'
require 'lib/country_state_list'

class CountryState

  include Common
  include Messages
  include CountryStateList

  def initialize
  end

  def getCountryList()
    return $COUNTRIES.map{ |y| "#{y[0]}=#{y[1]}" if (y[0].to_i > 1) }
                     .compact
                     .sort{ |a, b| a.split('=')[1] <=> b.split('=')[1] } #{ |a, b| a.to_i <=> b.to_i }
                     .uniq
  end

  def findMatchingCountry(try_country)
    countries = getCountryList()
    found = []
    countries.each do |country|
      if country =~ /#{try_country}/i
        found << country
      end
    end
    return found
  end

  def getCountryName(country)
    c = country.to_i
    return $COUNTRIES.map{ |y| "#{y[0]}=#{y[1]}" if (y[0].to_i == c) }
                     .compact[0]
  end

  def getStatesList(country)
    c = country.to_i
    return $STATES.map{ |y| "#{y[0]}=#{y[1]} (#{y[3]})" if ((c < 2) or (y[2].to_i == c)) }
                  .compact
                  .sort{ |a, b| a.split('=')[1] <=> b.split('=')[1] } #{ |a, b| a.to_i <=> b.to_i }
                  .uniq
  end

  def findMatchingState(try_state, country)
    states = getStatesList(country)
    found = []
    states.each do |state|
      if state =~ /#{try_state}/i
        found << state
      end
    end
    return found
  end

  def getStateName(state)
    s = state.to_i
    return $STATES.map{ |y|"#{y[0]}=#{y[1]} (#{y[3]})" if (y[0].to_i == s) }
                  .compact[0]
  end

end
