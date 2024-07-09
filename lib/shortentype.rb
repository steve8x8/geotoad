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
      when /Lost and Found Celebration/		# obsolete
        stype = 'gchqceleb'
      when /Geocaching HQ Celebration/
        stype = 'gchqceleb'
      when /Lost and Found Event/		# obsolete
        stype = 'communceleb'
      when /Community Celebration Event/
        stype = 'communceleb'
      when /Groundspeak HQ/			# obsolete
        stype = 'gchq'
      when /Geocaching HQ/
        stype = 'gchq'
      when /Project APE Cache/
        stype = 'ape'
      when /Locationless/
        stype = 'locationless'
      when /Block Party/
        stype = 'block'
      when /Exhibit/
        stype = 'gps'
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
