# $Id$

class Input
    include Common
    include Display
    
    def initialize
        # Originally, it  was @optHash. Rather than write a probably unneeded
        # restore and save for it so that it can keep preferences between runs,
        # I thought I would just make it class-wide instead of instance wide.
        
        resetOptions
        @configDir = findConfigDir
        @configFile = @configDir + '/' + 'config.yaml'
    end
    
    def resetOptions
        @@optHash = Hash.new
        # some default values.
        @@optHash['queryType'] = 'zipcode'    
    end

    def saveConfig
        if (! File.exists?(@configDir))
            File.makedirs(@configDir)
        end

        f=File.open(@configFile, 'w')
        f.puts @@optHash.to_yaml
        #@@optHash.each_key { |option|
        #    f.puts option + ": " + @@optHash[option].to_s
        #}
        f.close
        debug "Saved configuration" 
    end
    
    def loadConfig
        if File.exists?(@configFile)
            displayMessage "Loading configuration from #{@configFile}"
            @@optHash = YAML::load( File.open(@configFile) )
        end
    end
    
    def getopt
        opts = GetoptLong.new(
                          
        [ "--travelBug",                "-b",    GetoptLong::NO_ARGUMENT ],
        
        [ "--difficultyMax",            "-D",        GetoptLong::OPTIONAL_ARGUMENT ],
        [ "--difficultyMin",            "-d",        GetoptLong::OPTIONAL_ARGUMENT ],
        
        [ "--funFactorMax",                "-F",        GetoptLong::OPTIONAL_ARGUMENT ],
        [ "--funFactorMin",                "-f",        GetoptLong::OPTIONAL_ARGUMENT ],
        
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
        [ "--format",                    "-x",        GetoptLong::OPTIONAL_ARGUMENT ],
        
        [ "--distanceMax",                "-y",        GetoptLong::OPTIONAL_ARGUMENT ]
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
        loadConfig
        showMenu
        saveConfig
        if (@@optHash['outDir'])
            @@optHash['output']=@@optHash['outDir'] + "/"
        else
            @@optHash['output']=findOutputDir + "/"
        end
        
        if (@@optHash['outFile'])
            if @@optHash['output']
                @@optHash['output']=@@optHash['output'] + @@optHash['outFile']
            else
                @@optHash['output']=@@optHash['outFile']
            end
        end
        
            
        # demonstrate a sample command line
        cmdline = "geotoad.rb"
        @@optHash.each_key { |option|
            if (option != 'queryArg') && (option != 'outDir') && (option != 'outFile') && @@optHash[option]
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
        cmdline = cmdline + " \'" + @@optHash['queryArg'].to_s + '\''
        displayMessage "To use this query in the future, type:"
        displayMessage cmdline
        puts
        sleep(4)
        #exit
        return @@optHash
    end
    
    def showMenu
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
            
            puts "=============================================================================="
            printf(":::           %46.46s               :::\n", "// GeoToad #$VERSION Text User Interface //")
            puts "=============================================================================="
            
            printf("(1)  GC.com login     [%-13.13s] | (2)  search type          [%-10.10s]\n", (@@optHash['user'] || 'REQUIRED'), @@optHash['queryType'])
            printf("(3)  %-16.16s [%-13.13s] | (4)  distance maximum            [%-3.3s]\n", @@optHash['queryType'], (@@optHash['queryArg'] || 'REQUIRED'), (@@optHash['distanceMax'] || 10))
            puts   "                                      |"
            printf("(5)  difficulty           [%-2.1f - %-1.1f] | (6)  terrain               [%-1.1f - %-1.1f]\n",
                    (@@optHash['difficultyMin'] || 0.0), (@@optHash['difficultyMax'] || 5.0), 
                    (@@optHash['terrainMin'] || 0.0), (@@optHash['terrainMax'] || 5.0))
            printf("(7)  fun factor           [%-1.1f - %-1.1f] |\n", (@@optHash['funFactorMin'] || 0.0), (@@optHash['funFactorMax'] || 5.0))
            printf("(8) virgin caches only            [%1.1s] | (9) travel bug caches only         [%1.1s]\n", @@optHash['notFound'], @@optHash['travelBug'])
            printf("(10) cache age (days)       [%3.3s-%-3.3s] | (11) last found (days)       [%3.3s-%-3.3s] \n", 
                    (@@optHash['placeDateExclude'] || 0), (@@optHash['placeDateInclude'] || 'any'), 
                    (@@optHash['foundDateExclude'] || 0), (@@optHash['foundDateInclude'] || 'any'))
            puts   "                                      |"
            printf("(12) title keyword       [%-10.10s] | (13) descr. keyword    [%-13.13s]\n", @@optHash['titleKeyword'], @@optHash['descKeyword'])
            printf("(14) cache not found by  [%-10.10s] | (15) cache owner isn't [%-13.13s]\n", @@optHash['userExclude'], @@optHash['ownerExclude'])
            printf("(16) cache found by      [%-10.10s] | (17) cache owner is    [%-13.13s]\n", @@optHash['userInclude'], @@optHash['ownerInclude'])
           
            printf("(18) EasyName WP length         [%3.3s] | \n", @@optHash['waypointLength'] || '0')
            puts "- - - - - - - - - - - - - - - - - - - + - - - - - - - - - - - - - - - - - - -"
            printf("(19) output format       [%-10.10s]   (20) filename   [%-20.20s]\n", (@@optHash['format'] || 'gpx'), (@@optHash['outFile'] || 'automatic'))
            printf("(21) output directory    [%-51.51s]\n", (@@optHash['outDir'] || findOutputDir))
            puts "=============================================================================="
            puts ""
            print "-- Enter menu number, (s) to start, (r) to reset, or (x) to exit --> "
            answer = $stdin.gets.chop
            puts ""
            
            case answer
            when '1'
                @@optHash['user'] = ask("What is your Geocaching.com username?", 'NO_DEFAULT')
                @@optHash['password'] = ask("What is your Geocaching.com password?", 'NO_DEFAULT')
                
            when '2'
                type = ask("What type of search would you like to perform? (zipcode, state, coordinate, keyword [title only])", nil)
                @@optHash['queryType'] = guessQueryType(type).to_s
            
            when '3'
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
                
                
            when '4'
                @@optHash['distanceMax'] = ask("What is the maximum distance from your #{@@optHash['queryType']} that you would like to include geocaches from?", 10)
                
            when '5'
                @@optHash['difficultyMin'] = ask('What is the minimum difficulty you would like? (0.0)', nil)
                @@optHash['difficultyMax'] = ask('What is the maximum difficulty you would like? (5.0)', nil)
                
            when '6'
                @@optHash['terrainMin'] = ask('What is the minimum terrain you would like? (0.0)', nil)
                @@optHash['terrainMax'] = ask('What is the maximum terrain you would like? (5.0)', nil)
                
            when '7'
                @@optHash['funFactorMin'] = ask('What is the minimum fun factor you would like? (0.0)', nil)
                @@optHash['funFactorMax'] = ask('What is the maximum fun factor you would like? (5.0)', nil)
                
            when '8'
                answer = ask('Would you like to only include virgin geocaches (geocaches that have never been found)?', nil)
                if (answer =~ /y/)
                    @@optHash['notFound'] = 'X'
                else
                    @@optHash['notFound'] = nil
                end
                
            when '9'
                answer = ask('Would you like to only include geocaches with travelbugs in them?', nil)
                if (answer =~ /y/)
                    @@optHash['travelBug'] = 'X'
                else
                    @@optHash['travelBug'] = nil
                end
                
                
            when '10'
                @@optHash['placeDateExclude'] = ask('How many days old is the youngest a geocache can be for your list? (0)', nil)
                @@optHash['placeDateInclude'] = ask('How many days old is the oldest a geocache can be for your list? (any)', nil)
                
            when '11'
                @@optHash['foundDateExclude'] = ask('How many days ago is the minimum a geocache can be found in for your list? (0)', nil)
                @@optHash['foundDateInclude'] = ask('How many days ago is the maximum a geocache can be found in for your list? (any)', nil)
                                
            when '12'
                @@optHash['titleKeyword'] = ask('Only include geocaches with these keywords in their title (seperate by |)?', nil)
                
            when '13'
                @@optHash['descKeyword'] = ask('Only include geocaches with these keywords in their description (seperate by |)', nil)
                
            when '14'
                @@optHash['userExclude'] = ask('Filter out geocaches found by these people (seperate by commas)', '').gsub(/, */, ':')
                
            when '16'
                @@optHash['userInclude'] = ask('Only include geocaches that have been found by these people (separate by commas)', '').gsub(/, */, ':')
                
            when '15'
                @@optHash['ownerExclude'] = ask('Filter out geocaches owned by these people (seperate by commas)', '').gsub(/, */, ':')
                
            when '17'
                @@optHash['ownerInclude'] = ask('Only include geocaches owned by these people (seperate by commas)', '').gsub(/, */, ':')
                
                
       
            when '18'
                @@optHash['waypointLength'] = ask('How long can your EasyName waypoint id\'s be? (8 for Magellan, 16 for Garmin, 0 to use standard waypoint id\'s)?', nil)
                
                
            when '19'
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
                
            when '20'
                @@optHash['outFile'] = ask('What filename would you like to output to? (press enter for automatic)', nil)
                if (@@optHash['outFile'])
                    @@optHash['outFile'].gsub!(/\\/,  '/')
                end
                
                if (@@optHash['outFile'] =~ /\//) 
                    @@optHash['outDir']=File.dirname(@@optHash['outFile'])
                    @@optHash['outFile']=File.basename(@@optHash['outFile'])
                end
            when '21'
                 @@optHash['outDir'] = ask("Output directory (#{findOutputDir})", nil)
                 if @@optHash['outDir']
                    @@optHash['outDir'].gsub!(/\\/,  '/')
                    
                    if (! File.exists?(@@optHash['outDir']))
                        answer = ask("This directory does not exist. Would you like me to create it?", 'n')
                        if answer =~ /y/
                            File.makedirs(@@optHash['outDir'])
                        else
                            puts "Fine, suit yourself."
                            sleep(1)
                        end
                     end
                 end
                 
            when 's', 'q'
                if (! @@optHash['queryArg']) || (@@optHash['queryArg'].size < 1)
                    puts "You cannot start till you specify what #{@@optHash['queryType']} data you would like to search with"
                    puts "(press enter to continue)"
                    answer=$stdin.gets
                end
            when 'r'
                resetOptions
                
            when 'x'
                puts "Git'rdone"
                exit
                
                
            end
            
            saveConfig
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
