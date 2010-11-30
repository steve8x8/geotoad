# $Id$
require 'lib/funfactor'
require 'time'
require 'zlib'

class CacheDetails
  attr_writer :useShadow, :cookie

  include Common
  include Messages

  # Use a printable template that shows the last 10 logs.
  @@baseURL="http://www.geocaching.com/seek/cdpf.aspx?lc=10"

  def initialize(data)
    @waypointHash = data
    @useShadow=1

    debug "Loading funfactor"
    @funfactor = FunFactor.new()
    @funfactor.load_scores()
    @funfactor.load_adjustments()
    debug "Loaded funfactor: #{@funfactor}"
  end

  def waypoints
    @waypointHash
  end

  def baseURL
    @@baseURL
  end

  # this routine is for compatibility.
  def fetchWid(id)
    fetch(id)
  end

  def fullURL(id)
    if (id =~ /^GC/)
      # If we can look up the guid, use it. It's not actually required, but
      # it behaves a lot more like a standard web browser on the gc.com website.
      if @waypointHash[id]['guid']
        suffix = 'guid=' + @waypointHash[id]['guid'].to_s
      else
        suffix = 'wp=' + id.to_s
      end
    else
      suffix = 'guid=' + id.to_s
    end

    url = @@baseURL + "&" + suffix
  end

  # fetches by geocaching.com sid
  def fetch(id)
    if id.to_s.empty?
      displayError "Empty fetch by id, quitting."
      exit
    end

    url = fullURL(id)
    page = ShadowFetch.new(url)
    if (@cookie)
      page.cookie=@cookie
    end

    page.fetch
    if page.data
      success = parseCache(page.data)
    else
      debug "No data found, not attempting to parse the entry at #{url}"
    end

    # We try to download the page one more time.
    if not success
      sleep(5)
      debug "Trying to download #{url} again."
      page.invalidate()
      page.fetch()
      success = parseCache(page.data)
    end

    if success
      if success == 'login-required'
        page.invalidate()
      end
      return success
    else
      displayWarning "Could not parse #{url} (tried twice)"
      return nil
    end
  end

  def calculateFun(total, num_graded)
    # if no num_graded, it must be at least somewhat interesting!
    if num_graded == 0
      return 3.0
    end

    score=total.to_f / num_graded.to_f

    # a grade of >28 is considered awesome
    # a grade of <-20 is considered pretty bad
    debug "fun total=#{total} num_graded=#{num_graded} score=#{score}"
    grade=((score + 25) / 5.3).round.to_f / 2.0
    if grade > 5.0
      grade=5.0
    elsif grade < 0.0
      grade=0.0
    end
    debug "calculateFun: score=#{score} grade=#{grade}"
    return grade
  end

  # Parse attributes: convert name of image into index and yes/no value
  def parseAttr(text)
    # "bicycles-yes" -> 32, 1
    attrmap = {
      # list confirmed 2010-10-20 ("edit attributes")
      "attribute-blank"  =>  0,
      "dogs"             =>  1,
      "fee"              =>  2,
      "rappelling"       =>  3,
      "boat"             =>  4,
      "scuba"            =>  5,
      "kids"             =>  6,
      "onehour"          =>  7,
      "scenic"           =>  8,
      "hiking"           =>  9,
      "climbing"         => 10,
      "wading"           => 11,
      "swimming"         => 12,
      "available"        => 13,
      "night"            => 14,
      "winter"           => 15,
      "16"               => 16,
      "poisonoak"        => 17,
      "dangerousanimals" => 18,
      "ticks"            => 19,
      "mine"             => 20,
      "cliff"            => 21,
      "hunting"          => 22,
      "danger"           => 23,
      "wheelchair"       => 24,
      "parking"          => 25,
      "public"           => 26,
      "water"            => 27,
      "restrooms"        => 28,
      "phone"            => 29,
      "picnic"           => 30,
      "camping"          => 31,
      "bicycles"         => 32,
      "motorcycles"      => 33,
      "quads"            => 34,
      "jeeps"            => 35,
      "snowmobiles"      => 36,
      "horses"           => 37,
      "campfires"        => 38,
      "thorn"            => 39,
      "stealth"          => 40,
      "stroller"         => 41,
      "firstaid"         => 42,
      "cow"              => 43,
      "flashlight"       => 44,
      "landf"            => 45,
      "rv"               => 46,
      "field_puzzle"     => 47,
      "UV"               => 48,
      "snowshoes"        => 49,
      "skiis"            => 50,
      "s-tool"           => 51,
      "nightcache"       => 52,
      "parkngrab"        => 53,
      "AbandonedBuilding"=> 54,
      "hike_short"       => 55,
      "hike_med"         => 56,
      "hike_long"        => 57,
      "fuel"             => 58,
      "food"             => 59,
      "wirelessbeacon"   => 60,
      # obsolete?, but image still exists
      "snakes"           => 18,
    }
    if text == "attribute-blank"
      return 0, 0
    end
    what = text.gsub(/(.*)-.*/, "\\1") # only strip "yes" or "no"!
    how = text.gsub(/^.*-/, "")
    # get mapping
    attrid = attrmap[what]
    attrval = (how=="yes")?1:0
    if not attrid
      # we may have missed an addition or change to the list
      debug "Unknown attribute #{text}, please report!"
      return 0, 0
    end
    return attrid, attrval
  end

  def parseCache(data)
    # find the geocaching waypoint id.
    wid = nil
    cache = nil
    nextline_coords = false

    data.split("\n").each { |line|
      # <title id="pageTitle">(GC1145) Lake Crabtree computer software store by darylb</title>
      if line =~ /\<title.*\((GC\w+)\) (.*?) by (.*?)\</
        wid = $1
        name = $2
        creator = $3
        debug "wid = #{wid} name=#{name} creator=#{creator}"
        cache = @waypointHash[wid]
        cache['name'] = name
        if ! cache.key?('visitors')
          cache['visitors'] = []
        end
        cache['creator'] = creator
        # Calculate a semi-unique integer creator id, since we can no longer get it from this page.
        cache['creator_id'] = Zlib.crc32(creator)
        cache['shortdesc'] = ''
        cache['longdesc'] = ''
        cache['funfactor'] = 0
        cache['url'] = "http://www.geocaching.com/seek/cache_details.aspx?wp=" + wid

        if not cache['mtime']
          cache['mdays'] = -1
          cache['mtime'] = Time.at(0)
        end
      end

      # <h2><img src="../images/WptTypes/2.gif" alt="Traditional Cache" width="32" height="32" />&nbsp;Lake Crabtree computer software store</h2>
      if line =~ /WptTypes.*? alt="(.*?)"/
        if ! cache
          displayWarning "Found waypoint type, but never saw cache title. Did geocaching.com change their layout again?"
        end
        full_type = $1
        # there may be more than 1 match, don't overwrite (see GC1PQKR, GC1PQKT)
        # actually, types have been set by search - is this code obsolete then?
        if cache['fulltype']
          debug "Not overwriting \"#{cache['fulltype']}\"(#{cache['type']}) with \"#{full_type}\""
        else
          cache['fulltype'] = full_type
          cache['type'] = full_type.split(' ')[0].downcase.gsub(/\-/, '')
          # two special cases: "Cache In Trash Out" and "Lost and Found"
          case full_type
          when /Cache In Trash Out/
            cache['type'] = 'cito'
          when /Lost [Aa]nd Found/
            # spelling to be confirmed!
            cache['type'] = 'lost+found'
          end
          debug "stype=#{cache['type']} full_type=#{cache['fulltype']}"
        end
      end


      # <p class="Meta">Placed Date: 7/17/2001</p>
      # also, event dates.
      if line =~ /[lE][av][ce][ne][dt] Date: ([\w\/]+)\</
        if $1 != 'N/A'
          cache['ctime'] = parseDate($1)
          cache['cdays'] = daysAgo(cache['ctime'])
          debug "ctime=#{cache['ctime']} cdays=#{cache['cdays']}"
        end
      end

      if line =~ /with an account to view|You must be logged in/
        displayWarning "Oops, we are not actually logged in!"
        return 'login-required'
      end

      # <p class="Meta"><strong>Size:</strong> <img src="../images/icons/container/regular.gif" alt="Size: Regular" />&nbsp;<small>(Regular)</small></p>
      if line =~ /\<img src=".*?" alt="Size: (.*?)" \/\>/
        cache['size'] = $1.downcase
        debug "found size: #{$1}"
      end

      # latitude and longitude in the written form. Rewritten by Scott Brynen for Southpole compatibility.
      if line =~ /=\"LatLong Meta"\>/
        nextline_coords = true
      end

      if nextline_coords && (line =~ /([NWSE]) (\d+).*? ([\d\.]+) ([NWSE]) (\d+).*? ([\d\.]+)\</)
        cache['latwritten'] = $1 + $2 + ' ' + $3
        cache['lonwritten'] = $4 + $5 + ' ' + $6
        cache['latdata'] = ($2.to_f + $3.to_f / 60) * ($1 == 'S' ? -1:1)
        cache['londata'] = ($5.to_f + $6.to_f / 60) * ($4 == 'W' ? -1:1)
        debug "got written lat/lon"
        nextline_coords = false
      end

      # why a geocache is closed. It seems to always be the same.
      # <span id="ctl00_ContentBody_ErrorText"><p class="OldWarning"><strong>Cache Issues:</strong></p><ul class="OldWarning"><li>This cache is temporarily unavailable. Read the logs below to read the status for this cache.</li></ul></span>
      if line =~ /Warning\".*?>(.*?)\</
        warning = $1
        warning.gsub!(/\<.*?\>/, '')
        debug "got a warning: #{warning}"
        if (wid)
          cache['archived'] = true
          cache['warning'] = warning.dup
        end
        if warning =~ /be a Premium Member to view/
          debug "This cache appears to be available to premium members only."
          return 'subscriber-only'
        end
      end

      # extract attributes assigned, and their value, plus the short text
      if line =~ /title=\"What are Attributes\?\">/
        debug "inspecting attributes: #{line}"
        # list of attributes only in cdpf version :(
        # cumulative text
        atxt = ""
        # attribute counter
        anum = 0
        # is this really necessary?
        line.gsub!(/\<p\>/, ' ')
        # <img src="/images/attributes/bicycles-no.gif" alt="no bikes" width="30" height="30" />
        line.scan(/\/images\/attributes\/(.+?)\.gif" alt="(.*?)"[^\>]*\/>/) { |icon, alt|
          # convert each image name into index/value pair, keep related text
          aid, ainc = parseAttr(icon)
          debug "attribute #{anum}: ic=#{icon} id=#{aid} inc=#{ainc} alt=#{alt} "
          if aid > 0
            # make this a 3d array instead? ...['attributes'][aid]=ainc
            cache["attribute#{anum}id"] = aid
            cache["attribute#{anum}inc"] = ainc
            cache["attribute#{anum}txt"] = alt
            anum = anum + 1
            atxt << alt + ", "
          end
        }   # no more attributes
        # keep the collected text in wp hash, for GPSr units to show
        cache['attributeText'] = atxt.gsub(/, $/, '')
        cache['attributeCount'] = anum
        debug "Found #{anum} attributes: #{atxt}"
      end

      if line =~ /Cache is Unpublished/
        return "unpublished"
      end
    }

    # Short-circuit and abort if the data is no good.
    if not cache
      displayWarning "Unable to parse any cache details from data."
      return false
    elsif not cache['latwritten']
      displayWarning "#{cache['wid']} was parsed, but no coordinates found."
      return false
    end

    if data =~ /Difficulty:.*?([\d\.]+) out of 5/m
      cache['difficulty'] = $1.to_f
      if $1.to_f == $1.to_i
        cache['difficulty'] = $1.to_i
      end
      debug "difficulty: #{cache['difficulty']}"
    end

    if data =~ /Terrain:.*?([\d\.]+) out of 5/m
      cache['terrain'] = $1.to_f
      if $1.to_f == $1.to_i
        cache['terrain'] = $1.to_i
      end
      debug "terrain: #{cache['terrain']}"
    end

    if data =~ /id="uxDecryptedHint".*?\>(.*?)\s*\<\/div/m
      hint = $1.strip
      if hint =~ /[\<\>]/
        debug "Hint contains HTML: #{hint}"
      end
      hint.gsub!(/^ +/, '')
      hint.gsub!(/[\r\n]+/, '|')
      hint.gsub!(/\<[bB][rR] *\/?\>/, '|')
      hint.gsub!('<div>', '')
      cache['hint'] = hint
      debug "got hint: [#{hint}]"
    end

    if data =~ /Short Description\<\/h2\>\s*\<\/div\>\s*\<div class="item-content"\>(.*?)\<\/div\>\s*\<\/div\>\s*\<div class="item"\>/m
      shortdesc = $1.gsub(/^\s+/, '').gsub(/\s+$/, '')
      debug "found short desc: [#{shortdesc}]"
      cache['shortdesc'] = removeAlignments(fixRelativeImageLinks(removeSpam(shortdesc)))
    end

    if data =~ /Long Description\<\/h2\>\s*\<\/div\>\s*\<div class="item-content"\>(.*?)\<\/div\>\s*\<\/div\>\s*\<div class="item"\>/m
      longdesc = $1.gsub(/^\s+/, '').gsub(/\s+$/, '')
      debug "got long desc [#{longdesc}]"
      longdesc = removeAlignments(fixRelativeImageLinks(removeSpam(longdesc)))
      cache['longdesc'] = longdesc
    end

    # Parse the additional waypoints table. Needs additional work for non-HTML templates.
    comments, last_find_date, fun_factor, visitors = parseComments(data, cache['creator'])
    cache['visitors'] = cache['visitors'] + visitors
    cache['comments'] = comments
    if comments
      cache['last_find_type'] = comments[0]['type']
      cache['last_find_days'] = daysAgo(comments[0]['date'])
    end

    if cache['mdays'] == -1 and last_find_date
      cache['mtime'] = last_find_date
      cache['mdays'] = daysAgo(cache['mtime'])
    end

    comment_text = comments.collect{ |x| x['text'] }
    ff_score = @funfactor.calculate_score_from_list(comment_text)
    # A primitive form of approximate rounding
    cache['funfactor'] = (ff_score * 20).round / 20.0
    debug "Funfactor score: #{cache['funfactor']}"
    cache['additional_raw'] = parseAdditionalWaypoints(data)
    return cache
  end  # end function

  def removeAlignments(text)
    new_text = text.gsub(/(\<div .*?)align=/m, '\1noalign=')
    new_text.gsub!(/(\<p .*?)align=/m, '\1noalign=')
    new_text.gsub!('<center>', '')
    if text != new_text
      debug "fixed alignments in #{new_text}"
    end
    return new_text
  end

  def fixRelativeImageLinks(text)
    new_text = text.gsub(' src="/', ' src="http://www.geocaching.com/')
    if text != new_text
      debug "fixed relative links in #{new_text}"
    end
    return new_text
  end

  def parseAdditionalWaypoints(text)
    # <p><p><strong>Additional Waypoints</strong></p></p>
    if text =~ /Additional Waypoints.*?(\<table.*?\/table\>)/m
      additional = $1
      return fixRelativeImageLinks(additional)
    else
      return nil
    end
  end

  def parseComments(data, creator)
    comments = []
    visitors = []
    last_find = nil
    total_grade = 0
    graded = 0

    # <dt>
    #   [<img src='http://www.geocaching.com/images/icons/icon_smile.gif' alt="Found it" />&nbsp;Found it]
    #   Sunday, 10 October 2010
    #   by <strong>
    #       silvinator</strong> (52
    #   found)
    # </dt>
    # <dd>
    # Gut gefunden. Man sollte nur auf Muggels achten!  Danke!</dd>
    data.scan(/<dt.*?icon_(\w+).*?alt=\"(.*?)\".*?, ([\w, ]+)\s+by \<strong\>\s*(.*?)\s*\<\/strong\>.*?\<dd\>\s*(.*?)\s*\<\/dd\>/m) { |icon, type, datestr, user, comment|
      debug "comment date: #{datestr}"
      should_grade = true
      grade = 0
      date = Time.parse(datestr)

      if icon == 'smile'
        visitors << user.downcase
        if not last_find
          last_find = Time.parse(datestr)
        end
      elsif icon == 'remove' or icon == 'disabled' or icon == 'greenlight' or icon == 'maint'
        should_grade = false
      end

      if user == creator
        debug "comment from creator #{creator}, not grading"
        should_grade = false
      end

      comment = {
        'type' => type,
        'date' => date,
        'icon' => icon,
        'user' => user,
        'user_id' => Zlib.crc32(user),
        'text' => comment,
        'grade' => 0
      }
      debug "COMMENT: #{comment.inspect}"
      comments <<  comment
    }
    return [comments, last_find, 0.0, visitors]
  end

  def removeSpam(text)
    # <a href="http://s06.flagcounter.com/more/NOk"><img src= "http://s06.flagcounter.com/count/NOk/bg=E2FFC4/txt=000000/border=CCCCCC/columns=4/maxflags=32/viewers=0/labels=1/pageviews=1/" alt="free counters" /></a>
    #removed = text.gsub(/\<a href.*?flagcounter.*?\<\/a\>/m, '')
    removed = text.gsub(/\<a href[^\>]*\>\<img src[^\>]*(flagcounter|gccounter|andyhoppe\.com\/count|gcstat\.selfip|gcvote)[^\>]*\>\<\/a\>/m, '')
    removed.gsub!(/\<\/*center\>/, '')
    if removed != text
      debug "Removed spam from: ----------------------------------"
      debug removed
      debug "-----------------------------------------------------"
    end

    return removed
  end

end  # end class
