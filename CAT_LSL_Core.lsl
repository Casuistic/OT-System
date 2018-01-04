// CORE 201

integer GI_N_Dialog  = 8100;
integer GI_N_Relay   = 8200;
integer GI_N_Speaker = 8300;
integer GI_N_GoTo    = 8400;
integer GI_N_Titler  = 8500;
integer GN_N_CORE    = 8600;
integer GI_N_Leash   = 8700;
integer GI_N_Zapper  = 8800;
//integer GI_N_Interface = 8900;
integer GN_N_DB      = 8950;

integer GI_Debug = FALSE;





/*
    Collar Core Stuff
*/
string GS_CollarName = "Tether Collar";
string GS_Version = "0.02.01";
// end of collar core stuff

key GK_GroupID = "bba4ab91-691d-a362-3245-b6a1469142fb"; // omega group

integer GI_IC = FALSE; // ic/ooc?

/*
*   ACTIVE CHAR DATA
*/
integer GI_ID = 0;
string GS_TypeA = "N";
string GS_TypeB = "N";
string GS_Flag = "A";
string GS_Rank = "0";
integer GI_Rank = 0;

string GS_FullRank = "Visitor";

// CUSTOM DATA
string GS_ChatTitle = "";
string GS_Line_Scent = "";
string GS_Line_Injury = "";
string GS_Line_Status = "";

string CS_Name = "00000";
string GS_Crime = "Unset";

vector GV_RColour = <0.5,0.5,0.5>;
// END OF ACTIVE CHAR DATA

integer GI_ActiveChar = 0; // marker of active character found in chars index

list GL_Loaded_Chars_Index = []; // indexing list
list GL_Loaded_Chars_Data_A = []; // DB char data
list GL_Loaded_Chars_Data_B = []; // local only char data

integer GI_Chan_Server = 9; // noteserver channel

list GL_RoleCols = [ 
    "G", <1,0,0>, <0.5,0,0>, // Guard
    "E", <1,0.5,0>, <0.5,0.25,0>, // Mechanic
    "M", <0,1,0.5>, <0,0.25,0.25>, // Medic
    "P", <0.2,0.5,1>, <0.15,0.15,0.35>, // Inmate
    "U", <1,0,1>, <0.25,0,0.25>, // Unit
    "X", <1,1,1>, <0.25,0.25,0.25>, // Agent
    "H", <1,1,0>, <0.5,0.5,0> // Bounty Hunter
];

list GL_Ranktitles = [
    0, "Non-Entity",
    1, "Visitor|P|Prisoner",
    3, "Visitor|P|Trustee",
    10, "Entity|G|Guard|E|Mechanic|M|Medic|U|Unit|H|Hunter|X|Agent",
    11, "Sergeant|X|Agent",
    15, "Staff Sergeant|X|Agent",
    20, "2nd Lieutenant|X|Agent",
    21, "Lieutenant|X|Agent",
    22, "Captain|X|Agent",
    23, "Major|X|Agent",
    31, "Agent"
];
//  END OF FIXED VALUES

integer GI_HoldActive = FALSE; // holding active state

integer GI_ChanMin = 500000; // channel gen base
integer GI_ChanRng = 100000; // channel gen range


/*
*   END OF VARS
*/

debug( string msg ) {
    if( GI_Debug ) {
        string output = llGetScriptName() +": "+ msg;
        llOwnerSay( output );
        llWhisper( -9966, output );
        integer per = (integer)(((float)llGetSPMaxMemory() / (float)llGetMemoryLimit()) * 100);
        integer alt = (integer)(((float)llGetSPMaxMemory() / (float)llGetMemoryLimit()) * 100);
        llSetText( llGetScriptName() +" "+ (string)per +"% Mem Usage", <1,1,1>, 1.0 );
    }
}




/*
*   menu reigster stuff
*/
string GS_Pri_Menu = "Setup";
string GS_Pub_Menu = "Character";

list GL_Menu_Pri = [ 
        "Debug", "-", "Role"
    ];

list GL_Menu_Pub = ["-", "Dummy!", "-"];


integer GI_N_MenuRef = 5000;

integer GI_N_PriMenu;
integer GI_N_PubMenu;




