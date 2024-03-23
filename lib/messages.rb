# This is where code specific to the user interface display gets put.

module Messages

  def enableStderr
    $useStderr = 1
  end
  
  def enableDebug(level = 1)
    $debugMode = level
    debug "Debug level set to #{level}", 0
  end

  def disableDebug
    $debugMode = 0
  end

  def debug(text, level = 1)
    if $debugMode >= level
      if $useStderr
        $stderr.puts "D#{level}: #{text}"
      else
        puts "D#{level}: #{text}"
      end
    end
  end

  # only levels 0-3 are supported by TUI
  def debug0(text)  displayInfo(text) end
  def debug1(text)  debug text, 1     end
  def debug2(text)  debug text, 2     end
  def debug3(text)  debug text, 3     end
  def nodebug(text) debug text, 9     end

  # Text that's just fluff that can be ignored.
  def displayInfo(text)
    puts "( - ) #{text}"
    #$stderr.puts "I: #{text}" if $useStderr
  end

  # often worth displaying
  def displayTitle(text)
    puts "(===) #{text}"
  end

  # often worth displaying
  def displayMessage(text)
    puts "( o ) #{text}"
  end

  # mindless warnings
  def displayWarning(text)
    puts " ***  #{text}"
    $stderr.puts "W: #{text}" if $useStderr
  end

  # horizontal bar
  def displayBar(len = 79, char = "-")
    puts char * len
  end

  # display boxed text
  def displayBox(text, len = 79)
    if text.length <= (len - 4)
      # single-line output
      puts "| #{text.ljust(len - 4)} |"
    else
      # break into max two lines
      puts "| #{text[0 .. (len - 5)].ljust(len - 4)}>|"
      puts "|>#{text[(len - 4) .. -1].ljust(len - 4)} |"[0 .. (len - 1)]
    end
  end

  # graceful exit
  def displayExit(text0, rc = 0)
    text = text0.to_s.empty? ? "Terminating regularly" : text0
    #puts "DONE: #{text}"
    $stderr.puts "I: #{text} - rc #{rc}" if $useStderr
    exit(rc)
  end

  # fatal errors
  # error codes:
  #  1 = general
  #  2 = input parser
  #  3 = page progress
  #  4 = cache details
  #  5
  #  6
  #  7 = network connection lost
  #  8 = cookie lost
  #  9 = login data
  # 42 = special, feedback needed

  def displayError(text0, rc = 1)
    text = text0.to_s.empty? ? "Terminating on error" : text0
    #abort("ERROR: #{text}")
    puts "ERROR: #{text} - rc #{rc}"
    $stderr.puts "E: #{text} - rc #{rc}" if $useStderr
    exit(rc)
  end
end
