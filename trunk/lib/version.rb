# The version gets inserted by makedist.sh
module GTVersion

  MY_VERSION = '%VERSION%'

  def self.version
    if MY_VERSION !~ /^\d/
      return '3.13-CURRENT'
    else
      return MY_VERSION
    end
  end
end
