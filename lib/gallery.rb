require 'lib/common'
require 'lib/messages'
require 'lib/shadowget'

module Gallery

  include Common
  include Messages

  # Retrieve image links from gallery RSS
  # ideas by daniel.k.ache, February-March 2017

  @@gallery_url  = 'https://www.geocaching.com/datastore/rss_galleryimages.ashx'

  def getImageLinks(guid, cacheimages=true, logimages=false)
    debug2 "getImageLinks(#{guid.inspect}, #{cacheimages.inspect}, #{logimages.inspect})"
    return '' if guid.nil?
    return '' if (not cacheimages and not logimages)
    # fetch gallery RSS
    gallery = ShadowFetch.new(@@gallery_url + "?guid=" + guid)
    gallery.localExpiry = 31
    gallery.localExpiry = 14 if logimages
    gallery.useCookie = false
    gallery.closingHTML = false
    data = gallery.fetch
    debug3 "data returned #{data.inspect}"
    return '' if (data.to_s.length < 512)
    # extract image links, deselect cache log images
    # <item>
    #   <title>Foto 2, 3 &amp; 4</title>
    #   <link>https://img.geocaching.com/cache/log/e1916107-62d8-40fb-bc9a-00874c710640.jpg</link>
    #   <description />
    #   <media:thumbnail url="https://img.geocaching.com/cache/log/display/e1916107-62d8-40fb-bc9a-00874c710640.jpg" />
    #   <media:content url="https://img.geocaching.com/cache/log/e1916107-62d8-40fb-bc9a-00874c710640.jpg" type="image/jpeg" />
    # </item>
    # Caveat: This may break if for some reason CDATA is used. I haven't seen such a case yet.
    images_c = []
    images_l = []
    data.split(/<item>/).each{ |item|
      link = nil
      text = ''
      if (item =~ /<title>(.*?)<\/title>\s*<link>(.*?)<\/link>/m)
        link = $2
        text = $1
      end
      if (item =~ /<description>(.*?)<\/description>/m)
        text << '|' + $1
      end
      # skip if there's no image
      next if not link
      # use image guid if no description
      text = link.split(/\//)[-1].split(/\./)[0] if text.empty?
      # add to cache or log images
      if (link =~ /\/cache\/log\//)
        images_l << [ link, text ]
      elsif (link =~ /\/cache\//)
        images_c << [ link, text ]
      end
    } # item
    # create one or two lists of image links, newest first
    imagelinks = ''
    if not images_c.empty? and cacheimages
      imagelinks << "<p>Cache images:<ul>" +
                    images_c.map{ |img| "<li><a href=\"#{img[0]}\">&nbsp;#{img[1]}&nbsp;</a></li>" }.join("")
                    "</ul></p>"
    end
    if not images_l.empty? and logimages
      imagelinks << "<p>Log images:<ul>" +
                    images_l.map{ |img| "<li><a href=\"#{img[0]}\">&nbsp;#{img[1]}&nbsp;</a></li>" }.join("")
                    "</ul></p>"
    end
    return imagelinks
  end

end