register() {
    //debug( "Register" );
    llMessageLinked( LINK_SET, GI_N_MenuRef, GS_Pri_Menu, "addPriMenu" );
    llMessageLinked( LINK_SET, GI_N_MenuRef, GS_Pub_Menu, "addPubMenu" );
}



procPubCmd( key id, list tokens ) {
    //debug( "procPubCmd: "+ llDumpList2String( tokens, " | " ) );
    string cmd = llToLower( llList2String( tokens, 0 ) );
    if( cmd == "Derp" ) {
        // do stuff
    } else {
        debug( "Unknown Pub Command: "+ cmd );
    }
}


integer procPriCmd( key id, list tokens ) {
    //debug( "procPriCmd: "+ llDumpList2String( tokens, " | " ) );
    string cmd = llToLower( llList2String( tokens, 0 ) );
    if( cmd == "debug" ) {
        GI_Debug = !GI_Debug;
        llOwnerSay( llGetScriptName() +" Debug set: "+ (string)GI_Debug );
    } else if( cmd == "role" ) {
        llMessageLinked( LINK_SET, GI_N_MenuRef, "menu|"+ (string)id +"|"+ llDumpList2String( GenCharMenu(), "|" ), "openMenu" );
        return FALSE;
    } else if( cmd == "refresh" ) {
        fetchChars();
        //llMessageLinked( LINK_SET, GI_N_MenuRef, "menu|"+ (string)id +"|"+ llDumpList2String( ["-", "-", "Role"], "|" ), "openMenu" );
        //return FALSE;
    } else {
        cmd = llList2String( tokens, 0 );
        integer index = llListFindList( GL_Loaded_Chars_Index, [ cmd ] );
        if( index != -1 ) {
            loadChar( index+1 );
        } else {
            debug( "Unknown Pri Command: "+ cmd );
        }
    }
    return TRUE;
}


list genPubMenu( key id ) {
    return GL_Menu_Pub;
}

list genPriMenu( ) {
    return GL_Menu_Pri;
}

menuCommon( integer src, string msg, key cmd ) {
    //debug( "Menu: "+ msg +" : "+ (string)cmd );
    if( cmd == "getMenu" ) {
        register();
    } else if( cmd == "setPubChan" ) {
        list tokens = llParseStringKeepNulls( msg, ["|"], [] );
        if( llList2String( tokens, 0 ) == GS_Pub_Menu ) {
            GI_N_PubMenu = (integer)llList2String( tokens, 1 );
            //debug( "SetPubChan: "+ (string)GI_N_PubMenu );
        }
    } else if( cmd == "setPriChan" ) {
        list tokens = llParseStringKeepNulls( msg, ["|"], [] );
        if( llList2String( tokens, 0 ) == GS_Pri_Menu ) {
            GI_N_PriMenu = (integer)llList2String( tokens, 1 );
            //debug( "SetPriChan: "+ (string)GI_N_PriMenu );
        }
    }
}

menuPriInput( integer src, string msg, key cmd ) {
    //debug( "Pri Cmd: "+ (string)src +" : "+ msg +" : "+ (string)cmd );
    if( cmd == "selectMenu" ) {
        list tokens = llParseStringKeepNulls( msg, ["|"], [] );
        if( llList2String( tokens, 0 ) == "menu" ) {
            llMessageLinked( src, GI_N_MenuRef, "menu|"+ llList2String( tokens, 1 ) +"|"+ llDumpList2String( genPriMenu(), "|" ), "openMenu" );
                
        } else if( llList2String( tokens, 0 ) == "menuOption" ){
            if( procPriCmd( llList2Key( tokens, 1 ), llList2List( tokens, 2, -1 ) ) ) {
                llMessageLinked( src, GI_N_MenuRef, "menu|"+ llList2String( tokens, 1 ) +"|"+ llDumpList2String( genPriMenu(), "|" ), "openMenu" );
            }
        }
    } else {
        debug( "Unknown Pri Action: "+ msg +" : "+ (string)cmd );
    }
}


