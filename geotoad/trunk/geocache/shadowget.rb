# $Id: shadowget.rb,v 1.3 2002/08/05 03:42:24 strombt Exp $

require 'net/http'
require 'ftools'
#require 'geocache/common'

# find out where we want our cache #############################
cacheDir = nil
# we'll make this more dynamic in the future. Lets start out badly though.
$shadowHosts = [
	'http://toadstool.sh/hacks/shadowfetch/get.php',
	'http://home.toadstool.sh/hacks/shadowfetch/get.php',
    'http://bitstream.dyn.dhs.org/shadowfetch/get.php',
	'http://smtp.stromberg.org/hacks/shadowfetch/get.php'
]

$Header = {
  'Referer'         => 'http://www.geocaching.com/',
  'User-Agent'      => 'Mozilla/4.5 (compatible; OmniWeb/4.1.1-v424.6; Mac_PowerPC)',
  'Accept'          => 'image/gif, image/jpeg, image/png, multipart/x-mixed-replace, */*',
  'Accept-Language' => 'en',
  'Accept-Charset'  => 'iso-8859-1, utf-8, iso-10646-ucs-2, macintosh, windows-1252, *'
}

# Does a webget, but stores a local directory with cached results ###################
class ShadowFetch < Common

	# gets a URL, but stores it in a nice webcache
	def initialize (url)
		@url = url
		@remote = 0
        @shadowExpiry=345600	# 4 days
        @localExpiry=432000		# 4 days
        debug "new fetch: #{url}"
	end

	# to change the URL
	def url=(url)
		@url = url
        debug "set url to #{url}"
	end

    def shadowExpiry=(expiry)
        debug "setting shadow expiry to #{expiry}"
        @shadowExpiry=expiry
    end

    def localExpiry=(expiry)
        debug "setting local expiry to #{expiry}"
        @localExpiry=expiry
    end

    def postVars=(vars)
        vars.each_key {|key|
            debug "Set post variable: #{key}"
        }
        @postVars=vars
    end

	# to get the data returned back to you.
	def data
		@data
	end

	def waypoints
		@waypoints
	end

	def src
		debug "src of last get was #{@@src}"
		@@src
	end

	# returns the cache filename that the URL will be stored as
	def cacheFile(url)
        if (@postVars)
            @postVars.each_key { |key|
                value=@postVars[key].slice(0,20)
                url = url + "&POST-#{key}=#{value}"
            }
            debug "added post vars to url: #{url}"
        else
            debug "no post vars to add to filename"
        end

		fileParts = url.split('/')
		host = fileParts[2]

		# if there is anything to salvage
		if fileParts[3]
			dir = fileParts[3..-2].join('/')
			file = fileParts[-1]
			localfile = $TEMP_DIR + '/' + host + '/' + dir + '/' + file
		else
			localfile = $TEMP_DIR + '/' + host + '/' + 'index.html'
		end

		# make a friendly filename
		localfile.gsub!(/[=\?\*\%\&\$]/, "_")
		debug "cachefile: #{localfile}"
		return localfile
	end






	# gets the file
	def fetch
		@@src = nil
		time = Time.now
		localfile = cacheFile(@url)
		localparts = localfile.split(/[\\\/]/)
		localdir = localparts[0..-2].join("/")		# basename sucks in Windows.

		# expiry?
		if (File.exists?(localfile))
			age = time.to_i - File.mtime(localfile).to_i
			if (age > @localExpiry)
				debug "local cache is #{age} old, older than #{@localExpiry}. removing.."
				#File.unlink(localfile)
			elsif (File.size(localfile) < 32)
				debug "local cache appears corrupt. removing.."
				File.unlink(localfile)
			else
            debug "local cache is only #{age} old (#{@localExpiry}), using local file."
                @data = fetchLocal(localfile)
                @@src='local'
				# short-circuit out of here!
				return @data
			end
		else
			debug "no local cache file found for #{localfile}"
		end

		## this assumes there was no local cache that was useable ############
		# check shadow
		(size, mtime) = checkShadow
		# if we got back a valid result of some kind.
		if (size)
			age = time.to_i - mtime
			if ((size > 128) && (age < @shadowExpiry))
            debug "shadow has cache entry #{age} old, using."
				@data = fetchShadow
                @@src='shadow'
			else
                debug "shadow gave results we don't like (s:#{size} a:#{age} e:#{@shadowExpiry})"
				#(size, mtime) = checkGoogle(url)
				#age = time.to_i - mtime
				@data = fetchRemote
                if (@data)
                    @@src='remote'
    				updateShadow
                else
                    size=nil
                end
			end
        end

        # normally, this is an else, but I do that evil size=nil trick above.
		if (! size)
			debug "shadow servers gave back garbarge. shadowing disabled"
			# we could not reach a local shadow server!
			@data = fetchRemote

            if (! @data)
                debug "we must not have a net connection, uh no"
                if (File.exists?(localfile))
                    debug "using local cache instead"
                    @data = fetchLocal(localfile)
                    return @data
                end
                @@src=nil
                debug "ERROR: #{@url} could not be fetched, even by cache"
                return nil
            end
		end


		if (! File.exists?(localdir))
			debug "creating #{localdir}"
			File.makedirs(localdir)
		end


		debug "outputting #{localfile}"
		cache = File.new(localfile, "w")
		cache.puts @data

		debug "Returning #{@data.length} bytes worth of data"
		return @data
	end





	## the real fetch methods ########################################################

	def fetchLocal(file)
		debug "fetching local data from #{file}"
		data = IO.readlines(file).join
		debug "#{data.length} bytes retrieved from local cache"
		return data
	end


	def fetchRemote
		debug "fetching remote data from #{@url}"
		data = fetchURL(@url)
	end


	def fetchURL (url)  # full http:// string!
		fileParts = url.split('/')
		host = fileParts[2]
		file = '/' + fileParts[3..-1].join('/')

		debug "Connecting to #{host} to retrieve #{file}"
		w = Net::HTTP.new(host, 80)
		detail = nil

		begin
			debug "get #{host}#{file}"
			resp, data = w.get(file, $Header)
			return data
		rescue => detail
			debug "Error fetching #{url} (members only cache?)"

            # our debugging is messed up right now.
            return nil

			if (detail)
				head.each { |key, val|
					debug "        #{key}: #{val}"
				}
			end
			debug "retrying..."
			sleep 2

			# can we even do this!?!?
			begin
                webagain = Net::HTTP.new(host, 80)
				resp, data = webagain.get(file, nil)
				return data
			rescue
				debug "retry failed"
				return ""
			end
		end
	end


	def fetchGoogle
		debug "fetching google data of #{@url}"
		data = fetchURL 'http://216.239.37.100/search?q=cache:FsU-6uPWmo4C:#{url}%&hl=en&ie=UTF-8'
		return data
	end

	def fetchShadow
		debug "fetching shadow data of #{@url}"
		parsed = CGI.escape(@url)
		data = fetchURL $shadowHosts[0] + "?c=return&p=" + parsed
	end

	def checkShadow
		parsed = CGI.escape(@url)
		size = 0
		mtime = 0

		$shadowHosts.each { |host|
			debug "checking shadow entry on #{host}"
			ret = fetchURL "#{host}?c=check&p=#{parsed}"
			if (ret)
				if (ret =~ /^(\d+) (\d+)/)
					size = $1.to_i
					mtime = $2.to_i
					debug "shadow reply: size = #{size} mtime=#{mtime}"
					return size, mtime
				else
					debug "invalid shadow reply: #{ret}"
				end
			else
				debug "#{host} unavailable, deleting from shadow list"
				$shadowHosts.delete(host)
			end
		}
		return nil
	end

	def updateShadow
		fileParts = $shadowHosts[0].split('/')
		host = fileParts[2]
		file = '/' + fileParts[3..-1].join('/')

        if (! @data)
            debug "No data found for #{@url}, not updating shadow"
            return nil
        end

        uploadEncoded = "c=update&p=" + CGI.escape(@url) + "&d=" + CGI.escape(@data)

		#puts uploadEncoded
		web = Net::HTTP.new(host, 80)
		headers = { "Content-Type" => "application/x-www-form-urlencoded" }
		debug "Uploading cache data to shadowfetch server: #{$shadowHosts[0]}"
    response, data = web.post("#{file}?", uploadEncoded, headers)
		if (data !~ /^OK/)
			puts "* data failed to upload, deleting shadow host: #{data}"
            $shadowHosts.delete(host)
			return nil
		else
			debug "uploaded: #{data}"
		end
	end
end

