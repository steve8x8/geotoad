require 'pathname'
$THISDIR = File.dirname(File.realpath(__FILE__))
$LOAD_PATH << File.join($THISDIR, '..')
$LOAD_PATH << File.join($THISDIR, '..', 'lib')

require 'country_state'
require 'common'
require 'messages'

class Input

  include Common
  include Messages

  def initialize
    # Originally, it  was @optHash. Rather than write a probably unneeded
    # restore and save for it so that it can keep preferences between runs,
    # I thought I would just make it class-wide instead of instance wide.

    resetOptions
    @configDir = findConfigDir
    @configFile = File.join(@configDir, 'config.yaml')
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

    @@optHash.each_key{ |key|
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
      [ "--attributeInclude",            "-a",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--attributeExclude",            "-A",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--travelBug",    "--trackable", "-b",    GetoptLong::NO_ARGUMENT ],
# -B
      [ "--cacheType",         "--type", "-c",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--clearCache",     "--cleanup", "-C",    GetoptLong::NO_ARGUMENT ],
      [ "--difficultyMin",  "--minDiff", "-d",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--difficultyMax",  "--maxDiff", "-D",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--userInclude",     "--doneBy", "-e",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--userExclude",  "--notdoneBy", "-E",    GetoptLong::REQUIRED_ARGUMENT ],
# -f (was funFactorMin)
# -F (was finFactorMax)
      [ "--favFactorMin",    "--minFav", "-g",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--favFactorMax",    "--maxFav", "-G",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--help",                        "-h",    GetoptLong::NO_ARGUMENT ],
# -H
      [ "--ownerInclude",        "--by", "-i",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--ownerExclude",     "--notby", "-I",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--placeDateInclude", "--since", "-j",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--placeDateExclude", "--until", "-J",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--titleKeyword",                "-k",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--descKeyword",                 "-K",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--logCount",                    "-l",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--limitSearchPages",            "-L",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--delimiter",   "--delimiters", "-m",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--myLogs",         "--getlogs", "-M",    GetoptLong::NO_ARGUMENT ],
      [ "--notFound",        "--virgin", "-n",    GetoptLong::NO_ARGUMENT ],
      [ "--notFoundByMe",     "--notme", "-N",    GetoptLong::NO_ARGUMENT ],
      [ "--output",                      "-o",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--noPMO",            "--nopmo", "-O",    GetoptLong::NO_ARGUMENT ],
      [ "--password",                    "-p",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--proxy",                       "-P",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--queryType",                   "-q",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--onlyPMO",            "--pmo", "-Q",    GetoptLong::NO_ARGUMENT ],
      [ "--foundDateInclude",            "-r",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--foundDateExclude",            "-R",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--sizeMin",        "--minSize", "-s",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--sizeMax",        "--maxSize", "-S",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--terrainMin",  "--minTerrain", "-t",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--terrainMax",  "--maxTerrain", "-T",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--user",          "--username", "-u",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--unbufferedOutput",            "-U",    GetoptLong::NO_ARGUMENT ],
      [ "--verbose",          "--debug", "-v",    GetoptLong::NO_ARGUMENT ],
      [ "--version",    "--showVersion", "-V",    GetoptLong::NO_ARGUMENT ],
      [ "--waypointLength",              "-w",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--myTrackables",   "--gettrks", "-W",    GetoptLong::NO_ARGUMENT ],
      [ "--format",                      "-x",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--disableEarlyFilter",          "-X",    GetoptLong::NO_ARGUMENT ],
      [ "--distanceMax",     "--radius", "-y",    GetoptLong::REQUIRED_ARGUMENT ],
      [ "--noCacheDescriptions",         "-Y",    GetoptLong::NO_ARGUMENT ],
      [ "--includeDisabled",    "--bad", "-z",    GetoptLong::NO_ARGUMENT ],
      [ "--preserveCache",  "--keepOld", "-Z",    GetoptLong::NO_ARGUMENT ],
    # no short option available
      [ "--includeArchived", "--gone",            GetoptLong::NO_ARGUMENT ],
      [ "--minLongitude", "--longMin",            GetoptLong::REQUIRED_ARGUMENT ],
      [ "--maxLongitude", "--longMax",            GetoptLong::REQUIRED_ARGUMENT ],
      [ "--minLatitude",  "--latMin",             GetoptLong::REQUIRED_ARGUMENT ],
      [ "--maxLatitude",  "--latMax",             GetoptLong::REQUIRED_ARGUMENT ]
    ) || usage

    # put the stupid crap in a hash. Much nicer to deal with.
    begin
      @@optHash = Hash.new
      opts.each do |opt0, arg|
        opt = opt0.gsub(/-/, '')
        # replace default delimiter(s)
        if (opt == 'delimiter')
          $delimiters = Regexp.compile('['+Regexp.escape(arg)+']')
          $delimiter = arg[0]
          displayWarning "Using delimiter pattern #{$delimiters.inspect}"
        end
        # queryType gets special treatment. We try and normalize what they mean.
        if (opt == 'queryType')
          arg = guessQueryType(arg)
          debug "queryType is now #{arg}"
        end
        # rectangular filter: 4 options
        if (opt =~ /(min|max)L(ong|at)itude/)
          input = arg.tr(':,', '  ').gsub(/[NE\+]\s*/i, '').gsub(/[SW-]\s*/i, '-')
          arg = parseCoordinate(input)
          debug "#{opt} is now #{arg}"
        end
        # store opt/arg pairs into hash
        # verbose special treatment: sum up how often
        if (opt == 'verbose')
          @@optHash['verbose'] = @@optHash['verbose'].to_i + 1
        elsif (@@optHash[opt] == "")
          # NO_ARG but already set: toggle
          #@@optHash[opt] = nil
          @@optHash.delete(opt)
        else
          @@optHash[opt] = arg
        end
      end
    rescue => e
      displayError "Error in option parsing: #{e} - this may be a bug, please check and report."
    end

    # some sanity check
    if @@optHash['noPMO'] and @@optHash['onlyPMO']
      displayError   "Cannot select and exclude PMO at the same time."
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
      @@optHash['output'] = @@optHash['outDir']
    else
      @@optHash['output'] = findOutputDir()
    end

    if (@@optHash['outFile'])
      if @@optHash['output']
        @@optHash['output'] = File.join(@@optHash['output'], @@optHash['outFile'])
      else
        @@optHash['output'] = @@optHash['outFile']
      end
    else
      # automatic filename: append slash
      @@optHash['output'] = File.join(@@optHash['output'], '')
    end

    # completely forget about those:
    @@optHash.delete('outDir')
    @@optHash.delete('outFile')

    # demonstrate a sample command line
    cmdline = "geotoad.rb"
    hidden_opts = ['queryArg', 'user', 'password', 'usemetric', 'verbose']
    # hide unlimited search
    if @@optHash['limitSearchPages'] == 0
      hidden_opts.push('limitSearchPages')
    end

    @@optHash.keys.sort.each{ |option|
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

    puts " -m [delimiters]        set delimiter(s) (default \"|:\") for multiple selections"

    puts " -o [filename]          output file name (automatic otherwise)"
    puts " -x [format]            output format type, see list below (default: gpx)"
    puts " -q [location|coord|user|owner|country|state|keyword|wid|guid]"
    puts "                        query type (default: location)"

    puts " -d/-D [1.0-5.0]        difficulty minimum/maximum"
    puts " -t/-T [1.0-5.0]        terrain minimum/maximum"
    puts " -g/-G [0.0-5.0]        fav factor minimum/maximum"
    puts " -y    [0.01-500]       distance maximum, in miles, or suffixed \"km\" (10)"
    puts " -k    [keyword]        title keyword(s) search"
    puts " -K    [keyword]        desc keyword(s) search (slow!)"
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
    puts " -b                     only include caches with travelbugs/trackables"
    puts " -w [length]            set EasyName waypoint id length. (default: 0=use WID)"
    puts " -L [count]             limit number of search pages (0=unlimited)"
    puts " -l [count]             limit number of log entries (default: 10)"
    puts " -Y                     do not fetch cache descriptions, search only"
    puts " -Z                     don't overwrite existing cache descriptions"
    puts " -O                     exclude Premium Member Only caches"
    puts " -Q                     select only Premium Member Only caches"
    puts " -P                     HTTP proxy server, http://username:pass@host:port/"
    puts " -M                     download my cache logs (/my/logs.aspx?s=1)"
    puts " -W                     download my trackable logs (/my/logs.aspx?s=2)"
    puts " -X                     emergency switch: disable early filtering"
    puts " -C                     selectively clear local browser cache"
    puts " -U                     use unbuffered output"
    puts " -V                     show version, then exit"
    puts ""
    puts "See manual page for more details, including \"long\" options."
    puts ""
    outputDetails = Output.new
    $validFormats = outputDetails.formatList.sort
    puts ""
    puts "::: OUTPUT FORMATS:"
    column = 0
    $validFormats.each{ |f|
      type = f.dup
      if (column > 4)
        puts ""
        column = 0
      end
      if (outputDetails.formatRequirement(type) == 'gpsbabel')
        type << '(+)'
      elsif (outputDetails.formatRequirement(type) == 'cmconvert')
        type << '(=)'
      elsif (outputDetails.formatRequirement(type) == 'iconv')
        type << '(%)'
      end
      printf(" %-13.13s", type)
      column += 1
    }
    puts ""
    puts " (+) requires gpsbabel  (=) requires cmconvert  (%) requires iconv in PATH"
    puts ""
    puts "::: EXAMPLES:"
    puts " geotoad.rb -u helixblue -p password 27502"
    puts "   find zipcode 27502 (Apex, NC 27502, USA), search 10 mi around, write gpx"
    puts " geotoad.rb -u john -p password -c unknown -d 3 -x csv -o NC.cvs -q state 34"
    puts "   will find all mystery caches with difficulty >= 3 in all of North Carolina"
    puts "   (Be careful: NC has more than 24k active caches!)"
    puts " geotoad.rb -u ... -p ... -z -Y -H -c cito -x list -o cito.list -q country 11"
    puts "   creates a list (with dates, but no coordinates) of all CITO events in the UK"
    puts " for more examples - and options explanations - see manual page and README"
  end

  def showMenu
    answer = nil

    # if using TUI, only | is delimiter
    $delimiters = /\|/
    $delimiter = '|'
    @@optHash['delimiter'] = '|'

    while (answer !~ /^[sq]/i)
      if RUBY_PLATFORM =~ /win32/
        system("cls")
      else
        system("clear")
      end

      puts "=============================================================================="
      printf(":::           %46.46s               :::\n", "// GeoToad #$VERSION Text User Interface //")
      puts "=============================================================================="
      printf("(1)  GC.com login [%-17.17s] | (2)  search type          [%-10.10s]\n", (@@optHash['user'] || 'REQUIRED'), @@optHash['queryType'])
      printf("(3)  %-12.12s [%-17.17s] |", @@optHash['queryType'], (@@optHash['queryArg'] || 'REQUIRED'))
      if (@@optHash['queryType'] == 'coord') or (@@optHash['queryType'] == 'location')
        printf(" (4)  distance maximum (%-2.2s)  [%8.8s]\n",
          (@@optHash['usemetric'] && "km" || "mi"), (@@optHash['distanceMax'] || 10))
      else
        puts   "                                      |"
      end
      puts "- - - - - - - - - - - - - - - - - - - + - - - - - - - - - - - - - - - - - - -"
      printf("(5)  difficulty           [%-2.1f - %-1.1f] | (6)  terrain               [%-1.1f - %-1.1f]\n",
        (@@optHash['difficultyMin'] || 1.0), (@@optHash['difficultyMax'] || 5.0),
        (@@optHash['terrainMin'] || 1.0), (@@optHash['terrainMax'] || 5.0))
      printf("(7)  fav factor           [%-1.1f - %-1.1f] | (8)  cache size            [%3.3s - %3.3s]\n", (@@optHash['favFactorMin'] || 0.0),
        (@@optHash['favFactorMax'] || 5.0), @@optHash['sizeMin'] || 'any', @@optHash['sizeMax'] || 'any')
      printf("(9)  cache type   [%58.58s]\n", (@@optHash['cacheType'] || 'any'))
      printf("(10) caches not found by me       [%1.1s] | (11) caches not found by anyone    [%1.1s]\n", @@optHash['notFoundByMe'], @@optHash['notFound'])
      printf("(12) cache age (days)     [%3.3s - %-3.3s] | (13) last found (days ago) [%3.3s - %-3.3s]\n",
        (@@optHash['placeDateExclude'] || 0), (@@optHash['placeDateInclude'] || 'any'),
        (@@optHash['foundDateExclude'] || 0), (@@optHash['foundDateInclude'] || 'any'))
      printf("(14) title keyword       [%-10.10s] | (15) descript. keyword [%-13.13s]\n", @@optHash['titleKeyword'], @@optHash['descKeyword'])
      printf("(16) cache not found by  [%-10.10s] | (17) cache owner isn't [%-13.13s]\n", @@optHash['userExclude'], @@optHash['ownerExclude'])
      printf("(18) cache found by      [%-10.10s] | (19) cache owner is    [%-13.13s]\n", @@optHash['userInclude'], @@optHash['ownerInclude'])

      printf("(20) EasyName WP length         [%3.3s] | (21) include disabled caches       [%1.1s]\n", @@optHash['waypointLength'] || '0', @@optHash['includeDisabled'])
      printf("(22) caches with trackables only  [%1.1s] | (23) no Premium Member Only caches [%1.1s]\n", @@optHash['travelBug'], @@optHash['noPMO'])
      puts "- - - - - - - - - - - - - - - - - - - + - - - - - - - - - - - - - - - - - - -"
      printf("(24) output format  [%-15.15s] | (25) filename   [%-20.20s]\n", (@@optHash['format'] || 'gpx'), (@@optHash['outFile'] || 'automatic'))
      printf("(26) output directory    [%-51.51s]\n", (@@optHash['outDir'] || findOutputDir))
      puts "=============================================================================="
      if @@optHash['verbose']
        level = @@optHash['verbose'].to_i
        level = (level > 0) ? level : 1
        enableDebug(level)
        msg = "enabled (level #{level})"
      else
        disableDebug
        msg = "disabled"
      end
      puts "** Verbose (debug) mode #{msg}, (v) to change"
      print "-- Enter menu number, (s) to start, (R) to reset, or (Q) to exit --> "
      answer = $stdin.gets.chop
      puts ""

      case answer
      when '1'
        @@optHash['user'] = ask("What is your Geocaching.com username?", 'NO_DEFAULT')
          @@optHash['user'] = convertEscapedHex(@@optHash['user'])
        @@optHash['password'] = ask("What is your Geocaching.com password?", 'NO_DEFAULT')

      when '2'
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
        @@optHash['favFactorMin'] = askNumber('What is the minimum fav factor you would like? (0.0)', nil)
        @@optHash['favFactorMax'] = askNumber('What is the maximum fav factor you would like? (5.0)', nil)

      when '8'
        # 'virtual' and 'not chosen' are equivalent
        sizes = ['virtual', 'not_chosen', 'not chosen', 'other', 'micro', 'small', 'regular', 'large']
        @@optHash['sizeMin'] = askFromList("What is the smallest cache you seek (#{sizes.join(', ')})?", sizes, nil)
        @@optHash['sizeMax'] = askFromList("Great! What is the largest cache you seek (#{sizes.join(', ')})?", sizes, nil)

      when '9'
        # full list of supported types; no "+" types
        kinds = ['traditional', 'multicache', 'virtual', 'letterbox',
                  'event', 'cito', 'megaevent', 'gigaevent', 'lost+found', 'lfceleb', 'block',
                  'unknown', 'gshq', 'ape', 'webcam', 'earthcache', 'exhibit', 'wherigo']
        @@optHash['cacheType'] = askFromList("Valid types: #{kinds.join(', ')}.\nWhat do you seek (separate with commas)?", kinds, nil, trailing_dash_allowed = true)

      when '10'
        answer = ask('Would you like to only include geocaches you have not found yet?', nil)
        if (answer =~ /y/)
          @@optHash['notFoundByMe'] = 'X'
        else
          @@optHash['notFoundByMe'] = nil
        end

      when '11'
        answer = ask('Would you like to only include virgin geocaches (geocaches that have never been found)?', nil)
        if (answer =~ /y/)
          @@optHash['notFound'] = 'X'
        else
          @@optHash['notFound'] = nil
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
        @@optHash['waypointLength'] = askNumber('How long can your EasyName waypoint id\'s be? (recommended: 8 for Magellan, 16 for Garmin, 0 to disable and use waypoint id\'s)?', nil) #, true)

      when '21'
        answer = ask('Include disabled caches in your results?', nil)
        if (answer =~ /y/)
          @@optHash['includeDisabled'] = 'X'
        else
          @@optHash['includeDisabled'] = nil
        end

      when '22'
        answer = ask('Would you like to only include geocaches with travelbugs in them?', nil)
        if (answer =~ /y/)
          @@optHash['travelBug'] = 'X'
        else
          @@optHash['travelBug'] = nil
        end

      when '23'
        answer = ask('Would you like to only include geocaches which are not Premium Member Only?', nil)
        if (answer =~ /y/)
          @@optHash['noPMO'] = 'X'
        else
          @@optHash['noPMO'] = nil
        end

      when '24'
        outputDetails = Output.new
        puts "List of Output Formats [Extension] {Requirement}: "
        $validFormats = outputDetails.formatList.sort
        $validFormats.each{ |type|
          desc = ""
          ext  = "[" + outputDetails.formatExtension(type) + "]"
          desc << outputDetails.formatDesc(type)
          req  = outputDetails.formatRequirement(type)
          if (req)
            desc << " {" + req + "}"
          end
          printf("%-13.13s%6.6s %s\n", type, ext, desc)
        }

        puts ""
        @@optHash['format'] = ask('What format would you like your output in?', 'gpx').gsub(/, */, '|')

      when '25'
        @@optHash['outFile'] = ask('What filename would you like to output to? (press enter for automatic)', nil)
        if (@@optHash['outFile'])
          @@optHash['outFile'].gsub!(/\\/,  '/')
        end
        # if (full) path: split into parts
        if (@@optHash['outFile'] =~ /\//)
          @@optHash['outDir'] = File.dirname(@@optHash['outFile'])
          @@optHash['outFile'] = File.basename(@@optHash['outFile'])
        end

      when '26'
        currentOutDir = @@optHash['outDir'] || findOutputDir()
        @@optHash['outDir'] = ask("Output directory (#{currentOutDir})", currentOutDir)
        if @@optHash['outDir']
          @@optHash['outDir'].gsub!(/\\/,  '/')

          if File.exists?(@@optHash['outDir'])
            if (! File.directory?(@@optHash['outDir']))
              puts " ***  Although existing, this is no directory. Trouble ahead!"
              print "Press enter to continue: "
              answer=$stdin.gets
            end
            if (! File.writable?(@@optHash['outDir']))
              puts " ***  Although existing, this is not writable. Trouble ahead!"
              print "Press enter to continue: "
              answer=$stdin.gets
            end
          else
            answer = ask("This directory does not exist. Would you like me to create it?", 'n')
            if answer =~ /y/
              begin
                FileUtils::mkdir_p(@@optHash['outDir'], :mode => 0700)
              rescue
                puts " ***  Directory cannot be created. Trouble ahead!"
                print "Press enter to continue: "
                answer=$stdin.gets
              end
            else
              puts "Fine, suit yourself."
              sleep(3)
            end
          end
        end

      when 's', 'q'
        if (! @@optHash['queryArg']) || (@@optHash['queryArg'].size < 1)
          puts " ***  You cannot start till you specify what #{@@optHash['queryType']} data you would like to search with"
          print "Press enter to continue: "
          answer=$stdin.gets
        end
        # in case of country or state query, return numeric id only
        if (@@optHash['queryType'] == 'country' || @@optHash['queryType'] == 'state')
          @@optHash['queryArg'] = @@optHash['queryArg'].to_s.split(/=/)[0]
        end

      when 'R'
        resetOptions

      when 'v'
        # cycle through verbose levels 0--3
        # get current level
        if @@optHash['verbose']
          level = @@optHash['verbose'].to_i
          level = (level > 0) ? level : 1
        else
          level = 0
        end
        # next one
        level = (level + 1) % 4
        # map 0 back to nil
        level = (level == 0) ? nil : level
        @@optHash['verbose'] = level

      when 'x', 'X', 'Q'
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

  def askNumber(string, default)
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
          if (answerf < 0)
            puts "** #{answer} is negative, not allowed."
          # If it is equivalent to it's integer, return the integer instead
          elsif answerf == answerf.to_i
            return answerf.to_i
          else
            return answerf
          end
        end
      rescue ArgumentError
        puts "** #{answer} does not look like a valid number."
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
            puts "** Cannot parse #{answer}!"
          end
        end
      rescue ArgumentError
        puts "** #{answer} does not look like valid input."
      end
    end
  end

  def askCountry()
    country = nil
    c = CountryState.new()
    while not country
      try_country = ask("What country would you like to search for (id, or name pattern)?", nil)
      # numerical value? country 1 doesn't exist
      if try_country.to_i > 1
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
            puts "  #{i}.\t#{co}"
          end
          country = askFromList("Enter index", countries, nil)
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
      # numerical value? state 1 doesn't exist
      if try_state.to_i > 1
        state = try_state.to_i
      else
        # get from country's list
        try_country = try_state.to_s.split(/\//)[0]
        if try_country.nil? or try_country.empty?
          puts "** No country pattern. Use \"Country/State\""
        else
          try_state = try_state.split(/\//)[1]
          if try_state.nil? or try_state.empty?
            puts "** No state pattern, using \".\" to match all"
            try_state = '.'
          end
          # match country from list
          countries = c.findMatchingCountry(try_country)
          if countries.length == 1
            country = countries[0]
          elsif countries.length > 1
            i = 0
            countries.each do |co|
              i += 1
              puts "  #{i}.\t#{co}"
            end
            country = askFromList("Enter index", countries, nil)
          else
            puts "** No country matches found. Try something else!"
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
                puts "  #{i}.\t#{st}"
              end
              state = askFromList("Enter index", states, nil)
            else
              puts "** No state matches found. Try something else!"
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

  def askFromList(string, choices, default, trailing_dash_allowed = false)
    # Ask for an item from a list. We accept either a number or word.

    try_again = true
    while try_again
      begin
        answer = ask(string, default)
        # empty response returns default
        if not answer
          return default
        end
        # exceeding choices
        if answer.to_i > choices.length
          puts "** That index is beyond the list. Try to match id."
          # fall through to text pattern matching
        # numerical answer not validated, multiple not allowed
        elsif answer.to_i > 0
          return choices[answer.to_i - 1]
        end
        # validate text answer(s)
        answer.gsub!(/, */, '|')
        try_again = false
        answer = answer.split($delimiters).map{ |try_answer|
          # build a list of matches: 0 means invalid, 1 is perfect, 2 ambiguous
          # for cacheTypes, we allow trailing dashes (inverse filtering)
          if trailing_dash_allowed
            try_answer_nodash = try_answer.gsub(/-$/, '')
          else
            try_answer_nodash = try_answer
          end
          # check for match
          matches = choices.map{ |e| (e =~ Regexp.compile('^'+try_answer_nodash)) ? e : nil }.compact
          if matches.length == 0
            puts "** \"#{try_answer}\" is invalid!"
            try_again = true
            nil
          elsif  matches.length == 1
            # if needed, re-add dash
            (trailing_dash_allowed and (try_answer =~ /-$/)) ? matches[0]+'-' : matches[0]
          else
            puts "** \"#{try_answer_nodash}\" is ambiguous! Matches: #{matches.join(', ')}"
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
