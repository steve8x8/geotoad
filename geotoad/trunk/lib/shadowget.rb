# $Id$

require 'digest/md5'
require 'net/http'
require 'ftools'
require 'uri'

# find out where we want our cache #############################
cacheDir = nil


# Does a webget, but stores a local directory with cached results ###################
class ShadowFetch
    attr_reader :data, :waypoints, :cookie
    attr_accessor :url
    
    include Common
    include Display
    @@downloadErrors = 0
    
    # gets a URL, but stores it in a nice webcache
    def initialize (url)
        @url = url
        @remote = 0
        @localExpiry=518400    		# 6 days
        @maxFailures = 4
        debug "** new fetch: #{url}"
        @httpHeaders = {
          'User-Agent'      => "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/417.9 (KHTML, like Gecko) Safari/417.8",
          'Accept'          => 'image/gif, image/jpeg, image/png, multipart/x-mixed-replace, */*',
          'Accept-Language' => 'en',
          'Accept-Charset'  => 'iso-8859-1, utf-8, iso-10646-ucs-2, macintosh, windows-1252, *'
        }
    end
    
    
    def maxFailures=(maxfail)
        debug "setting max failures to #{maxfail}"
        @maxFailures=maxfail
    end
    
    
    def localExpiry=(expiry)
        debug "setting local expiry to #{expiry}"
        @localExpiry=expiry
    end
    
    def postVars=(vars)
        vars.each_key {|key|
            if (@postString)
                @postString = @postString + "&"
            else
                @postString = ''
            end
            @postString = @postString + key + "=" + CGI.escape(vars[key])
        }
        @postVars=vars
        debug "Set POST string to: #{@postString}"
    end
    
    def src
        debug "src of last get was #{@@src}"
        @@src
    end
    
    def cookie=(cookie)
        debug "set cookie to #{cookie}"
        @cookie=cookie
    end
    
    # returns the cache filename that the URL will be stored as
    def cacheFile(url)
        if (@postVars)
            postdata=''
            @postVars.each_key { |key|
                postdata = postdata + "#{key}=#{@postVars[key]}"
            }
            
            # we used to just keep the postdata in the filename, but DOS has
            # a 255 character limit on filenames. Lets hash it instead.
            url = url + "-P=" + Digest::MD5.hexdigest(postdata)
            debug "added post vars to url: #{url}"
        else
            debug "no post vars to add to filename"
        end
        
        fileParts = url.split('/')
        host = fileParts[2]
        
        
        if fileParts[3]
            dir = fileParts[3..-2].join('/')
            file = fileParts[-1]
            localfile = '/' + host + '/' + dir + '/' + file
        end
        
        if url =~ /\/$/
            localfile = localfile + '/index.html'
        end
        
        # make a friendly filename
        localfile.gsub!(/[=\?\*\%\&\$:\-\.]/, "_")
        localfile.gsub!(/_+/, "_")
        localfile = $TEMP_DIR + localfile;
        
        # Windows users have a max of 255 characters I believe.
        if (localfile.length > 250)
            debug "truncating #{localfile} -- too long"
            localfile = localfile.slice(0,250)
        end
        
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
        
        debug "Checking to see if #{localfile} exists"
        
        # expiry?
        if (File.exists?(localfile))
            age = time.to_i - File.mtime(localfile).to_i
            if (age > @localExpiry)
                debug "local cache is #{age} old, older than #{@localExpiry}"
            elsif (File.size(localfile) < 6)
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
        
        
        @data = fetchRemote
        size = nil
        if (@data)
            @@src='remote'
            size = @data.length
        else
            debug "we must not have a net connection, uh no"
            if (File.exists?(localfile))
                debug "using local cache instead"
                @data = fetchLocal(localfile)
                @@src = "local <offline>"
                return @data
            else
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
        
        debug "Returning #{@data.length} bytes: #{@data[0..512]}"
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
        @httpHeaders['Referer'] = @url
        data = fetchURL(@url)
    end
    
    def fetchURL (url_str, redirects=2)  # full http:// string!
        raise ArgumentError, 'HTTP redirect too deep' if redirects == 0
        
        debug "Fetching #{url_str}"
        
        uri = URI.parse(url_str)
        
        if (@@downloadErrors >= @maxFailures)
            debug "#{@@downloadErrors} download errors so far, no more retries will be attempted."
            disableRetry = 1
        else
            debug "Only #{@@downloadErrors} download errors so far, will try until #{@maxFailures}"
            disableRetry = nil
        end
        
        http = Net::HTTP.new(uri.host, 80)
        if uri.query
            query=uri.path + "?" + uri.query
        else
            query=uri.path
        end
        
        if @cookie 
            debug "Added Cookie to #{url}: #{@cookie}"
            @httpHeaders['Cookie']=@cookie
        else
            debug "No cookie to add to #{url}"
        end
        
        if (@postVars)
            @httpHeaders['Content-Type'] =  "application/x-www-form-urlencoded";
            debug "POST to #{query}, headers are #{@httpHeaders.keys.join(" ")}"
            resp = http.post(query, @postString, @httpHeaders)
        else
            debug "GET to #{query}, headers are #{@httpHeaders.keys.join(" ")}"
            resp = http.get(query, @httpHeaders)
        end
        
        case resp
        when Net::HTTPSuccess
            debug "#{url_str} successfully downloaded."
            
        when Net::HTTPRedirection
            fetchURL(resp['location'], limit - 1)
            
        else
            debug "error downloading #{url}"
            @@downloadErrors = @@downloadErrors + 1
            
            if (disableRetry)
                # only show the first few failures..
                if @@downloadErrors < @maxFailures
                    displayWarning "Could not fetch #{url}, no more retries available. (failures=#{@@downloadErrors})"
                end
                return nil
            else
                disableRetry = 1
                displayWarning "Could not fetch #{url}, retrying in 5 seconds.. (failures=#{@@downloadErrors}, max=#{@maxFailures})"
                sleep(5)
            end
        end    
        
        
        if resp.response && resp.response['set-cookie']
            @cookie = resp.response['set-cookie']
            debug "receieved cookie: #{@cookie}"
        end
        
        return resp.body
    end
end