menuPubInput( integer src, string msg, key cmd ) {
    //debug( "Pub Cmd: "+ (string)src +" : "+ msg +" : "+ (string)cmd );
    if( cmd == "selectMenu" ) {
        list tokens = llParseStringKeepNulls( msg, ["|"], [] );
        if( llList2String( tokens, 0 ) == "menu" ) {
            //llMessageLinked( src, GI_N_MenuRef, "menu|"+ llList2String( tokens, 1 ) +"|"+ llDumpList2String( genPubMenu( llList2Key( tokens, 1 ) ), "|" ), "openMenu" );
            llOwnerSay( "!!!Pub Cmd: "+ msg );
        } else if( llList2String( tokens, 0 ) == "menuOption" ){
            procPubCmd( llList2Key( tokens, 1 ), llList2List( tokens, 2, -1 ) );
            llMessageLinked( src, GI_N_MenuRef, "menu|"+ llList2String( tokens, 1 ) +"|"+ llDumpList2String( genPubMenu( llList2Key( tokens, 1 ) ), "|" ), "openMenu" );
        }
    } else {
        //debug( "Unknown Pub Action: "+ msg +" : "+ (string)cmd );
    }
}


/*
*   END OF MENU REGISTER STUFF
*/




//  Perform Default Setup
setup() {
    //debug( "setup" );
    setIC( FALSE );
}

// REZED ON GROUND
clear() {
    //debug( "clear" );
    llSetLinkPrimitiveParamsFast( LINK_ROOT, [
                PRIM_NAME, "OT Collar "+ GS_Version
            ] );
    GenDesc( "N", "N", "N", "00", llGetOwner() );
}

// ATTACHED
init() {
    //debug( "init" );
    llSetLinkPrimitiveParamsFast( LINK_ROOT, [
                PRIM_NAME, GS_CollarName
            ] );
    GenDesc( "N", "N", "N", "00", llGetOwner() );
    fetchChars();
}

// reset all scripts
resetAll() {
    //debug( "resetAll" );
    integer count = llGetInventoryNumber( INVENTORY_SCRIPT );
    string me = llGetScriptName();
    while( count-- ) {
        string name = llGetInventoryName( INVENTORY_SCRIPT, count );
        if( name != me ) {
            if( llGetSubString( name, 0, 2 ) == "OC_" ) {
                llResetOtherScript( name );
            }
        }
    }
    //llResetScript( );
}




string getRankTitle( integer rank, string flag ) {
    //debug( "GetRank: "+ (string)rank +" : "+ flag );
    string o_rank = "";
    integer index = llListFindList( GL_Ranktitles, [rank] );
    if( index != -1 ) {
        list temp = llParseString2List( llList2String( GL_Ranktitles, index+1 ), ["|"], [] );
        index = llListFindList( temp, [flag] );
        if( index != -1 ) {
            o_rank = llList2String( temp, index+1 );
        } else {
            o_rank = llList2String( temp, 0 );
        }
    }
    debug( "GotRank: "+ o_rank );
    return o_rank;
}

string getRole( string flag ) {
    //debug( "getRole: "+ flag );
    list roles = [ "Entity", 
            "P", "Prisoner",
            "G", "Guard", 
            "E", "Mechanic",
            "M", "Medic",
            "U", "Unit",
            "H", "Hunter",
            "X", "Agent"
        ];
    integer index = 1 + llListFindList( roles, [flag] );
    //debug( "gR: "+ (string)index +" : "+ llList2String( roles, index ) );
    return llList2String( roles, index );
}

integer getRank( key id ) {
    //debug( "getRank: "+ (string)id );
    list data = llGetAttachedList( id );
    integer count = llGetListLength( data );
    while( count-- ) {
        key pid = llList2Key( data, count );
        list peram = llGetObjectDetails( pid, [OBJECT_NAME, OBJECT_DESC] );
        if( llList2String( peram, 0 ) == GS_CollarName ) {
            integer rank = llList2Integer( llCSV2List( llList2String( peram, 1 ) ), 4 );
            debug( "Test Rand: "+ (string)rank +" "+ (string)id );
            return rank;
        }
    }
    //debug( "Test Rand: 0 "+ (string)id );
    return 0;
}

vector getFlagColour( string flag ) {
    //debug( "getFlagColour: "+ flag );
    vector col = <0.5,0.5,0.5>;
    integer index = llListFindList( GL_RoleCols, [flag] );
    if( index != -1 ) {
        col = llList2Vector( GL_RoleCols, index+1 );
    }
    return col;
}






