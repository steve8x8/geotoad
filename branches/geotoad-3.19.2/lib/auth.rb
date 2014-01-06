# $Id$

### 20131114 related modifications to cookie handling:
### Each session started with a fresh cookie, no cookies file anymore
### Received cookies dissected and written to hash,
### cookies to be sent combined from hash

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
    # We only login if there's something wrong with the cookie
    # remove invalid cookie, and recreate
    saveCookie(nil)
    cookie = getLoginCookie(user, password)
    if cookie
        saveCookie(cookie)
    end
    logged_in = checkLoginScreen(cookie)
    # get the current (set of) cookie(s) and pretend that login was successful
    cookie = loadCookie()
    return cookie
  end

  def loadCookie()
    ### 20131114
    debug "loadCookie: #{hideCookie(@@cookie)}"
    return @@cookie
  end

  def saveCookie(cookie)
    ### 20131114
    # don't do anything without a cookie
    return if ! cookie
    nodebug "saveCookie: merge #{hideCookie(cookie)}"
    # get individual cookies
    cookie.split(/; */).map{ |f|
      # split at ';' will yield 2nd cookie with "HttpOnly, " prefix
      # recombine fragments, insert unique separator
      if f =~ /(.*),(.*?=.*)/
        $1 + '%' + $2
      else
        f
      end
    }.join('; ').split(/% */).each{ |c|
      # individual cookies
      debug "saveCookie: process cookie #{hideCookie(c)}"
      # key=value; [domain=...; ][expires=Sat, 06-Apr-2013 07:45:26 GMT; ]path=...; HttpOnly
      # if expires date is in the past, remove/disable
      case c
      when /^(.*?)=(.*?);.*expires=(\w+, (\d+)-(\w+)-(\d+) (\d+):(\d+):(\d+) GMT);/
        key = $1
        value = $2
        expire = $3
        et = Time.gm($6, $5, $4, $7, $8, $9)
        life = (et.to_i - Time.now.to_i) / 86400.0
        if (life <= 0)
          value = 'expired'
          displayWarning "Cookie \"#{key}\" has expired! (#{expire})"
        end
        if @@cookies[key] != value
          debug "saveCookie: set #{key}, expires #{expire}"
          @@cookies[key] = value
        else
          debug "saveCookie: confirm #{key}, expires #{expire}"
        end
      when /^(.*?)=(.*?);/ # SessionId has no expires
        key = $1
        value = $2
        if @@cookies[key] != value
          debug "saveCookie: set #{key}"
          @@cookies[key] = value
        else
          debug "saveCookie: confirm #{key}"
        end
      end
    }
    @@cookie = @@cookies.keys.map{ |k| (@@cookies[k] == 'expired') ? nil : "#{k}=#{@@cookies[k]}" }.compact.join('; ')
    debug "saveCookie: save #{hideCookie(@@cookie)}"
    return
  end

  # obfuscate cookie so nobody can use it
  def hideCookie(cookie)
    hcookie = cookie.to_s
    if cookie =~ /(ASP.NET_SessionId=)(\w{5})(\w+)(\w{5})(;.*)?/
      hcookie = $1 + $2 + "*" * $3.length + $4 + $5.to_s
    end
    hcookie = 'nil' if hcookie.empty?
    return hcookie
  end

  def checkLoginScreen(cookie)
    ### 20131114
    # if we have no cookie we aren't logged in
    nodebug "checkLoginScreen with #{hideCookie(cookie)}"
    return nil if ! cookie
    ### 20131114
    @postVars = Hash.new
    page = ShadowFetch.new(@@login_url + 'default.aspx')
    page.localExpiry = 1
    debug "Checking validity of cookie #{hideCookie(cookie)}"
    data = page.fetch
    data.each_line do |line|
      case line
      #when /ctl00_ContentBody_LoggedInPanel/
        #debug "Found logged-in panel"
        #return true
      when /You are (logged|signed) in as/
        debug "Found login confirmation!"
        return true
      when /^\<input type=\"hidden\" name=\"(.*?)\".*value=\"(.*?)\"/
        @postVars[$1] = $2
        nodebug "found hidden post variable: #{$1}"
      when /\<form name=\"aspnetForm\" method=\"post\" action=\"(.*?)\"/
        @postURL = @@login_url + $1
        @postURL.gsub!('&amp;', '&')
        nodebug "post URL is #{@postURL}"
      end
    end
    debug "Looks like we don't have a valid cookie. Must login."
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
        @postVars[$1] = $2
        debug "found hidden post variable: #{$1}"
      when /\<form name=\"aspnetForm\" method=\"post\" action=\"(.*?)\"/
        nodebug "found post action: #{$1.inspect}"
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
    if (cookie =~ /userid=/) && (cookie =~ /(ASP.NET_SessionId=\w+)/)
      debug "Cookie #{hideCookie(cookie)} looks good, rock on."
      return cookie
    else
      debug "Cookie #{hideCookie(cookie)} looks fishy..."
      displayWarning "Login failed for #{user}:#{password.to_s.gsub(/./, '*')}, retry."
      return nil
    end
  end

end
