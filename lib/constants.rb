# -*- encoding : utf-8 -*-

module Constants

# Some constant tables.
# See country_state_list (which gets maintained by a separate script) for more.

$Attributes = {
      "attribute-blank"  =>  0,
      "dogs"             =>  1,
      "fee"              =>  2,
      "rappelling"       =>  3,
      "boat"             =>  4,
      "scuba"            =>  5,
      "kids"             =>  6,
      "onehour"          =>  7,
      "scenic"           =>  8,
      "hiking"           =>  9,
      "climbing"         => 10,
      "wading"           => 11,
      "swimming"         => 12,
      "available"        => 13,
      "night"            => 14,
      "winter"           => 15,
      "16"               => 16,
      "poisonoak"        => 17,
      "dangerousanimals" => 18,
      "ticks"            => 19,
      "mine"             => 20,
      "cliff"            => 21,
      "hunting"          => 22,
      "danger"           => 23,
      "wheelchair"       => 24,
      "parking"          => 25,
      "public"           => 26,
      "water"            => 27,
      "restrooms"        => 28,
      "phone"            => 29,
      "picnic"           => 30,
      "camping"          => 31,
      "bicycles"         => 32,
      "motorcycles"      => 33,
      "quads"            => 34,
      "jeeps"            => 35,
      "snowmobiles"      => 36,
      "horses"           => 37,
      "campfires"        => 38,
      "thorn"            => 39,
      "stealth"          => 40,
      "stroller"         => 41,
      "firstaid"         => 42,
      "cow"              => 43,
      "flashlight"       => 44,
      "landf"            => 45,
      "rv"               => 46,
      "field_puzzle"     => 47,
      "uv"               => 48,
      "snowshoes"        => 49,
      "skiis"            => 50,
      "s-tool"           => 51,
      "nightcache"       => 52,
      "parkngrab"        => 53,
      "abandonedbuilding"=> 54,
      "hike_short"       => 55,
      "hike_med"         => 56,
      "hike_long"        => 57,
      "fuel"             => 58,
      "food"             => 59,
      "wirelessbeacon"   => 60,
      "partnership"      => 61,
      "seasonal"         => 62,
      "touristok"        => 63,
      "treeclimbing"     => 64,
      "frontyard"        => 65,
      "teamwork"         => 66,
      "geotour"          => 67,
      "unknown68"        => 68,
      "bonuscache"       => 69,
      "powertrail"       => 70,
      "challengecache"   => 71,
      "hqsolutionchecker"=> 72,
      # obsolete?, but image still exists
      "snakes"           => 18,
      "sponsored"        => 61,
    }

$WptTypes = {
      217 => "Parking Area",
      218 => "Virtual Stage",
      219 => "Physical Stage",
      220 => "Final Location",
      221 => "Trailhead",
      452 => "Reference Point",
    }

# synced with c:geo 2020-07-02
$CacheTypes = {
	'2'	=> 'Traditional Cache',
	'3'	=> 'Multi-cache',
	'4'	=> 'Virtual Cache',
	'5'	=> 'Letterbox Hybrid',		# spelling? 'Letterbox hybrid'
	'6'	=> 'Event Cache',
	'8'	=> 'Unknown Cache',
	'9'	=> 'Project APE Cache',		# spelling? 'Project Ape Cache'
	'11'	=> 'Webcam Cache',
	'12'	=> 'Locationless (Reverse) Cache',
	'13'	=> 'Cache In Trash Out Event',
	'137'	=> 'EarthCache',		# spelling? 'Earthcache'
	'453'	=> 'Mega-Event Cache',
	'1304'	=> 'GPS Adventures Exhibit',
	'1858'	=> 'Wherigo Cache',
	#'3653'	=> 'Lost and Found Event Cache',
	'3653'	=> 'Community Celebration Event',
	#'3773'	=> 'Groundspeak HQ',
	'3773'	=> 'Geocaching HQ',
	#'3774'	=> 'Groundspeak Lost and Found Celebration',
	'3774'	=> 'Geocaching HQ Celebration',
	'4738'	=> 'Geocaching HQ Block Party',
	'7005'	=> 'Giga-Event Cache',
	'ape'		=> 'Project APE Cache',
	'block'		=> 'Geocaching HQ Block Party',
	'cito'		=> 'Cache In Trash Out Event',
	'communceleb'	=> 'Community Celebration Event',
	'earth'		=> 'EarthCache',
	'earthcache'	=> 'EarthCache',
	'event'		=> 'Event Cache',
	'gshq'		=> 'Geocaching HQ',
	'gchq'		=> 'Geocaching HQ',
	'gchqceleb'	=> 'Geocaching HQ Celebration',
	'giga'		=> 'Giga-Event Cache',
	'gps'		=> 'GPS Adventures Exhibit',
	'exhibit'	=> 'GPS Adventures Exhibit',
	'maze'		=> 'GPS Adventures Exhibit',
	'letterbox'	=> 'Letterbox Hybrid',
	'locationless'	=> 'Locationless (Reverse) Cache',
	'mega'		=> 'Mega-Event Cache',
	'multi'		=> 'Multi-cache',
	'traditional'	=> 'Traditional Cache',
	'unknown'	=> 'Unknown Cache',
	'mystery'	=> 'Unknown Cache',
	'virtual'	=> 'Virtual Cache',
	'webcam'	=> 'Webcam Cache',
	'wherigo'	=> 'Wherigo Cache',
    }

