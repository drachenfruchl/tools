untyped
globalize_all_functions

#if UI
array<FriendsData> function GetSeperateFriendsData(){
	CommunityFriendsWithPresence friendInfo = GetFriendInfoAndPresence()

	FriendsData returnData_online
	FriendsData returnData_offline

	returnData_online.isValid 	= friendInfo.isValid
	returnData_offline.isValid 	= friendInfo.isValid

	if ( !friendInfo.isValid )
		return [ returnData_online, returnData_offline ]

	array<Friend> friends
	array<Friend> offlineFriends

	foreach ( entry in friendInfo.friends ){
		Friend friend
		friend.id = entry.id
		friend.name = entry.name

		if ( entry.online ){
			friend.status = eFriendStatus.ONLINE_INVITABLE
			friends.append( friend )
		} else {
			friend.status = eFriendStatus.OFFLINE
			offlineFriends.append( friend )
		}
	}

	returnData_online.friends 	= friends
	returnData_offline.friends 	= offlineFriends

	return [ returnData_online, returnData_offline ]
}

void function dtool_getOnlineFriends(){
	string		 		friendNames = ""
	FriendsData 		fd 			= GetSeperateFriendsData()[0]

	if( !fd.isValid || fd.friends.len() == 0 ){
		SetConVarString( "dtool_onlineFriends", "" )
		return
	}

	foreach( friend in fd.friends ){
		friendNames += friend.name + " "
		// printt( "Name:", friend.name, "ID:", friend.id )
	}

	SetConVarString( "dtool_onlineFriends", friendNames )
	return
}

void function dtool_getOfflineFriends(){
	string		 		friendNames = ""
	FriendsData 		fd 			= GetSeperateFriendsData()[1]

	if( !fd.isValid || fd.friends.len() == 0 ){
		SetConVarString( "dtool_offlineFriends", "" )
		return
	}

	foreach( friend in fd.friends ){
		friendNames += friend.name + " "
		// printt( "Name:", friend.name, "ID:", friend.id )
	}

	SetConVarString( "dtool_offlineFriends", friendNames )
	return
}

void function dtool_getPartyMembers(){
	string		 	memberNames = ""
	Party 			partyData 	= GetParty()

	if( partyData.numSlots == 0 ){
		SetConVarString( "dtool_partyMembers", "" )
		return
	}

	foreach( member in partyData.members ){
		memberNames += member.name + " "
		// printt( "ADDED", member.name, "TO PARTY MEMBER LIST", member.uid )
	}

	SetConVarString( "dtool_partyMembers", memberNames )
	return
}

string function dtool_formatModToggleColor( string convar, string text ){
    vector colorEnabled	 = < 255, 255, 255 >
    vector colorDisabled = < 150, 150, 150 >

	bool enabled = GetConVarBool( format( "%s", convar ) )

	return format( "^%s00%s", dtool_RGBtoHEX( ( enabled ? colorEnabled : colorDisabled ) ), ( enabled ? "" : "[DISABLED] " ) + text )
}

string function dtool_RGBtoHEX( vector RGB ){
    array<string> HEXVALUES = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" ]
    string HEX = "" //#

    int r = int( clamp( RGB.x.tointeger(), 0, 255 ) )
    int g = int( clamp( RGB.y.tointeger(), 0, 255 ) )
    int b = int( clamp( RGB.z.tointeger(), 0, 255 ) )

    HEX += HEXVALUES[ ( r >> 4 ) & 0xF ] + HEXVALUES[ r & 0xF ]
    HEX += HEXVALUES[ ( g >> 4 ) & 0xF ] + HEXVALUES[ g & 0xF ]
    HEX += HEXVALUES[ ( b >> 4 ) & 0xF ] + HEXVALUES[ b & 0xF ]

    return HEX
}

vector function dtool_lerp( float cur, float max, vector v_start, vector v_end ){
    float t = cur / max
    t = clamp( t, 0.0, 1.0 )

    return <
        v_start.x + ( v_end.x - v_start.x ) * t,
        v_start.y + ( v_end.y - v_start.y ) * t,
        v_start.z + ( v_end.z - v_start.z ) * t
    >
}

string function dtool_fadeModText( string text, string color ){
	array<string> fades = split( color.slice( 1 ), "," )

	array<string> 	rgb1 	= split( fades[ 0 ], " " )
	vector 		  	v1 		= <
								rgb1[ 0 ].tointeger(),
								rgb1[ 1 ].tointeger(),
								rgb1[ 2 ].tointeger()
							>

	array<string> 	rgb2 	= split( fades[ 1 ], " " )
	vector 		  	v2 		= <
								rgb2[ 0 ].tointeger(),
								rgb2[ 1 ].tointeger(),
								rgb2[ 2 ].tointeger()
							>

	string 			result 	= ""
	int 			textlen = text.len()

	for( int i = 0; i < textlen; i++ )
		result += format( "^%s00", dtool_RGBtoHEX( dtool_lerp( i.tofloat(), textlen.tofloat(), v1, v2 ) ) ) + text.slice( i, i + 1 )

	return result
}

