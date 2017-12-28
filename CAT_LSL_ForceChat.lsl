integer GI_N_Dialog = 8100;
integer GI_N_Relay = 8200;
integer GI_N_Speaker = 8300;
integer GI_N_GoTo = 8400;
integer GI_N_Titler = 8500;
integer GI_N_Interface = 8900;
integer GI_N_Zapper = 8800;
integer Gi_N_Leash = 8700;

integer GN_N_HData = 8600;


string GS_Title = "Unknown";
integer g_iVolume = 102;

integer g_iChan_A = 55;
integer g_iListen_A;

integer GI_ChatPrim = 0;

integer GI_Mood = FALSE;
integer GI_Enabled = TRUE;




setVolume( integer lev ) {
    debug( "setVolume" );
    g_iVolume = 100 + lev;
}


enable( ) {
    debug( "enable: "+ (string)GI_Enabled +" : "+ (string)GI_Mood );
    
    key me = llGetInventoryKey( llGetScriptName() );
    if( GI_Enabled && GI_Mood ) {
        llListenRemove( g_iListen_A );
        g_iListen_A = llListen( g_iChan_A, "", llGetOwner(), "" );
        llMessageLinked( LINK_SET, GI_N_Relay, "GagMe,"+ (string)llGetOwner() +",@redirchat:"+ (string)g_iChan_A +"=add|@rediremote:"+ (string)g_iChan_A +"=add", me );
    } else {
        llListenRemove( g_iListen_A );
        llMessageLinked( LINK_SET, GI_N_Relay, "GagMe,"+ (string)llGetOwner() +",!release", me );
    }
}



setup( key id ) {
    debug( "setup" );
    map();
}


map() {
    debug( "map" );
    integer i;
    integer num = llGetNumberOfPrims();//.Chatter
    for( i=2; i<=num; ++i ) {
        string desc = llList2String( llGetLinkPrimitiveParams( i, [PRIM_DESC]), 0 );
        if( desc == ".chatter" || desc == ".Chatter" ) {
            debug( "Found Chatter" );
            GI_ChatPrim = i;
        }
    }
    
}


integer GI_Debug = FALSE;
debug( string msg ) {
    if( GI_Debug ) {
        string output = llGetScriptName() +": "+ msg;
        llOwnerSay( output );
        llWhisper( -9999, output );
    }
}


default {
    link_message( integer src, integer num, string msg, key id ) {
        if( num == 100 || num == GI_N_Speaker ) {
            debug( (string)id +" : "+ msg );
            
            if( id == "set_mood" ) {
                GI_Mood = (integer)msg;
                enable( );
            } else if ( id == "Talker" ) {
                list data = llParseString2List( msg, ["|"], [] );
                string token = llList2String( data, 0 );
                if( token == "Enable" ) {
                    GI_Enabled = (integer)llList2String( data, 1 );
                    enable( );
                } else if( token == "Mood" ) {
                    GI_Enabled = (integer)llList2String( data, 1 );
                    enable( );
                } else if( token == "setTitle" ) {
                    GS_Title = llList2String( data, 1 );
                } else if( token == "Title" ) {
                    llOwnerSay( "Old Title Command" );
                    GS_Title = llList2String( data, 1 );
                } else if( token == "Debug" ) {
                    GI_Debug = (integer)llList2String( data, 1 );
                } else if( token == "Reset" ) {
                    debug( "Resetting Chatter" );
                    setup( id );
                }
            }
                
                
                
            else { // old system
                list data = llParseString2List( msg, ["|"], [] );
                msg == "";
                string token = llList2String( data, 0 );
                if( token == "cset_title" ) {
                    GS_Title = llList2String( data, 1 );
                } else if ( token == "reset" ) {
                    debug( "Resetting Chatter" );
                    setup( id );
                } else if( token == "debug" ) {
                    GI_Debug = (integer)llList2String( data, 1 );
                } else if( token == "enable" ) {
                    GI_Enabled = TRUE; // GI_Mood
                    enable( );
                } else if( token == "disable" ) {
                    GI_Enabled = FALSE; // GI_Mood
                    enable( );
                }
            }
        }
        
    }
    
    state_entry() {
        setup( llGetOwner() );
    }
    
    listen( integer chan, string name, key id, string msg ) {
        debug( "Listen: "+ msg );
        if( llGetOwnerKey( id ) == llGetOwner() ) {
            debug( "Listen Test: A" );
            if( chan == g_iChan_A ) {
                debug( "Listen Test: B" );
                if( g_iVolume <= 103 && g_iVolume >= 100 ) {
                    llSetLinkPrimitiveParamsFast( GI_ChatPrim, [PRIM_NAME, GS_Title] );
                    llMessageLinked( GI_ChatPrim, g_iVolume, msg, (string)("CH:Emote") );
                } else if( g_iVolume == 99 ) {
                    llSetLinkPrimitiveParamsFast( GI_ChatPrim, [PRIM_NAME, GS_Title] );
                    llMessageLinked( GI_ChatPrim, g_iVolume, "...", (string)("CH:Emote") );
                } else {
                    debug( "Unknown Chat State" );
                }
            }
        }
    }
    
    
}
