#!/usr/bin/env ruby
# $Id$

fun = YAML::load( File.open( 'good.txt' ) )
#boring = YAML::load( File.open( 'bad.txt' ) )

fun.each_key { |key| 
  puts key
}
