class Input
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

        return @optHash
    end

    def interactive
        # ask questions.
    end
end

