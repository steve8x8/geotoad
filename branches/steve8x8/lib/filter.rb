# $Id$
require 'cgi'

class Filter
  include Common
  include Messages
    
  @@sizes = {
    # order by cache sizes
    # 'other' usually is nano/nacro/bison
    # how to handle 'unspecified/not applicable'?
    'virtual' => 0,
    # events, earthcaches, citos are kind of virtual too
    'not chosen' => 0,
    'not_chosen' => 0,
    # 'other' here means 'nano' (nacro, bison, ...)
    'other' => 1,
    'micro'   => 2,
    'small' => 3,
    'regular' => 4,
    'large' => 5
    # don't confuse with GC's internal mapping (modulo offset 1):
    #'not chosen' => 0,
    #'not_chosen' => 0,
    #'micro'      => 1,
    #'regular'    => 2,
    #'large'      => 3,
    #'virtual'    => 4,
    #'other'      => 5,
    #'small'      => 7
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
    debug "filtering by difficultyMin: #{num}"
    @waypointHash.delete_if { |wid, values|
      @waypointHash[wid]['difficulty'] < num
    }
  end
    
  def difficultyMax(num)
    debug "filtering by difficultyMax: #{num}"
        
    @waypointHash.delete_if { |wid, values|
      @waypointHash[wid]['difficulty'] > num
    }
  end
    
    
  def terrainMin(num)
    debug "filtering by terrainMin: #{num}"
        
    @waypointHash.delete_if { |wid, values|
      @waypointHash[wid]['terrain'] < num
    }
  end
    
  def terrainMax(num)
    debug "filtering by terrainMax: #{num}"
    @waypointHash.delete_if { |wid, values|
      @waypointHash[wid]['terrain'] > num
    }
  end
    
  def funFactorMin(num)
    debug "filtering by funFactorMin: #{num}"
    @waypointHash.delete_if { |wid, values|
      @waypointHash[wid]['funfactor'] < num
    }
  end
    
  def funFactorMax(num)
    debug "filtering by funFactorMax: #{num}"
    @waypointHash.delete_if { |wid, values|
      @waypointHash[wid]['funfactor'] > num
    }
  end

  def sizeMin(size_name)
    debug "filtering by sizeMin: #{size_name} (#{@@sizes[size_name]})"        
    @waypointHash.delete_if { |wid, values|
      debug "size check for #{wid}: #{@waypointHash[wid]['size']}"
      @@sizes[@waypointHash[wid]['size']] < @@sizes[size_name]
    }
  end
  
  def cacheType(typestr0)
    typestr = typestr0.dup
    typestr.gsub!('regular', 'traditional')
    typestr.gsub!('puzzle', 'unknown')
    typestr.gsub!('mystery', 'unknown')
    types = typestr.split(/[:\|]/)
    debug "filtering by types: #{types}"
    @waypointHash.delete_if { |wid, values|
      not types.include?(@waypointHash[wid]['type'])
    }
  end  

  def sizeMax(size_name)
    debug "filtering by sizeMax: #{size_name} (#{@@sizes[size_name]})"        
    @waypointHash.delete_if { |wid, values|
      debug "size check for #{wid}: #{@waypointHash[wid]['size']}"
      @@sizes[@waypointHash[wid]['size']] > @@sizes[size_name]
    }
  end
    
  def notFound
    debug "filtering by notFound"
    @waypointHash.delete_if { |wid, values|
      @waypointHash[wid]['mdays'].to_i > -1
    }
  end
    
  def foundDateInclude(days)
    debug "filtering by foundDateInclude: #{days}"
    @waypointHash.delete_if { |wid, values|
      @waypointHash[wid]['mdays'].to_i >= days.to_i
    }
  end
    
  def foundDateExclude(days)
    debug "filtering by foundDateExclude: #{days}"
    @waypointHash.delete_if { |wid, values|
      @waypointHash[wid]['mdays'].to_i < days.to_i
    }
  end
    
  def placeDateInclude(days)
    debug "filtering by placeDateInclude: #{days}"
    @waypointHash.delete_if { |wid, values|
      @waypointHash[wid]['cdays'].to_i >= days.to_i
    }
  end
    
  def placeDateExclude(days)
    debug "filtering by placeDateExclude: #{days}"
    @waypointHash.delete_if { |wid, values|
      @waypointHash[wid]['cdays'].to_i < days.to_i
    }
  end
    
  def travelBug
    debug "filtering by travelBug"
        
    @waypointHash.delete_if { |wid, values|
      @waypointHash[wid]['travelbug'].to_s.length < 1
    }
  end
    
    
  def ownerExclude(nick)
    debug "filtering by ownerExclude: #{nick}"
    @waypointHash.delete_if { |wid, values|
      creator = CGI.unescapeHTML(@waypointHash[wid]['creator'])
      creator =~ /#{nick}/i
    }
  end
    
  def ownerInclude(nick)
    debug "filtering by ownerInclude: #{nick}"
    @waypointHash.delete_if { |wid, values|
      @waypointHash[wid]['creator'] !~ /#{nick}/i
    }
  end
    
  def userExclude(nick)
    nick.downcase!
    debug "filtering by notUser: #{nick}"
        
    @waypointHash.each_key { |wid|
      debug "#{wid} visitors: #{@waypointHash[wid]['visitors']}"
      if (@waypointHash[wid]['visitors'].include?(nick))
        debug " - #{nick} has visited #{wid} #{@waypointHash[wid]['name']}, filtering."
        @waypointHash.delete(wid)
      end
    }
  end
    
  def userInclude(nick)
    nick.downcase!
    debug "filtering by User: #{nick}"
        
    @waypointHash.each_key { |wid|
      debug "#{wid} visitors: #{@waypointHash[wid]['visitors']}"
      if (! @waypointHash[wid]['visitors'].include?(nick))
        debug " - #{nick} has not visited #{@waypointHash[wid]['name']}, filtering."
        @waypointHash.delete(wid)
      end
    }
  end
    
  def titleKeyword(string)
    debug "filtering by title keyword: #{string}"
    @waypointHash.each_key { |wid|
      # I wanted to use delete_if, but I had run into a segfault in ruby 1.6.7/8
      if string =~ /^\!(.*)/
        real_string = $1
        if (! (@waypointHash[wid]['name'] !~ /#{real_string}/i) )
          @waypointHash.delete(wid)
        end
      else
        if (! (@waypointHash[wid]['name'] =~ /#{string}/i) )
          @waypointHash.delete(wid)
        end
      end
    }
  end
    
    
  def descKeyword(string)
    debug "filtering by desc keyword: #{string}"
    @waypointHash.each_key { |wid|
      cache = @waypointHash[wid]
      
      if string =~ /^\!(.*)/
        real_string = $1
        if cache['details'] =~ /#{real_string}/i || cache['longdesc'] =~ /#{real_string}/i || cache['shortdesc'] =~ /#{real_string}/i 
          @waypointHash.delete(wid)
        end
      else
        if ! (cache['details'] =~ /#{string}/i || cache['longdesc'] =~ /#{string}/i || cache['shortdesc'] =~ /#{string}/i)
          @waypointHash.delete(wid)
        end
      end
    }
  end
     
  def removeByElement(element)
    debug "filtering by removeByElement: #{element}"
        
    @waypointHash.each_key { |wid|
      if @waypointHash[wid][element]
        @waypointHash.delete(wid)
        debug " - #{wid} has #{element}, filtering."
      end
    }
  end
    
    
  # add a visitor to a cache. Used by the userlookup feeder.
  def addVisitor(wid, visitor)
    if (@waypointHash[wid])
      debug "Added visitor to #{wid}: #{visitor}"
      # I don't believe we should downcase the visitors at this stage,
      # since we really are losing data for the templates. I need to
      # modify userInclude() and userExclude() to be case insensitive
      # first.
            
      @waypointHash[wid]['visitors'] << visitor.downcase
    else
      return 0
    end
  end
end
