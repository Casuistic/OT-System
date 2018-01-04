// SHOCK COLLAR 116

integer GI_N_Dialog = 8100;
integer GI_N_Relay = 8200;
integer GI_N_Speaker = 8300;
integer GI_N_GoTo = 8400;
integer GI_N_Titler = 8500;
integer GI_N_Interface = 8900;
integer GI_N_Zapper = 8800;
integer GI_N_Leash = 8700;
integer GN_N_CORE = 8600;


integer GN_N_DB = 8950;



integer GI_ZapCount;

integer GI_ZapTotal;

integer GI_ZapRecover;



integer GI_Debug = FALSE;
debug( string msg ) {
    if( GI_Debug ) {
        string output = llGetScriptName() +": "+ msg;
        llOwnerSay( output );
        llWhisper( -9999, output );
    }
}


/*
*   menu reigster stuff
*/
string GS_Pri_Menu = "Zap Collar";
string GS_Pub_Menu = "Punish";

list GL_Menu_Pri = [ 
        "Debug"
    ];

list GL_Menu_Pub = [
        "Zap", 
        "Stun"
    ];


integer GI_N_MenuRef = 5000;

integer GI_N_PriMenu;
integer GI_N_PubMenu;


register() {
    debug( "Register" );
    llMessageLinked( LINK_SET, GI_N_MenuRef, GS_Pri_Menu, "addPriMenu" );
    llMessageLinked( LINK_SET, GI_N_MenuRef, GS_Pub_Menu, "addPubMenu" );
}

procPubCmd( key id, list tokens ) {
    debug( "procPubCmd: "+ llDumpList2String( tokens, " | " ) );
    string cmd = llToLower( llList2String( tokens, 0 ) );
    if( cmd == "zap" ) {
        zapStart( 8 );
        llSay( 0, "ZAP!\n"+ catGetName( llGetOwner() ) +" zapped by "+ catGetName( id ) );
    } else if( cmd == "stun" ) {
        zapStart( 30 );
        llWhisper( 0, "ZAP!\n"+ catGetName( llGetOwner() ) +" stunned by "+ catGetName( id ) );
    } else {
        debug( "Unknown Pub Command: "+ cmd );
    }
}

procPriCmd( list tokens ) {
    debug( "procPriCmd: "+ llDumpList2String( tokens, " | " ) );
    string cmd = llToLower( llList2String( tokens, 0 ) );
    if( cmd == "debug" ) {
        GI_Debug = !GI_Debug;
        llOwnerSay( llGetScriptName() +" Debug set: "+ (string)GI_Debug );
    } else {
        debug( "Unknown Pri Command: "+ cmd );
    }
}

list genPubMenu( key id ) {
    return GL_Menu_Pub + ["-"];
}

list genPriMenu( ) {
    return GL_Menu_Pri + ["-", "-"];
}

menuCommon( integer src, string msg, key cmd ) {
    debug( "Menu: "+ msg +" : "+ (string)cmd );
    if( cmd == "getMenu" ) {
        register();
    } else if( cmd == "setPubChan" ) {
        list tokens = llParseStringKeepNulls( msg, ["|"], [] );
        if( llList2String( tokens, 0 ) == GS_Pub_Menu ) {
            GI_N_PubMenu = (integer)llList2String( tokens, 1 );
            debug( "SetPubChan: "+ (string)GI_N_PubMenu );
        }
    } else if( cmd == "setPriChan" ) {
        list tokens = llParseStringKeepNulls( msg, ["|"], [] );
        if( llList2String( tokens, 0 ) == GS_Pri_Menu ) {
            GI_N_PriMenu = (integer)llList2String( tokens, 1 );
            debug( "SetPriChan: "+ (string)GI_N_PriMenu );
        }
    }
}

menuPriInput( integer src, string msg, key cmd ) {
    debug( "Pri Cmd: "+ (string)src +" : "+ msg +" : "+ (string)cmd );
    if( cmd == "selectMenu" ) {
        list tokens = llParseStringKeepNulls( msg, ["|"], [] );
        if( llList2String( tokens, 0 ) == "menu" ) {
            llMessageLinked( src, GI_N_MenuRef, "menu|"+ llList2String( tokens, 1 ) +"|"+ llDumpList2String( genPriMenu(), "|" ), "openMenu" );
                
        } else if( llList2String( tokens, 0 ) == "menuOption" ){
            procPriCmd( llList2List( tokens, 2, -1 ) );
            llMessageLinked( src, GI_N_MenuRef, "menu|"+ llList2String( tokens, 1 ) +"|"+ llDumpList2String( genPriMenu(), "|" ), "openMenu" );
        }
    } else {
        debug( "Unknown Pri Action: "+ msg +" : "+ (string)cmd );
    }
}

menuPubInput( integer src, string msg, key cmd ) {
    debug( "Pub Cmd: "+ (string)src +" : "+ msg +" : "+ (string)cmd );
    if( cmd == "selectMenu" ) {
        list tokens = llParseStringKeepNulls( msg, ["|"], [] );
        if( llList2String( tokens, 0 ) == "menu" ) {
            llMessageLinked( src, GI_N_MenuRef, "menu|"+ llList2String( tokens, 1 ) +"|"+ llDumpList2String( genPubMenu( llList2Key( tokens, 1 ) ), "|" ), "openMenu" );
                
        } else if( llList2String( tokens, 0 ) == "menuOption" ){
            procPubCmd( llList2Key( tokens, 1 ), llList2List( tokens, 2, -1 ) );
            llMessageLinked( src, GI_N_MenuRef, "menu|"+ llList2String( tokens, 1 ) +"|"+ llDumpList2String( genPubMenu( llList2Key( tokens, 1 ) ), "|" ), "openMenu" );
        }
    } else {
        debug( "Unknown Pub Action: "+ msg +" : "+ (string)cmd );
    }
}

