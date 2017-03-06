# collect template definitions

require 'fileutils'
require 'pathname'
require 'lib/common'
require 'lib/messages'

class Templates

  include Common
  include Messages

  $allFormats = Hash.new

  def initialize
    # default template directory
    systempdir = findTemplateDir()
    owntempdir = File.join(findConfigDir(), 'templates')
    [systempdir, owntempdir].each{ |dir|
      begin
        next if not (File.directory?(dir) && FileTest.readable?(dir))
        # now read all templates from there
        displayMessage "Templates: #{dir}"
        Dir.entries(dir).sort.each{ |fn|
          if fn =~ /^.*\.tm$/
            file = File.join(dir, fn)
            if File.file?(file)
              begin
                s = File.new(file, 'r').read
                begin
                  # ready to catch syntax errors
                  newentry = eval(s)
                  # add/replace in hash
                  $allFormats.merge!(newentry)
                rescue SyntaxError => e
                  displayWarning "#{file} - syntax error, skipping:"
                  displayInfo    "  #{e}"
                end
              rescue => e
                displayWarning "#{file} - I/O error, skipping"
              end
            end
          end
        }
      rescue => e
        displayWarning "#{dir} causing problems: #{e}"
      end
    }
    displayInfo "#{$allFormats.keys.length.to_s.rjust(6)} templates total"
  end

end