string function dtool_rainbowModText( string text ){
	array<string> colors = [
		"^FF000000",
		"^FF7F0000",
		"^FFFF0000",
		"^7FFF0000",
		"^00FF0000",
		"^00FF7F00",
		"^00FFFF00",
		"^007FFF00",
		"^0000FF00",
		"^7F00FF00",
		"^FF00FF00",
		"^FF007F00"
	]

	int      colorlen   = colors.len()
	int      textlen    = text.len()
	float    step       = colorlen.tofloat() / textlen.tofloat()

	string   result     = ""

	for( int i = 0; i < textlen; i++ ){
		int index = ( step * i ).tointeger() % colorlen
		result += colors[ index ] + text.slice( i, i + 1 )
	}
	return result
}
#elseif CLIENT
global struct LogoData
{
    array<string> logo
    vector color_start = < -1, -1, -1 >
    vector color_end = < -1, -1, -1 >
}

global struct KeyStates
{
    bool HAS_TOGGLED = false
    bool TOGGLING = false
}

//< 131, 56, 236 >, < 255, 190, 11 >
//< 255, 0, 110 >, < 131, 56, 236 >
vector function dtool_getRandomColorVector(){
    array<vector> colors = [
        <255, 0, 110>,
        <131, 56, 236>,
        <255, 190, 11>,
        <131, 56, 236>,
        <255, 105, 180>,
        <0, 255, 255>,
        <255, 255, 0>,
        <0, 0, 255>,
        <0, 255, 0>,
        <255, 0, 0>,
        <255, 140, 0>,
        <148, 0, 211>,
        <0, 206, 209>,
        <255, 20, 147>,
        <173, 216, 230>,
        <25, 25, 112>,
        <255, 255, 255>,
        //<0, 0, 0>,
        <128, 0, 128>,
        <255, 165, 0>,
        <255, 69, 0>,
        <255, 215, 0>,
        <0, 191, 255>,
        <255, 99, 71>,
        <60, 179, 113>,
        <255, 192, 203>,
        <72, 61, 139>,
        <106, 90, 205>,
        <255, 223, 0>,
        <255, 204, 0>,
        <255, 51, 153>,
        <0, 255, 127>,
        <138, 43, 226>,
        <255, 160, 122>,
        <70, 130, 180>,
        <221, 160, 221>,
        <0, 128, 128>,
        <175, 238, 238>,
        <75, 0, 130>,
        <240, 230, 140>,
        <210, 105, 30>,
        <255, 100, 100>,
        <100, 100, 255>,
        <255, 255, 153>,
        <153, 0, 0>,
        <50, 205, 50>,
        <255, 140, 0>,
        <135, 206, 250>
    ]
    return colors.getrandom()
    //return RandomVec( 255.0 )
}

void function dtool_printLogo( LogoData LD ){

    array<string> logo = LD.logo
    int length = logo.len()
    vector v_start = ( LD.color_start == < -1, -1, -1 > ? dtool_getRandomColorVector() : LD.color_start )
    vector v_end = ( LD.color_end == < -1, -1, -1 > ? dtool_getRandomColorVector() : LD.color_end )

    // printt( format("v_start: %s - v_end: %s", v_start.tostring(), v_end.tostring() ) )

    printt("")
    for( int line = 0; line < length; line++ )
        printt( dtool_lerpANSI( line, length, v_start , v_end ) + logo[ line ] + "\x1b[0m" )
    printt("")
}

void function dtool_printLogo_chat( LogoData LD ){

    array<string> logo = LD.logo
    int length = logo.len()
    vector v_start = ( LD.color_start == < -1, -1, -1 > ? dtool_getRandomColorVector() : LD.color_start )
    vector v_end = ( LD.color_end == < -1, -1, -1 > ? dtool_getRandomColorVector() : LD.color_end )

    // printt( format("v_start: %s - v_end: %s", v_start.tostring(), v_end.tostring() ) )

    for( int line = 0; line < length; line++ )
        Chat_GameWriteLine( dtool_lerpANSI( line, length, v_start , v_end ) + logo[ line ] + "\x1b[0m" )
}

