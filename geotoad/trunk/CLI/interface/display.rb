# This is where code specific to the user interface display gets put.
#
# $HeadURL$
# $Id$

module Display
    def debugMode=(deb)
        $debugMode = deb
    end

    def debug(text)
        if $debugMode == 1
            puts "<d> #{text}"
        end
    end

    # Text that's just fluff that can be ignored.
    def displayInfo(text)
        puts "[-] #{text}"
    end

    # often worth displaying
    def displayTitleMessage(text)
        puts "[=] #{text}"
    end

    # often worth displaying
    def displayMessage(text)
        puts "[o] #{text}"
    end

    # mindless warnings
    def displayWarning(text)
        puts " * Warning: #{text}"
    end

    # fatal errors
    def displayError(text)
        puts "=!= ERROR: #{text}"
    end
end
