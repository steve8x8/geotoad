# $Id: common.rb,v 1.2 2002/08/04 21:21:18 strombt Exp $

class Common
	def initialize
		$debugMode=0
	end
	
	def debugMode=(deb)
		$debugMode = deb
	end
	
	def debug(text)
		if $debugMode == 1
			puts ":DEB: #{text}"
		end
	end

		
	## finds a place to put temp files on the system ###################################
	def findTempDir
		# find out where we want our cache #############################
		tempDir = nil
		tryTempDirs = [ ENV['GEO_TEMP'], "#{ENV['HOME']}/Library/Caches", ENV['TEMP'], 
			"C:/temp/", "C:/windows/temp", "C:/tmp/", ENV['TMP'], "/var/cache", "/var/tmp" ];

			# get rid of the Nils'
			tryTempDirs.compact!
	
		tryTempDirs.each { |dir|
			begin
				debug "Checking if #{dir} is suitable"
				if ((File.stat(dir).directory?) && (File.stat(dir).writable?))
					tempDir=dir + "/GeoToad"
					break
				end
			rescue
			end
		}
		
		# probably what we fallback to in most UNIX's. 
		if ((! tempDir) && ENV['HOME'])
			tempDir=ENV['HOME'] + '/.geotoad'
			end
	
		# Convert DOS C:// to C:\
		if tempDir
			tempDir.gsub!(/\\\\/, '/')
		end
		debug "#{tempDir} is being used for temp"
		return tempDir
	end
end

