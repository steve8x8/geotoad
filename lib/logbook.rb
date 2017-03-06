require 'time'
require 'cgi'
require 'lib/common'
require 'lib/messages'
require 'lib/shadowget'

module LogBook

  include Common
  include Messages

  # Retrieve log entries from Geocache Logbook page
  # idea by daniel.k.ache, January 2017
  # converted from JS jQuery to HTTP GET request

  @@logbook_url  = 'https://www.geocaching.com/seek/cache_logbook.aspx'
  @@getjson_url  = 'https://www.geocaching.com/seek/geocache.logbook'
  @@getjson_base = 'https://www.geocaching.com'

  def json2comments(jsonstring)
    # comments are array of hashes
    commentarray = Array.new
    # required for eval()!
    null = ""
    # "Images" contains a sub-array, empty it so it doesn't get split
    jsonstring.gsub(/\"[^\"]*\":/){ |m| "#{m.split(/:/)[0]} => " } #.gsub(/,\"Images\" => \[[^\]]*\]/, "")
              .gsub(/ => \[[^\]]*\]/, " => []")
              .split(/},{/)
              .each { |jsonentry|
      begin
        jsonhash = eval("{" + jsonentry + "}")
        commenthash = { "type"    => jsonhash["LogType"],
                                     # "Visited" is in user-defined format
                        "date"    => parseDate(jsonhash["Visited"]) || Time.at($ZEROTIME),
                        "log_id"  => jsonhash["LogID"],
                                     # properly handle "&" -> "&amp;"
                        "user"    => CGI.escapeHTML(jsonhash["UserName"]),
                        "user_id" => jsonhash["AccountID"],
                        "text"    => jsonhash["LogText"]}
        commentarray.push(commenthash)
      rescue SyntaxError => e
        debug2 "dropped json entry \"#{jsonentry}\"because of #{e}"
#      rescue => e
#        debug2 "dropped json entry \"#{jsonentry}\"because of #{e}"
      end
    }
    return commentarray
  end

  def getLogBook(guid, logCount=10)
    debug2 "getLogBook(#{guid.inspect}, #{logCount})"
    comments = []
    return [comments, Time.at($ZEROTIME)] if guid.nil?
    return [comments, Time.now] if logCount <= 0

    # - try to read from json file (with fake URL)
    # - if that fails, we need a new token and a new json request
    # - use the data read from cache file

    # try to read from cached file
    url = @@getjson_url # nothing else
    json = ShadowFetch.new(url)
    # since this is a fake attempt, no headers are required
    # no need to present any cookies
    json.useCookie = false
    # do not check for valid HTML
    json.closingHTML = false
    # stored logbook
    json.localFile = "cache_logbook.json?guid=#{guid}"
    data = json.fetch
    timestamp = json.fileTimestamp
    src = json.src
    # if we got a remote file, things went wrong
    if src =~ /^r/
      # no need to invalidate because the "file" was shorter than 1 kB and not stored!
      # get user token for logbook ajax access
      aspx = ShadowFetch.new(@@logbook_url + "?guid=" + guid)
      aspx.localExpiry = -1 # do not store userToken
      data = aspx.fetch
      @@userToken = ""
      data.each_line do |line|
        case line
        when /userToken\s*=\s*\'(.*?)\';/
          debug2 "userToken = #{$1}"
          @@userToken = $1
        when /getJSON\(\"(.*?)\",/
          # use URL from the getJSON request to be safe
          getjsonUrl = $1
          debug2 "getJSON URL \"#{getjsonUrl}\""
          @@getjson_url = @@getjson_base + getjsonUrl
        end
      end
      debug "userToken is #{@@userToken.length} characters long."
      # we cannot get a userToken, it seems - return gracefully
      return [comments, Time.now] if @@userToken.empty?

      # now retry the JSON part
      # $.getJSON("/seek/geocache.logbook", { tkn: userToken, idx: 1, num: 10, sp: false, sf: false, decrypt: false }
      # it is possible to request more than 10 logs here (in one go), adjust logCount option accordingly
      url = @@getjson_url + "?tkn=#{@@userToken}&idx=1&num=#{logCount}&sp=false&sf=false&decrypt=false"
      debug2 "getJSON URL #{url.inspect}"
      json = ShadowFetch.new(url)
      json.httpHeader = ["Accept", "application/json, text/javascript, */*; q=0.01"]
      json.httpHeader = ["Accept-Encoding", "gzip, deflate"]
      json.httpHeader = ["Referer", @@logbook_url + "?guid=" + guid]
      # no need to present any cookies, token is enough?
      #json.useCookie = false
      # do not check for valid HTML
      json.closingHTML = false
      # store logbook for default time, using a crafted name
      #json.localFile = "cache_logbook.json?guid=#{guid}&lc=#{logCount}"
      json.localFile = "cache_logbook.json?guid=#{guid}"
      data = json.fetch
      timestamp = json.fileTimestamp
      src = json.src
    end
    debug3 "data returned #{data.inspect}"
    # convert JSON to comments format, strip outer brackets for better splitting
    # {"status":"success","data":[{"LogID": ... }],"pageInfo":{"idx":1,"size":10,"totalRows":69,"totalPages":4,"rows":10}}
    # without token:
    # {"status":"success","data":[],"pageInfo":{"idx":1,"size":5,"totalRows":0,"totalPages":1,"rows":0}}
    # with expired token:
    # {"status":"error","value":"1","msg":".*\.ExpiredQueryStringException: .*"}
    # with invalid token:
    # {"status":"error","value":"2","msg":".*\.InvalidQueryStringException: .*"}
    begin
      if data =~ /^{\"status\":\"success\",\"data\":\[\],/
      displayWarning "LogBook returns no logs."
      elsif data =~ /^{\"status\":\"success\",\"data\":\[{(.*)}\],\"pageInfo\":{.*\"rows\":(\d+)}}/
        jsonstring = $1.to_s
        logentries = $2.to_i
        if (jsonstring.length > 0) and (logentries > 0)
          comments = json2comments(jsonstring)
        else
          displayWarning "LogBook returns no logs."
        end
      elsif data =~ /^{\"status\":\"error\",\"value\":\"\d+\",.*\.(\w+Exception): Exception.*}/
        displayWarning "LogBook returns error #{$1}: ${2}."
      else
        displayWarning "Unknown error."
      end
    rescue => e
      displayWarning "Exception #{e} caught. Please report."
    end
    if comments.length == 0
      json.invalidate
      displayWarning "LogBook errors may indicate an issue with the userToken."
      displayWarning "Check file(s) cache_logbook.*_guid_#{guid}."
      displayWarning "This may become a serious error instead of a warning only."
    end
    debug "LogBook entries retrieved: #{comments.length} (#{src})"
    return [comments, timestamp]
  end

end
