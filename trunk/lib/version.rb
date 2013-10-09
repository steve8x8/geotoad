# $Id: version.rb 1475 2013-10-09 08:39:26Z Steve8x8@googlemail.com $

# The version gets inserted by makedist.sh

module GTVersion

  MY_VERSION = '%VERSION%'

  def self.version
    if MY_VERSION !~ /^\d/
      return '(CURRENT)'
    else
      return MY_VERSION
    end
  end

end
