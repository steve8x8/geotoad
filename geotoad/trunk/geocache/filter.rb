# $Id: filter.rb,v 1.7 2002/08/05 03:38:51 strombt Exp $

class Filter < Common
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

    def terrainMax(num)
		debug "filtering by terrainMax: #{num}"

		@waypointHash.delete_if { |wid, values|
			@waypointHash[wid]['terrain'] > num
		}
	end

    def notFound
		debug "filtering by notFound"
		@waypointHash.delete_if { |wid, values|
			@waypointHash[wid]['mdate'].to_s.length > 7
        }
	end

    def travelBug
		debug "filtering by travelBug"
     
		@waypointHash.delete_if { |wid, values|            
			@waypointHash[wid]['travelbug'].to_s.length < 1
        }
	end

    
    def notUser(nick)
            debug "filtering by notUser: #{nick}"

                @waypointHash.each_key { |wid|
                        #puts "notUser #{nick}: #{wid}"
                        @waypointHash[wid]['visitors'].each { |visitor|
                                if visitor == nick
                                        @waypointHash.delete(wid)
                                        debug " - #{nick} has visited #{wid}, filtering."
                                end
                        }
                }
    end

    
    
	def keyword(string)
		debug "filtering by keyword: #{string}"

		@waypointHash.each_key { |wid|
            # I wanted to use delete_if, but I had run into a segfault in ruby 1.6.7/8
            if (! (@waypointHash[wid]['details'] =~ /#{string}/))
                #uts @waypointHash[wid]['details']
                 @waypointHash.delete(wid)
            end
		}
	end
    
    

    def removeByElement(element)
		debug "filtering by removeByElement: #{element}"

        @waypointHash.each_key { |wid|
            if @waypointHash[wid][element]
                @waypointHash.delete(wid)
                puts " - #{wid} has #{element}, filtering."
            end
        }
    end

end
