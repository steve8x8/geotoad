#!/usr/bin/ruby
# $Id$
$LOAD_PATH << (File.dirname(__FILE__.gsub(/\\/, '/')) + '/' + '..')
$LOAD_PATH << (File.dirname(__FILE__.gsub(/\\/, '/')) + '/' + '../lib')

require 'yaml'
require 'bishop'
fun = YAML::load(File.open('fun.txt'))
boring = YAML::load(File.open('boring.txt'))

$grade = Bishop::Bayes.new	
good_comments = 0
bad_comments = 0

def calculateBaseScore(str)
  good = $grade.guess(str)[1][1] * 100
  bad = $grade.guess(str)[0][1] * 100
  return ((good * $good_adjustment) - bad)
end

def average(list)
  list.inject(0.0) { |sum, el| sum + el } / list.size
end

fun.each_key { |key| 
  fun[key]['comments'].each do |comment|
    if comment && comment.length > 4
      good_comments += 1
      #puts "training good on: [#{comment}]"
      $grade.train("good", comment)
    end
  end
}

boring.each_key { |key| 
  boring[key]['comments'].each do |comment|
    if comment && comment.length > 4
      #puts "training bad on: [#{comment}]"
      bad_comments += 1
      $grade.train("bad", comment)
    end
  end
}


$good_adjustment = bad_comments.to_f / good_comments.to_f
puts "BASE ADJUSTMENT: #{$good_adjustment} (g=#{good_comments} b=#{bad_comments})"

training = YAML::load(File.open('adjustment_training.txt'))
trained_scores = {}
training.each_key do |type|
  trained_scores[type] = []
  training[type].each do |comment|
    trained_scores[type] << calculateBaseScore(comment)
  end
end

trained_scores.each_key do |type|
  average = average(trained_scores[type])
  puts "#{type}: AVG=#{average} | #{trained_scores[type].join(', ')}"
end

bottom_end = average(trained_scores['boring'])
top_end = trained_scores['awesome'].max()
puts bottom_end
puts top_end
$grade.save("fun_or_not.txt")
