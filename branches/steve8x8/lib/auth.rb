# $Id$


module Auth
  include Common
  include Messages
  @@login_url = 'https://www.geocaching.com/login/'
  @@cookie = nil

  def login(user, password)
    password2 = password.to_s.gsub(/./, '*')
    debug "login called for user=#{user} pass=#{password2}"
    cookie = loginGetCookie(user, password)
    if cookie
      saveCookie(cookie)
    end
    return cookie
  end

  def getCookie(user, password)
    cookie = loadCookie()
    if not cookie
      cookie = login(user, password)
    end
    return cookie
  end

  def loadCookie()
    cookie = @@cookie
    #debug "loadCookie #{cookie.inspect}"
    return cookie
  end

  def saveCookie(cookie)
    debug "saveCookie #{cookie.inspect}"
    @@cookie = cookie
  end

  def loginGetCookie(user, password)
    @postVars = Hash.new
    # get login form
    page = ShadowFetch.new(@@login_url)
    page.localExpiry=0
    data = page.fetch
    data.each_line do |line|
      case line
      when /^\<input type=\"hidden\" name=\"(.*?)\".*value=\"(.*?)\"/
        debug "found hidden post variable: #{$1}"
        @postVars[$1]=$2
      when /\<form name=\"aspnetForm\" method=\"post\" action=\"(.*?)\"/
        @postURL = @@login_url + $1
        @postURL.gsub!('&amp;', '&')
        debug "post URL is #{@postURL}"
      end
    end
    # fill in form, and submit
    page = ShadowFetch.new(@postURL)
    page.localExpiry=1
    @postVars['ctl00$SiteContent$tbUsername']=user
    @postVars['ctl00$SiteContent$tbPassword']=password
    @postVars['ctl00$SiteContent$cbRememberMe']='on'
    @postVars['ctl00$SiteContent$btnSignIn']='Login'
    page.postVars=@postVars
    data = page.fetch
    # extract cookie
    cookie = page.cookie
    debug "loginGetCookie got cookie: [#{cookie}]"
    if (cookie =~ /userid/) && (cookie =~ /(ASP.NET_SessionId=\w+)/)
      debug "userid found, rock on. Setting cookie to #{$1}"
      cookie=$1
      return cookie
    else
      password2 = password.to_s.gsub(/./, '*')
      displayWarning "Login failed for #{user}:#{password2}"
      return nil
    end
  end

end
