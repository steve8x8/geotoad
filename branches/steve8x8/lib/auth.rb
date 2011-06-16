# $Id$


module Auth
  include Common
  include Messages
  @@login_url = 'https://www.geocaching.com/login/'

  def login(user, password)
    password2 = password.to_s.gsub(/./, '*')
    debug "login called for user=#{user} pass=#{password2}"
    cookie = loadCookie()
    logged_in = checkLoginScreen(cookie)
    if ! logged_in
      cookie = getLoginCookie(user, password)
      if cookie
        saveCookie(cookie)
      end
    end
    return cookie
  end

  def cookieFile()
    return findConfigDir() + '/cookie'
  end

  def loadCookie()
    cookie_file = cookieFile()
    if File.exist?(cookie_file)
      cookie = File.new(cookie_file).readline.chomp!
      debug "Read cookie from #{cookie_file}: [#{cookie}]"
      return cookie
    else
      return nil
    end
  end

  def saveCookie(cookie)
    cookie_file = cookieFile()
    debug "Saving cookie in #{cookie_file}: [#{cookie}]"
    f = File.new(cookie_file, 'w')
    f.puts cookie
    f.close
  end

  def checkLoginScreen(cookie)
    @postVars = Hash.new
    page = ShadowFetch.new(@@login_url)
    page.localExpiry=0

    if cookie
      debug "Checking to see if my previous cookie is valid (#{cookie})"
      page.cookie = cookie
    end
    data = page.fetch

    data.each_line do |line|
      case line
      when /You are logged in as/
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
    debug "Looks like we are not logged in."
    return nil
  end

  def getLoginCookie(user, password)
    page = ShadowFetch.new(@postURL)
    page.localExpiry=1
    @postVars['ctl00$SiteContent$tbUsername']=user
    @postVars['ctl00$SiteContent$tbPassword']=password
    @postVars['ctl00$SiteContent$cbRememberMe']='on'
    @postVars['ctl00$SiteContent$btnSignIn']='Login'
    page.postVars=@postVars
    data = page.fetch
    cookie = page.cookie
    debug "getLoginCookie got cookie: [#{cookie}]"
    if (cookie =~ /userid/) && (cookie =~ /(ASP.NET_SessionId=\w+)/)
      debug "userid found in cookie, rock on. Setting session to #{$1}"
      cookie=$1
      return cookie
    else
      password2 = password.to_s.gsub(/./, '*')
      displayWarning "Login failed for #{user}:#{password2}"
      return nil
    end
  end

end
