# The version gets inserted during release/packaging

module GTVersion

  MY_VERSION = '3.33.3'

  def self.version
    if MY_VERSION !~ /^\d/
      return '(CURRENT)'
    else
      return MY_VERSION
    end
  end

end
