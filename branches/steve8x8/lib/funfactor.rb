#!/usr/bin/env ruby
#
# So, is the cache any good or not?

# $Id$
$LOAD_PATH << (File.dirname(__FILE__.gsub(/\\/, '/')) + '/' + '..')
$LOAD_PATH << (File.dirname(__FILE__.gsub(/\\/, '/')) + '/' + '../lib')

require 'yaml'
require 'bishop'
require 'common'

def average(list)
  list.inject(0.0) { |sum, el| sum + el } / list.size
end

class FunFactor
  include Common
  
  def initialize()
    @data_dir = findDataDir()
    @bishop = Bishop::Bayes.new
    @good_skew = 1
    @adjusted_min = nil
    @adjusted_max = nil
    @adjusted_mid = nil
  end

  def load_training_files()
    # TODO(helixblue): Remove this hardcoded madness
    fun = YAML::load(File.open("#{@data_dir}/funfactor_training_fun.txt"))
    boring = YAML::load(File.open("#{@data_dir}/funfactor_training_boring.txt"))

    good_comments = process_training_material(fun, 'good')
    bad_comments = process_training_material(boring, 'bad')
    return [good_comments, bad_comments]
  end

  def calculate_base_score(str, good_skew=nil)
    if not good_skew
      good_skew = @good_skew
    end
    good = @bishop.guess(str)[1][1] * 100
    bad = @bishop.guess(str)[0][1] * 100
    return ((good * good_skew) - bad)
  end

  def calculate_score_from_list(list)
    scores = []
    list.each {|str|
      # It may be that we are unable to gather any score from the string
      begin
        scores << calculate_score(str)
      rescue
      end
    }
    avg_score = average(scores)
    return avg_score
  end

  def calculate_score(str)
    base_score = calculate_base_score(str)
    if not @adjusted_min or not @adjusted_max
      return base_score
    end

    if base_score < @adjusted_min
      return 0
    elsif base_score > @adjusted_max
      return 5
    elsif base_score > @adjusted_mid
      return 2.5 + ((2.5 / (@adjusted_max - @adjusted_mid)) * (base_score - @adjusted_mid))
    else
      return ((2.5 / (@adjusted_mid - @adjusted_min)) * (base_score - @adjusted_min))
    end
  end

  def process_training_material(data, name)
    # data is a dictionary containing comment fields
    comments_parsed = 0
    data.each_key { |key|
      data[key]['comments'].each do |comment|
        if comment && comment.length > 4
          comments_parsed += 1
          @bishop.train(name, comment)
        end
      end
    }
    return comments_parsed
  end

  def load_scores()
    @bishop.load("#{@data_dir}/funfactor.txt")
  end

  def save_scores()
    @bishop.save("#{@data_dir}/funfactor.txt")
  end

  def load_adjustments()
    adjustments = YAML.load(open("#{@data_dir}/funfactor_adjustment.txt"))
    @good_skew = adjustments['good_skew']
    @adjusted_max = adjustments['max']
    @adjusted_min = adjustments['min']
    @adjusted_mid = adjustments['mid']
  end

  def calculate_adjustments()
    good_comments, bad_comments = load_training_files()
    good_skew = bad_comments.to_f / good_comments.to_f

    training = YAML::load(File.open("#{@data_dir}/adjustment_training.txt"))
    trained_scores = {}
    training.each_key do |type|
      trained_scores[type] = []
      training[type].each do |comment|
        trained_scores[type] << calculate_base_score(comment, good_skew)
      end
    end

    trained_scores.each_key do |type|
      average = average(trained_scores[type])
    end

    bottom_end = average(trained_scores['boring'])
    top_end = trained_scores['awesome'].max()

    adjustments = {
      'max' => trained_scores['awesome'].max(),
      'mid' => average(trained_scores['good']),
      'min' => average(trained_scores['boring']),
      'good_skew' => good_skew
    }
    puts "Writing: #{adjustments}"
    f = File.open("#{@data_dir}/funfactor_adjustment.txt", "w")
    f.puts adjustments.to_yaml
    f.close
  end

end

if __FILE__ == $0
  #f = FunFactor.new()
  #f.calculate_adjustments()
  #f.save_scores()

  f2 = FunFactor.new()
  f2.load_scores()
  f2.load_adjustments()
  puts f2.calculate_score("Park and grab.")
  puts f2.calculate_score("It was awesome!")

  puts f2.calculate_score_from_list(["good", "bad", "parked"])
  puts f2.calculate_score_from_list(["wolves", "snakes", "waterfall"])
end

