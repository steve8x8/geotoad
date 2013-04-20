# $Id$
$LOAD_PATH << (File.dirname(__FILE__.gsub(/\\/, '/')) + '/' + '..')
$LOAD_PATH << (File.dirname(__FILE__.gsub(/\\/, '/')) + '/' + '../lib')

require 'country_state'


class Input
  include Common
  include Messages

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
    @@optHash['queryType'] = 'location'
  end

  def saveConfig
    if (! File.exists?(@configDir))
      File.makedirs(@configDir)
    end

    @@optHash.each_key {|key|
      if @@optHash[key].to_s.empty?
        @@optHash.delete(key)
      end
    }

    # File contains password, keep it safe..
    f = File.open(@configFile, 'w', 0600)
    f.puts @@optHash.to_yaml
    f.close
    debug "Saved configuration"
  end

  def loadConfig
    if File.exists?(@configFile)
      displayMessage "Loading configuration from #{@configFile}"
      return YAML::load(File.open(@configFile))
    end
  end

  def loadUserAndPasswordFromConfig
    data = loadConfig()
    if data
      return [data['user'], data['password']]
    else
      return [nil, nil]
    end
  end

  def getopt
    opts = GetoptLong.new(
      [ "--attributeInclude",         "-a",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--attributeExclude",         "-A",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--travelBug",                "-b",    GetoptLong::NO_ARGUMENT ],

      [ "--cacheType",                "-c",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--clearCache",               "-C",    GetoptLong::NO_ARGUMENT ],
      [ "--difficultyMin",            "-d",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--difficultyMax",            "-D",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--userInclude",              "-e",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--userExclude",              "-E",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--funFactorMin",             "-f",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--funFactorMax",             "-F",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--favFactorMin",             "-g",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--favFactorMax",             "-G",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--help",                     "-h",    GetoptLong::NO_ARGUMENT ],

      [ "--ownerInclude",             "-i",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--ownerExclude",             "-I",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--placeDateInclude",         "-j",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--placeDateExclude",         "-J",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--titleKeyword",             "-k",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--descKeyword",              "-K",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--waypointLength",           "-l",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--limitSearchPages",         "-L",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--delimiter",                "-m",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--mylogs",                   "-M",    GetoptLong::NO_ARGUMENT ],
      [ "--notFound",                 "-n",    GetoptLong::NO_ARGUMENT ],
      [ "--notFoundByMe",             "-N",    GetoptLong::NO_ARGUMENT ],
      [ "--output",                   "-o",    GetoptLong::REQUIRED_ARGUMENT ],

      [ "--password",                 "-p",    GetoptLong::REQUIRED_ARGUMENT ],         # * REQ
      [ "--proxy",                    "-P",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--queryType",                "-q",    GetoptLong::REQUIRED_ARGUMENT ],

      [ "--foundDateInclude",         "-r",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--foundDateExclude",         "-R",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--sizeMin",                  "-s",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--sizeMax",                  "-S",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--terrainMin",               "-t",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--terrainMax",               "-T",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--user",                     "-u",    GetoptLong::REQUIRED_ARGUMENT ],         # * REQ

      [ "--verbose",                  "-v",    GetoptLong::NO_ARGUMENT ],

      [ "--format",                   "-x",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--disableEarlyFilter",       "-X",    GetoptLong::NO_ARGUMENT ],
      [ "--distanceMax",              "-y",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--noCacheDescriptions",      "-Y",    GetoptLong::NO_ARGUMENT ],
      [ "--includeDisabled",          "-z",    GetoptLong::NO_ARGUMENT ],
      [ "--preserveCache",            "-Z",    GetoptLong::NO_ARGUMENT ]
    ) || usage

    # put the stupid crap in a hash. Much nicer to deal with.
    begin
      @@optHash = Hash.new
      opts.each do |opt, arg|
        # debug doesn't work here
        #puts "opt=#{opt.inspect} arg=#{arg.inspect}"
        # replace default delimiter(s)
        if (opt == '--delimiter')
          $delimiters = Regexp.compile('['+Regexp.escape(arg)+']')
          displayWarning "Using delimiter pattern #{$delimiters.inspect}"
        end
        # queryType gets special treatment. We try and normalize what they mean.
        if (opt == '--queryType')
          arg = guessQueryType(arg)
          debug "queryType is now #{arg}"
        end
        @@optHash[opt.gsub(/-/,'')] = arg
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
      displayWarning "Extra arguments found on command-line: \"#{ARGV.join(" ")}\""
      displayWarning "Perhaps you forgot quote marks around any arguments that contain spaces?"
      displayWarning "Example: -q #{@@optHash['queryType']} \"#{@@optHash['queryArg']} #{ARGV.join(" ")}\""
      displayError   "Correct your input and re-run."
      exit
    end

    @@optHash['user'] = convertEscapedHex(@@optHash['user'])
    if (@@optHash['queryType'] == 'user') or (@@optHash['queryType'] == 'owner')
      @@optHash['queryArg'] = convertEscapedHex(@@optHash['queryArg'])
    end

    return @@optHash
  end

  def interactive
    # pop up the menu
    loaded_config = loadConfig()
    if loaded_config
      @@optHash = loaded_config
    end
    showMenu()
    saveConfig()

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
    hidden_opts = ['queryArg', 'outDir', 'outFile', 'user', 'password', 'usemetric', 'verbose']
    # hide unlimited search
    if @@optHash['limitSearchPages'] == 0
      hidden_opts.push('limitSearchPages')
    end

    @@optHash.keys.sort.each { |option|
      if ! @@optHash[option].to_s.empty? and ! hidden_opts.include?(option)
        if @@optHash[option] == 'X'
          cmdline = cmdline + " --#{option}"
        elsif not @@optHash[option].to_s.empty?
          # Omit the quotes if the argument is 'simple'
          if @@optHash[option].to_s =~ /^[\w\.:]+$/
            cmdline = cmdline + " --#{option}=#{@@optHash[option]}"
          else
            cmdline = cmdline + " --#{option}=\'#{@@optHash[option]}\'"
          end
        end
        # in the metric case, we must append "km" to the distance
        if option == 'distanceMax' and @@optHash['usemetric']
          cmdline << "km"
        end
      end

    }
    if @@optHash['queryArg'].to_s[0] == "-"
      cmdline << " --"
    end
    if @@optHash['queryArg'].to_s =~ /^[\w\.:]+$/
      cmdline = cmdline + " " + @@optHash['queryArg'].to_s
    else
      cmdline = cmdline + " \'" + @@optHash['queryArg'].to_s + '\''
    end
    displayMessage "To use this query in the future, type:"
    displayMessage cmdline
    puts
    sleep(4)
    return @@optHash
  end


  def usage
    puts "::: SYNTAX: geotoad.rb [options] <search>"
    puts ""
    puts " -u <username>          Geocaching.com username, required for coordinates"
    puts " -p <password>          Geocaching.com password, required for coordinates"

    #puts " -m [delimiters]        set delimiter(s) (default #{$delimiters.inspect})"
    puts " -m [delimiters]        set delimiter(s) (default \":|\") for multiple selections"

    puts " -o [filename]          output file name (automatic otherwise)"
    puts " -x [format]            output format type, see list below"
    puts " -q [location|coord|user|owner|country|state|keyword|wid|guid]"
    puts "                        query type (location by default)"

    puts " -d/-D [1.0-5.0]        difficulty minimum/maximum"
    puts " -t/-T [1.0-5.0]        terrain minimum/maximum"
    puts " -f/-F [0.0-5.0]        fun factor minimum/maximum"
    puts " -g/-G [0.0-5.0]        fav factor minimum/maximum"
    puts " -y    [1-500]          distance maximum, in miles, or suffixed \"km\" (10)"
    puts " -k    [keyword]        title keyword(s) search"
    puts " -K    [keyword]        desc keyword(s) search (slow)"
    puts " -i/-I [username]       include/exclude caches owned by this person"
    puts " -e/-E [username]       include/exclude caches found by this person"
    puts " -s/-S [virtual|not_chosen|other|micro|small|regular|large]"
    puts "                        min/max size of the cache"
    puts " -c    [traditional|multicache|unknown|virtual|event|...]"
    puts "                        type(s) of cache"
    puts " -j/-J [# days]         include/exclude caches placed in the last X days"
    puts " -r/-R [# days]         include/exclude caches found in the last X days"
    puts " -a/-A [attribute]      include/exclude caches with attributes set"
    puts " -z                     include disabled caches"
    puts " -n                     only include not found caches (virgins)"
    puts " -N                     only caches not yet found by login user"
    puts " -b                     only include caches with travelbugs"
    puts " -l                     set EasyName waypoint id length. (16)"
    puts " -L                     limit number of search pages (0=unlimited)"
    puts " -Y                     do not fetch cache descriptions, search only"
    puts " -Z                     don't overwrite existing cache descriptions"
    puts " -P                     HTTP proxy server, http://username:pass@host:port/"
    puts " -X                     emergency switch: disable early filtering"
    puts " -M                     download my logs (/my/logs.aspx)"
    puts " -C                     selectively clear local browser cache"
    puts ""
    puts "::: OUTPUT FORMATS:"
    outputDetails = Output.new
    i=0
    print ""
    $validFormats.each { |type|
      desc = outputDetails.formatDesc(type)
      if (i>4)
        puts ""
        print ""
        i=0
      end
      i=i+1


      if (outputDetails.formatRequirement(type) == 'gpsbabel')
        type = type + "+"
      elsif (outputDetails.formatRequirement(type) == 'cmconvert')
        type = type + "="
      end

      printf(" %-12.12s", type)

    }
    puts ""
    puts "    + requires gpsbabel in PATH           = requires cmconvert in PATH"
    puts ""
    puts "::: EXAMPLES:"
    puts "  geotoad.rb -u helixblue -p password 27502"
    puts "  geotoad.rb -u john -p password -d 3 -s helixblue -f vcf -o NC.vcf \'North Carolina\'"
  end

  def showMenu
    # if windows
    # else
    answer = nil

    # if using TUI, only | is delimiter
    $delimiters = /\|/
    @@optHash['delimiter'] = '|'

    while (answer !~ /^[sq]/i)
      if RUBY_PLATFORM =~ /win32/
        system("cls")
      else
        # This could be bad under Ubuntu
        #        system("stty erase ^H >/dev/null 2>/dev/null")
        system("clear")
      end

      puts "=============================================================================="
      printf(":::           %46.46s               :::\n", "// GeoToad #$VERSION Text User Interface //")
      puts "=============================================================================="
      printf("(1)  GC.com login [%-17.17s] | (2)  search type          [%-10.10s]\n", (@@optHash['user'] || 'REQUIRED'), @@optHash['queryType'])
      printf("(3)  %-12.12s [%-17.17s] | (4)  distance maximum (%-2.2s)  [%8.8s]\n", @@optHash['queryType'], (@@optHash['queryArg'] || 'REQUIRED'),
        (@@optHash['usemetric'] && "km" || "mi"), (@@optHash['distanceMax'] || 10))
      #puts   "                                      |"
      puts "- - - - - - - - - - - - - - - - - - - + - - - - - - - - - - - - - - - - - - -"
      printf("(5)  difficulty           [%-2.1f - %-1.1f] | (6)  terrain               [%-1.1f - %-1.1f]\n",
        (@@optHash['difficultyMin'] || 1.0), (@@optHash['difficultyMax'] || 5.0),
        (@@optHash['terrainMin'] || 1.0), (@@optHash['terrainMax'] || 5.0))
      #printf("(7)  fun factor           [%-1.1f - %-1.1f] | (8)  cache size            [%3.3s - %3.3s]\n", (@@optHash['funFactorMin'] || 0.0),
      #  (@@optHash['funFactorMax'] || 5.0), @@optHash['sizeMin'] || 'any', @@optHash['sizeMax'] || 'any')
      printf("(7)  fav factor           [%-1.1f - %-1.1f] | (8)  cache size            [%3.3s - %3.3s]\n", (@@optHash['favFactorMin'] || 0.0),
        (@@optHash['favFactorMax'] || 5.0), @@optHash['sizeMin'] || 'any', @@optHash['sizeMax'] || 'any')
      printf("(9)  cache type   [%-58.58s]\n", (@@optHash['cacheType'] || 'any'))
      printf("(10) virgin caches only           [%1.1s] | (11) travel bug caches only        [%1.1s]\n", @@optHash['notFound'], @@optHash['travelBug'])
      printf("(12) cache age (days)     [%3.3s - %-3.3s] | (13) last found (days)     [%3.3s - %-3.3s] \n",
        (@@optHash['placeDateExclude'] || 0), (@@optHash['placeDateInclude'] || 'any'),
        (@@optHash['foundDateExclude'] || 0), (@@optHash['foundDateInclude'] || 'any'))
      #puts   "                                      |"
      printf("(14) title keyword       [%-10.10s] | (15) descr. keyword    [%-13.13s]\n", @@optHash['titleKeyword'], @@optHash['descKeyword'])
      printf("(16) cache not found by  [%-10.10s] | (17) cache owner isn't [%-13.13s]\n", @@optHash['userExclude'], @@optHash['ownerExclude'])
      printf("(18) cache found by      [%-10.10s] | (19) cache owner is    [%-13.13s]\n", @@optHash['userInclude'], @@optHash['ownerInclude'])

      printf("(20) EasyName WP length         [%3.3s] | (21) include disabled caches       [%1.1s] \n", @@optHash['waypointLength'] || '0', @@optHash['includeDisabled'])
      puts "- - - - - - - - - - - - - - - - - - - + - - - - - - - - - - - - - - - - - - -"
      printf("(22) output format  [%-15.15s] | (23) filename   [%-20.20s]\n", (@@optHash['format'] || 'gpx'), (@@optHash['outFile'] || 'automatic'))
      printf("(24) output directory    [%-51.51s]\n", (@@optHash['outDir'] || findOutputDir))
      puts "=============================================================================="
      if @@optHash['verbose']
        enableDebug
        puts "** VERBOSE MODE ENABLED"
      else
        disableDebug
        puts "** Verbose (debug) mode disabled, (v) to change"
      end
      print "-- Enter menu number, (s) to start, (r) to reset, or (x) to exit --> "
      answer = $stdin.gets.chop
      puts ""

      case answer
      when '1'
        @@optHash['user'] = ask("What is your Geocaching.com username?", 'NO_DEFAULT')
          @@optHash['user'] = convertEscapedHex(@@optHash['user'])
        @@optHash['password'] = ask("What is your Geocaching.com password?", 'NO_DEFAULT')

      when '2'
        # TODO(helixblue): Add state searches back in once things settle down.
        chosen = askFromList("What type of search would you like to perform:

  1. Within distance of a location (landmark, city, postal code, coordinates) - DEFAULT
  2. By coordinates
  3. All caches found by a user
  4. All caches created by an owner
  5. All caches within a country
  6. All caches within a state
  7. By title keyword
  8. By waypoint ID
  9. By waypoint GUID

", ['location', 'coord', 'user', 'owner', 'country', 'state', 'keyword', 'wid', 'guid'], 'location')

        # Clear the query argument if the type has changed.
        if @@optHash['queryType'] != chosen
          @@optHash['queryArg'] = nil
        end

        @@optHash['queryType'] = chosen

      when '3'
        case @@optHash['queryType']
        when 'location'
          @@optHash['queryArg'] = ask("Type in an address, city, state, postal code, or coordinates (uses Google Maps).\nMultiple locations may be separated by the | symbol\n\n", 'NO_DEFAULT')

        when 'country'
          @@optHash['queryArg'] = askCountry()

        when 'state'
          @@optHash['queryArg'] = askState()

        when 'wid'
          @@optHash['queryArg'] = ask('Enter a list of waypoint id\'s (separated by commas)', 'NO_DEFAULT').gsub(/, */, '|')

        when 'guid'
          @@optHash['queryArg'] = ask('Enter a list of guid\'s (separated by commas)', 'NO_DEFAULT').gsub(/, */, '|')

        when 'user'
          @@optHash['queryArg'] = ask('Enter a list of users (separated by commas)', 'NO_DEFAULT').gsub(/, */, '|')
            @@optHash['queryArg'] = convertEscapedHex(@@optHash['queryArg'])

        when 'owner'
          @@optHash['queryArg'] = ask('Enter a list of owners (separated by commas)', 'NO_DEFAULT').gsub(/, */, '|')
            @@optHash['queryArg'] = convertEscapedHex(@@optHash['queryArg'])

        when 'coord'
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
              query = query + coord + '|'
              coordset = coordset + 1
            end
          end

          query.gsub!(/\|$/, '')
          @@optHash['queryArg'] = query

        when 'keyword'
          puts "Please enter a list of keywords, pressing enter after each one."
          puts "Press (q) when done."

          keyset = 1
          key = nil
          query = ''

          while (key != 'q')
            print keyset.to_s + ": "
            key = $stdin.gets.chomp
            if key != 'q'
              query = query + key + '|'
              keyset = keyset + 1
            end
          end

          query.gsub!(/\|$/, '')
          @@optHash['queryArg'] = query
        end


      when '4'
        unit = (@@optHash['usemetric'] && "km" || "mi")
        # re-use old unit by default
        value, unit = askNumberandUnit("How far away are you willing to search? (10 #{unit})", 10, unit)
        @@optHash['distanceMax'] = value
        @@optHash['usemetric'] = (unit=="km" || nil)

      when '5'
        @@optHash['difficultyMin'] = askNumber('What is the minimum difficulty you would like? (1.0)', nil)
        @@optHash['difficultyMax'] = askNumber('What is the maximum difficulty you would like? (5.0)', nil)

      when '6'
        @@optHash['terrainMin'] = askNumber('What is the minimum terrain you would like? (1.0)', nil)
        @@optHash['terrainMax'] = askNumber('What is the maximum terrain you would like? (5.0)', nil)

      when '7'
        #@@optHash['funFactorMin'] = askNumber('What is the minimum fun factor you would like? (0.0)', nil)
        #@@optHash['funFactorMax'] = askNumber('What is the maximum fun factor you would like? (5.0)', nil)
        @@optHash['favFactorMin'] = askNumber('What is the minimum fav factor you would like? (0.0)', nil)
        @@optHash['favFactorMax'] = askNumber('What is the maximum fav factor you would like? (5.0)', nil)

      when '8'
        # 'virtual' and 'not chosen' are equivalent
        sizes = ['virtual', 'not_chosen', 'not chosen', 'other', 'micro', 'small', 'regular', 'large']
        @@optHash['sizeMin'] = askFromList("What is the smallest cache you seek (#{sizes.join(', ')})?", sizes, nil)
        @@optHash['sizeMax'] = askFromList("Great! What is the largest cache you seek (#{sizes.join(', ')})?", sizes, nil)

      when '9'
        kinds = ['traditional', 'multicache', 'event', 'unknown', 'letterbox', 'virtual', 'earthcache', 'wherigo', 'cito']
        @@optHash['cacheType'] = askFromList("Valid types: #{kinds.join(', ')}\nWhat do you seek (separate with commas)?", kinds, nil)

      when '10'
        answer = ask('Would you like to only include virgin geocaches (geocaches that have never been found)?', nil)
        if (answer =~ /y/)
          @@optHash['notFound'] = 'X'
        else
          @@optHash['notFound'] = nil
        end

      when '11'
        answer = ask('Would you like to only include geocaches with travelbugs in them?', nil)
        if (answer =~ /y/)
          @@optHash['travelBug'] = 'X'
        else
          @@optHash['travelBug'] = nil
        end


      when '12'
        @@optHash['placeDateExclude'] = askNumber('How many days old is the youngest a geocache can be for your list? (0)', nil)
        @@optHash['placeDateInclude'] = askNumber('How many days old is the oldest a geocache can be for your list? (any)', nil)

      when '13'
        @@optHash['foundDateExclude'] = askNumber('How many days ago is the minimum a geocache can be found in for your list? (0)', nil)
        @@optHash['foundDateInclude'] = askNumber('How many days ago is the maximum a geocache can be found in for your list? (any)', nil)

      when '14'
        @@optHash['titleKeyword'] = ask('Filter caches by title keywords (negate using !, separate multiple using |): ', nil)

      when '15'
        @@optHash['descKeyword'] = ask('Filter caches by description keywords (negate using !, separate multiple using |): ', nil)

      when '16'
        @@optHash['userExclude'] = ask('Filter out geocaches found by these people (separate by commas)', '').gsub(/, */, '|')

      when '17'
        @@optHash['ownerExclude'] = ask('Filter out geocaches owned by these people (separate by commas)', '').gsub(/, */, '|')

      when '18'
        @@optHash['userInclude'] = ask('Only include geocaches that have been found by these people (separate by commas)', '').gsub(/, */, '|')

      when '19'
        @@optHash['ownerInclude'] = ask('Only include geocaches owned by these people (separate by commas)', '').gsub(/, */, '|')

      when '20'
        @@optHash['waypointLength'] = askNumber('How long can your EasyName waypoint id\'s be? (8 for Magellan, 16 for Garmin, -1 to use full text, 0 to disable and use waypoint id\'s)?', nil, true)

      when '21'
        answer = ask('Include disabled caches in your results?', nil)
        if (answer =~ /y/)
          @@optHash['includeDisabled'] = 'X'
        else
          @@optHash['includeDisabled'] = nil
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
          printf("%-12.12s: %-45.45s %s\n", type, desc, req)
        }

        puts ""
        @@optHash['format'] = ask('What format would you like your output in?', 'gpx').gsub(/, */, '|')

      when '23'
        @@optHash['outFile'] = ask('What filename would you like to output to? (press enter for automatic)', nil)
        if (@@optHash['outFile'])
          @@optHash['outFile'].gsub!(/\\/,  '/')
        end

        if (@@optHash['outFile'] =~ /\//)
          @@optHash['outDir']=File.dirname(@@optHash['outFile'])
          @@optHash['outFile']=File.basename(@@optHash['outFile'])
        end

      when '24'
        @@optHash['outDir'] = ask("Output directory (#{findOutputDir})", nil)
        if @@optHash['outDir']
          @@optHash['outDir'].gsub!(/\\/,  '/')

          if (! File.exists?(@@optHash['outDir']))
            answer = ask("This directory does not exist. Would you like me to create it?", 'n')
            if answer =~ /y/
              FileUtils::mkdir_p(@@optHash['outDir'], :mode => 0700)
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
        # in case of country or state query, return numeric id only
        if (@@optHash['queryType'] == 'country' || @@optHash['queryType'] == 'state')
          @@optHash['queryArg'] = @@optHash['queryArg'].to_s.split(/=/)[0]
        end
      when 'r'
        resetOptions
      when 'v'
        if  @@optHash['verbose']
          @@optHash['verbose']=nil
        else
          @@optHash['verbose'] = 'X'
        end
      when 'x'
        puts "Cya!"
        exit


      end

      saveConfig
    end

  end



  def ask(string, default)
    answer = nil
    while not answer or answer.length() == 0
      print string + ": "
      answer = $stdin.gets.chomp
      answer.gsub!(/ +$/, '')

      if not answer or answer.length() == 0
        if default == 'NO_DEFAULT'
          puts "You must supply an answer, there is no default!"
        else
          return default
        end
      end
    end
    return answer
  end

  def askNumber(string, default, allowNegative = false)
    # Ask for a floating point number. Only accept non-negative values.
    while true
      begin
        answer = ask(string, default)
        if not answer
          return default
        else
          # this may throw an ArgumentError
          answerf = Float(answer)
          # negative values aren't allowed
          if (answerf < 0) and (not allowNegative)
            puts "*** #{answer} is negative, not allowed."
          # If it is equivalent to it's integer, return the integer instead
          elsif answerf == answerf.to_i
            return answerf.to_i
          else
            return answerf
          end
        end
      rescue ArgumentError
        puts "*** #{answer} does not look like a valid number."
      end
    end
  end

  def askNumberandUnit(string, default, defaultunit)
    # Ask for a (non-negative) floating point number, optionally followed by a unit.
    while true
      begin
        answer = ask(string, "#{default} #{defaultunit}")
        if not answer
          return default, defaultunit
        else
          # split into numeric and string part
          if answer =~ /([\d\.]+)\s*(mi|km)?/
            # this may throw an ArgumentError
            answerf = Float($1)
            # If it is equivalent to it's integer, return the integer instead
            if answerf == answerf.to_i
              answerf = answerf.to_i
            end
            # if we got a valid unit, return that
            if $2
              return answerf, $2
            else
              return answerf, defaultunit
            end
          else
            puts "*** Cannot parse #{answer}!"
          end
        end
      rescue ArgumentError
        puts "*** #{answer} does not look like valid input."
      end
    end
  end

  def askCountry()
    country = nil
    c = CountryState.new()
    while not country
      try_country = ask("What country would you like to search for (id, or name pattern)?", nil)
      # numerical value?
      if try_country.to_i.nonzero?
        country = try_country.to_i
      else
        # match from country list
        countries = c.findMatchingCountry(try_country)
        if countries.length == 1
          country = countries[0]
        elsif countries.length > 1
          i = 0
          countries.each do |co|
            i += 1
            puts "  #{i}. #{co}"
          end
          country = askFromList("Enter index (not id!)", countries, nil)
        else
          puts "No country matches found. Try something else!"
        end
      end
    end
    if country
      puts "Using #{country}"
      sleep(3)
    end
    return country
  end

  def askState()
    state = nil
    c = CountryState.new()
    while not state
      try_state = ask("Which state do you want to search for (id, or country/state pattern)?", nil)
      # numerical value?
      if try_state.to_i.nonzero?
        state = try_state.to_i
      else
        # get from country's list
        try_country = try_state.split(/\//)[0]
        try_state = try_state.split(/\//)[1]
        if try_state.empty?
          puts "Use \"Country/State\" style"
        else
          # match country from list
          countries = c.findMatchingCountry(try_country)
          if countries.length == 1
            country = countries[0]
          elsif countries.length > 1
            i = 0
            countries.each do |co|
              i += 1
              puts "  #{i}. #{co}"
            end
            country = askFromList("Enter index (not id!)", countries, nil)
          else
            puts "No country matches found. Try something else!"
          end
          if country
            puts "Searching in country #{country}"
            country = country.split(/=/)[0]
            states = c.findMatchingState(try_state, country)
            if states.length == 1
              state = states[0]
            elsif states.length > 1
              i = 0
              states.each do |st|
                i += 1
                puts "  #{i}. #{st}"
              end
              state = askFromList("Enter index (not id!)", states, nil)
            else
              puts "No state matches found. Try something else!"
            end
          end
        end
      end
    end
    if state
      puts "Using #{state}"
      sleep(3)
    end
    return state
  end

  def askFromList(string, choices, default)
    # Ask for an item from a list. We accept either a number or word.

    try_again = true
    while try_again
      begin
        answer = ask(string, default)
        # empty response returns default
        if not answer
          return default
        end
        # numerical answer not validated, multiple not allowed
        if answer.to_i > 0
          return choices[answer.to_i - 1]
        end
        # validate text answer(s)
        answer.gsub!(/, */, '|')
        try_again = false
        answer = answer.split($delimiters).map{ |try_answer|
          # build a list of matches: 0 means invalid, 1 is perfect, 2 ambiguous
          matches = choices.map{ |e| (e =~ Regexp.compile('^'+try_answer)) ? e : nil }.compact
          if matches.length == 0
            puts "** \"#{try_answer}\" is invalid!"
            #puts "Try: #{choices.join(', ')}"
            try_again = true
            nil
          elsif  matches.length == 1
            matches[0]
          else
            puts "** \"#{try_answer}\" is ambiguous! Matches: #{matches.join(', ')}"
            try_again = true
            nil
          end
        }.join('|')
      end
    end
    return answer
  end

  def convertEscapedHex(string)
    text = nil
    if string
      text = string.dup
      text.gsub!(/(\\x|%)([0-9a-fA-F][0-9a-fA-F])/) { $2.to_i(16).chr }
    end
    return text
  end


  def guessQueryType(type)

    case type
    when /auto/
      return 'location'
    when /loc/
      return 'location'
    when /zip/
      return 'location'
    when /country/
      return 'country'
    when /state/
      return 'state'
    when /province/
      return 'state'
    when /coo/
      return 'coord'
    when /wid/
      return 'wid'
    when /waypoint/
      return 'wid'
    when /guid/
      return 'guid'
    when /user/
      return 'user'
    when /own/
      return 'owner'
    when /key/
      return 'keyword'
    end
    # Could not guess
    return nil
  end

end
