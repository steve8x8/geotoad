require 'digest/md5'
require 'net/https'
require 'fileutils'
require 'uri'
require 'cgi'
require 'time'
require 'lib/common'
require 'lib/messages'
require 'lib/auth'

# Does a webget, but stores a local directory with cached results ###################
class ShadowFetch

  include Common
  include Messages
  include Auth

  @@downloadErrors = 0
  @@remotePages = 0
  # json sizes: error ~300 bytes, "publish" only ~700, +FTF ~1300
  @@minFileSize = 512

  attr_reader :data
  attr_reader :cookie
  attr_writer :maxFailures
  attr_writer :localExpiry
  attr_writer :useCookie
  attr_writer :closingHTML
  attr_writer :localFile

  # gets a URL, but stores it in a nice webcache
  def initialize (url)
    @url = url
    @remote = 0
    @localExpiry = 5 * $DAY		# Do not store if < 0
    @maxFailures = 10			#was 3
    @useCookie   = true
    @httpHeaders = {
      'User-Agent'      => #'Mozilla/5.0 (X11; Linux i686; rv:45.0) Gecko/20100101 Firefox/45.0',
                           'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; en-US) AppleWebKit/532.9 (KHTML, like Gecko) Chrome/5.0.307.11 Safari/532.9',
      'Accept'          => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
      'Accept-Language' => 'en-us,en;q=0.5',
      'Accept-Charset'  => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7'
    }
    @closingHTML = true
    @localFile   = nil
    @cacheFile   = nil
    @src         = nil
  end

  def httpHeader=(keyvalue)
    key, value = keyvalue
    debug "set http header #{key}: #{value}"
    @httpHeaders[key] = value
    debug "http headers now: #{@httpHeaders.inspect}"
  end

  def postVars=(vars)
    if vars
      vars.each_key{ |key|
        if key !~ /^__/
          debug2 "SET #{key}: #{(key =~ /[Pp]assword/)?'(hidden)':vars[key]}"
        end
        if (@postString)
          @postString = @postString + "&"
        else
          @postString = ''
        end
        @postString = @postString + key + "=" + CGI.escape(vars[key])
      }
    else
      @postString = nil
    end
    @postVars = vars
  end

  def src
    debug2 "src of last get was #{@src}"
    @src
  end

  # returns the cache filename that the URL will be stored as
  def cacheFile(orig_url)
    url = orig_url.dup
    if (@postVars)
      postdata = ''
      @postVars.each_key{ |key|
        postdata << "#{key}=#{@postVars[key]}"
      }

      # we used to just keep the postdata in the filename, but DOS has
      # a 255 character limit on filenames. Lets hash it instead.
      url << "-P=" + Digest::MD5.hexdigest(postdata)
      debug3 "added post vars to url: #{url}"
    end

    fileParts = url.split('/')
    host = fileParts[2]


    if fileParts[3]
      dir = File.join(fileParts[3..-2])
      if @localFile
        file = @localFile
      else
        file = fileParts[-1]
      end
      @cacheFile = File.join(host, dir, file)
    end

    if url =~ /\/$/
      @cacheFile = File.join(@cacheFile, 'index.html')
    end

    # make a friendly filename
    @cacheFile.gsub!(/[^\/\w\.\-]/, "_")
    @cacheFile.gsub!(/_+/, "_")
    if $CACHE_DIR
      @cacheFile = File.join($CACHE_DIR, @cacheFile)
    else
      @cacheFile = File.join('', 'tmp', @cacheFile)
    end
    # Windows users have a max of 255 characters I believe.
    if (@cacheFile.length > 250)
      debug "truncating \"#{@cacheFile}\" -- too long"
      @cacheFile = @cacheFile[0..219]
    end
    debug2 "cachefile: #{@cacheFile}"
    return @cacheFile
  end

  def invalidate
    return if not @url
    filename = cacheFile(@url)
    if File.exist?(filename)
      debug "Invalidating cache at #{filename}"
      begin
        File.unlink(filename)
      rescue Errno::EACCES => e
        displayWarning "Could not delete #{filename}: #{e} - attempting truncation."
        File.truncate(filename, 0)
      end
    end
  end

  # timestamp of local cache file (if any)
  def fileTimestamp
    timestamp = Time.at($ZEROTIME)
    localfile = cacheFile(@url)
    if localfile and File.exist?(localfile)
      begin
        timestamp = File.mtime(localfile)
      rescue => e
        # there's no cache file
        debug "mtime failed: #{e}"
      end
    end
    return timestamp
  end

  # file age (if file exists)
  def fileAge
    return (Time.now - fileTimestamp()).to_i
  end


  # gets the file
  def fetch
    @src = nil
    time = Time.now
    # this is kind of an ugly hack
    if @localExpiry < 0
      localfile = "/dev/null"
    else
      localfile = cacheFile(@url)
    end
    localparts = localfile.split(/[\\\/]/)
    localdir = File.join(localparts[0..-2])  # basename sucks in Windows.
    debug3 "====+ Fetch URL: #{@url}"
    debug3 "====+ Fetch File: #{localfile}"
    if @localExpiry >= 0
     # expired?
     if (File.readable?(localfile))
      age = time.to_i - File.mtime(localfile).to_i
      if (age > @localExpiry)
        debug "local cache is #{age} (> #{@localExpiry}) sec old"
      elsif (File.size(localfile) <  @@minFileSize)
        # this also takes care of failed JSON requests
        debug "local cache appears corrupt. removing.."
        invalidate
      else
        debug "local cache is only #{age} (<= #{@localExpiry}) sec old, using local file."
        @data = fetchLocal(localfile)
        @src = 'l'	#'local'
        # short-circuit out of here!
        return @data
      end
     else
      debug "no local cache file found for #{localfile}"
     end
    end

    # fetch a new version from remote
    @data = fetchRemote
    size = nil
    # check for valid closed html
    if not @data
      debug "we must not have a net connection, uh no"
    elsif @data !~ /<\/html>\s*$/ and @closingHTML
      if @url =~ /geocaching\.com/
        displayWarning "No closing HTML tag found"
        #@data = nil
      end
    end
    if (@data)
      @src = 'r'	#'remote'
      size = @data.length
    else
      if (File.readable?(localfile))
        debug "using local cache instead"
        @data = fetchLocal(localfile)
        @src = "lo"	#'local <offline>'
        return @data
      else
        @src = nil
        debug "ERROR: #{@url} could not be fetched, even by cache"
        return nil
      end
    end

    if (! File.exists?(localdir))
      debug2 "creating #{localdir}"
      FileUtils::mkdir_p(localdir)
    end

    # some magic to not overwrite a publicly viewable cdpf with PMO
    dowrite = false
    # protect against network failures
    if @data and @data.length >= @@minFileSize
      dowrite = true
      if @data =~ /be a Premium Member to view/
        # we got a PMO description
        # is there already one, possibly non-PMO?
        if File.readable?(localfile)
          # Properly handle changed cache characteristics (D/T/S), coordinates:
          # Get "old" non-PMO file, then append "new" data. Parser should find last info.
          # Works at least with non-WID/GUID queries.
          # As this is a kludge anyway, mimicking the old "paperful caching", don't care.
          olddata = fetchLocal(localfile)
          if olddata =~ /be a Premium Member to view/
            # we do not lose important information by overwriting
            dowrite = true
          else
            # we would lose information by overwriting, but have to concat
            dowrite = false
            @data = olddata + @data
            @src = 'l+r'	#'local+remote'
          end #oldPMO
        end #oldcdpf
      end # newPMO
    end # valid @data
    if @localExpiry < 0
      dowrite = false
    end
    if dowrite
      debug "writing #{localfile}"
      begin
        cache = File.open(localfile, File::WRONLY|File::TRUNC|File::CREAT, 0666)
        cache.puts @data
        cache.close
      rescue
        displayWarning "Could not overwrite #{localfile}!"
      end
    #else
    #  displayWarning "Merging current PMO with non-PMO cache file!"
    end
    debug3 "Returning #{@data.length} bytes: #{@data[0..20]}(...)#{data[-21..-1]}"
    return @data
  end


  ## the real fetch methods ########################################################

  def fetchLocal(file)
    begin
      data = IO.readlines(file).join
    rescue Errno::EACCES => e
      displayWarning "Could not read #{file}: #{e}"
      invalidate()
      return nil
    end
    debug2 "#{data.length} bytes retrieved from local cache"
    data.force_encoding("UTF-8")
    return data
  end


  def fetchRemote
    @@remotePages += 1
    randomizedSleep(@@remotePages)
    @httpHeaders['Referer'] = @url
    data = fetchURL(@url).to_s
    debug2 "#{data.length} bytes retrieved from #{@url}"
    data.force_encoding("UTF-8")
    # although implicit:
    return data
  end


  def fetchURL (url_str, redirects=4)  # full http:// string!
    if (redirects == 0)
      displayWarning "HTTP redirect loop for #{url_str}."
      displayWarning "Your cookie may have expired suddenly. Try to re-run once."
      displayError   "Check your login data if problem persists."
    end
    debug "Fetching URL [#{url_str}]"
    uri = URI.parse(url_str)

    if ENV['HTTP_PROXY']
      proxy = URI.parse(ENV['HTTP_PROXY'])
      proxy_user, proxy_pass = uri.userinfo.split(/:/) if uri.userinfo
      debug2 "Using proxy from environment: " + ENV['HTTP_PROXY']
      http = Net::HTTP::Proxy(proxy.host, proxy.port, proxy_user, proxy_pass).new(uri.host, uri.port)
    else
      debug3 "No proxy found in environment, using standard HTTP connection."
      http = Net::HTTP.new(uri.host, uri.port)
    end
    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = $SSLVERIFYMODE
      # reduce set of ciphers
      # http://gursevkalra.blogspot.de/2009/09/ruby-and-openssl-based-ssl-cipher.html
      # https://www.ssllabs.com/ssltest/analyze.html?d=geocaching.com, drop <256 bit
      #http.ciphers = [ 'RC4-SHA', 'AES128-SHA', 'AES256-SHA', 'DES-CBC3-SHA' ]
      http.ciphers = OpenSSL::SSL::SSLContext.new($SSLVERSION).ciphers.map{ |c,x,y,z|
        (z >= 256) ? c : nil
      }.compact.join(':')
      # force ssl context http://www.ruby-forum.com/topic/200072
      http.instance_eval { @ssl_context = OpenSSL::SSL::SSLContext.new($SSLVERSION) }
    end

    query = uri.path
    if uri.query
      query += "?" + uri.query
    end

    if @useCookie
      @cookie = loadCookie()
      if @cookie
        debug3 "Added Cookie to #{url_str}: #{hideCookie(@cookie)}"
        @httpHeaders['Cookie'] = @cookie
      else
        debug3 "No cookie to add to #{url_str}"
      end
    else
      debug3 "Cookie not added to #{url_str}"
    end

    success = true
    begin
      if (@postVars)
        @httpHeaders['Content-Type'] =  "application/x-www-form-urlencoded"
        debug2 "POST to #{query}, headers are #{@httpHeaders.keys.join(" ")}"
        resp = http.post(query, @postString, @httpHeaders)
        # reset POST variables
        @postVars = nil
        @postString = nil
      else
        debug2 "GET to #{query}, headers are #{@httpHeaders.keys.join(" ")}"
        resp = http.get(query, @httpHeaders)
      end
    rescue Timeout::Error => e
      success = false
      displayWarning "Timeout #{uri.host}:#{uri.port}"
    rescue Errno::ECONNREFUSED => e
      success = false
      displayWarning "Connection refused #{uri.host}:#{uri.port}"
    rescue => e
      success = false
      displayWarning "Cannot connect to #{uri.host}:#{uri.port}: #{e}"
    end

    case resp
    # these are "combined" return codes ("if" doesn't work)
    when Net::HTTPRedirection
      # we may have received a cookie
      if resp.response && resp.response['set-cookie'] && @useCookie
        @cookie = resp.response['set-cookie']
        debug2 "received cookie: #{hideCookie(@cookie)}"
        saveCookie(@cookie)
      end
      location = resp['location']
      debug "REDIRECT: [#{location}]"
      # error 500
      # D: REDIRECT: [/error/error.aspx?aspxerrorpath=/seek/cdpf.aspx]
      if location =~ /^\/error\/error\.aspx/
        displayWarning "Error 500: [#{url_str}]"
        if location =~ /aspxerrorpath=\/seek\/cdpf.aspx/
          # try to strip off "&lc=10"
          if url_str =~ /\&lc=\d+/
            url_str.gsub!(/&lc=\d+/, '')
            displayInfo "Retry no-log #{url_str}"
            return fetchURL(url_str, redirects - 1)
          end
        end
        if location =~ /aspxerrorpath=\/seek\/cache_details.aspx/
          displayInfo "May be issue 304. Try to use another language."
        end
        displayInfo "Not following redirect [#{location}]"
        return "" # nil would cause split()ting to fail
      end
      # relative redirects are against RFC, but we may encounter them.
      if location =~ /^https?:\/\//
        # full url given, use this location
      elsif location =~ /^\//
        prefix = "#{uri.scheme}://#{uri.host}:#{uri.port}"
        location = prefix + location
      else
        displayWarning "RFC violation: rel redirect [#{location}]"
      end
      return fetchURL(location, redirects - 1)
    when Net::HTTPSuccess
      # do nothing
    when Net::HTTPNotFound
      # error 404
      displayWarning "Not Found #{resp.response.inspect}"
      debug "#{resp.body.length} bytes in body"
    else
      # we may have reported a problem before
      if success
        success = false
        displayWarning "Unknown response \"#{resp.inspect}\" [#{url_str}]"
      end
    end

    if not success
      @@downloadErrors += 1
      if @@downloadErrors < @maxFailures
        debug "#{@@downloadErrors} download errors so far, will try until #{@maxFailures}"
        # progressive sleep time: 5, 20, 45 sec.
        sleep( 5*@@downloadErrors**2)
      elsif @@downloadErrors == @maxFailures
        debug "#{@@downloadErrors} download errors so far, maximum reached"
        sleep(10*@@downloadErrors**2)
      else
        displayInfo "Offline mode: not fetching #{url_str}"
        return nil
      end
      return fetchURL(url_str, redirects)
    end

    debug3 "#{url_str} successfully downloaded."
    # decrement error counter
    if @@downloadErrors > 0
      @@downloadErrors -= 1
    end

    if resp.response && resp.response['set-cookie'] && @useCookie
      @cookie = resp.response['set-cookie']
      debug2 "received cookie: #{hideCookie(@cookie)}"
      saveCookie(@cookie)
    end

    return resp.body
  end


  # compute random sleep time from number of pages remotely fetched
  def randomizedSleep(counter)
    # start with 1.5 seconds, add a second for each 250 caches, randomize by factor 0.5 .. 1.5, somewhat rounded
    sleeptime = ($SLEEP + counter/250.0) * (rand+0.5)
    sleeptime = (10.0*sleeptime).round/10.0
    sleeptime = $SLEEP if (sleeptime<$SLEEP)
    debug3 "sleep #{sleeptime} seconds"
    sleep sleeptime
  end

end
