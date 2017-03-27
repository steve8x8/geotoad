### Each session started with a fresh cookie, no cookies file anymore
### Received cookies dissected and written to hash,
### cookies to be sent combined from hash

require 'time'
require 'lib/common'
require 'lib/messages'

module Auth

  include Common
  include Messages

  @@login_url = 'https://www.geocaching.com/account/login'
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
      # default format
      when /^(.*?)=(.*?);.*expires=(\w+, (\d+)-(\w+)-(\d+) (\d+):(\d+):(\d+) GMT);/
        key = $1
        value = $2
        expire = $3
        et = Time.gm($6, $5, $4, $7, $8, $9)
        life = (et.to_i - Time.now.to_i) / 86400.0
        if (life <= -86400)
          value = 'expired'
          displayWarning "Cookie \"#{key}\" has expired! (#{expire})"
        elsif (life <= 0)
          displayWarning "Cookie \"#{key}\" is expiring! (#{expire})"
        end
        if @@cookies[key] != value
          debug3 "saveCookie: set #{key}, expires #{expire}"
          @@cookies[key] = value
        else
          debug3 "saveCookie: confirm #{key}, expires #{expire}"
        end
      # unsupported format or timezone
      when /^(.*?)=(.*?);.*expires=(.*);/
        key = $1
        value = $2
        expire = $3
        displayWarning "Cookie \"#{key}\" has unsupported expires=#{expire}"
      # cookie without expires, e.g. SessionID
      when /^(.*?)=(.*?);/
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
    hcookie = cookie.to_s.split(/; */).map{ |c|
    if c =~ /(__RequestVerificationToken=|gspkauth=|ASP.NET_SessionId=)(\w{5})(\w+)(\w{5})/
      "#{$1}#{$2}[#{$3.length}]#{$4}"
    else
      c
    end
    }.compact.join("; ")
    return hcookie
  end

  def getLoginCookie(user, password)
    @@user = user
    @postVars = Hash.new
    @postURL = @@login_url
    # get login form
    page = ShadowFetch.new(@@login_url)
    page.localExpiry = -1
    data = page.fetch
    # all form data are in one line now (20170323)
    # as a workaround, split at tag end - FIXME
    data.gsub(">", ">\n").each_line do |line|
      case line
      # sequence of type="hidden" and name="..." may change
      # make this more robust - FIXME
      when /<input .*name=\"(.*?)\".*value=\"(.*?)\"/
        @postVars[$1] = $2
        debug3 "found post variable: #{$1}"
      when /<form .*logout/
        # ignore
        true
      when /<form .*action=\"(.*?)\"/
        debug3 "getLoginCookie form action \"#{$1}\""
        @postURL = @@login_url
        debug3 "post URL is #{@postURL}"
      end
    end
    # fill in form with user credentials, and submit
    page = ShadowFetch.new(@postURL)
    page.localExpiry = -1
    @postVars['Username'] = user
    @postVars['Password'] = password
    debug3 "login postVars #{@postVars.keys.inspect}"
    page.postVars = @postVars
    data = page.fetch
    # extract cookie
    cookie = page.cookie
    debug3 "getLoginCookie got cookie: [#{hideCookie(cookie)}]"
    # merge this new cookie with the one we got at login time
    saveCookie(cookie)
    cookie = loadCookie()
    # spring 2016 replaced userid with other cookies
    # spring 2017 did this again
    if (cookie =~ /gspkauth=/) and
      ((cookie =~ /(__RequestVerificationToken=\w+)/) or (@cookie =~ /(ASP.NET_SessionId==\w+)/))
      debug "Cookie #{hideCookie(cookie)} looks good, rock on."
      return cookie
    else
      debug "Cookie #{hideCookie(cookie)} looks fishy..."
      displayWarning "Login failed for #{user}:#{password.to_s.gsub(/./, '*')}, retry."
      return nil
    end
  end

end