$CacheTypes_TX = {
	# commented-out types won't match post-filter
	# order taken from advanced search

	'all_cache'	=> '9a79e6ce-3344-409c-bbe9-496530baf758',
	'traditional'	=> '32bc9333-5e52-4957-b0f6-5a2c8fc7b257',
	'multicache'	=> 'a5f6d0ad-d2f2-4011-8c14-940a9ebf3c74',
	'multi'		=> 'a5f6d0ad-d2f2-4011-8c14-940a9ebf3c74',
	'virtual'	=> '294d4360-ac86-4c83-84dd-8113ef678d7e',
	'letterbox'	=> '4bdd8fb2-d7bc-453f-a9c5-968563b15d24',

	# "-parent" doesn't work with "tx="
#	'all_event'	=> '69eb8534-b718-4b35-ae3c-a856a55b0874-parent&children=y',
	'all_event'	=> '69eb8534-b718-4b35-ae3c-a856a55b0874&children=y',
#	'event+'	=> '69eb8534-b718-4b35-ae3c-a856a55b0874-parent&children=y', # all event types, as listed below
	'event+'	=> '69eb8534-b718-4b35-ae3c-a856a55b0874&children=y', # all event types, as listed below
	'event'		=> '69eb8534-b718-4b35-ae3c-a856a55b0874',
	'cito'		=> '57150806-bc1a-42d6-9cf0-538d171a2d22',
	'megaevent'	=> '69eb8535-b718-4b35-ae3c-a856a55b0874',
	'mega'		=> '69eb8535-b718-4b35-ae3c-a856a55b0874', #X
	'communceleb'	=> '3ea6533d-bb52-42fe-b2d2-79a3424d4728',
	'commceleb'	=> '3ea6533d-bb52-42fe-b2d2-79a3424d4728', #X
	'lost+found'	=> '3ea6533d-bb52-42fe-b2d2-79a3424d4728', #X
	'gchqceleb'	=> 'af820035-787a-47af-b52b-becc8b0c0c88',
	'hqceleb'	=> 'af820035-787a-47af-b52b-becc8b0c0c88', #X
	'lfceleb'	=> 'af820035-787a-47af-b52b-becc8b0c0c88', #X
	'block'		=> 'bc2f3df2-1aab-4601-b2ff-b5091f6c02e3',
	'gigaevent'	=> '51420629-5739-4945-8bdd-ccfd434c0ead',
	'giga'		=> '51420629-5739-4945-8bdd-ccfd434c0ead', #X

#	'all_unknown'	=> '40861821-1835-4e11-b666-8d41064d03fe-parent&children=y',
	'all_unknown'	=> '40861821-1835-4e11-b666-8d41064d03fe&children=y',
#	'unknown+'	=> '40861821-1835-4e11-b666-8d41064d03fe-parent&children=y', # all unknown types
	'unknown+'	=> '40861821-1835-4e11-b666-8d41064d03fe&children=y', # all unknown types
#	'mystery+'	=> '40861821-1835-4e11-b666-8d41064d03fe-parent&children=y', #X
	'mystery+'	=> '40861821-1835-4e11-b666-8d41064d03fe&children=y', #X
	'unknown'	=> '40861821-1835-4e11-b666-8d41064d03fe',
	'mystery'	=> '40861821-1835-4e11-b666-8d41064d03fe', #X
	'gshq'		=> '416f2494-dc17-4b6a-9bab-1a29dd292d8c',
	'gchq'		=> '416f2494-dc17-4b6a-9bab-1a29dd292d8c', #X
	'ape'		=> '2555690d-b2bc-4b55-b5ac-0cb704c0b768',

	'webcam'	=> '31d2ae3c-c358-4b5f-8dcd-2185bf472d3d',
	'earthcache'	=> 'c66f5cf3-9523-4549-b8dd-759cd2f18db8',
	'earth'		=> 'c66f5cf3-9523-4549-b8dd-759cd2f18db8',
	'gps'		=> '72e69af2-7986-4990-afd9-bc16cbbb4ce3',
	'exhibit'	=> '72e69af2-7986-4990-afd9-bc16cbbb4ce3', #X
	'wherigo'	=> '0544fa55-772d-4e5c-96a9-36a51ebcf5c9',

	'locationless'	=> '8f6dd7bc-ff39-4997-bd2e-225a0d2adf9d', #X?
	'reverse'	=> '8f6dd7bc-ff39-4997-bd2e-225a0d2adf9d', #X?
    }

$Sizes = {
    # order by cache sizes
    # sizes not in this list get mapped to 'nil' (and 0)
    # 'unspecified/not applicable' (becoming obsolete)
    'virtual' => 0,
    # events, earthcaches, citos are kind of virtual too
    'not chosen' => 0, #X
    'not_chosen' => 0,
    # 'other' here means 'nano' (nacro, bison, ...) mostly
    'other' => 1,
    'micro'   => 2,
    'small' => 3,
    'regular' => 4,
    'medium' => 4, #X
    'large' => 5
  }

end
