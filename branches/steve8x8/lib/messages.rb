# This is where code specific to the user interface display gets put.
#
# $HeadURL$
# $Id$

module Messages

  def enableDebug(level = 1)
    $debugMode = level
  end

  def disableDebug
    $debugMode = 0
  end

  def ndebug(level, text)
      if $debugMode >= level
        puts "[D-#{level}] #{text}"
      end
  end

  def debug(text)
    if $debugMode >= 1
      puts "[-D-] #{text}"
    end
  end

  # Text that's just fluff that can be ignored.
  def displayInfo(text)
    puts "( - ) #{text}"
  end

  # often worth displaying
  def displayTitleMessage(text)
    puts "( = ) #{text}"
  end

  # often worth displaying
  def displayMessage(text)
    puts "( o ) #{text}"
  end

  # mindless warnings
  def displayWarning(text)
    puts " ***  #{text}"
  end

  # fatal errors
  def displayError(text)
    abort("ERROR: #{text}")
  end
end
