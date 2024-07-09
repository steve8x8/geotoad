# -*- encoding : utf-8 -*-

require 'fileutils'
require 'pathname'
require 'time'
require 'cgi'
require 'yaml'

module Mapping

# mapping.yaml interface routines

  # mapping WID to GUID via dictionary file
  def loadMapping
    mappingFile  = File.join(findConfigDir, 'mapping.yaml')
    displayMessage "Dictionary: #{mappingFile}"
    mapping = false
    if File.readable?(mappingFile)
      mapping = YAML::load(File.open(mappingFile))
    end
    if not mapping or (mapping.class != Hash)
      displayInfo "No valid dictionary found, initializing"
      mapping = Hash.new
      begin
        File.open(mappingFile, 'w'){ |f|
          f.puts "---"
        }
      rescue => error
        displayWarning "Could not reset dictionary:\n\t#{error}"
      end
    end
    displayInfo "#{mapping.length.to_s.rjust(6)} WID->GUID mappings total"
    return mapping
  end

  def getMapping(wid)
    return $mapping[wid]
  end

  def appendMapping(wid, guid, src="")
    # this is a simple YAML file that can just be appended to
    return if $mapping[wid]
    $mapping[wid] = guid
    mappingFile  = File.join(findConfigDir, 'mapping.yaml')
    debug "Mapping#{src} #{wid} -> #{guid}"
    begin
      File.open(mappingFile, 'a'){ |f|
        f.puts "#{wid}: #{guid}"
      }
    rescue => error
      displayWarning "Could not append mapping for #{wid}:\n\t#{error}"
    end
  end

  def getRemoteMapping(wid)
    # get guid from cache_details page
    guid = getRemoteMapping1(wid)
    return [guid, '1'] if guid
    # get guid from log entry page
    guid = getRemoteMapping2(wid)
    return [guid, '2'] if guid
#    # get guid from gallery RSS
#    guid = getRemoteMapping3(wid)
#    return [guid, '3'] if guid
    # get guid from somewhere else
    guid = getRemoteMapping4(wid)
    return [guid, '4'] if guid
    #displayWarning "Could not map #{wid} to GUID"
    return [nil, '0']
  end

  def getRemoteMapping1(wid)
    debug "Get GUID from cache_details for #{wid}"
    # extract mapping from cache_details page
    @pageURL = 'https://www.geocaching.com/seek/cache_details.aspx?wp=' + wid
    # 20231210+: this redirects to https://www.geocaching.com/geocache/${wid}_*
    # but provides no GUID if cache is PMO
    page = ShadowFetch.new(@pageURL)
    # do not store response in file cache
    page.localExpiry = -1
    page.filePattern = 'meta name="page_name" content='
    data = page.fetch
    if data =~ /cdpf\.aspx\?guid=([0-9a-f-]{36})/m
      guid = $1
      debug2 "Found GUID: #{guid}"
      return guid
    end
    debug "Could not map(1) #{wid} to GUID"
    return nil
  end

  def getRemoteMapping2(wid)
    # originally suggested by skywalker90 (2012)
    debug "Get GUID from log submission page for #{wid}"
    # log submission page contains guid of cache [2016-04-30]
    # 2024: https://www.geocaching.com/seek/geocache_logs.aspx?code=${wid},
    # also no GUID found
    logid = cacheID(wid)
    @pageURL = 'https://www.geocaching.com/seek/log.aspx?ID=' + logid.to_s + '&lcn=1'
    # 2023-12-10+: this maps to https://www.geocaching.com/live/geocache/${wid}/log
    page = ShadowFetch.new(@pageURL)
    # do not store response in file cache
    page.localExpiry = -1
    data = page.fetch
    if data =~ /The listing has been locked/m
      displayWarning "#{wid} logbook is locked, cannot map"
    end
    if data =~ /cache_details\.aspx\?guid=([0-9a-f-]{36})/m
      guid = $1
      debug2 "Found GUID: #{guid}"
      return guid
    end
    debug "Could not map(2) #{wid} to GUID"
    return nil
  end

  def getRemoteMapping3(wid)
    debug "Get GUID from gallery for #{wid}"
    # extract mapping from cache_details page
    # 2024: returns empty page, no GUID
    @pageURL = 'https://www.geocaching.com/datastore/rss_galleryimages.ashx?id=' + cacheID(wid).to_s
    # 2023-12-10+: returns RSS with ${wid} but no GUID
    page = ShadowFetch.new(@pageURL)
    # do not store response in file cache
    page.localExpiry = -1
    page.useCookie = false
    page.closingHTML = false
    data = page.fetch
    if data =~ /cache_details\.aspx\?guid=([0-9a-f-]{36})/m
      guid = $1
      debug2 "Found GUID: #{guid}"
      return guid
    end
    debug "Could not map(3) #{wid} to GUID"
    return nil
  end

  def getRemoteMapping4(wid)
    debug "Could not map(4) #{wid} to GUID"
    return nil
  end

end
