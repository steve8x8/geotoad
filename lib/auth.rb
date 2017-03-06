### Each session started with a fresh cookie, no cookies file anymore
### Received cookies dissected and written to hash,
### cookies to be sent combined from hash

require 'time'
require 'lib/common'
require 'lib/messages'

module Auth

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
    # trash and recreate cookie
    saveCookie(nil)
    cookie = getLoginCookie(user, password)
    if cookie
        saveCookie(cookie)
    else
        debug "no cookie from login"
    end
    logged_in = checkLoginScreen(cookie, user)
    debug "checkLoginScreen returns #{logged_in.inspect}"
    # get the current (set of) cookie(s) and pretend that login was successful
    return cookie
  end

  def loadCookie()
    debug2 "loadCookie: #{hideCookie(@@cookie)}"
    return @@cookie
  end

  def saveCookie(cookie)
    # don't do anything without a cookie
    return if not cookie
    debug3 "saveCookie: merge #{hideCookie(cookie)}"
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
      debug3 "saveCookie: process cookie #{hideCookie(c)}"
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
          debug3 "saveCookie: set #{key}, expires #{expire}"
          @@cookies[key] = value
        else
          debug3 "saveCookie: confirm #{key}, expires #{expire}"
        end
      when /^(.*?)=(.*?);/ # SessionId has no expires
        key = $1
        value = $2
        if @@cookies[key] != value
          debug3 "saveCookie: set #{key}"
          @@cookies[key] = value
        else
          debug3 "saveCookie: confirm #{key}"
        end
      end
    }
    @@cookie = @@cookies.keys.map{ |k| (@@cookies[k] == 'expired') ? nil : "#{k}=#{@@cookies[k]}" }.compact.join('; ')
    debug2 "saveCookie: save #{hideCookie(@@cookie)}"
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

  def checkLoginScreen(cookie, user)
    # if we have no cookie we aren't logged in
    debug2 "checkLoginScreen with #{hideCookie(cookie)}"
    return nil if not cookie
    @postVars = Hash.new
    page = ShadowFetch.new(@@login_url + 'default.aspx')
    page.localExpiry = -1
    debug3 "Checking validity of cookie #{hideCookie(cookie)}"
    data = page.fetch
    data.each_line do |line|
      case line
      #  <h3><span id="ctl00_ContentBody_lbUsername">Has iniciado sesión como <strong>Ölscheich99</strong></span></h3>
      # Note: the only occurrence of utf-8 characters is in the comment above
      when /You are (logged|signed) in as/
        debug "Found login confirmation!"
        return true
      when /<strong>#{user}<\/strong>/
        debug "Username confirmed!"
        return true
      when /<input type=\"hidden\" name=\"(.*?)\".*value=\"(.*?)\"/
        @postVars[$1] = $2
        debug3 "found hidden post variable: #{$1}"
      when /<form .*logout/
        # ignore
        true
      #when /<form name=\"aspnetForm\" method=\"post\" action=\"(.*?)\"/
      # 20161010:
      # <form method="post" action="./default.aspx" onsubmit="javascript:return WebForm_OnSubmit();" id="aspnetForm">
      when /<form .*action=\"(.*?)\"/
        debug3 "checkLoginScreen form action \"#{$1}\""
        @postURL = @@login_url + $1
        @postURL.gsub!('/./', '/')
        @postURL.gsub!('&amp;', '&')
        debug3 "post URL is #{@postURL}"
      end
    end
    debug "Looks like we don't have a valid cookie. Must login again?"
    return nil
  end

  def getLoginCookie(user, password)
    @@user = user
    @postVars = Hash.new
    # get login form
    page = ShadowFetch.new(@@login_url + 'default.aspx')
    page.localExpiry = -1
    data = page.fetch
    data.each_line do |line|
      case line
      when /<input type=\"hidden\" name=\"(.*?)\".*value=\"(.*?)\"/
        @postVars[$1] = $2
        debug3 "found hidden post variable: #{$1}"
      when /<form .*logout/
        # ignore
        true
      #when /<form name=\"aspnetForm\" method=\"post\" action=\"(.*?)\"/
      # 20161010:
      # <form method="post" action="./default.aspx" onsubmit="javascript:return WebForm_OnSubmit();" id="aspnetForm">
      when /<form .*action=\"(.*?)\"/
        debug3 "getLoginCookie form action \"#{$1}\""
        @postURL = @@login_url + $1
        @postURL.gsub!('/./', '/')
        @postURL.gsub!('&amp;', '&')
        debug3 "post URL is #{@postURL}"
      end
    end
    # fill in form, and submit
    page = ShadowFetch.new(@postURL)
    page.localExpiry = -1
    @postVars['ctl00$ContentBody$tbUsername'] = user
    @postVars['ctl00$ContentBody$tbPassword'] = password
    @postVars['ctl00$ContentBody$cbRememberMe'] = 'on'
    @postVars['ctl00$ContentBody$btnSignIn'] = 'Sign In'
    page.postVars = @postVars
    data = page.fetch
    # extract cookie
    cookie = page.cookie
    debug3 "getLoginCookie got cookie: [#{hideCookie(cookie)}]"
    # merge this new cookie with the one we got at login time
    saveCookie(cookie)
    cookie = loadCookie()
    # spring 2016 replaced userid with other cookies
    if (cookie =~ /gspkauth=/) and (cookie =~ /(ASP.NET_SessionId=\w+)/)
      debug "Cookie #{hideCookie(cookie)} looks good, rock on."
      return cookie
    else
      debug "Cookie #{hideCookie(cookie)} looks fishy..."
      displayWarning "Login failed for #{user}:#{password.to_s.gsub(/./, '*')}, retry."
      return nil
    end
  end

end