string function dtool_lerpANSI( int line, int totalLines, vector v_start, vector v_end ){
    float t = float( line ) / float( totalLines-1 )
    t = clamp( t, 0.0, 1.0 )

    int R = int( v_start.x + (v_end.x - v_start.x) * t )
    int G = int( v_start.y + (v_end.y - v_start.y) * t )
    int B = int( v_start.z + (v_end.z - v_start.z) * t )

    R = int( clamp( R, 0, 255 ) )
    G = int( clamp( G, 0, 255 ) )
    B = int( clamp( B, 0, 255 ) )

    return( format( "\x1b[38;2;%d;%d;%dm", R, G, B ) )
}

vector function dtool_lerp( float cur, float max, vector v_start, vector v_end ){
    float t = cur / max
    t = clamp( t, 0.0, 1.0 )

    return <
        v_start.x + ( v_end.x - v_start.x ) * t,
        v_start.y + ( v_end.y - v_start.y ) * t,
        v_start.z + ( v_end.z - v_start.z ) * t
    >
}

void function dtool_waitForValidGamestate( int gamestate, void functionref() fn_after ){
    void functionref() ref = void function() : ( gamestate, fn_after ){
        while( GetMapName() == "mp_lobby" ) wait 1
        while( GetGameState() < gamestate ) WaitFrame()
        fn_after()
    }

    thread ref()
}

vector function dtool_normalizeToScreensize( float x, float y, float offsetX = 0.0, float offsetY = 0.0 ){
    return < x / GetScreenSize()[0] + offsetX, y / GetScreenSize()[1] + offsetY, 0.0 >
}

vector function dtool_lerpColorSimple( string col_start, string col_end, float cur, float max, float offset = 0.0 ){
    table channels = {
        R = 0.0,
        G = 0.0,
        B = 0.0
    }

    float start = clamp(cur / max, 0.0, 1.0)
    float end = clamp(1.0 - (start + offset), 0.0, 1.0)

    if ( col_start in channels ) channels [ col_start ] = start
    if ( col_end in channels ) channels[ col_end ] += end

    return Vector( channels.R, channels.G, channels.B )
}

void function dtool_multiButtonPress( KeyStates KS, int KEY, array< float > thresholds, array< void functionref() > callbacks ){
    RegisterButtonPressedCallback( KEY, void function( entity player ) : ( KS, thresholds, callbacks ){
        if( !KS.TOGGLING )
            thread handleMultiButtonPress( player, KS, thresholds, callbacks )
    })

    RegisterButtonReleasedCallback( KEY, void function( entity player ) : ( KS ){
        KS.HAS_TOGGLED = true
    })
}

void function handleMultiButtonPress( entity player, KeyStates KS, array< float > thresholds, array< void functionref() > callbacks ){
    KS.HAS_TOGGLED = false
    KS.TOGGLING = true
    float init_time = Time()

    while( !KS.HAS_TOGGLED )
        WaitFrame()

    float end_time = Time()
    float total_press_time = end_time - init_time
    for( int i = 0; i < thresholds.len(); i++ ){
        if ( total_press_time >= thresholds[i] ){
            callbacks[i]()
            break
        }
    }

    KS.TOGGLING = false
}

void function handleButtonPress( entity player, KeyStates KS, float threshold, void functionref() press_short, void functionref() press_long ){
    KS.HAS_TOGGLED = false
    KS.TOGGLING = true
    float init_time = Time()

    while( Time() < init_time + threshold ){
        if( KS.HAS_TOGGLED ){
            KS.TOGGLING = false
            press_short()
            return
        }
        WaitFrame()
    }

    KS.TOGGLING = false
    press_long()
}

void function dtool_advancedButtonPress( KeyStates KS, int KEY, float threshold, void functionref() press_short, void functionref() press_long ) {
    RegisterButtonPressedCallback( KEY, void function( entity player ) : ( KS, threshold, press_short, press_long ) {
        if( !KS.TOGGLING )
            thread handleButtonPress( player, KS, threshold, press_short, press_long )
    })

    RegisterButtonReleasedCallback( KEY, void function( entity player ) : ( KS ){
        KS.HAS_TOGGLED = true
    })
}

string function dtool_getClanTagByEntity( entity player ){
    if( player == null )
        return ""
    string playername = player.GetPlayerNameWithClanTag()
    if( playername.find( "]" ) == null )
        return ""

    var index_seperator = playername.find( " " )
    string tag = playername.slice( 1, index_seperator-1 )

    return tag
}