//  Generate String Verificastion Hash
string genHash( string fa, string fb, string ff, string fr, key id ) {
    //debug( "genHash" );
    return llGetSubString( llMD5String( fa +":"+ fb +":"+ ff +":"+ fr, user2Chan( id, 100, 100 ) ), 0, 12 );
}

//  Generate True Format Desc
string GenDesc( string fa, string fb, string ff, string fr, key id ) {
    //debug( "genDesc" );
    string desc = GS_Version +","+ fa +","+ fb +","+ ff +","+ fr +","+ genHash( fa, fb, ff, fr, id );
    llSetLinkPrimitiveParamsFast( LINK_ROOT, [ 
            PRIM_DESC, desc
        ] );
    return desc;
}

//  Generate an int based on a UUID
integer user2Chan(key id, integer min, integer rng ) {
    //debug( "user2Chan: "+ (string)id +" : "+ (string)min +" : "+ (string)rng );
    integer viMult = 1;
    if( min < 0 ) { viMult = -1; }
    return ( min + (viMult * (((integer)("0x"+(string)id) & 0x7FFFFFFF) % rng)));
}


list GenCharMenu() {
    //debug( "GenCharMenu: (\n"+ llDumpList2String( GL_Loaded_Chars_Index, "\n" ) +")" );
    list buttons = llList2ListStrided( GL_Loaded_Chars_Index, 0, -1, 2 );
    integer num = 7 - llGetListLength( buttons );
    
    buttons = ["Refresh"] + llList2List( ["-", "-", "-", "-", "-", "-", "-", "-"], 0, num ) + buttons;
    return buttons;
}


// UPDATE TITLER
updateTitler() {
    //debug( "updateTitler" );
    string id = "Titler";
    llMessageLinked( LINK_SET, GI_N_Titler, "setCrime|"+ GS_Crime, id );
    llMessageLinked( LINK_SET, GI_N_Titler, "setName|"+ CS_Name, id );
    llMessageLinked( LINK_SET, GI_N_Titler, "setRank|"+ GS_Rank, id );
        
    llMessageLinked( LINK_SET, GI_N_Titler, "setFlag|"+ GS_FullRank, id );//GS_Flag, "" );
    llMessageLinked( LINK_SET, GI_N_Titler, "setCol|"+ (string)GV_RColour, id );
}

// turn TITLER ON/OFF
titlerEnable( integer on ) {
    llMessageLinked( LINK_SET, GI_N_Titler, "enable|"+ (string)on, "Titler" );
}

// UPDATE TALKER
updateTalker() {
    //debug( "updateTalker" );
    if( GS_FullRank == "Inmate" ) {
        //llMessageLinked( LINK_SET, GI_N_Speaker, "cset_title|"+ GS_FullRank +" "+CS_Name, "" );
        if( GS_ChatTitle != "" ) {
            llMessageLinked( LINK_SET, GI_N_Speaker, "setTitle|"+ GS_FullRank +" - "+ CS_Name +" ("+ GS_ChatTitle +")", "Talker" );
        } else {
            llMessageLinked( LINK_SET, GI_N_Speaker, "setTitle|"+ GS_FullRank +" - "+CS_Name, "Talker" );
        }
    } else {
        if( GS_ChatTitle != "" ) {
            llMessageLinked( LINK_SET, GI_N_Speaker, "setTitle|"+ GS_FullRank +" "+GS_ChatTitle, "Talker" );
        } else {
            llMessageLinked( LINK_SET, GI_N_Speaker, "setTitle|"+ GS_FullRank +" - "+CS_Name, "Talker" );
        }
    }
    
    llMessageLinked( LINK_SET, GI_N_Titler, "SetScent|"+ GS_Line_Scent, "Titler" );
    llMessageLinked( LINK_SET, GI_N_Titler, "SetInjury|"+ GS_Line_Injury, "Titler" );
    llMessageLinked( LINK_SET, GI_N_Titler, "SetStatus|"+ GS_Line_Status, "Titler" );
}

