# $Id$

### 20131114 related modifications to cookie handling:
### Each session started with a fresh cookie, no cookies file anymore
### Received cookies dissected and written to hash,
### cookies to be sent combined from hash
### ToDo: remove cookie if expires= date is in the past

module Auth

  require 'yaml'

  include Common
  include Messages
  @@login_url = 'https://www.geocaching.com/login/'
  @@user = nil
  # cookie to be sent
  @@cookie = nil
  # cookie collection hash
  @@cookies = {}

  # called by main program at the beginning
  def login(user, password)
    @@user = user
    password2 = password.to_s.gsub(/./, '*')
    debug "login called for user=#{user} pass=#{password2}"
    cookie = loadCookie()
    logged_in = checkLoginScreen(cookie)
    if ! logged_in
      # remove invalid cookie, and recreate
      saveCookie(nil)
      cookie = getLoginCookie(user, password)
    end
    if cookie
        saveCookie(cookie)
    end
    logged_in = checkLoginScreen(cookie)
    # got to keep this kludge because login check returns another set of cookies :(
    # FIXME!
    if logged_in and (cookie !~ /userid/)
      # successful login can happen without returning userid?
      cookie = cookie.to_s + ' userid=known;'
    end
    return cookie
  end

  def cookieFile()
    return findConfigDir() + '/cookies.yaml'
  end

  def loadCookie()
    ### 20131114
    return @@cookie
    # --- NOTREACH
    ### 20131114
  # return cookie from variable if set, read from file otherwise
    if ! @@cookie and @@user
      cookie_file = cookieFile()
      cookies = nil
      if File.readable?(cookie_file)
        debug "Loading cookies from #{cookie_file}"
        cookies = YAML::load(File.open(cookie_file))
      end
      if cookies && cookies[@@user.inspect]
        #@@cookie = cookies[@@user.inspect]
        if (cookies[@@user.inspect] =~ /(ASP.NET_SessionId=\w+)/)
          @@cookie = $1
          debug "loadCookie: found #{hideCookie(@@cookie)}"
        end
      end
    end
    debug "using cookie [#{@@user.inspect}] #{hideCookie(@@cookie)}"
    return @@cookie
  end

  def saveCookie(cookie)
    ### 20131114
    # don't do anything without a cookie
    return if ! cookie
    debug "saveCookie merges #{hideCookie(cookie)}"
    cookie.split(/[;,] */).each{ |f|
    # remove unneccessary information
      if f !~ /=/
       nil
      elsif f =~ /(path|domain|secure|expires)=/
        nil
      elsif f =~ /(.*)=(.*)/
        @@cookies[$1]=$2
      end
    }
    @@cookie = @@cookies.keys.map{ |k| "#{k}=#{@@cookies[k]}" }.join('; ')
    debug "saveCookie saved #{hideCookie(@@cookie)}"
    return
    # --- NOTREACH
    ### 20131114
    if ! cookie
      debug "saveCookie: no cookie, will delete"
    end
    if ! @@user
      debug "saveCookie: cannot save cookie, user undefined"
      return
    end
    if cookie
      if (cookie !~ /(ASP.NET_SessionId=\w+)/)
        debug "saveCookie: invalid cookie"
        return
      else
        cookie = $1
      end
    end
    debug "saveCookie: [#{@@user.inspect}] #{hideCookie(cookie)}"
    if @@cookie != cookie
      # cookie has changed: write to file
      @@cookie = cookie
      cookie_file = cookieFile()
      cookies = false
      if File.readable?(cookie_file)
        cookies = YAML::load(File.open(cookie_file))
      end
      # cookie file may be empty
      if not cookies
        cookies = Hash.new
      end
      # add/replace/remove cookie for user
      if @@cookie
        debug "insert cookie #{hideCookie(@@cookie)} for user #{@@user.inspect}"
        cookies[@@user.inspect] = @@cookie
      else
        cookies.delete(@@user.inspect)
      end
      if (cookies.length > 0)
        File.open(cookie_file, 'w') { |f| f.puts(YAML::dump(cookies)) }
      end
      # nil cookie to force reloading
      @@cookie = nil
    end
  end

  # obfuscate cookie so nobody can use it
  def hideCookie(cookie)
    hcookie = cookie.to_s
    if cookie =~ /(ASP.NET_SessionId=)(\w{5})(\w+)(\w{5})(;.*)?/
      hcookie = $1 + $2 + "*" * $3.length + $4 + $5.to_s
    end
    if hcookie.empty?
      hcookie = '(none)'
    end
    return hcookie
  end

  def checkLoginScreen(cookie)
    ### 20131114
    # if we have no cookie we aren't logged in
    debug "checkLoginScreen with #{hideCookie(cookie)}"
    return nil if ! cookie
    ### 20131114
    @postVars = Hash.new
    page = ShadowFetch.new(@@login_url + 'default.aspx')
    page.localExpiry = 1

    if cookie
      debug "Checking validity of cookie (#{cookie[0..22]+'...'+cookie[-5..-1]})"
    end
    data = page.fetch
    data.each_line do |line|
      case line
      when /ctl00_ContentBody_LoggedInPanel/
        debug "Found logged-in panel"
        #return true
      when /You are (logged|signed) in as/
        debug "Found login confirmation!"
        return true
      when /^\<input type=\"hidden\" name=\"(.*?)\".*value=\"(.*?)\"/
        debug "found hidden post variable: #{$1}"
        @postVars[$1]=$2
      when /\<form name=\"aspnetForm\" method=\"post\" action=\"(.*?)\"/
        @postURL = @@login_url + $1
        @postURL.gsub!('&amp;', '&')
        debug "post URL is #{@postURL}"
      end
    end
    debug "Looks like we don't have a valid cookie. Must login."
    nodebug "#{data.inspect}"
    return nil
  end

  def getLoginCookie(user, password)
    @@user = user
    @postVars = Hash.new
    # get login form
    page = ShadowFetch.new(@@login_url + 'default.aspx')
    page.localExpiry = 1
    data = page.fetch
    data.each_line do |line|
      case line
      when /^\<input type=\"hidden\" name=\"(.*?)\".*value=\"(.*?)\"/
        debug "found hidden post variable: #{$1}"
        @postVars[$1] = $2
      when /\<form name=\"aspnetForm\" method=\"post\" action=\"(.*?)\"/
        debug "found post action: #{$1.inspect}"
        @postURL = @@login_url + $1
        @postURL.gsub!('&amp;', '&')
        debug "post URL is #{@postURL}"
      end
    end
    # fill in form, and submit
    page = ShadowFetch.new(@postURL)
    page.localExpiry = 0
    @postVars['ctl00$ContentBody$tbUsername'] = user
    @postVars['ctl00$ContentBody$tbPassword'] = password
    @postVars['ctl00$ContentBody$cbRememberMe'] = 'on'
    @postVars['ctl00$ContentBody$btnSignIn'] = 'Sign In'
    page.postVars = @postVars
    data = page.fetch
    # extract cookie
    cookie = page.cookie
    debug "getLoginCookie got cookie: [#{hideCookie(cookie)}]"
    ### 20131114
    # merge this new cookie with the one we got at login time
    saveCookie(cookie)
    cookie = loadCookie()
    # FIXME: this always succeeds if we don't delete cookies
    if (cookie =~ /userid/) && (cookie =~ /(ASP.NET_SessionId=\w+)/)
      #cookie = $1
      ### 20131114
      debug "userid found, rock on. Setting cookie to #{hideCookie(cookie)}"
      return cookie
    else
      #displayWarning "Login failed for #{user}:#{password.to_s.gsub(/./, '*')}, retry."
      return nil
    end
  end

end
