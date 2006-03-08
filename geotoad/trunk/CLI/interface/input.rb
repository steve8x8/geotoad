class Input
    include Common
    include Display

    def initialize
        # Originally, it  was @optHash. Rather than write a probably unneeded
        # restore and save for it so that it can keep preferences between runs,
        # I thought I would just make it class-wide instead of instance wide.


        @@optHash = Hash.new
        # some default values.
        @@optHash['queryType'] = 'zipcode'
    end

    def getopt
        opts = GetoptLong.new(
            [ "--aratingMax",                "-A",        GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--aratingMin",                "-a",        GetoptLong::OPTIONAL_ARGUMENT ],

            [ "--travelBug",                "-b",    GetoptLong::NO_ARGUMENT ],
            
            [ "--cacheExpiry"                  "-c",    GetoptLong::OPTIONAL_ARGUMENT ],

            
            [ "--difficultyMax",            "-D",        GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--difficultyMin",            "-d",        GetoptLong::OPTIONAL_ARGUMENT ],
            
            [ "--disableEasyName",          "-E",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--format",                    "-f",        GetoptLong::OPTIONAL_ARGUMENT ],

            [ "--foundDateExclude",                "-R",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--foundDateInclude",                "-r",    GetoptLong::OPTIONAL_ARGUMENT ],

            [ "--help",                     "-h",    GetoptLong::NO_ARGUMENT ],

            [ "--ownerInclude",                "-i",    GetoptLong::OPTIONAL_ARGUMENT ],            
            [ "--ownerExclude",                "-I",    GetoptLong::OPTIONAL_ARGUMENT ],

            [ "--placeDateInclude",                "-j",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--placeDateExclude",                "-J",    GetoptLong::OPTIONAL_ARGUMENT ],

            [ "--titleKeyword",               "-k",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--descKeyword",                "-K",    GetoptLong::OPTIONAL_ARGUMENT ],

            [ "--waypointLength",            "-l",    GetoptLong::OPTIONAL_ARGUMENT ],    
            [ "--notFound",                 "-n",    GetoptLong::NO_ARGUMENT ],
            [ "--output",                    "-o",        GetoptLong::OPTIONAL_ARGUMENT ],           

            [ "--password",                     "-p",          GetoptLong::REQUIRED_ARGUMENT ],         # * REQ

            [ "--queryType",                    "-q",        GetoptLong::OPTIONAL_ARGUMENT ],

            [ "--userExclude",                "-S",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--userInclude",                "-s",    GetoptLong::OPTIONAL_ARGUMENT ],

            [ "--terrainMax",                "-T",        GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--terrainMin",                "-t",        GetoptLong::OPTIONAL_ARGUMENT ],

            [ "--user",                     "-u",          GetoptLong::REQUIRED_ARGUMENT ],         # * REQ


            [ "--verbose",                    "-v",    GetoptLong::NO_ARGUMENT ],
            [ "--quitAfterFetch",           "-x",    GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--distanceMax",                "-y",        GetoptLong::OPTIONAL_ARGUMENT ],
            [ "--slowlink",                 "-z",    GetoptLong::NO_ARGUMENT ]
        ) || usage

        # put the stupid crap in a hash. Much nicer to deal with.
        begin
            @@optHash = Hash.new
            opts.each do |opt, arg|
                # queryType gets special treatment. We try and normalize what they mean.
                debug "opt = #{opt} arg=#{arg}"
                if (opt == '--queryType')
                    arg = guessQueryType(arg)
                    debug "queryType is now #{arg}"
                end

                @@optHash[opt.gsub(/-/,'')]=arg
            end
        rescue
            usage
            exit
        end


        @@optHash['queryArg'] = ARGV.shift

        # if there are still remaining arguments, error out. Usually missed quote marks.
        # We used to make assumptions about this, but it ended up being more confusing when
        # wrong.
        if ARGV[0]
            displayError "Extra arguments found on command-line: \"#{ARGV.join(" ")}\""
            displayError "Perhaps you forgot to put quote marks around any arguments that"
            displayError "contain spaces in them. Example: -q #{@formatType} \"#{@@optHash['queryArg']} #{ARGV.join(" ")}\""
            exit
        end

        return @@optHash
    end

    def interactive
        # pop up the menu
        showmenu

        # demonstrate a sample command line
        cmdline = "geotoad.rb"
        @@optHash.each_key { |option|
            if (option != 'queryArg') && @@optHash[option]
                if (@@optHash[option] == 'X')
                    cmdline = cmdline + " --#{option}"
                else
                    # it's just a number..
                    if (@@optHash[option] =~ /^[\w\.]+$/)
                        cmdline = cmdline + " --#{option}=#{@@optHash[option]}"
                    else
                        cmdline = cmdline + " --#{option}=\'#{@@optHash[option]}\'"
                    end
                end
            end

        }
        cmdline = cmdline + " \'" + @@optHash['queryArg'] + '\''
        displayMessage "To use this query in the future, type:"
        displayMessage cmdline
        puts
        sleep(4)
        #exit
        return @@optHash
    end

    def showmenu
        # if windows
        # else
        answer = nil


        while (answer !~ /^[sq]/i)
            if RUBY_PLATFORM =~ /win32/
                system("cls");
            else
                system("stty erase ^H >/dev/null 2>/dev/null")
                system("clear")
            end
            puts ""
            puts "  GeoToad #{$VERSION} TUI edition.  Type a number to modify the fields value."
            puts "=============================================================================="
            printf("(1)  search type         [%-10.10s] | (2) %-18.18s [%-13.13s]\n", @@optHash['queryType'], @@optHash['queryType'], (@@optHash['queryArg'] || 'REQUIRED'))
            printf("(3)  distance maximum    [%-3.3s]        |\n", (@@optHash['distanceMax'] || 10))
            puts   "                                      |"
            printf("(4)  difficulty min      [%-3.3s]        | (5)  terrain min       [%-3.3s]\n", (@@optHash['difficultyMin'] || 0.0), (@@optHash['terrainMin'] || 0.0))
            printf("(6)  difficulty max      [%-3.3s]        | (7)  terrain max       [%-3.3s]\n", (@@optHash['difficultyMax'] || 5.0), (@@optHash['terrainMax'] || 5.0))
            printf("(8)  title keyword       [%-10.10s] | (9)  descr. keyword    [%-13.13s]\n", @@optHash['titleKeyword'], @@optHash['descKeyword'])
            puts   "                                      |"
            printf("(10) cache not found by  [%-10.10s] | (11) cache owner isn't [%-13.13s]\n", @@optHash['userExclude'], @@optHash['ownerExclude'])
            printf("(12) cache found by      [%-10.10s] | (13) cache owner is    [%-13.13s]\n", @@optHash['userInclude'], @@optHash['ownerInclude'])
            puts   "                                      |"
            printf("(14) virgin caches only  [%1.1s]          | (15) travel bug caches only [%1.1s]\n", @@optHash['notFound'], @@optHash['travelBug'])
            printf("(16) cache newer than    [%-3.3s] days   | (17) cache found within     [%-3.3s] days\n", @@optHash['placeDateInclude'], @@optHash['foundDateInclude'])
            printf("(18) cache older than    [%-3.3s] days   | (19) cache not found within [%-3.3s] days\n", @@optHash['placeDateExclude'], @@optHash['foundDateExclude'])
            printf("(20) EasyName WP length  [%-3.3s]        | (21) slowlink mode          [%1.1s]\n", @@optHash['waypointLength'] || '0', @@optHash['slowlink'])
            puts "- - - - - - - - - - - - - - - - - - - + - - - - - - - - - - - - - - - - - - -"
            printf("(22) output format       [%-10.10s] | (23) filename          [%-13.13s]\n", (@@optHash['format'] || 'gpx'), (@@optHash['output'] || 'automatic'))
            puts "=============================================================================="
            print "   Enter menu number, (s) to start, or (x) to exit --> "
            answer = $stdin.gets.chop
            puts ""

            case answer
               when '1'
                   type = ask("What type of search would you like to perform? (zipcode, state, coordinate, keyword [title only])", nil)
                   @@optHash['queryType'] = guessQueryType(type).to_s

               when '2'
                   if (@@optHash['queryType'] == 'zipcode')
                       @@optHash['queryArg'] = ask('Enter a list of zipcodes (seperated by commas)', 'NO_DEFAULT').gsub(/, */, ':')
                   end

                   if (@@optHash['queryType'] == 'state')
                       @@optHash['queryArg'] = ask('Enter a list of states (seperated by commas)', 'NO_DEFAULT').gsub(/, */, ':')
                   end

                   if (@@optHash['queryType'] == 'wid')
                       @@optHash['queryArg'] = ask('Enter a list of waypoint id\'s (seperated by commas)', 'NO_DEFAULT').gsub(/, */, ':')
                   end

                   if (@@optHash['queryType'] == 'coord')
                       puts "You will be asked to enter in a list of coordinates in the following format:"
                       puts "N56 44.392 E015 52.780"
                       puts ""
                       puts "Press (q) when done."

                       coordset = 1
                       coord = nil
                       query = ''

                       while (coord != 'q')
                           print coordset.to_s + ": "
                           coord = $stdin.gets.chomp
                           if coord != 'q'
                               query = query + coord + ':'
                               coordset = coordset + 1
                           end
                       end

                       query.gsub!(/:$/, '')
                       @@optHash['queryArg'] = query
                   end

                   if (@@optHash['queryType'] == 'keyword')
                       puts "Please enter a list of keywords, pressing enter after each one."
                       puts "Press (q) when done."

                       keyset = 1
                       key = nil
                       query = ''

                       while (key != 'q')
                           print keyset.to_s + ": "
                           key = $stdin.gets.chomp
                           if key != 'q'
                               query = query + key + ':'
                               keyset = keyset + 1
                           end
                       end

                       query.gsub!(/:$/, '')
                       @@optHash['queryArg'] = query
                   end


               when '3'
                   @@optHash['distanceMax'] = ask("What is the maximum distance from your #{@@optHash['queryType']} that you would like to include geocaches from?", 10)

               when '4'
                   @@optHash['difficultyMin'] = ask('What is the minimum difficulty you would like? (0.0)', nil)

               when '6'
                   @@optHash['difficultyMax'] = ask('What is the maximum difficulty you would like? (0.0)', nil)

               when '5'
                   @@optHash['terrainMin'] = ask('What is the minimum terrain you would like? (0.0)', nil)

               when '7'
                   @@optHash['terrainMax'] = ask('What is the maximum terrain you would like? (0.0)', nil)

               when '8'
                   @@optHash['titleKeyword'] = ask('Only include geocaches with these keywords in their title (seperate by |)?', nil)

               when '9'
                   @@optHash['descKeyword'] = ask('Only include geocaches with these keywords in their description (seperate by |)', nil)

               when '10'
                   @@optHash['userExclude'] = ask('Filter out geocaches found by these people (seperate by commas)', '').gsub(/, */, ':')

               when '12'
                   @@optHash['userInclude'] = ask('Only include geocaches that have been found by these people (separate by commas)', '').gsub(/, */, ':')

               when '11'
                   @@optHash['ownerExclude'] = ask('Filter out geocaches owned by these people (seperate by commas)', '').gsub(/, */, ':')

               when '13'
                   @@optHash['ownerInclude'] = ask('Only include geocaches owned by these people (seperate by commas)', '').gsub(/, */, ':')

               when '14'
                   answer = ask('Would you like to only include virgin geocaches (geocaches that have never been found)?', nil)
                   if (answer =~ /y/)
                       @@optHash['notFound'] = 'X'
                   else
                       @@optHash['notFound'] = nil
                   end

               when '15'
                   answer = ask('Would you like to only include geocaches with travelbugs in them?', nil)
                   if (answer =~ /y/)
                       @@optHash['travelBug'] = 'X'
                   else
                       @@optHash['travelBug'] = nil
                   end

               when '16'
                   @@optHash['placeDateInclude'] = ask('How many days old is the oldest a geocache can be for your list?', nil)

               when '18'
                   @@optHash['placeDateExclude'] = ask('How many days old is the youngest a geocache can be for your list?', nil)

               when '17'
                   @@optHash['foundDateInclude'] = ask('How many days ago is the maximum a geocache can be found in for your list?', nil)

               when '19'
                   @@optHash['foundDateExclude'] = ask('How many days ago is the minimum a geocache can be found in for your list?', nil)

               when '20'
                   @@optHash['waypointLength'] = ask('How long can your EasyName waypoint id\'s be? (8 for Magellan, 16 for Garmin, 0 to use standard waypoint id\'s)?', nil)


               when '21'
                   answer = ask('Would you like to enable slowlink mode (faster for dialups, slower for broadband)?', nil)
                   if (answer =~ /y/)
                       @@optHash['slowlink'] = 'X'
                   else
                       @@optHash['slowlink'] = nil
                   end



               when '22'
                   puts "List of Output Formats: "
                   outputDetails = Output.new
                   i=0
                   print ""
                   $validFormats.each { |type|
                       desc = outputDetails.formatDesc(type)
                       req = outputDetails.formatRequirement(type)
                       if (req)
                           req = "[" + req + " required]"
                       end
                       printf("%-12.12s: %-45.45s %s\n", type, desc, req);
                   }

                   puts ""
                   @@optHash['format'] = ask('What format would you like your output in?', 'gpx')

                when '23'
                    @@optHash['output'] = ask('What filename would you like to output to? (press enter for automatic)', nil)

                when 's', 'q'
                    if (! @@optHash['queryArg']) || (@@optHash['queryArg'].size < 1)
                        puts "You cannot start till you specify what #{@@optHash['queryType']} data you would like to search with"
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

                # chomp any trailing slashes.
                answer.gsub!(/ +$/, '')
            end
            return answer
        else
            puts "Assuming the default answer \'#{default}\'"
            return default
        end
    end

    def guessQueryType(type)

        case type
            when /zip/
                return 'zipcode'
            when /coo/
                return 'coord'
            when /stat/
                return 'state'
            when /wid/
                return 'wid'
            when /waypoint/
                return 'wid'

            when /key/
                return 'keyword'
        end
    end

end