// punish an inmate for trying to set a custom name
punishNameSet() {
    //integer index = (integer)llFloor( llFrand( llGetListLength( GL_Insults ) ) );
    applyZap( 10 );
    //GS_ChatTitle = llList2String( GL_Insults, index );
    //updateTalker();
}

// TURN TALKER ON OR OFF
talkerEnable( integer on ) {
    if( on ) {
        llMessageLinked( LINK_SET, GI_N_Speaker, "Enable|1", "Talker" );
    } else {
        llMessageLinked( LINK_SET, GI_N_Speaker, "Enable|0", "Talker" );
    }
}


// UPDATE LEASH
updateLeash() {
    leashColour( GV_RColour );
}

leashGrab( key id ){
    llMessageLinked( LINK_SET, GI_N_Leash, "Leash|"+ (string)id, "Leash" );
}

leashExtend( float len ) {
    llMessageLinked( LINK_SET, GI_N_Leash, "LeashLengthAdd|"+(string)len, "Leash" );
}

leashColour( vector col ) {
    llMessageLinked( LINK_SET, GI_N_Leash, "LeashColour|"+ (string)col, "Leash" );
}

// ZAP THE BASTARD
applyZap( integer len ) {
    //debug( "applyZap: "+ (string)len );
    GI_HoldActive = TRUE;
    llMessageLinked( LINK_SET, GI_N_Zapper, (string)len, "do_zap" );
}



// UPDATE APPEARANCE
updateAppearance( integer active ) {
    //debug( "updateAppearance: "+ (string)active );
    float mod = 0.5;
    integer bright = FALSE;
    float glow = 0.0;
    if( active || GI_HoldActive ) {
        llSetTimerEvent( 15 );
        mod = 1;
        bright = TRUE;
        glow = 0.2;
    }
    if( GI_IC ) {
        integer i;
        integer num = llGetNumberOfPrims();
        for( i=1; i<=num; ++i ) {
            if( ".FlagCol" == llList2String( llGetLinkPrimitiveParams( i, [PRIM_DESC] ), 0 ) ) {
                llSetLinkPrimitiveParamsFast( i, [
                                    PRIM_COLOR, ALL_SIDES, GV_RColour*mod, 1,
                                    PRIM_FULLBRIGHT, ALL_SIDES, bright,
                                    PRIM_GLOW, ALL_SIDES, glow
                            ] );
                if( GI_Rank >= 31 || GS_Flag == "X" ) {
                    llSetLinkTextureAnim( i, ANIM_ON | LOOP, ALL_SIDES, 1,400, 1,400, 40 );
                } else {
                    llSetLinkTextureAnim( i, 0, ALL_SIDES, 1,400, 1,400, 40 );
                }
            }
        }
    } else {
        integer i;
        integer num = llGetNumberOfPrims();
        for( i=1; i<=num; ++i ) {
            if( ".FlagCol" == llList2String( llGetLinkPrimitiveParams( i, [PRIM_DESC] ), 0 ) ) {
                llSetLinkPrimitiveParamsFast( i, [
                                    PRIM_COLOR, ALL_SIDES, <0.2,0.2,0.2>*mod, 1,
                                    PRIM_FULLBRIGHT, ALL_SIDES, bright,
                                    PRIM_GLOW, ALL_SIDES, glow
                            ] );
                if( GI_Rank >= 31 || GS_Flag == "X" ) {
                    llSetLinkTextureAnim( i, ANIM_ON | LOOP, ALL_SIDES, 1,400, 1,400, 40 );
                } else {
                    llSetLinkTextureAnim( i, 0, ALL_SIDES, 1,400, 1,400, 40 );
                }
            }
        }
    }
}

// UPDATE IC/OOC STATE
setIC( integer ic ) {
    //debug( "setIC: "+ (string)ic );
    GI_IC = ic;
    string mood = (string)GI_IC;
    llMessageLinked( LINK_SET, GI_N_Titler, mood, "set_mood" );
    llMessageLinked( LINK_SET, GI_N_Speaker, mood, "set_mood" );
    updateAppearance( TRUE );
}


/*
*   CHARACTER HANDLING
*/

// request character sheet from server
getCharSheet( key id ) {
    llRegionSay( GI_Chan_Server, "SRV|"+ (string)llGetOwner() +"|"+ (string)id );
}

