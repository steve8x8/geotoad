# The version gets inserted during release/packaging

module GTVersion

  MY_VERSION = '3.26.1'

  def self.version
    if MY_VERSION !~ /^\d/
      return '(CURRENT)'
    else
      return MY_VERSION
    end
  end

end