string function dtool_getClanTagByName( string player ){
    string playername = ""
    if( player == "" )
        return playername

    array<entity> all_players = GetPlayerArray()
    foreach( p in all_players ){
        if( p.GetPlayerName() == player ){
            playername = p.GetPlayerNameWithClanTag()
            break
        }
    }

    if( playername.find( "]" ) == null )
        return ""

    var index_seperator = playername.find( " " )
    string tag = playername.slice( 1, index_seperator-1 )

    return tag
}

entity function dtool_getPlayerMatch_entity( string namePart ){
    array<entity> matches = []
    array<entity> all_players = GetPlayerArray()

    foreach( player in all_players ){
        string playername = player.GetPlayerName()
        if( playername.len() < namePart.len() )
            continue
        if( playername.tolower().slice( 0, namePart.len() ) == namePart.tolower() )
            matches.append( player )
    }

    if( matches.len() != 1 )
        return null

    return matches[0]
}

string function dtool_getPlayerMatch_name( string namePart ){
    array<entity> matches = []
    array<entity> all_players = GetPlayerArray()

    foreach( player in all_players ){
        string playername = player.GetPlayerName()
        if( playername.len() < namePart.len() )
            continue
        if( playername.tolower().slice( 0, namePart.len() ) == namePart.tolower() )
            matches.append( player )
    }

    if( matches.len() != 1 )
        return ""

    return matches[0].GetPlayerName()
}

table function dtool_getCurrentTime( int timezoneOffset = 2 ){
    #if MP
        table tp = GetUnixTimeParts( GetUnixTimestamp() )

        var hour = tp["hour"] + int( clamp( timezoneOffset, -12, 14 ) )
        hour = hour % 24
        if( hour < 0 )
            hour += 24

        return {
            year   = tp["year"],
            month  = tp["month"]
            day    = tp["day"],
            hour   = hour,
            minute = tp["minute"],
            second = tp["second"]
        }
    #endif

    return {}
}

table function dtool_getCurrentDate(){
    #if MP
        table   tp      = GetUnixTimeParts( GetUnixTimestamp() )

        int     year    = expect int( tp["year"] )
        int     month   = expect int( tp["month"] )
        int     day     = expect int( tp["day"] )

        year -= 2000

        return {
            year        = year,
            month       = month,
            day         = day
        }
    #endif

    return {}
}

vector function dtool_normalizeRGB( vector RGB ){
    float R = RGB.x / 255
    float G = RGB.y / 255
    float B = RGB.z / 255

    return Vector( R,G,B )
}

string function dtool_RGBtoHEX( vector RGB ){
    array<string> HEXVALUES = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" ]
    string HEX = "" //#

    int r = int( clamp( RGB.x.tointeger(), 0, 255 ) )
    int g = int( clamp( RGB.y.tointeger(), 0, 255 ) )
    int b = int( clamp( RGB.z.tointeger(), 0, 255 ) )

    HEX += HEXVALUES[ ( r >> 4 ) & 0xF ] + HEXVALUES[ r & 0xF ]
    HEX += HEXVALUES[ ( g >> 4 ) & 0xF ] + HEXVALUES[ g & 0xF ]
    HEX += HEXVALUES[ ( b >> 4 ) & 0xF ] + HEXVALUES[ b & 0xF ]

    return HEX
}

void function dtool_playRandomAudio( string prefix, int files ){
    if( files == 0 )
        return

    entity player = GetLocalClientPlayer()
    if( player == null || !IsValid( player ) )
        return

    string fileName = prefix + string( RandomInt( files ) + 1 )

    player.ClientCommand( format( "playvideo %s 1 1", fileName ) )
}

array<entity> function dtool_getPlayersInDistance( float dist ){
	entity self = GetLocalClientPlayer()
	array<entity> all_players = GetPlayerArray()
    array<entity> playersInDist = []

	foreach( player in all_players ){
		if( Distance( self.EyePosition(), player.EyePosition() ) <= dist )
			playersInDist.append( player )
	}

    return playersInDist
}

void function dtool_waitUntilAllThreadsFinished( array< void functionref() > threads ){
    table state = {
        threadsFinished = 0,
        totalThreads = threads.len()
    }

    foreach( void functionref() threadFunc in threads ) {
        thread function() : ( threadFunc, state ) {
            threadFunc()
            state.threadsFinished++
        }()
    }

    while( state.threadsFinished < state.totalThreads )
        WaitFrame()
}

bool function dtool_isEnemy( entity ent ){
    return ( ent.GetTeam() != GetLocalClientPlayer().GetTeam() )
}