/*
*   END OF MENU REGISTER STUFF
*/


string catGetName( key id ) {
    string name = llGetDisplayName( id );
    if( name != "" ) {
        return name;
    } else if( (name = llKey2Name( id )) != "" ) {
        if( llGetSubString( name, -9, -1 ) == " Resident" ) {
            return llGetSubString( name, 0, -10 );
        }
        return name;
    }
    return "Unknown";
}


zapStart( integer count ) {
    llRequestPermissions( llGetOwner(), PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS );
    if( GI_ZapCount == 0 ) {
        llSetTimerEvent( 0.5 );
    }
    
    GI_ZapCount += count;
    GI_ZapTotal += count;
    if( GI_ZapCount >= 30 ) {
        GI_ZapCount = 30;
    }
    if( GI_ZapTotal >= 15 ) {
        GI_ZapRecover = 30;
    }
}



zap() {
    llMessageLinked( LINK_SET, GN_N_CORE, "Zap|Active", "Status" );
    llTakeControls(
        CONTROL_FWD |
        CONTROL_BACK |
        CONTROL_LEFT |
        CONTROL_RIGHT |
        CONTROL_ROT_LEFT |
        CONTROL_ROT_RIGHT |
        CONTROL_UP |
        CONTROL_DOWN |
        CONTROL_LBUTTON |
        CONTROL_ML_LBUTTON ,
        TRUE, FALSE
        );
    
    llParticleSystem([
                        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                        PSYS_PART_FLAGS, PSYS_PART_FOLLOW_VELOCITY_MASK | PSYS_PART_EMISSIVE_MASK,
                        PSYS_PART_MAX_AGE,0.75,
                        PSYS_PART_START_COLOR, <1.0,0.95,1>,
                        PSYS_PART_END_COLOR, <1,1,1>,
                        PSYS_PART_START_SCALE,<0.15,0.15,0>,
                        PSYS_PART_END_SCALE,<0.20,0.20,0>, 
                        PSYS_SRC_BURST_RATE, 0.1,
                        PSYS_SRC_ACCEL, <0,0,0>,
                        PSYS_SRC_BURST_PART_COUNT,5,
                        PSYS_SRC_BURST_RADIUS,.01,
                        PSYS_SRC_BURST_SPEED_MIN,.2,
                        PSYS_SRC_BURST_SPEED_MAX,.4,
                        PSYS_SRC_INNERANGLE,1.54, 
                        PSYS_SRC_OUTERANGLE,1.54,
                        PSYS_SRC_OMEGA, <0,0,0>,
                        PSYS_SRC_MAX_AGE, 0,
                        PSYS_SRC_TEXTURE, "1a62b9cf-8372-f1ee-6ae1-a78e39847aff",
                        PSYS_PART_START_GLOW, 0.5,
                        PSYS_PART_END_GLOW, 0.5,
                        PSYS_PART_START_ALPHA, 1.0,
                        PSYS_PART_END_ALPHA, 0.5
                        ]);
                        
    llStartAnimation( "Zap" );
    llLoopSound("4546cdc8-8682-6763-7d52-2c1e67e8257d",0.25);
}


zapRecover() {
    llMessageLinked( LINK_SET, GN_N_CORE, "Zap|Recover", "Status" );
    llStopSound();
    llParticleSystem([]);
    GI_ZapTotal = 0;
    llStartAnimation( "Stungunned" );
    llStopAnimation( "Zap" );
}


zapStop() {
    llMessageLinked( LINK_SET, GN_N_CORE, "Zap|Done", "Status" );
    llStopSound();
    llParticleSystem([]);
    llSetTimerEvent( 0 );
    llReleaseControls();
    GI_ZapTotal = 0;
    llStopAnimation( "Zap" );
    llStopAnimation( "Stungunned" );
    
}


setup( key id ) {
    llRequestPermissions( id, PERMISSION_TRIGGER_ANIMATION );
}





default {
    state_entry() {
        setup( llGetOwner() );
        register();
    }
    
    attach( key id ) {
        if( id != NULL_KEY ) {
            setup( id );
        }
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        if( num == GI_N_Zapper ) {
            if( id == "do_zap" ) {
                zapStart( (integer)msg );
            } else if( id == "debug" ) {
                GI_Debug = (integer)msg;
            }
        } else if( num == 5000 ) {
            menuCommon( src, msg, id );
        } else if( num == GI_N_PriMenu ) {
            menuPriInput( src, msg, id );
        } else if( num == GI_N_PubMenu ) {
            menuPubInput( src, msg, id );
        }
    }
    
    run_time_permissions( integer flag ) {
        if( flag & PERMISSION_TAKE_CONTROLS ) {
            zap();
        }
    }
    
    timer() {
        debug( "Time: "+ (string)GI_ZapCount +" : "+ (string)GI_ZapRecover );
        if( 0 == GI_ZapCount ) {
            if( 0 >= GI_ZapRecover ) {
                zapStop();
            } else if( GI_ZapRecover == 30 ) {
                zapRecover();
            }
            GI_ZapRecover -= 1;
        } else {
            GI_ZapCount -= 1;
        }
    }
}
