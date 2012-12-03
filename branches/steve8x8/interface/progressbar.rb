# $Id$

class ProgressBar
  def initialize(start, max, name)
    @value = 0
    @max = max
    @name = name
    display
  end

  def update(value)
    @value = value
  end

  def setName(name)
    @name = name
  end

  def updateText(value, valueText)
    @value = value
    @valueText = valueText
    display
  end

  def setMax(value)
    @max = max
  end

  def display
    if (@max == 0)
      showMax = "?"
    else
      showMax = @max.to_s
    end

    # if the value is 0 or less, don't bother to print up a bar.
    if not @value or @value < 1
      return
    end

    # adjust the definition of metercols and meterchar to actual needs
    # number of columns
    metercols = 3
    # available character set, with increasing black density
    meterchar = ' .-+x*=%#'		# [0..7] for mini, [8] for full
    minichars = meterchar.length - 1	# 8
    if @value == @max
      meter = meterchar[-1,1] * metercols
    else
      # map 0..100% to 0..24 different states
      percentage = (@value.to_f / @max.to_f) * metercols * minichars
      # divmod by 8 gives full thirds and remainder
      bardiv = percentage.divmod(minichars)
      fullbars = bardiv[0]
      minibars = bardiv[1]
      #debug "#{percentage} -> #{fullbars}*full+#{minibars}"
      meter = meterchar[-1,1] * fullbars + meterchar[minibars,1]
      meter = meter.ljust(metercols)
    end

    pvalue = "#{@value}".rjust(@max.to_s.length)
    addtext = (@valueText)? ": #{@valueText}" : ""
    puts "[#{meter}] (#{pvalue}/#{@max}) #{@name}#{addtext}"
  end
end
