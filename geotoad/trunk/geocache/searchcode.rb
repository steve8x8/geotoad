class SearchCode < Common

# output from tools/countryrip.rb
$idHash = Hash.new
$idHash['state_id'] = Hash.new
$idHash['state_id']['Alabama']=60
$idHash['state_id']['Alaska']=2
$idHash['state_id']['Arizona']=3
$idHash['state_id']['Arkansas']=4
$idHash['state_id']['California']=5
$idHash['state_id']['Colorado']=6
$idHash['state_id']['Connecticut']=7
$idHash['state_id']['Delaware']=9
$idHash['state_id']['District of Columbia']=8
$idHash['state_id']['Florida']=10
$idHash['state_id']['Georgia']=11
$idHash['state_id']['Hawaii']=12
$idHash['state_id']['Idaho']=13
$idHash['state_id']['Illinois']=14
$idHash['state_id']['Indiana']=15
$idHash['state_id']['Iowa']=16
$idHash['state_id']['Kansas']=17
$idHash['state_id']['Kentucky']=18
$idHash['state_id']['Louisiana']=19
$idHash['state_id']['Maine']=20
$idHash['state_id']['Maryland']=21
$idHash['state_id']['Massachusetts']=22
$idHash['state_id']['Michigan']=23
$idHash['state_id']['Minnesota']=24
$idHash['state_id']['Mississippi']=25
$idHash['state_id']['Missouri']=26
$idHash['state_id']['Montana']=27
$idHash['state_id']['Nebraska']=28
$idHash['state_id']['Nevada']=29
$idHash['state_id']['New Hampshire']=30
$idHash['state_id']['New Jersey']=31
$idHash['state_id']['New Mexico']=32
$idHash['state_id']['New York']=33
$idHash['state_id']['North Carolina']=34                                                                             
$idHash['state_id']['North Dakota']=35
$idHash['state_id']['Ohio']=36
$idHash['state_id']['Oklahoma']=37
$idHash['state_id']['Oregon']=38
$idHash['state_id']['Pennsylvania']=39
$idHash['state_id']['Rhode Island']=40
$idHash['state_id']['South Carolina']=41
$idHash['state_id']['South Dakota']=42
$idHash['state_id']['Tennessee']=43
$idHash['state_id']['Texas']=44
$idHash['state_id']['Utah']=45
$idHash['state_id']['Vermont']=46
$idHash['state_id']['Virginia']=47
$idHash['state_id']['Washington']=48
$idHash['state_id']['West Virginia']=49
$idHash['state_id']['Wisconsin']=50
$idHash['state_id']['Wyoming']=51

