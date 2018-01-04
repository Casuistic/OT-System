// LEASH 116

integer GI_N_Dialog = 8100;
integer GI_N_Relay = 8200;
integer GI_N_Speaker = 8300;
integer GI_N_Interface = 8900;
integer GI_N_Zapper = 8800;
integer Gi_N_Leash = 8700;


key GK_Leash_Target = NULL_KEY;
integer GI_Leash_Oragin = 1;

vector GV_Leash_Colour = <1,0,0>;




float GF_Leash_Min = 1;
float GF_Leash_Max = 30;
float GF_Leash_Len = 5; 




string GS_Pri_Menu = "Leash";
string GS_Pub_Menu = "Leash";

list GL_Menu_Pri = [ "Debug", "-", "-" ];

list GL_Menu_Pub = [
            "Length +5", "Length -5", "Length +1", "Length -1"
    ];


integer GI_N_MenuRef = 5000;

integer GI_N_PriMenu;
integer GI_N_PubMenu;




integer GI_Debug = FALSE;
debug( string msg ) {
    if( GI_Debug ) {
        string output = llGetScriptName() +": "+ msg;
        llOwnerSay( output );
        llWhisper( -9966, output );
    }
}






map() {
    debug( "map" );
    integer i;
    integer num = llGetNumberOfPrims();
    GI_Leash_Oragin = LINK_ROOT;
    for( i = 2; i <= num; i++ ) {
        string name =  llGetLinkName( i );
        if( llToLower( llGetSubString( name, 0, 12 ) ) == ".leash oragin" ) {
            GI_Leash_Oragin = i;
            llSetLinkPrimitiveParamsFast( i, [PRIM_COLOR, ALL_SIDES, <0,0,0>, 0]);
            return;
        }
    }
}


leashClear() {
    debug( "leashClear" );
    llStopMoveToTarget();
    llSetTimerEvent( 0 );
}


leashSet( key id ) {
    debug( "leashSet: "+ (string)id +" ("+ llKey2Name( id ) +")" );
    GK_Leash_Target = id;
    if( GK_Leash_Target == NULL_KEY || GK_Leash_Target == "" ) {
        leashClear();
    } else {
        llSetTimerEvent( 0.5 );
    }
    leashParti( id );
}


leashParti( key id ) {
    debug( "leashParty: "+ (string)id +" ("+ llKey2Name( id ) +")" );
    if( id != NULL_KEY  ) {
        llLinkParticleSystem( GI_Leash_Oragin, [
            PSYS_PART_FLAGS,       PSYS_PART_RIBBON_MASK | PSYS_PART_EMISSIVE_MASK | PSYS_PART_TARGET_POS_MASK,
            PSYS_SRC_PATTERN,      PSYS_SRC_PATTERN_DROP, PSYS_SRC_TARGET_KEY, id,
            PSYS_PART_START_COLOR, GV_Leash_Colour,
            PSYS_PART_START_SCALE, <0.05,0,0>,
            PSYS_PART_MAX_AGE, 1.0,
            PSYS_SRC_ACCEL, <0,0,-2.5>,
            PSYS_SRC_TEXTURE, "59facb66-4a72-40a2-815c-7d9b42c56f60"
        ] );
    } else {
        llLinkParticleSystem( GI_Leash_Oragin, [] );
    }
}


setup( key id ) {
    debug( "setup" );
    if( id != NULL_KEY ) {
        map();
        leashSet( NULL_KEY );
    }
}




register() {
    debug( "Register" );
    llMessageLinked( LINK_SET, GI_N_MenuRef, GS_Pri_Menu, "addPriMenu" );
    llMessageLinked( LINK_SET, GI_N_MenuRef, GS_Pub_Menu, "addPubMenu" );
}


procPubCmd( key id, list tokens ) {
    debug( "procPubCmd: "+ llDumpList2String( tokens, " | " ) );
    string cmd = llToLower( llList2String( tokens, 0 ) );
    if( cmd == "grab" ) {
        llWhisper( 0, "Leash Grabbed by "+ llKey2Name( id ) );
        leashSet( id );
    } else if( cmd == "snatch" ) {
        llWhisper( 0, "Leash Snatched by "+ llKey2Name( id ) );
        leashSet( id );
    } else if( cmd == "drop" ) {
        llWhisper( 0, "Leash Dropped" );
        leashSet( NULL_KEY );
    } else if( llGetSubString( cmd, 0, 5 ) == "length +5" ) {
        adjustLeashLength( 5 );
    } else if( llGetSubString( cmd, 0, 5 ) == "length -5" ) {
        adjustLeashLength( -5 );
    } else if( llGetSubString( cmd, 0, 5 ) == "length +1" ) {
        adjustLeashLength( 1 );
    } else if( llGetSubString( cmd, 0, 5 ) == "length -1" ) {
        adjustLeashLength( -1 );
    }
}


