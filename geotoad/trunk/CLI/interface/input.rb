class Input
    include Common
    include Display

    def initialize
        @optHash = Hash.new
        # some default values.
        @optHash['queryType'] = 'zipcode'
    end

    def getopt
        opts = GetoptLong.new(
            [ "--format",                    "-f",        GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--output",                    "-o",        GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--query",                    "-q",        GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--distanceMax",                "-y",        GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--difficultyMin",            "-d",        GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--difficultyMax",            "-D",        GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--terrainMin",                "-t",        GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--terrainMax",                "-T",        GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--keyword",                  "-k",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--cacheExpiry"               "-c",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--quitAfterFetch",           "-x",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--notFound",                 "-n",    GetoptLong::NO_ARGUMENT ],
            [ "--travelBug",                "-b",    GetoptLong::NO_ARGUMENT ],
            [ "--verbose",                    "-v",    GetoptLong::NO_ARGUMENT ],
            [ "--userInclude",                "-u",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--userExclude",                "-U",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--ownerInclude",                "-c",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--ownerExclude",                "-C",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--placeDateInclude",                "-p",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--placeDateExclude",                "-P",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--foundDateInclude",                "-r",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--foundDateExclude",                "-R",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--waypointLength",            "-l",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--libraryInclude",            "-L",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--help",                     "-h",    GetoptLong::NO_ARGUMENT ],
            [ "--slowlink",                 "-z",    GetoptLong::NO_ARGUMENT ]
        )

        # put the stupid crap in a hash. Much nicer to deal with.
        begin
            @optHash = Hash.new
            opts.each do |opt, arg|
                @optHash[opt.gsub('-','')]=arg
            end
        rescue
            usage
            exit
        end


        @optHash['queryArg'] = ARGV.shift

        # if there are still remaining arguments, error out. Usually missed quote marks.
        # We used to make assumptions about this, but it ended up being more confusing when
        # wrong.
        if ARGV[0]
            displayError "Extra arguments found on command-line: \"#{ARGV.join(" ")}\""
            displayError "Perhaps you forgot to put quote marks around any arguments that"
            displayError "contain spaces in them. Example: -q #{@formatType} \"#{optHash['queryArg']} #{ARGV.join(" ")}\""
            exit
        end

        return @optHash
    end

    def interactive


        # pop up the menu
        showmenu

        # demonstrate a sample command line
        cmdline = "geotoad.rb"
        @optHash.each_key { |option|
            if (option != 'queryArg') && @optHash[option]
                cmdline = cmdline + " --#{option}=\'#{@optHash[option]}\'"
            end

        }
        cmdline = cmdline + " " + @optHash['queryArg']
        displayMessage "To use this query in the future, type:"
        displayMessage cmdline
        puts
        sleep(4)
        #exit
        return @optHash
    end

    def showmenu
        # if windows
        # else
        answer = nil


        while (answer !~ /q/i)
            system("stty erase ^H >/dev/null 2>/dev/null")
            system("clear")
            # end
            puts ""
            puts "  GeoToad #{$VERSION} TUI editon.  Type a number to modify the fields value."
            puts "============================================================================="
            puts "(1)  search type         [#{@optHash['queryType']}]  | (2)  #{@optHash['queryType']}            [#{@optHash['queryArg'] || 'REQUIRED'}]"
            puts "(3)  distance maximum    [#{@optHash['distanceMax'] || 10}]       |"
            puts "                                    |"
            puts "(4)  difficulty min        [#{@optHash['difficultyMin'] || 0.0}]    | (5)  terrain min       [#{@optHash['terrainMin'] || 0.0}]"
            puts "(6)  dificulty max         [#{@optHash['difficultyMax'] || 5.0}]    | (7)  terrain max       [#{@optHash['terrainMax'] || 5.0}]"
            puts "(8)  title keyword         [#{@optHash['titleKeyword']}]        | (9) description keyword [#{@optHash['descKeyword']}]"

            puts "                                    |"
            puts "(10) cache wasn't found by [#{@optHash['userExclude']}]       | (11)  cache owner isn't [#{@optHash['ownerExclude']}] "
            puts "(12) cache was found by    [#{@optHash['userInclude']}]       | (13) cache owner is    [#{@optHash['ownerInclude']}]"
            puts "                                    |"
            puts "(14) virgin caches only    [#{@optHash['notFound'] || 'n'}]      | (15) travel bug caches only  [#{@optHash['travelBug'] || 'n'}] "
            puts "(16) cache newer than      [#{@optHash['placeDateInclude']}] days  | (17) cache found within      [#{@optHash['foundDateInclude']}] days"
            puts "(18) cache older than      [#{@optHash['placeDateExclude']}] days  | (19) cache not found within  [#{@optHash['fouundDateExclude']}] days"
            puts "(20) waypoint length       [#{@optHash['waypointLength'] || 16}]     | (21) slowlink mode           [#{@optHash['slowlink'] || 'n'}]"
            puts "                                    |"
            puts "- - - - - - - - - - - - - - - - - - + - - - - - - - - - - - - - - - - - - - -"
            puts "(22) output format     [#{@optHash['format'] || 'gpx'}]        | (23) filename          [#{@optHash['output'] || 'automatic'}]    "
            puts "============================================================================="
            print "   Enter item number, (q) when done, or (x) to abort --> "
            answer = $stdin.gets.chop
            puts ""

            case answer
               when '1'
                   @optHash['queryType'] = ask("What type of search would you like to perform? (zip, state, coordinate)", nil)

               when '2'
                   if (@optHash['queryType'] =~ /^zip/)
                       @optHash['queryArg'] = ask('Enter a list of zipcodes (seperated by commas)', 'NO_DEFAULT').gsub(/, */, ':')
                   end

                   if (@optHash['queryType'] =~ /^state/)
                       @optHash['queryArg'] = ask('Enter a list of states (seperated by commas)', 'NO_DEFAULT').gsub(/, */, ':')
                   end

                   if (@optHash['queryType'] =~ /^coord/)
                       puts "You will be asked to enter in a list of coordinates in the following format:"
                       puts "N395.2359 W2359.23591"
                       puts ""
                       puts "Press (q) when done."

                       @optHash['queryArg'] = nil
                       coordset = 1
                       while (coord != 'q')
                           print coordest + ": "
                           @optHash['queryArg'] = @optHash['queryArg']
                       end
                   end

               when '3'
                   @optHash['distanceMax'] = ask("What is the maximum distance from your #{@optHash['queryType']} that you would like to include geocaches from?", 10)

               when '4'
                   @optHash['difficultyMin'] = ask('What is the minimum difficulty you would like? (0.0)', nil)

               when '6'
                   @optHash['difficultyMax'] = ask('What is the maximum difficulty you would like? (0.0)', nil)

               when '5'
                   @optHash['terrainMin'] = ask('What is the minimum terrain you would like? (0.0)', nil)

               when '7'
                   @optHash['terrainMax'] = ask('What is the maximum terrain you would like? (0.0)', nil)

               when '8'
                   @optHash['titleKeyword'] = ask('Only include geocaches with these keywords in their title (seperate by |)?', nil)

               when '9'
                   @optHash['descKeyword'] = ask('Only include geocaches with these keywords in their description (seperate by |)', nil)

               when '10'
                   @optHash['userExclude'] = ask('Filter out geocaches found by these people (seperate by commas)', '').gsub(/, */, ':')

               when '12'
                   @optHash['userInclude'] = ask('Only include geocaches that have been found by these people (separate by commas)', '').gsub(/, */, ':')

               when '11'
                   @optHash['ownerExclude'] = ask('Filter out geocaches owned by these people (seperate by commas)', '').gsub(/, */, ':')

               when '13'
                   @optHash['ownerInclude'] = ask('Only include geocaches owned by these people (seperate by commas)', '').gsub(/, */, ':')

               when '14'
                   answer = ask('Would you like to only include virgin geocaches (geocaches that have never been found)?', nil)
                   if (answer =~ /y/)
                       @optHash['notFound'] = 'y'
                   end

               when '15'
                   answer = ask('Would you like to only include geocaches with travelbugs in them?', nil)
                   if (answer =~ /y/)
                       @optHash['travelBug'] = 'y'
                   end

               when '16'
                   @optHash['placeDateInclude'] = ask('How many days old is the oldest a geocache can be for your list?', nil)

               when '18'
                   @optHash['placeDateExclude'] = ask('How many days old is the youngest a geocache can be for your list?', nil)

               when '17'
                   @optHash['foundDateInclude'] = ask('How many days ago is the maximum a geocache can be found in for your list?', nil)

               when '19'
                   @optHash['foundDateExclude'] = ask('How many days ago is the minimum a geocache can be found in for your list?', nil)

               when '20'
                   @optHash['waypointLength'] = ask('How long can your waypoint id\'s be? (8 for Magellan, 16 for Garmin, 0 to use standard waypoint id\'s)?', nil)

               when '21'
                   @optHash['slowlink'] = ask('Would you like to enable slowlink mode (faster for dialups, slower for broadband)?', nil)

               when '22'
                   puts "List of Output Formats: "
                   outputDetails = Output.new
                   i=0
                   print ""
                   @@validFormats.each { |type|
                       desc = outputDetails.formatDesc(type)
                       if (i>5)
                           puts ""
                           print ""
                           i=0
                       end
                       i=i+1


                       if (desc =~ /gpsbabel/)
                           type = type + "+"
                       elsif (desc =~ /cmconvert/)
                           type = type + "="
                       end

                       printf("  %-10.10s", type);

                   }
                   puts ""
                   puts "    + requires gpsbabel in PATH           = requires cmconvert in PATH"

                   @optHash['format'] = ask('What format would you like your output in?', 'gpx')

                when '23'
                    @optHash['output'] = ask('What filename would you like to output to? (press enter for automatic)', nil)

                when 'q'
                    if (! @optHash['queryArg']) || (@optHash['queryArg'].size < 1)
                        puts "You cannot quit till you specify a #{@optHash['queryType']} query to run"
                        puts "(press enter to continue)"
                        answer=$stdin.gets
                    end

                when 'x'
                    puts "Ya\'ll come back now, ya hear?"
                    exit


            end

        end

    end



    def ask(string, default)
        print string + ": "
        answer = $stdin.gets.chomp
        if answer.length > 0
            return answer
        elsif default == 'NO_DEFAULT'
            puts ""
            puts "You must supply an answer, there is no default. Please try again:"
            while (answer.length < 1)
                print string + ": "
                answer = $stdin.gets.chomp
            end
            return answer
        else
            puts "Assuming the default answer \'#{default}\'"
            return default
        end
    end

end
