# $Id$

require 'digest/md5'
require 'net/https'
require 'fileutils'
require 'uri'
require 'cgi'
require 'common'
require 'messages'
require 'auth'

# Does a webget, but stores a local directory with cached results ###################
class ShadowFetch
  attr_reader :data, :waypoints, :cookie
  attr_accessor :url

  include Common
  include Messages
  include Auth

  @@downloadErrors = 0
  @@remotePages = 0

  # gets a URL, but stores it in a nice webcache
  def initialize (url)
    @url = url
    @remote = 0
    @localExpiry = 6 * 86400		# 6 days
    @maxFailures = 3			#was 2
    @httpHeaders = {
      'User-Agent'      => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; en-US) AppleWebKit/532.9 (KHTML, like Gecko) Chrome/5.0.307.11 Safari/532.9",
      'Accept'          => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
      'Accept-Language' => 'en-us,en;q=0.5',
      'Accept-Charset'  => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7'
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
    if vars
      vars.each_key {|key|
        if key !~ /^__/
          debug "SET #{key}: #{(key =~ /[Pp]assword/)?'(hidden)':vars[key]}"
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
    debug "src of last get was #{@@src}"
    @@src
  end

# obsolete!
#  def cookie=(cookie)
#    debug "set cookie to #{hideCookie(cookie)}"
#    @cookie = cookie
#  end

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
      nodebug "added post vars to url: #{url}"
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
    localfile.gsub!(/[^\/\w\.\-]/, "_")
    localfile.gsub!(/_+/, "_")
    if $CACHE_DIR
      localfile = $CACHE_DIR + localfile
    else
      localfile = '/tmp' + localfile
    end
    # Windows users have a max of 255 characters I believe.
    if (localfile.length > 250)
      debug "truncating #{localfile} -- too long"
      localfile = localfile.slice(0,250)
    end

    debug "cachefile: #{localfile}"
    return localfile
  end

  def invalidate
    filename = cacheFile(@url)
    if File.exist?(filename)
      displayInfo "Invalidating cache at #{filename}"
      begin
        File.unlink(filename)
      rescue Errno::EACCES => e
        displayWarning "Could not delete #{filename}: #{e} - attempting truncation."
        f = File.truncate(filename, 0)
      end
    end
  end


  # gets the file
  def fetch
    @@src = nil
    time = Time.now
    localfile = cacheFile(@url)
    localparts = localfile.split(/[\\\/]/)
    localdir = localparts[0..-2].join("/")  # basename sucks in Windows.
    nodebug "====+ Fetch URL: #{url}"
    nodebug "====+ Fetch File: #{localfile}"

    # expiry?
    if (File.exists?(localfile))
      age = time.to_i - File.mtime(localfile).to_i
      if (age > @localExpiry)
        debug "local cache is #{age} (> #{@localExpiry}) sec old"
      elsif (File.size(localfile) < 6)
        debug "local cache appears corrupt. removing.."
        invalidate
      else
        debug "local cache is only #{age} (<= #{@localExpiry}) sec old, using local file."
        @data = fetchLocal(localfile)
        @@src = 'local'
        # short-circuit out of here!
        return @data
      end
    else
      debug "no local cache file found for #{localfile}"
    end

    # fetch a new version from remote
    @data = fetchRemote
    size = nil
    # check for valid closed html
    if not @data
      debug "we must not have a net connection, uh no"
    elsif @data !~ /\<\/html\>\s*$/
      displayWarning "No closing HTML tag found"
      #@data = nil
    end
    if (@data)
      @data.force_encoding("UTF-8") if $isRuby19
      @@src = 'remote'
      size = @data.length
    else
      if (File.exists?(localfile))
        debug "using local cache instead"
        @data = fetchLocal(localfile)
        @data.force_encoding("UTF-8") if $isRuby19
        @@src = "local <offline>"
        return @data
      else
        @@src = nil
        debug "ERROR: #{@url} could not be fetched, even by cache"
        return nil
      end
    end

    if (! File.exists?(localdir))
      debug "creating #{localdir}"
      FileUtils::mkdir_p(localdir)
    end

    debug "outputting #{localfile}"
    begin
      cache = File.open(localfile, File::WRONLY|File::TRUNC|File::CREAT, 0666)
      cache.puts @data
      cache.close
    rescue
      displayWarning "Could not overwrite #{localfile}!"
    end
    debug "Returning #{@data.length} bytes: #{@data[0..20]}(...)#{data[-21..-1]}"
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
    debug "#{data.length} bytes retrieved from local cache"
    return data
  end


  def fetchRemote
    @@remotePages = @@remotePages + 1
    randomizedSleep(@@remotePages)
    @httpHeaders['Referer'] = @url
    data = fetchURL(@url)
  end


  def fetchURL (url_str, redirects=2)  # full http:// string!
    #raise ArgumentError, 'HTTP redirect too deep' if redirects == 0
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
      debug "Using proxy from environment: " + ENV['HTTP_PROXY']
      http = Net::HTTP::Proxy(proxy.host, proxy.port, proxy_user, proxy_pass).new(uri.host, uri.port)
    else
      nodebug "No proxy found in environment, using standard HTTP connection."
      http = Net::HTTP.new(uri.host, uri.port)
    end
    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      # openssl 1.0.1 tends to produce long headers which gc doesnt handle
      # reduce set of ciphers to the one that's known to work with 1.0.0h
      # http://gursevkalra.blogspot.de/2009/09/ruby-and-openssl-based-ssl-cipher.html
      if $isRuby19
        http.ciphers = [ 'RC4-SHA', 'AES128-SHA', 'AES256-SHA', 'DES-CBC3-SHA' ]
      end
      # force ssl context to TLSv1/SSLv3
      # http://www.ruby-forum.com/topic/200072
      http.instance_eval { @ssl_context = OpenSSL::SSL::SSLContext.new(:TLSv1) }
    end

    query = uri.path
    if uri.query
      query += "?" + uri.query
    end

    @cookie = loadCookie()
    if @cookie
      nodebug "Added Cookie to #{url_str}: #{hideCookie(@cookie)}"
      @httpHeaders['Cookie'] = @cookie
    else
      debug "No cookie to add to #{url_str}"
    end

    success = true
    begin
      if (@postVars)
        @httpHeaders['Content-Type'] =  "application/x-www-form-urlencoded"
        nodebug "POST to #{query}, headers are #{@httpHeaders.keys.join(" ")}"
        resp = http.post(query, @postString, @httpHeaders)
        # reset POST variables
        @postVars = nil
        @postString = nil
      else
        nodebug "GET to #{query}, headers are #{@httpHeaders.keys.join(" ")}"
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
      if resp.response && resp.response['set-cookie']
        @cookie = resp.response['set-cookie']
        debug "received cookie: #{hideCookie(@cookie)}"
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
        displayInfo "Not following redirect [#{location}]"
        return "" # nil would cause split()ting to fail
      end
      # relative redirects are against RFC, but we may encounter them.
      if location =~ /^https?:\/\//
        # full url given, use this location
      elsif location =~ /^\//
        prefix = "#{uri.scheme}://#{uri.host}"
        #if (uri.scheme == 'http' && uri.port != 80) || (uri.scheme == 'https' && uri.port != 443)
          prefix = "#{prefix}:#{uri.port}"
        #end
        location = prefix + location
      else
        displayWarning "RFC violation: rel redirect [#{location}]"
      end
      return fetchURL(location, redirects - 1)
    when Net::HTTPSuccess
      # do nothing
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
      else #elsif @@downloadErrors > @maxFailures
        displayInfo "Offline mode: not fetching #{url_str}"
        return nil
      end
      return fetchURL(url_str, redirects)
    end

    nodebug "#{url_str} successfully downloaded."
    # clear/decrement error counter
    if @@downloadErrors > 0
      @@downloadErrors -= 1
    end

    if resp.response && resp.response['set-cookie']
      @cookie = resp.response['set-cookie']
      debug "received cookie: #{hideCookie(@cookie)}"
    end

    return resp.body
  end


  # compute random sleep time from number of pages remotely fetched
  def randomizedSleep(counter)
    # start with 1.5 seconds, add a second for each 250 caches, randomize by factor 0.5 .. 1.5, somewhat rounded
    sleeptime = ($SLEEP + counter/250.0) * (rand+0.5)
    sleeptime = (10.0*sleeptime).round/10.0
    sleeptime = $SLEEP if (sleeptime<$SLEEP)
    nodebug "sleep #{sleeptime} seconds"
    sleep sleeptime
  end

end
