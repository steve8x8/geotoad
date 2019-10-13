# -*- encoding : utf-8 -*-

module ShortenType

  def shortenType(full_type)
      ftype = full_type.dup
      stype = ftype.split(' ')[0].downcase.gsub(/\-/, '')
      debug2 "Shorten full type #{ftype} -> type #{stype}"
      # special cases
      case ftype
      when /Cache In Trash Out/
        stype = 'cito'
      when /Lost and Found Celebration/
        stype = 'lfceleb'
      when /Lost and Found Event/
        stype = 'lost+found'
      when /Project APE Cache/
        stype = 'ape'
      when /Locationless/
        stype = 'reverse'
      when /Block Party/
        stype = 'block'
      when /Exhibit/
        stype = 'exhibit'
      # new June 2019:
      when /Geocaching HQ Celebration/
        stype = 'hqceleb'
      when /Community Celebration Event/
        stype = 'commceleb'
      # do these still exist?
      when /Groundspeak HQ/
        stype = 'gshq'
      when /Geocaching HQ/
        stype = 'gshq'
      # planned transition
      when /Mystery/
        ftype = 'Unknown Cache'
        stype = 'unknown'
      # 2014-08-26 - obsolete?
      when /Traditional/
        ftype = 'Traditional Cache'
        stype = 'traditional'
      when /Earth/
        ftype = 'Earthcache'
        stype = 'earthcache'
      end
      debug2 "Shortened full type #{ftype} -> type #{stype}"
      return [stype, ftype]
  end

end