// call to server script to look up character
fetchChars() {
    //debug( "fetchChars" );
    llMessageLinked( LINK_SET, GN_N_DB, "Load_Char", "http_act" );
}

//   insert character into local data
//   user role as refferance
insertChar( string msg ) {
    //debug( "insertChar "+ msg );
    ///Load_Char|1|2|1|P|1|Being%20a%20Stupid%20Fucking%20Cat|Eternity|Never
    list data = llParseString2List( msg, ["|"], [] );
    integer marker = (integer)llList2String( data, 1 );
    integer index = llListFindList( GL_Loaded_Chars_Data_A, [marker] );
    if( index == -1 ) {
        debug( "Inserting: "+ (string)marker );
        GL_Loaded_Chars_Index += [ getRole( llList2String( data, 4 ) ), marker ];
        GL_Loaded_Chars_Data_A += [marker, llDumpList2String( llList2List( data,3,-1 ), "|" ) ];
        GL_Loaded_Chars_Data_B += [marker, "|||"];
    } else {
        debug( "Updating: "+ (string)marker );
        GL_Loaded_Chars_Data_A = llListReplaceList( GL_Loaded_Chars_Data_A, 
            [ llDumpList2String( llList2List( data,3,-1 ), "|" )
                ], index+1, index+1 );
    }
    
    if( marker == GI_ActiveChar ) {
        loadChar( GI_ActiveChar );
    }
}

// load the currently active character
loadChar( integer marker ) {
    //debug( "loadChar "+ (string)marker );

    GI_ActiveChar = marker;
    
    loadCharLocalData( marker );
    
    integer index = 1 + llListFindList( GL_Loaded_Chars_Data_A, [marker] );
    
    setIC( FALSE );
    
    if( index != 0 && index < llGetListLength( GL_Loaded_Chars_Data_A ) ) {
        list data = llParseString2List( llList2String( GL_Loaded_Chars_Data_A, index ), ["|"], [] );

        GI_ID = 403 + (integer)llList2String( data, 0 );
        GS_Flag = llList2String( data, 1 );
        GS_Rank = llList2String( data, 2 );
        GI_Rank = (integer)GS_Rank;
        GS_Crime = llUnescapeURL( llList2String( data, 3 ) );
        
        GS_TypeA = "A";
        GS_TypeB = "A";
        
        CS_Name = (string)( ((integer)GS_Rank)*10000 + GI_ID );
        while( llStringLength( CS_Name ) < 6 ) {
            CS_Name = "0"+ CS_Name;
        }
        
        GS_FullRank = getRankTitle( (integer)GS_Rank, GS_Flag );
        GV_RColour = getFlagColour( GS_Flag );
    } else {
        GI_ID = 0;
        GS_Rank = "00";
        GS_Flag = "N";
        GS_Crime = "Unknown";
        
        GS_TypeA = "A";
        GS_TypeB = "A";
        
        CS_Name = (string)( ((integer)GS_Rank)*10000 + GI_ID );
        while( llStringLength( CS_Name ) < 6 ) {
            CS_Name = "0"+ CS_Name;
        }
    }
        
    GenDesc( GS_TypeA, GS_TypeB, GS_Flag, GS_Rank, llGetOwner() );
    updateAppearance( TRUE );
    
    updateTitler();
    updateTalker();
    updateLeash();
    
    setIC( TRUE );
}

// load suplamentory data
loadCharLocalData( integer marker ) {
    //debug( "loadCharLocalData: "+ (string)marker );
    integer index = 1 + llListFindList( GL_Loaded_Chars_Data_A, [marker] );
    
    if( index != 0 && index < llGetListLength( GL_Loaded_Chars_Data_B ) ) {
        list data = llParseStringKeepNulls( llList2String( GL_Loaded_Chars_Data_B, index ), ["|"], [] );
        GS_ChatTitle = llList2String( data, 0 );
        GS_Line_Scent = llList2String( data, 1 );
        GS_Line_Injury = llList2String( data, 2 );
        GS_Line_Status = llList2String( data, 3 );
    } else {
        GS_ChatTitle = "";
        GS_Line_Scent = "";
        GS_Line_Injury = "";
        GS_Line_Status = "";
    }
    
    updateTitler();
    updateTalker();
}

