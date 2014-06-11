# $Id$

# collect template definitions

require 'common'
require 'messages'
require 'realpath'

class Templates

  include Common
  include Messages

  $FORMATS = Hash.new

  def initialize
    # default template directory
    # this doesn't work for Windows combined exe (as this script isn't in ./lib/):
    #systempdir = File.join(File.dirname(File.realpath(__FILE__)), '..', 'templates')
    systempdir = findTemplateDir()
    owntempdir = File.join(findConfigDir(), 'templates')
    [systempdir, owntempdir].each{ |dir|
      begin
        if ! (File.directory?(dir) && FileTest.readable?(dir))
          #displayWarning "#{dir} - not a readable directory, skipping"
          next
        end
        # now read all templates from there
        displayMessage "Populating templates from #{dir}"
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
                  $FORMATS.merge!(newentry)
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
    displayInfo "#{$FORMATS.keys.length} templates total"
  end

end
