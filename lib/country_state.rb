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

  # developer switch: [20170222]
  # false = use table (to fix issue 348, allow for all-country state search)
  # true  = fetch c and s lists from GC (old style, pre-issue 348)
  @@fetch_cs = false

  @@base_url = 'https://www.geocaching.com/seek/nearest.aspx'

  def initialize
    @ttl = 61 * $DAY	# 2 months
  end

  def getPage(url, post_vars)
    page = ShadowFetch.new(url)
    page.localExpiry = @ttl
    if post_vars
      page.postVars = post_vars.dup
    end

    if page.fetch
      return page.data
    else
      return nil
    end
  end

  def getCountriesPage()
    post_vars, options = parseSearchPage(@@base_url + "?country_id=2", nil)
    option, key = findOptionAndValue(options, "By Country")
    debug2 "Changing #{option} from #{post_vars[option]} to #{key}"
    post_vars[option] = key

    post_vars, options = parseSearchPage(@@base_url + "?country_id=2", post_vars)
    return [post_vars, options]
  end

  def getCountryValues()
    post_vars, options = getCountriesPage()
    options.each_key do |option|
      if option =~ /selectCountry/
        return options[option]
      end
    end
  end

  def getCountryList()
    if @@fetch_cs
      return getCountryValues.map{ |y| "#{y[0]}=#{y[1]}" if y[0].to_i > 1 }.compact.sort.uniq
    else
      return $COUNTRIES.map{ |y| "#{y[0]}=#{y[1]}" if y[0].to_i > 1 }.compact.sort.uniq
    end
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

  def getStatesPage(country)
    post_vars, options = getCountriesPage()
    found_country = nil
    options.each_key do |option|
      if option =~ /selectCountry/
        options[option].each do |key, desc|
          if key == country or desc == country
            debug2 "Setting country option #{option} to #{key} (#{desc})"
            found_country = key
            post_vars[option] = key
          end
        end
      end
    end

    if not found_country
      displayWarning "Could not find country: #{country}"
      puts options.inspect
      return nil
    end

    post_vars, options = parseSearchPage(@@base_url + "?country_id=#{found_country}&as=0&children=y", post_vars)
    return [post_vars, options]
  end

  def getStatesValues(country)
    post_vars, options = getStatesPage(country)
    options.each_key do |option|
      if option =~ /selectState/
        return options[option]
      end
    end
  end

  def getStatesList(country)
    c = country.to_i
    if @@fetch_cs
      # cannot search all countries
      return [] if (c < 2)
      return getStatesValues(country).map{ |y| "#{y[0]}=#{y[1]}" if y[0].to_i > 1 }.compact.sort.uniq
    else
      return $STATES.map{ |y| "#{y[0]}=#{y[1]} (#{y[3]})" if ((c < 2) or (y[2].to_i == c)) }.compact.sort.uniq
    end
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

  # Find the country option, return it's value
  def findOptionAndValue(options, keyword)
    options.each_key do |option|
      options[option].each do |key, desc|
        if desc =~ /#{keyword}/i
          return [option, key]
        end
      end
    end
  end

  def parseSearchPage(url, post_vars)
    data = getPage(url, post_vars)
    current_select_name = nil
    post_vars = Hash.new
    options = Hash.new

    data.each_line{ |line|
      if line =~ /^<input type=\"hidden\" name=\"([^\"]*?)\".* value=\"([^\"]*?)\" \/>/
        debug3 "found hidden post variable: #{$1}=#{$2}"
        post_vars[$1] = $2
      elsif line =~ /^<input type=\"submit\" name=\"([^\"]*?)\".* value=\"([^\"]*?)\"/
        debug3 "found submit post variable: #{$1}=#{$2}"
        post_vars[$1] = $2
      elsif line =~ /<select name=\"([^\"]*?)\"/
        current_select_name = $1
        options[current_select_name] = []
      elsif line =~ /<option selected=\"selected\" value=\"([^\"]*?)\".*?>(.*?)</
        options[current_select_name] << [$1, $2]
        if current_select_name
          debug3 "found selected option for #{current_select_name} #{$1}=#{$2}"
          post_vars[current_select_name] = $1
        else
          displayWarning "Found selected <option> #{$1}, but no previous <select> tag."
          return nil
        end
      elsif line =~ /<option.*value=\"([^\"]*?)\".*?>(.*?)</
        debug3 "found option: #{$1}=#{$2}"
        options[current_select_name] << [$1, $2]
      end
    }
    return [post_vars, options]
  end

end