// save current active character custom data
updateLocalData() {
    //debug( "updateLocalData" );
    string name = GS_ChatTitle;
    if( GS_FullRank == "Inmate" ) {
        name = "";
    }
    saveCharLocalData( GI_ActiveChar, name, GS_Line_Scent, GS_Line_Injury, GS_Line_Status );
}

// save custom data
saveCharLocalData( integer marker , string name, string scent, string injury, string status ) {
    //debug( "updateLocalCharData: "+ (string)marker +" : "+ name +" : "+ scent +" : "+ injury +" : "+ status );
    integer index = llListFindList( GL_Loaded_Chars_Data_B, [marker] );
    string data = name +"|"+ scent +"|"+ injury +"|"+ status;
    if( index == -1 ) {
        GL_Loaded_Chars_Data_B += [marker, data];
    } else {
        GL_Loaded_Chars_Data_B = llListReplaceList( GL_Loaded_Chars_Data_B, [data], index+1, index+1 );
    }
}







/*
   EVENTS
*/
default {
    state_entry() {
        debug( "state_entry" );
        llSetLinkPrimitiveParamsFast( LINK_SET, [PRIM_TEXT, "", <1,1,1>, 1] );
        llScriptProfiler(PROFILE_SCRIPT_MEMORY);
        //llSetTimerEvent( 5 );
        setup();
        if( llGetAttached() ) {
            init(); // set name for active user
        } else {
            clear(); // set default name for on ground rez
        }
        register();
    }
    
    on_rez( integer peram ) {
        debug( "on_rez" );
        llScriptProfiler(PROFILE_SCRIPT_MEMORY);
        if( !llGetAttached() ) {
            setup();
            clear(); // set default name for on ground rez
        }
    }
    
    attach( key id ) {
        debug( "attach" );
        if( id ) {
            setup();
            init();
        }
    }
    
    timer() {
        llSetTimerEvent( 0 );
        updateAppearance( FALSE );
    }

    link_message( integer src, integer num, string msg, key id ) {
        debug( "link_message: "+ (string)num +" : "+ msg +" : "+ (string)id );
        if( num == 100 || num == GN_N_CORE ) {
            list data = llParseString2List( msg, ["|"], [] );
            //msg = "";
            string token = llList2String( data, 0 );
            
            if( id == "Char_Data" ) {
                insertChar( msg );
            } else if( id == "debug" ) {
                GI_Debug = (integer)msg;
            } else if( id == "Status" ) {
                if( token == "Zap" ) {
                    token = llList2String( data, 1 );
                    if( token == "Active" ) {
                        GI_HoldActive = TRUE;
                        updateAppearance( TRUE );
                    } else if( token == "Recover" ) {
                        GI_HoldActive = FALSE;
                        updateAppearance( FALSE );
                    } else if( token == "Done" ) {
                        GI_HoldActive = FALSE;
                        updateAppearance( FALSE );
                    }
                } 
            }
        } else if( num == 5000 ) {
            menuCommon( src, msg, id );
        } else if( num == GI_N_PriMenu ) {
            menuPriInput( src, msg, id );
        } else if( num == GI_N_PubMenu ) {
            menuPubInput( src, msg, id );
        }
        
    }
    
    changed( integer change ) {
        if( change & CHANGED_INVENTORY ) {
            debug( "changed Inv" );
            state reset;
        } else if( change & CHANGED_OWNER ) {
            debug( "changed Own" );
            state reset;
        }
    }
    
}

//  RESET SEQUENCE
state reset {
    state_entry() {
        debug( "reset: State Entry" );
        llSetTimerEvent( 5.0 );
    }
    
    touch_start( integer num ) {
        debug( "reset: Touch Start" );
        llRegionSayTo( llDetectedKey(0), 0, "Rebooting" );
    }
    
    timer() {
        debug( "reset: Timer" );
        llSetTimerEvent(0);
        resetAll();
        state default;
    }
    
    changed( integer change ) {
        debug( "reset: Changed" );
        if( change & CHANGED_INVENTORY ) {
            llSetTimerEvent(5);
        }
    }
    
}
