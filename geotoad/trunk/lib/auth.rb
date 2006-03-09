# $Id$

module Auth
    include Common
    include Display
    
    def login(user, password)
        debug "login called for user=#{user} pass=#{password}"
        getLoginValues
        cookie = getLoginCookie(user, password)
        return cookie
    end
    
    def getLoginValues
        @postVars = Hash.new
        
        page = ShadowFetch.new('http://www.geocaching.com/login/')
        data = page.fetch
        
        data.each do |line| 
            case line
            when /^\<input type=\"hidden\" name=\"(.*?)\" value=\"(.*?)\" \/\>/
                debug "found hidden post variable: #{$1}"
                @postVars[$1]=$2
            when /\<form name=\"frmLogin\" method=\"post\" action=\"(.*?)\"/
                @postURL='http://www.geocaching.com/login/' + $1
                @postURL.gsub!('&amp;', '&')
                debug "post URL is #{@postURL}"
            end
        end
    end
    
    def getLoginCookie(user, password)
        page = ShadowFetch.new(@postURL)
        page.localExpiry=1
        @postVars['myUsername']=user
        @postVars['myPassword']=password
        @postVars['cookie']='on'
        @postVars['Button1']='Login'
        page.postVars=@postVars
        data = page.fetch
        cookie = page.cookie
        debug "getLoginCookie got cookie: #{cookie}"
        if (cookie =~ /userid/) && (cookie =~ /(ASP.NET_SessionId=\w+)/) 
            debug "userid found in cookie, rock on. Setting session to #{$1}"
            cookie=$1
            return cookie
        else
            debug "login failed"
            return nil
        end
    end
end
