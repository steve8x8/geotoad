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
    if (@value < 1)
      return
    end
        
    percentage = (@value.to_f / @max.to_f) * 100
    bardiv = percentage.divmod(33.333333333333333333333333333333333333)
        
    fullbars = bardiv[0]
    minibars = bardiv[1] / (16.66666666666666666666666666667).round
    # "p=#{percentage} f=#{fullbars} m=#{minibars}"
    meter = "=" * fullbars + "-" * minibars
    meter = meter.ljust(3)
        
    if (@valueText)
      puts "[#{meter}] (#{@value}/#{@max}) #{@name}: #{@valueText}"
    else
      puts "[#{meter}] (#{@value}/#{@max}) #{@name}"
    end
  end
end
