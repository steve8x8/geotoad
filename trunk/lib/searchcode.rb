# $Id$

class SearchCode
  include Common
  include Messages
    
  # output from tools/countryrip.rb
  $idHash = Hash.new
  $idHash['state_id'] = Hash.new
  $idHash['state_id']['alabama']=60
  $idHash['state_id']['alaska']=2
  $idHash['state_id']['arizona']=3
  $idHash['state_id']['arkansas']=4
  $idHash['state_id']['california']=5
  $idHash['state_id']['colorado']=6
  $idHash['state_id']['connecticut']=7
  $idHash['state_id']['delaware']=9
  $idHash['state_id']['district of columbia']=8
  $idHash['state_id']['florida']=10
  $idHash['state_id']['georgia']=11
  $idHash['state_id']['hawaii']=12
  $idHash['state_id']['idaho']=13
  $idHash['state_id']['illinois']=14
  $idHash['state_id']['indiana']=15
  $idHash['state_id']['iowa']=16
  $idHash['state_id']['kansas']=17
  $idHash['state_id']['kentucky']=18
  $idHash['state_id']['louisiana']=19
  $idHash['state_id']['maine']=20
  $idHash['state_id']['maryland']=21
  $idHash['state_id']['massachusetts']=22
  $idHash['state_id']['michigan']=23
  $idHash['state_id']['minnesota']=24
  $idHash['state_id']['mississippi']=25
  $idHash['state_id']['missouri']=26
  $idHash['state_id']['montana']=27
  $idHash['state_id']['nebraska']=28
  $idHash['state_id']['nevada']=29
  $idHash['state_id']['new hampshire']=30
  $idHash['state_id']['new jersey']=31
  $idHash['state_id']['new mexico']=32
  $idHash['state_id']['new york']=33
  $idHash['state_id']['north carolina']=34
  $idHash['state_id']['north dakota']=35
  $idHash['state_id']['ohio']=36
  $idHash['state_id']['oklahoma']=37
  $idHash['state_id']['oregon']=38
  $idHash['state_id']['pennsylvania']=39
  $idHash['state_id']['rhode island']=40
  $idHash['state_id']['south carolina']=41
  $idHash['state_id']['south dakota']=42
  $idHash['state_id']['tennessee']=43
  $idHash['state_id']['texas']=44
  $idHash['state_id']['utah']=45
  $idHash['state_id']['vermont']=46
  $idHash['state_id']['virginia']=47
  $idHash['state_id']['washington']=48
  $idHash['state_id']['west virginia']=49
  $idHash['state_id']['wisconsin']=50
  $idHash['state_id']['wyoming']=51

  $idHash['country_id'] = Hash.new
  $idHash['country_id']['afghanistan']=12
  $idHash['country_id']['aland islands']=272
  $idHash['country_id']['albania']=244
  $idHash['country_id']['algeria']=14
  $idHash['country_id']['american samoa']=245
  $idHash['country_id']['andorra']=16
  $idHash['country_id']['angola']=17
  $idHash['country_id']['anguilla']=246
  $idHash['country_id']['antarctica']=18
  $idHash['country_id']['antigua and barbuda']=13
  $idHash['country_id']['argentina']=19
  $idHash['country_id']['armenia']=15
  $idHash['country_id']['aruba']=20
  $idHash['country_id']['australia']=3
  $idHash['country_id']['austria']=227
  $idHash['country_id']['azerbaijan']=21
  $idHash['country_id']['bahamas']=23
  $idHash['country_id']['bahrain']=29
  $idHash['country_id']['bangladesh']=24
  $idHash['country_id']['barbados']=25
  $idHash['country_id']['belarus']=40
  $idHash['country_id']['belgium']=4
  $idHash['country_id']['belize']=31
  $idHash['country_id']['benin']=26
  $idHash['country_id']['bermuda']=27
  $idHash['country_id']['bhutan']=30
  $idHash['country_id']['bolivia']=32
  $idHash['country_id']['bonaire']=275
  $idHash['country_id']['bosnia and herzegovina']=234
  $idHash['country_id']['botswana']=33
  $idHash['country_id']['bouvet island']=247
  $idHash['country_id']['brazil']=34
  $idHash['country_id']['british indian ocean territories']=248
  $idHash['country_id']['british virgin islands']=39
  $idHash['country_id']['brunei']=36
  $idHash['country_id']['bulgaria']=37
  $idHash['country_id']['burkina faso']=216
  $idHash['country_id']['burundi']=35
  $idHash['country_id']['burxina']=28
  $idHash['country_id']['cambodia']=42
  $idHash['country_id']['cameroon']=43
  $idHash['country_id']['canada']=5
  $idHash['country_id']['cape verde']=239
  $idHash['country_id']['cayman islands']=44
  $idHash['country_id']['central african republic']=46
  $idHash['country_id']['chad']=249
  $idHash['country_id']['chile']=6
  $idHash['country_id']['china']=47
  $idHash['country_id']['christmas island']=250
  $idHash['country_id']['cocos (keeling) islands']=251
  $idHash['country_id']['colombia']=49
  $idHash['country_id']['comoros']=50
  $idHash['country_id']['congo']=51
  $idHash['country_id']['cook islands']=48
  $idHash['country_id']['costa rica']=52
  $idHash['country_id']['croatia']=53
  $idHash['country_id']['cuba']=238
  $idHash['country_id']['curacao']=54
  $idHash['country_id']['cyprus']=55
  $idHash['country_id']['czech republic']=56
  $idHash['country_id']['democratic republic of the congo']=257
  $idHash['country_id']['denmark']=57
  $idHash['country_id']['djibouti']=58
  $idHash['country_id']['dominica']=59
  $idHash['country_id']['dominican republic']=60
  $idHash['country_id']['east timor']=252
  $idHash['country_id']['ecuador']=61
  $idHash['country_id']['egypt']=63
  $idHash['country_id']['el salvador']=64
  $idHash['country_id']['equatorial guinea']=62
  $idHash['country_id']['eritrea']=65
  $idHash['country_id']['estonia']=66
  $idHash['country_id']['ethiopia']=67
  $idHash['country_id']['falkland islands']=69
  $idHash['country_id']['faroe islands']=68
  $idHash['country_id']['fiji']=71
  $idHash['country_id']['finland']=72
  $idHash['country_id']['france']=73
  $idHash['country_id']['french guiana']=70
  $idHash['country_id']['french polynesia']=74
  $idHash['country_id']['french southern territories']=253
  $idHash['country_id']['gabon']=75
  $idHash['country_id']['gambia']=76
  $idHash['country_id']['georgia']=78
  $idHash['country_id']['germany']=79
  $idHash['country_id']['ghana']=254
  $idHash['country_id']['gibraltar']=80
  $idHash['country_id']['greece']=82
  $idHash['country_id']['greenland']=83
  $idHash['country_id']['grenada']=81
  $idHash['country_id']['guadeloupe']=77
  $idHash['country_id']['guam']=229
  $idHash['country_id']['guatemala']=84
  $idHash['country_id']['guernsey']=86
  $idHash['country_id']['guinea']=255
  $idHash['country_id']['guinea-bissau']=85
  $idHash['country_id']['guyana']=87
  $idHash['country_id']['haiti']=89
  $idHash['country_id']['heard island and mcdonald islands']=256
  $idHash['country_id']['honduras']=90
  $idHash['country_id']['hong kong']=91
  $idHash['country_id']['hungary']=92
  $idHash['country_id']['iceland']=93
  $idHash['country_id']['india']=94
  $idHash['country_id']['indonesia']=95
  $idHash['country_id']['iran']=96
  $idHash['country_id']['iraq']=97
  $idHash['country_id']['ireland']=7
  $idHash['country_id']['isle of man']=243
  $idHash['country_id']['israel']=98
  $idHash['country_id']['italy']=99
  $idHash['country_id']['ivory coast']=100
  $idHash['country_id']['jamaica']=101
  $idHash['country_id']['japan']=104
  $idHash['country_id']['jersey']=102
  $idHash['country_id']['jordan']=103
  $idHash['country_id']['kazakhstan']=106
  $idHash['country_id']['kenya']=107
  $idHash['country_id']['kiribati']=109
  $idHash['country_id']['kuwait']=241
  $idHash['country_id']['kyrgyzstan']=108
  $idHash['country_id']['laos']=110
  $idHash['country_id']['latvia']=111
  $idHash['country_id']['lebanon']=113
  $idHash['country_id']['lesotho']=114
  $idHash['country_id']['liberia']=115
  $idHash['country_id']['libya']=112
  $idHash['country_id']['liechtenstein']=116
  $idHash['country_id']['lithuania']=117
  $idHash['country_id']['luxembourg']=8
  $idHash['country_id']['macau']=258
  $idHash['country_id']['macedonia']=125
  $idHash['country_id']['madagascar']=119
  $idHash['country_id']['malawi']=129
  $idHash['country_id']['malaysia']=121
  $idHash['country_id']['maldives']=124
  $idHash['country_id']['mali']=127
  $idHash['country_id']['malta']=128
  $idHash['country_id']['marshall islands']=240
  $idHash['country_id']['martinique']=122
  $idHash['country_id']['mauritania']=123
  $idHash['country_id']['mauritius']=134
  $idHash['country_id']['mayotte']=259
  $idHash['country_id']['mexico']=228
  $idHash['country_id']['micronesia']=242
  $idHash['country_id']['moldovia']=237
  $idHash['country_id']['monaco']=130
  $idHash['country_id']['mongolia']=131
  $idHash['country_id']['montenegro']=274
  $idHash['country_id']['montserrat']=135
  $idHash['country_id']['morocco']=132
  $idHash['country_id']['mozambique']=133
  $idHash['country_id']['myanmar']=136
  $idHash['country_id']['namibia']=137
  $idHash['country_id']['nauru']=138
  $idHash['country_id']['nepal']=140
  $idHash['country_id']['netherlands']=141
  $idHash['country_id']['netherlands antilles']=148
  $idHash['country_id']['nevis and st kitts']=142
  $idHash['country_id']['new caledonia']=41
  $idHash['country_id']['new zealand']=9
  $idHash['country_id']['nicaragua']=144
  $idHash['country_id']['niger']=143
  $idHash['country_id']['nigeria']=145
  $idHash['country_id']['niue']=149
  $idHash['country_id']['norfolk island']=260
  $idHash['country_id']['northern mariana islands']=236
  $idHash['country_id']['norway']=147
  $idHash['country_id']['oman']=150
  $idHash['country_id']['pakistan']=151
  $idHash['country_id']['palau']=261
  $idHash['country_id']['panama']=152
  $idHash['country_id']['papua new guinea']=156
  $idHash['country_id']['paraguay']=262
  $idHash['country_id']['people den rep yemen']=157
  $idHash['country_id']['peru']=153
  $idHash['country_id']['philippines']=154
  $idHash['country_id']['pitcairn islands']=155
  $idHash['country_id']['poland']=158
  $idHash['country_id']['portugal']=159
  $idHash['country_id']['puerto rico']=226
  $idHash['country_id']['qatar']=160
  $idHash['country_id']['reunion']=161
  $idHash['country_id']['romania']=162
  $idHash['country_id']['russia']=163
  $idHash['country_id']['rwanda']=164
  $idHash['country_id']['saint helena']=171
  $idHash['country_id']['saint kitts and nevis']=264
  $idHash['country_id']['saint lucia']=173
  $idHash['country_id']['samoa']=217
  $idHash['country_id']['san marino']=183
  $idHash['country_id']['sao tome and principe']=176
  $idHash['country_id']['saudi arabia']=166
  $idHash['country_id']['senegal']=167
  $idHash['country_id']['serbia and montenegro']=222
  $idHash['country_id']['seychelles']=168
  $idHash['country_id']['sierra leone']=178
  $idHash['country_id']['singapore']=179
  $idHash['country_id']['slovakia']=182
  $idHash['country_id']['slovenia']=181
  $idHash['country_id']['solomon islands']=184
  $idHash['country_id']['somalia']=185
  $idHash['country_id']['south africa']=165
  $idHash['country_id']['south georgia and sandwich islands']=267
  $idHash['country_id']['south korea']=180
  $idHash['country_id']['spain']=186
  $idHash['country_id']['sri lanka']=187
  $idHash['country_id']['st barthelemy']=169
  $idHash['country_id']['st eustatius']=170
  $idHash['country_id']['st kitts']=172
  $idHash['country_id']['st marten']=174
  $idHash['country_id']['st pierre miquelon']=175
  $idHash['country_id']['st vince grenadines']=177
  $idHash['country_id']['sudan']=188
  $idHash['country_id']['suriname']=189
  $idHash['country_id']['svalbard and jan mayen']=268
  $idHash['country_id']['swaziland']=190
  $idHash['country_id']['sweden']=10
  $idHash['country_id']['switzerland']=192
  $idHash['country_id']['syria']=193
  $idHash['country_id']['taiwan']=194
  $idHash['country_id']['tajikistan']=195
  $idHash['country_id']['tanzania']=196
  $idHash['country_id']['thailand']=198
  $idHash['country_id']['togo']=200
  $idHash['country_id']['tokelau']=269
  $idHash['country_id']['tonga']=201
  $idHash['country_id']['trinidad and tobago']=202
  $idHash['country_id']['tunisia']=203
  $idHash['country_id']['turkey']=204
  $idHash['country_id']['turkmenistan']=199
  $idHash['country_id']['turks and caicos islands']=197
  $idHash['country_id']['tuvalu']=205
  $idHash['country_id']['uganda']=208
  $idHash['country_id']['ukraine']=207
  $idHash['country_id']['united arab emirates']=206
  $idHash['country_id']['united kingdom']=11
  $idHash['country_id']['uruguay']=210
  $idHash['country_id']['us minor outlying islands']=270
  $idHash['country_id']['us virgin islands']=235
  $idHash['country_id']['uzbekistan']=211
  $idHash['country_id']['vanuatu']=212
  $idHash['country_id']['vatican city state']=213
  $idHash['country_id']['venezuela']=214
  $idHash['country_id']['vietnam']=215
  $idHash['country_id']['wallis and futuna islands']=218
  $idHash['country_id']['western sahara']=271
  $idHash['country_id']['yemen']=220
  $idHash['country_id']['zaire']=223
  $idHash['country_id']['zambia']=224
  $idHash['country_id']['zimbabwe']=225
      
  # some manual overrides
  $idHash['country_id']['britain']=11
    
  $idHash['zip'] = Hash.new
  $idHash['zip']['placeholder']=1
    
  $idHash['coord'] = Hash.new
  $idHash['coord']['placeholder']=1
    
    
  def initialize (type)
    if (type.downcase == "state")
      type="state_id"
    end
        
    if (type.downcase == "country")
      type="country_id"
    end
        
    if (type.downcase == "zipcode")
      type="zip"
    end
        
    if (type.downcase == "coords")
      type="coord"
    end
        
    if (type.downcase == "coordinates")
      type="coord"
    end
        
        
    if (! $idHash[type])
      displayWarning "* Invalid search type: #{type} (using state_id)"
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
        
    key.downcase!
    id = $idHash[@lookupType][key] || nil
    debug "looked up #{key} - #{id}"
    return id
  end
    
end