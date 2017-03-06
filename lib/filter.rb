require 'cgi'
require 'lib/common'
require 'lib/messages'

class Filter

  include Common
  include Messages

  @@sizes = {
    # order by cache sizes
    # sizes not in this list get mapped to 'nil' (and 0)
    # 'unspecified/not applicable' (becoming obsolete)
    'virtual' => 0,
    # events, earthcaches, citos are kind of virtual too
    'not chosen' => 0,
    'not_chosen' => 0,
    # 'other' here means 'nano' (nacro, bison, ...) mostly
    # starting Dec 14, 'not chosen' gets replaced with 'other' throughout
    'other' => 1,
    'micro'   => 2,
    'small' => 3,
    'regular' => 4,
    'medium' => 4,
    'large' => 5
  }

  def initialize(data)
    @waypointHash = data
  end

  def waypoints
    @waypointHash
  end

  def totalWaypoints
    @waypointHash.entries.length
  end

  def difficultyMin(num)
    debug2 "filtering by difficultyMin: #{num}"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['difficulty'].to_f < num
    }
  end

  def difficultyMax(num)
    debug2 "filtering by difficultyMax: #{num}"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['difficulty'].to_f > num
    }
  end

  def terrainMin(num)
    debug2 "filtering by terrainMin: #{num}"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['terrain'].to_f < num
    }
  end

  def terrainMax(num)
    debug2 "filtering by terrainMax: #{num}"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['terrain'].to_f > num
    }
  end

  def favFactorMin(num)
    debug2 "filtering by favFactorMin: #{num}"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['favfactor'].to_i < num
    }
  end

  def favFactorMax(num)
    debug2 "filtering by favFactorMax: #{num}"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['favfactor'].to_i > num
    }
  end

  def sizeMin(size_name)
    debug2 "filtering by sizeMin: #{size_name} (#{@@sizes[size_name]})"
    @waypointHash.delete_if{ |wid, values|
      debug3 "size check for #{wid}: #{@waypointHash[wid]['size']}"
      @@sizes[@waypointHash[wid]['size'].downcase].to_i < @@sizes[size_name]
    }
  end

  def sizeMax(size_name)
    debug2 "filtering by sizeMax: #{size_name} (#{@@sizes[size_name]})"
    @waypointHash.delete_if{ |wid, values|
      debug3 "size check for #{wid}: #{@waypointHash[wid]['size']}"
      @@sizes[@waypointHash[wid]['size'].downcase].to_i > @@sizes[size_name]
    }
  end

  def longMin(num)
    debug2 "filtering by longMin: #{num}"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['londata'].to_f < num
    }
  end

  def longMax(num)
    debug2 "filtering by longMax: #{num}"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['londata'].to_f > num
    }
  end

  def latMin(num)
    debug2 "filtering by latMin: #{num}"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['latdata'].to_f < num
    }
  end

  def latMax(num)
    debug2 "filtering by latMax: #{num}"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['latdata'].to_f > num
    }
  end

  def cacheType(typestr0)
    typestr = typestr0.dup
    typestr.gsub!('regular', 'traditional')
    typestr.gsub!('puzzle', 'unknown')
    typestr.gsub!('mystery', 'unknown')
    types = typestr.split($delimiters)
    fwdtypes = types.each.map{ |t| (t =~ /-$/) ? nil : t }.compact
    invtypes = types.each.map{ |t| (t =~ /-$/) ? t.gsub(/-$/, '') : nil }.compact
    debug2 "filtering by types: #{types}"
    # delete_if rule to be tested - FIXME
    #@waypointHash.delete_if{ |wid, values|
    #  checkType = @waypointHash[wid]['type']
    #  ((not invtypes.empty?) and (invtypes.include?(checkType))) or ((not fwdtypes.empty?) and (not fwdtypes.include?(checkType)))
    #}
    @waypointHash.each_key{ |wid|
      checkType = @waypointHash[wid]['type']
      debug3 "wid #{wid} type #{checkType}"
      if (not invtypes.empty?) and (invtypes.include?(checkType))
        debug3 "matches inverse"
        @waypointHash.delete(wid)
      elsif (not fwdtypes.empty?) and (not fwdtypes.include?(checkType))
        debug3 "matches forward"
        @waypointHash.delete(wid)
      end
    }
  end

  def notFound
    debug2 "filtering by notFound"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['mdays'].to_i > -1
    }
  end

  def foundDateInclude(days)
    debug2 "filtering by foundDateInclude: #{days}"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['mdays'].to_i > days.to_i
    }
  end

  def foundDateExclude(days)
    debug2 "filtering by foundDateExclude: #{days}"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['mdays'].to_i < days.to_i
    }
  end

  def placeDateInclude(days)
    debug2 "filtering by placeDateInclude: #{days}"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['cdays'].to_i > days.to_i
    }
  end

  def placeDateExclude(days)
    debug2 "filtering by placeDateExclude: #{days}"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['cdays'].to_i < days.to_i
    }
  end

  def travelBug
    debug2 "filtering by travelBug"
    @waypointHash.delete_if{ |wid, values|
      @waypointHash[wid]['travelbug'].to_s.empty?
    }
  end

  def ownerExclude(nick)
    debug2 "filtering by ownerExclude: #{nick}"
    @waypointHash.delete_if{ |wid, values|
      CGI.unescapeHTML(@waypointHash[wid]['creator'].to_s) =~ /#{nick}/i
    }
  end

  def ownerInclude(nick)
    debug2 "filtering by ownerInclude: #{nick}"
    @waypointHash.delete_if{ |wid, values|
      CGI.unescapeHTML(@waypointHash[wid]['creator'].to_s) !~ /#{nick}/i
    }
  end

  def userExclude(nick0)
    nick = nick0.gsub(/=.*/, '').downcase
    debug2 "filtering by notUser: #{nick}"
    @waypointHash.each_key{ |wid|
      debug3 "#{wid} visitors: #{@waypointHash[wid]['visitors']}"
      if @waypointHash[wid]['visitors'].include?(nick)
        debug3 " - #{nick} has visited #{wid} #{@waypointHash[wid]['name']}, filtering."
        @waypointHash.delete(wid)
      end
    }
  end

  def userInclude(nick0)
    nick = nick0.gsub(/=.*/, '').downcase
    debug2 "filtering by User: #{nick}"
    @waypointHash.each_key{ |wid|
      debug3 "#{wid} visitors: #{@waypointHash[wid]['visitors']}"
      if not @waypointHash[wid]['visitors'].include?(nick)
        debug3 " - #{nick} has not visited #{@waypointHash[wid]['name']}, filtering."
        @waypointHash.delete(wid)
      end
    }
  end

  # attributes: cache["attribute#{id}id"] cache["attribute#{id}inc"]
  def attributeExclude(id)
    aid = id.to_i
    # remove only if attribute set to "no"
    checkfor = ((id =~ /-$/) != nil)?0:1
    debug2 "filtering by notAttribute: #{id}"
    @waypointHash.delete_if{ |wid, values|
      dodelete = false
      cnt = @waypointHash[wid]['attributeCount']
      if cnt
        (0...cnt).each{ |attr|
          if (@waypointHash[wid]["attribute#{attr}id"] == aid)
            ainc = @waypointHash[wid]["attribute#{attr}inc"]
            debug3 "attribute check #{aid} for #{wid}: #{ainc}==#{checkfor}?"
            dodelete = true if (ainc == checkfor)
          end
        }
      end
      debug3 "#{wid} selected for removal" if dodelete
      dodelete
    }
  end

  def attributeInclude(id)
    aid = id.to_i
    # always remove unless attribute set to "yes"
    checkfor = ((id =~ /-$/) != nil)?0:1
    debug2 "filtering by Attribute: #{id}"
    @waypointHash.delete_if{ |wid, values|
      dodelete = true
      cnt = @waypointHash[wid]['attributeCount']
      if cnt
        (0...cnt).each{ |attr|
          if (@waypointHash[wid]["attribute#{attr}id"] == aid)
            ainc = @waypointHash[wid]["attribute#{attr}inc"]
            debug3 "attribute check #{aid} for #{wid}: #{ainc}!=#{checkfor}?"
            dodelete = false  if (ainc == checkfor)
          end
        }
      end
      debug3 "#{wid} selected for removal" if dodelete
      dodelete
    }
  end

  def titleKeyword(string)
    debug2 "filtering by title keyword: #{string}"
    @waypointHash.each_key{ |wid|
      # I wanted to use delete_if, but I had run into a segfault in ruby 1.6.7/8 [helixblue]
      if string =~ /^\!(.*)/
        real_string = $1
        if (@waypointHash[wid]['name'] =~ /#{real_string}/i)
          @waypointHash.delete(wid)
        end
      else
        if (@waypointHash[wid]['name'] !~ /#{string}/i)
          @waypointHash.delete(wid)
        end
      end
    }
  end

  def descKeyword(string)
    debug2 "filtering by desc keyword: #{string}"
    @waypointHash.each_key{ |wid|
      cache = @waypointHash[wid]
      if string =~ /^\!(.*)/
        real_string = $1
        if (cache['longdesc'] =~ /#{real_string}/i) or (cache['shortdesc'] =~ /#{real_string}/i)
          @waypointHash.delete(wid)
        end
      else
        if (cache['longdesc'] !~ /#{string}/i) and (cache['shortdesc'] !~ /#{string}/i)
          @waypointHash.delete(wid)
        end
      end
    }
  end

  def removeByElement(element, is = true)
    debug2 "filtering by removeByElement: #{element}"
    @waypointHash.each_key{ |wid|
      value = @waypointHash[wid][element]
      # handle nil as false
      if (value == true) == is
        debug3 " - #{wid}: #{element} => #{value.inspect}, filtering."
        @waypointHash.delete(wid)
      end
    }
  end

  # add a visitor to a cache. Used by the userlookup feeder.
  def addVisitor(wid, visitor)
    if (@waypointHash[wid] and visitor)
      debug3 "Added visitor to #{wid}: #{visitor}"
      @waypointHash[wid]['visitors'] << visitor.downcase
    else
      return 0
    end
  end

end
