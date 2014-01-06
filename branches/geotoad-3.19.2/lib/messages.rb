# $Id$

# This is where code specific to the user interface display gets put.

module Messages

  def enableDebug(level = 1)
    $debugMode = level
  end

  def disableDebug
    $debugMode = 0
  end

  def debug(text, level = 1)
    puts "D: #{text}" if ($debugMode >= level)
  end

  def nodebug(text)
    # do nothing
  end

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
  def displayBar(len = 78)
    puts "-"*len
  end

  # display boxed text
  def displayBox(text, len = 78)
    puts "|  #{text.ljust(len-6)}  |"[0..(len-1)]
  end

  # fatal errors
  def displayError(text)
    abort("ERROR: #{text}")
  end
end