adjustLeashLength( float mod ) {
    GF_Leash_Len += mod;
    if( GF_Leash_Len < GF_Leash_Min ) {
        GF_Leash_Len = GF_Leash_Min;
    } else if( GF_Leash_Len > GF_Leash_Max ) {
        GF_Leash_Len = GF_Leash_Max;
    }
}


procPriCmd( list tokens ) {
    debug( "procPriCmd: "+ llDumpList2String( tokens, " | " ) );
    string cmd = llToLower( llList2String( tokens, 0 ) );
    if( cmd == "debug" ) {
        GI_Debug = !GI_Debug;
        llOwnerSay( "Debug set: "+ (string)GI_Debug );
    }
}


list genPubMenu( key id ) {
    list menu = llList2List( GL_Menu_Pub, 0, 1 );
    if( id == GK_Leash_Target ) {
        menu += "Drop";
    } else if( GK_Leash_Target != NULL_KEY && GK_Leash_Target != "" ) {
        menu += "Snatch";
    } else {
        menu += "Grab";
    }
    menu += llList2List( GL_Menu_Pub, 2, 3 );
    return menu;
}

list genPriMenu() {
    return GL_Menu_Pri;
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





default {
    
    state_entry() {
        setup( llGetOwner() );
        register();
    }
    
    
    attach( key id ) {
        if( id ) {
            llResetScript();
        }
    }
    
    
    link_message( integer src, integer num, string msg, key id ) {
        if( num == 100 || num == Gi_N_Leash ) {
            if( id == "Leash" ) {
                list data = llParseString2List( msg, ["|"], [] );
                string act = llList2String( data, 0 );
                if( act == "Leash" ) {
                    if( id == NULL_KEY ) {
                        leashSet( NULL_KEY );
                    } else if( llGetOwner() != id ) {
                        leashSet( llList2Key( data, 1 ) );
                    }
                } else if( act == "LeashLength" ) {
                    GF_Leash_Len = (float)llList2String( data, 1 );
                    if( GF_Leash_Len < GF_Leash_Min ) {
                        GF_Leash_Len = GF_Leash_Min;
                    } else if( GF_Leash_Len > GF_Leash_Max ) {
                        GF_Leash_Len = GF_Leash_Max;
                    }
                } else if( act == "LeashLengthAdd" ) {
                    adjustLeashLength( (float)llList2String( data, 1 ) );
                } else if( act == "LeashColour" ) {
                    GV_Leash_Colour = (vector)llList2String( data, 1 );
                    leashParti( GK_Leash_Target );
                } else if( act == "tether" ) {
                    if( llGetOwner() != id ) {
                        leashSet( llList2Key( data, 1 ) );
                    }
                } else if( act == "pass" ) {
                    if( llGetOwner() != id ) {
                        leashSet( llList2Key( data, 1 ) );
                    }
                }
                debug( "Lesh Adjust: "+ (string)GF_Leash_Len +" : "+ (string)GV_Leash_Colour );
            }
        } else if( num == 5000 ) {
            menuCommon( src, msg, id );
        } else if( num == GI_N_PriMenu ) {
            menuPriInput( src, msg, id );
        } else if( num == GI_N_PubMenu ) {
            menuPubInput( src, msg, id );
        }
    }
    
    
    timer() {
        if( GK_Leash_Target == NULL_KEY ) {
            leashClear();
        } else {
            vector pos = llGetPos();
            vector tar = llList2Vector( llGetObjectDetails( GK_Leash_Target, [OBJECT_POS] ), 0 );
            float dist = llVecDist( pos, tar );
            if( dist >= GF_Leash_Len ) {
                debug( "Pull To: "+ (string)dist );
                vector mod = tar + (((pos - tar) / dist) * GF_Leash_Len);
                llMoveToTarget( mod, 0.25 );
            } else {
                llStopMoveToTarget();
            }
        }
    }
}
