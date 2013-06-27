# collect template definitions

require 'common'
require 'messages'

class Templates

  include Common
  include Messages

  $Format = Hash.new

  def initialize
    # default template directory
    systempdir = File.join(File.dirname(__FILE__.gsub(/\\/, '/')), '..', 'templates')
    owntempdir = File.join(findConfigDir, 'templates')
    [systempdir, owntempdir].each{ |dir|
      begin
        if not (File.directory?(dir) and FileTest.readable?(dir))
          #displayWarning "#{dir} - not a readable directory, skipping"
          next
        end
        # now read all templates from there
        displayMessage "Populating templates from #{dir}"
        tempstring = Dir.entries(dir).sort.each{ |fn|
          if fn =~ /^.*\.tm$/
            file = File.join(dir, fn)
            if File.file?(file)
              begin
                s = File.new(file, 'r').read
                begin
                  # ready to catch syntax errors
                  newentry = eval(s)
                  # add/replace in hash
                  $Format.merge!(newentry)
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
    displayInfo "#{$Format.keys.length} templates total"
  end
end