string function dtool_base64encode( string input ){
    string BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    string output = ""
    int i = 0
    int len = input.len()

    while( i < len ){
        int b1 = expect int( input[i++] )
        int b2 = ( i < len ) ? expect int( input[i++] ) : -1
        int b3 = ( i < len ) ? expect int( input[i++] ) : -1

        int triple = ( b1 << 16 ) | ( ( b2 != -1 ? b2 : 0 ) << 8 ) | ( b3 != -1 ? b3 : 0 )

        int i1 = ( triple >> 18 ) & 0x3F
        int i2 = ( triple >> 12 ) & 0x3F
        int i3 = ( triple >> 6  ) & 0x3F
        int i4 = triple & 0x3F

        output += BASE64_CHARS.slice( i1, i1 + 1 )
        output += BASE64_CHARS.slice( i2, i2 + 1 )

        if( b2 != -1 )
            output += BASE64_CHARS.slice( i3, i3 + 1 )
        else
            output += "="

        if ( b3 != -1 )
            output += BASE64_CHARS.slice( i4, i4 + 1 )
        else
            output += "="
    }

    return output
}

string function dtool_sanitizeUTF8( string text ){
    int i = 0
    int textlen = text.len()
    string result = ""

    table< int, string> charReplacements = {
        [ 182 ] = "oe",
        [ 132 ] = "ae",
        [ 156 ] = "ue",
        [ 159 ] = "ss"
    }

    while( i < textlen ){
        int charlength = dtool_byteSliceLength( text[i].tointeger() )
        int charint = expect int( text[i].tointeger() )
        string char = text.slice( i, i + charlength )

        if( i + charlength <= text.len() ){
            if( charint >= 32 && charint <= 126 ){
                result += char
            } else {
                array<int> charints = []
                for( int j = 0; j < char.len(); j++ ){
                    int b = expect int( char[j].tointeger() )
                    if( b < 0 )
                        b += 256
                    charints.append(b)
                }
                if(
                    charints.len() == 2 &&
                    charints[0] == 195 &&
                    charints[1] in charReplacements
                ){
                    result += charReplacements[ charints[1] ]
                } else {
                    result += "?"
                }
            }

            i += charlength
        }
    }

    return result
}

int function dtool_byteSliceLength( var byte ){
	byte 			= byte < 0 ? byte + 256 : byte

	int charLength 	= 1
	if( 		byte >= 0xF0 ) charLength = 4
	else if( 	byte >= 0xE0 ) charLength = 3
	else if( 	byte >= 0xC0 ) charLength = 2

	return charLength
}

void function dtool_loadFriendsAndParty(){
	RunUIScript( "dtool_getPartyMembers" )
    RunUIScript( "dtool_getOfflineFriends" )
	RunUIScript( "dtool_getOnlineFriends" )
}

bool function dtool_isFriend( string playerName ){
    if(
        split( GetConVarString( "dtool_onlineFriends" ), " " ).contains( playerName ) ||
        split( GetConVarString( "dtool_offlineFriends" ), " " ).contains( playerName )
    ) return true
    return false
}

bool function dtool_inParty( string playerName ){
	return split( GetConVarString( "dtool_partyMembers" ), " " ).contains( playerName )
}

bool function dtool_isModEnabled( string name, string version = "" ){
    foreach( ModInfo mod in NSGetModsInformation() ){
		if( mod.enabled && mod.name == name ){
            if( version != "" && mod.version != version )
                return false
            return true
        }
	}
    return false
}

void function dtool_setModEnabled( string name, string version, bool enable ){
    NSSetModEnabled( name, version, enable )
}

void function dtool_emitSoundsOnEntity( entity ent, array<string> sounds ){
	foreach( sound in sounds )
		EmitSoundOnEntity( ent, sound )
}

void function dtool_emitSoundsAtPosition( vector pos, array<string> sounds ){
	foreach( sound in sounds )
		EmitSoundAtPosition( TEAM_ANY, pos, sound )
}

void function dtool_stopSoundsOnEntity( entity ent, array<string> sounds ){
	foreach( sound in sounds )
		StopSoundOnEntity( ent, sound )
}

string function dtool_sanitizeMessage( string message ){
    message = dtool_stripWhitespaces( message )
    message = dtool_stripANSI( message )
    return message
}

string function dtool_stripWhitespaces( string message ){
    while( message.find( "\n" ) != null )
        message = StringReplace( message, "\n", "" )

    return message
}

string function dtool_stripANSI( string message ){
    while( true ){
        var escIndex = message.find( "\x1b" )
        if( !IsValid( escIndex ) )
            return message
        expect int( escIndex )

        var escMIndex = message.find( "m" )
        if( !IsValid( escMIndex ) )
            return message
        expect int( escMIndex )

        message = message.slice( 0, escIndex ) + message.slice( escMIndex + 1 , message.len() )
    }

    return message
}
#endif