$idHash['country_id'] = Hash.new
$idHash['country_id']['Andorra']=16
$idHash['country_id']['Antarctica']=18
$idHash['country_id']['Antigua and Barbuda']=13
$idHash['country_id']['Argentina']=19
$idHash['country_id']['Aruba']=20
$idHash['country_id']['Australia']=3
$idHash['country_id']['Austria']=227
$idHash['country_id']['Azerbaijan']=21
$idHash['country_id']['Bahamas']=23
$idHash['country_id']['Barbados']=25
$idHash['country_id']['Belgium']=4
$idHash['country_id']['Belize']=31
$idHash['country_id']['Bermuda']=27
$idHash['country_id']['Bolivia']=32
$idHash['country_id']['Bosnia and Herzegovina']=234
$idHash['country_id']['Botswana']=33
$idHash['country_id']['Brazil']=34
$idHash['country_id']['British Virgin Islands']=39
$idHash['country_id']['Bulgaria']=37
$idHash['country_id']['Cambodia']=42
$idHash['country_id']['Canada']=5
$idHash['country_id']['Cape Verde']=239
$idHash['country_id']['Cayman Islands']=44
$idHash['country_id']['Chile']=6
$idHash['country_id']['China']=47
$idHash['country_id']['Colombia']=49
$idHash['country_id']['Cook Islands']=48
$idHash['country_id']['Costa Rica']=52
$idHash['country_id']['Croatia']=53
$idHash['country_id']['Cuba']=238
$idHash['country_id']['Cyprus']=55
$idHash['country_id']['Czech Republic']=56
$idHash['country_id']['Denmark']=57
$idHash['country_id']['Dominica']=59
$idHash['country_id']['Dominican Republic']=60
$idHash['country_id']['Ecuador']=61
$idHash['country_id']['Egypt']=63
$idHash['country_id']['El Salvador']=64
$idHash['country_id']['Estonia']=66
$idHash['country_id']['Ethiopia']=67
$idHash['country_id']['Fiji']=71
$idHash['country_id']['Finland']=72
$idHash['country_id']['France']=73
$idHash['country_id']['French Guiana']=70
$idHash['country_id']['French Polynesia']=74
$idHash['country_id']['Germany']=79
$idHash['country_id']['Gibraltar']=80
$idHash['country_id']['Greece']=82
$idHash['country_id']['Greenland']=83
$idHash['country_id']['Grenada']=81
$idHash['country_id']['Guadeloupe']=77
$idHash['country_id']['Guam']=229
$idHash['country_id']['Guatemala']=84
$idHash['country_id']['Guernsey']=86
$idHash['country_id']['Haiti']=89
$idHash['country_id']['Honduras']=90
$idHash['country_id']['Hong Kong']=91
$idHash['country_id']['Hungary']=92
$idHash['country_id']['Iceland']=93
$idHash['country_id']['India']=94
$idHash['country_id']['Indonesia']=95
$idHash['country_id']['Ireland']=7
$idHash['country_id']['Israel']=98
$idHash['country_id']['Italy']=99
$idHash['country_id']['Jamaica']=101
$idHash['country_id']['Japan']=104
$idHash['country_id']['Jordan']=103
$idHash['country_id']['Kazakhstan']=106
$idHash['country_id']['Kenya']=107
$idHash['country_id']['Kiribati']=109
$idHash['country_id']['Kuwait']=241
$idHash['country_id']['Kyrgyzstan']=108
$idHash['country_id']['Laos']=110
$idHash['country_id']['Latvia']=111
$idHash['country_id']['Lebanon']=113
$idHash['country_id']['Liberia']=115
$idHash['country_id']['Libya']=112
$idHash['country_id']['Liechtenstein']=116
$idHash['country_id']['Lithuania']=117
$idHash['country_id']['Luxembourg']=8
$idHash['country_id']['Macedonia']=125
$idHash['country_id']['Malaysia']=121
$idHash['country_id']['Maldives']=124
$idHash['country_id']['Mali']=127
$idHash['country_id']['Malta']=128
$idHash['country_id']['Marshall Islands']=240
$idHash['country_id']['Martinique']=122
$idHash['country_id']['Mauritius']=134
$idHash['country_id']['Mexico']=228
$idHash['country_id']['Micronesia']=242
$idHash['country_id']['Monaco']=130
$idHash['country_id']['Mongolia']=131
$idHash['country_id']['Morocco']=132
$idHash['country_id']['Namibia']=137
$idHash['country_id']['Nepal']=140
$idHash['country_id']['Netherlands']=141
$idHash['country_id']['Netherlands Antilles']=148
$idHash['country_id']['Nevis and St Kitts']=142
$idHash['country_id']['New Zealand']=9
$idHash['country_id']['Nigeria']=145
$idHash['country_id']['Niue']=149
$idHash['country_id']['Norfolk Island']=260
$idHash['country_id']['Northern Mariana Islands']=236
$idHash['country_id']['Norway']=147
$idHash['country_id']['Oman']=150
$idHash['country_id']['Panama']=152
$idHash['country_id']['Papua New Guinea']=156
$idHash['country_id']['Peru']=153
$idHash['country_id']['Philippines']=154
$idHash['country_id']['Poland']=158
$idHash['country_id']['Portugal']=159
$idHash['country_id']['Puerto Rico']=226
$idHash['country_id']['Reunion']=161
$idHash['country_id']['Romania']=162
$idHash['country_id']['Russia']=163
$idHash['country_id']['Saint Lucia']=173
$idHash['country_id']['Saudi Arabia']=166
$idHash['country_id']['Senegal']=167
$idHash['country_id']['Seychelles']=168
$idHash['country_id']['Sierra Leone']=178
$idHash['country_id']['Singapore']=179
$idHash['country_id']['Slovakia']=182
$idHash['country_id']['Slovenia']=181
$idHash['country_id']['South Africa']=165
$idHash['country_id']['South Korea']=180
$idHash['country_id']['Spain']=186
$idHash['country_id']['Sri Lanka']=187
$idHash['country_id']['St Barthelemy']=169
$idHash['country_id']['St Marten']=174
$idHash['country_id']['St Vince Grenadines']=177
$idHash['country_id']['Suriname']=189
$idHash['country_id']['Swaziland']=190
$idHash['country_id']['Sweden']=10
$idHash['country_id']['Switzerland']=192
$idHash['country_id']['Syria']=193
$idHash['country_id']['Taiwan']=194
$idHash['country_id']['Tanzania']=196
$idHash['country_id']['Thailand']=198
$idHash['country_id']['Tonga']=201
$idHash['country_id']['Trinidad and Tobago']=202
$idHash['country_id']['Tunisia']=203
$idHash['country_id']['Turkey']=204
$idHash['country_id']['Turks and Caicos Islands']=197
$idHash['country_id']['Uganda']=208
$idHash['country_id']['Ukraine']=207
$idHash['country_id']['United Arab Emirites']=206
$idHash['country_id']['United Kingdom']=11
$idHash['country_id']['Uruguay']=210
$idHash['country_id']['US Virgin Islands']=235
$idHash['country_id']['Venezuela']=214
$idHash['country_id']['Vietnam']=215
$idHash['country_id']['Western Somoa ISL']=219
$idHash['country_id']['Yugoslavia']=222
$idHash['country_id']['Zimbabwe']=225


# some manual overrides
$idHash['country_id']['Britain']=11

$idHash['zip']=0

def initialize (type)
    if (type == "state")
        type="state_id"
    end
    
    if (type == "country")
        type="country_id"
    end
    
    if (type == "zipcode")
        type="zip"
    end
    
    if (! $idHash[type])
        puts "* Invalid search type: #{type} (using state_id)"
        type="state_id"
    end
    
    debug "set type to #{type}"
    @lookupType=type
end

def type
    return @lookupType
end

def lookup (key)
    # it's already a digit, stupid.
    if (key.to_i > 0)
        return key
    end

    id = $idHash[@lookupType][key] || nil
    debug "looked up #{key} - #{id}"
    return id
end

end

