# This is where code specific to the user interface display gets put.

module Messages

  def enableDebug(level = 1)
    $debugMode = level
    debug "Debug level set to #{level}"
  end

  def disableDebug
    $debugMode = 0
  end

  def debug(text, level = 1)
    puts "D#{level}: #{text}" if ($debugMode >= level)
  end

  # only levels 0-3 are supported by TUI
  def debug0(text) displayInfo(text) end
  def debug1(text) debug text, 1 end
  def debug2(text) debug text, 2 end
  def debug3(text) debug text, 3 end
  def nodebug(text) debug text, 9 end

  # Text that's just fluff that can be ignored.
  def displayInfo(text)
    puts "( - ) #{text}"
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

  # fatal errors
  def displayError(text, rc = 1)
    # 2018-03-03: write to stdout, not stderr, but set returncode
    if text.to_s.empty?
      #abort("")
      puts "ERROR: terminating - rc #{rc}"
    else
      #abort("ERROR: #{text}")
      puts "ERROR: #{text} - rc #{rc}"
    end
    exit rc
  end
end
