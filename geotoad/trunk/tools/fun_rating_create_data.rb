#!/usr/bin/ruby
# $Id$

require 'rubygems'
require 'yaml'
require 'bishop'
fun = YAML::load( File.open( 'fun.txt' ) )
boring = YAML::load( File.open( 'boring.txt' ) )

$grade = Bishop::Bayes.new	

fun.each_key { |key| 
	fun[key]['comments'].each do |comment|
		if comment && comment.length > 4
			#puts "training good on: [#{comment}]"
			$grade.train("good", comment)
		end
	end
}

boring.each_key { |key| 
	boring[key]['comments'].each do |comment|
		if comment && comment.length > 4
			#puts "training bad on: [#{comment}]"
			$grade.train("bad", comment)
		end
	end
}

def test(str)
	good = $grade.guess(str)[1][1] * 100
	bad = $grade.guess(str)[0][1] * 100
	score = (good - bad)
	scoreText = "Average"
	if score > 10
		scoreText = "Good"
	end
	if score > 28
		scoreText = "Very Good"
	end
	if score < -10 
		scoreText = "Dull"
	end
	if score < -20
		scoreText = "Very Dull"
	end
	printf("%10.10s (%3.2f, g=%2.2f b=%2.2f): %s\n", scoreText, score,  good, bad, str)
end


test("Found on an all night cache run through the area. TFTC")
test("This was an interesting event in our caching history. While searching for Stage one, a police man pulled up and asked us, Did you steal that candy machineThen he asked, Did you break into that store? Apparently someone had broken into an abandoned grocery store, stolen the candy machine, broke it open in the woods next to Stage one, and took all the loose change in the machine. After proclaiming our innocence, the officer asked us what we were doing. We introduced him to geocaching and then began chatting about GPS receivers for quite awhile. It was very interesting. We finally got back to Stage one, found the clue, and made our way to the final cache. We signed the log, and walked back down to our car. This was our eighth of eight caches today. Thanks for the adventure.")
test("The Team from Tennesse came to see just how high the water was in NC. At times it was almost to high and at times we almost got into hot water. At one point, a bolt of lightning came down from above to add to the fear factor. Team work prevailed and the mission was completed. Thanks for taking the time to plan this out so well.")
test("There was another cache near here that I never did find..... Got this one pretty quick during a beautiful drive in the mountains. TNLNSL - TFTH")
test("Walked right up to this one. I think you should change the name because it is appropriate. TFTH")
test("There are awesome views from nearby this well placed cache. This mtn. is very steep and this cache deserves it's rating.. TNLN.. TFTC MXCR")
test("Whew, what a hike. That last .8 of a mile was a killer. I am from Florida, I am not used to having to climb hills. But boy was it worth the pay off in the end. What a spectacular view. Has to be one of the best around. Had no problem finding the cache, and it is still in good shape. I only left a log in the log book, but I did sharpen the cache pencils, they needed it pretty badly. Thanks for the great view.")
test("Now this is what caching is about. What a blast. There was ice everywhere today.....it made the granite walls a bit challenging. At some points on the ice AdventureChick had to employ her trademarked Butt scoot. As a personal aside Smoothjazz, your log entries are side splitting The cache was in great shape. If you are reading this wondering if you should do it......Do it, you will love it. Just don't look at Allen's elevation profile")
test("I found this one this morning without a GPS! Mapped the location of the cache out last night, figured how far along 107 the drive from Cashiers was going to be. Found first stop easily. Then used math to approximate where the cache was; found a likely spot and got lucky! TNSL, left four magnets (that could be used to hold up pictures on the fridge). TFTC! (FTF!)")
test("Visited this cache to leave B's Bunny TB. Took nothing. Signed Log")
test("Found 8/23 while on vacation. Thanks for the hunt.")
test("Made the stop here so I could enjoy the view of the river. Finally found the cache and Mongo and I were on to the next one.")
test("This was a fun one! Had to be careful, though. There were a few people around. Found with chcknlittle")
test("Ooh, you are a tricksy one OG. We stood there looking at it for a moment, asking ourselves if that could possibly be right. ")
test("After parking at the recommended coodinates, Atrus and walked up to what we thought was the correct clearing and turned at restrooms and found a primitive trail. Well, it seems we had the “wrong” clearing and the “wrong” primitive trail. However, we did find out way to the falls and ultimately to the cache. They are really beautiful falls and worth the trip, but there “Ain’t No Way” I care to do it again!")
test("Found at 12:50 SL tnln tftc my gps was off over a 100 feet.")
test("Took my three nieces and nephew to find this but it wasn't there. My son and I found this one before, but it's no longer in the same spot. I think someone may have taken it.")
test("I found this one with my family after running some errands in Monterey. I left an orange and white marble and took the Halloween geocoin. Prunedale, CA")
$grade.save("fun_scores.dat")

puts "enter your own:"
while (1) do
	print "> "
	text = $stdin.gets
	test(text)
end
