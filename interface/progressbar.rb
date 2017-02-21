class ProgressBar

  def initialize(start, max, name)
    @value = 0
    @max = max
    @name = name
    display
  end

  def updateText(value, valueText)
    @value = value
    @valueText = valueText
    display
  end

  def display
    if (@max == 0)
      showMax = "?"
    else
      showMax = @max.to_s
    end

    # if the value is 0 or less, don't bother to print up a bar.
    return if @value.to_i <= 0

    # adjust the definition of metercols and meterchar to actual needs
    # number of columns
    metercols = 3
    # available character set, with increasing black density
    meterchar = ' .-+x*=%#'		# [0..7] for mini, [8] for full
    minichars = meterchar.length - 1	# 8
    if @value == @max
      meter = meterchar[-1, 1] * metercols
    else
      # map 0..100% to 0..24 different states
      percentage = (@value.to_f / @max.to_f) * metercols * minichars
      # divmod by 8 gives full thirds and remainder
      bardiv = percentage.divmod(minichars)
      fullbars = bardiv[0]
      minibars = bardiv[1]
      meter = meterchar[-1, 1] * fullbars + meterchar[minibars, 1]
      meter = meter.ljust(metercols)
    end

    pvalue = "#{@value}".rjust(@max.to_s.length)
    addtext = "#{@name}" + ((@name.empty?)?"":": ") + "#{@valueText}"
    puts "[#{meter}] (#{pvalue}/#{@max}) #{addtext}"
  end

end
