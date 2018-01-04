//  CORE 116
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
string GS_Version = "0.01.16";
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

integer GI_ChanMin = 500000; // channel gen base
integer GI_ChanRng = 100000; // channel gen range

integer GI_CD_Listen; // custom data listen

// open listen data
list GL_ActiveCUser;
list GL_ActiveChans;
list GL_ActiveCLAct;
list GL_ActiveCLEar;
// END OF CHAN GEN

integer GI_HoldActive = FALSE; // holding channel open

string GS_Action = ""; // custom data entry action holder

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
    1, "Visitor|P|Inmate",
    3, "Visitor|P|Trustee",
    10, "Entity|G|Guard|E|Mechanic|M|Medic|U|Unit|H|Hunter|X|Agent",
    11, "Sergeant|X|Agent",
    15, "Staff Sergeant|X|Agent",
    20, "2nd Lieutenant|X|Agent",
    21, "Lieutenant",
    22, "Captain|X|Agent",
    23, "Major|X|Agent",
    31, "Agent"
];
//  END OF FIXED VALUES



/*
*   END OF VARS
*/

debug( string msg ) {
    if( GI_Debug ) {
        string output = llGetScriptName() +": "+ msg;
        llOwnerSay( output );
        llWhisper( -9966, output );
    }
}

//  Perform Default Setup
setup() {
    //debug( "setup" );
    killAllListens();
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
    //debug( "GotRank: "+ o_rank );
    return o_rank;
}


string getRole( string flag ) {
    list roles = [ "Entity", 
            "P", "Inmate",
            "G", "Guard", 
            "E", "Mechanic",
            "M", "Medic",
            "U", "Unit",
            "H", "Hunter",
            "X", "Agent"
        ];
    integer index = 1 + llListFindList( roles, [flag] );
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
            //debug( "Test Rand: "+ (string)rank +" "+ (string)id );
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
    llSetLinkPrimitiveParamsFast( LINK_THIS, [ 
            PRIM_DESC, desc
        ] );
    return desc;
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
        //debug( "Inserting: "+ (string)marker );
        GL_Loaded_Chars_Index += [ getRole( llList2String( data, 4 ) ), marker ];
        GL_Loaded_Chars_Data_A += [marker, llDumpList2String( llList2List( data,3,-1 ), "|" ) ];
        GL_Loaded_Chars_Data_B += [marker, "|||"];
    } else {
        //debug( "Updating: "+ (string)marker );
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
*   MENU HANDLING
*/

// get ic or ooc button
string getICorOOC() {
    return llList2String( ["[OOC]/IC", "OOC/[IC]"], GI_IC );
}

// open a dialog menu
openMenu( string data, key id ) {
    //debug( "openMenu" );
    
    if( !GI_IC && llGetOwner() != llGetOwnerKey( id ) ) {
        return;
    }
    
    list buttons;
    string info;
    integer rank = getRank( id );
    integer chan = listenSetup( id );
    
    
    if( llStringLength( data ) == 0 || data == "Main" ) {
        if( llGetOwner() == llGetOwnerKey( id ) ) {
            string update = "-";
            if( llGetOwner() == (key)"91ac2b46-6869-48f3-bc06-1c0df87cc6d6" ) {
                update = "Push";
            }
            
            buttons = [
                    "-", "Done", "-",
                    "Character", update, getICorOOC(),
                    "Punish", "Leash", "Setup"
                ];
        } else {
            buttons = [
                    "-", "Done", "-",
                    "Punish", "Leash", "Character"
                ];
        }
        info = "main";
    } else if ( data == "Setup" ) {
        buttons = ["RP Titler", "RP Chatter", "Role"];
        info = "Character Options";
        
    } else if ( data == "Role" ) {
        buttons = GenCharMenu();
        info = "Character Options";
        
    } else if ( data == "Punish" ) {
        buttons = [
                "Zap", "Stun", "Back"
            ];
        info = "Zap Collar Options";
        
    } else if ( data == "Chatter" ) {
        buttons = ["Setup", "Done", "Main",
                    "Chatter On", "Chatter Off", "Set Name"
                ];
        info = "Chatter Options";
        
    } else if ( data == "Leash" ) {
        buttons = [
                "-", "Done", "Main",
                "-5 Length", "-1 Length", "Leash Drop",
                "+5 Length", "+1 Length", "Leash Grab"
            ];
        info = "Leash Options";
        
    } else if ( data == "Titler" ) {
        buttons = [ "Setup", "Done", "Main",
                    "Titler On", "Titler Off", "-",
                    "Set Scent", "Set Injury", "Set Status"
                ];
        info = "Titler Options";
        
    } else if ( data == "Debug" ) {
        buttons = ["Debug On", "Debug Off", "Back"];
        info = "Debug Options";
    } else {
        //debug( "Else: "+ data );
        buttons = ["Character", "Debug", "Back" ];
        info = "Oups?";
    }
    
    if( data == "-" ) {
        updateAppearance( FALSE );
    } else if( data == "Text" ) {
        updateAppearance( TRUE );
        llTextBox( id, "Enter Custom Data", openDataListen() );
    } else {
        updateAppearance( TRUE );
        llDialog( id, info, buttons, listenSetup( id ) );
    }
    
}

// generate the character meny
// KEYWORD needs overhaul
list GenCharMenu() {
    list buttons = [];
    integer i;
    integer e;
    integer num = llGetListLength( GL_Loaded_Chars_Data_A );
    if( num == 0 ){
        buttons = ["-", "-", "-", "-", "-", "-"];
    } else {
        integer layers = 1;
        if( (llGetListLength( GL_Loaded_Chars_Data_A ) / 2) > 7 ) {
            layers = 2;
        }
        for( e=layers; e>=0; --e ){
            for( i=2; i >= 0; --i ) {
                integer ref = (((e*3)+i)*2)+1;
                if( ref < num ) {
                    list tokens = llParseString2List( llList2String( GL_Loaded_Chars_Data_A, ref ), ["|"], [] );
                    //buttons += "#"+(string)i +": "+ getRole( llList2String( tokens, 1 ) );
                    buttons += getRole( llList2String( tokens, 1 ) );
                } else {
                    buttons += "-";
                }
            }
        }
    }
    buttons = ["Refresh", "Setup", "Main"] + buttons;
    return buttons;
}



/*
*   COMMAND HANDLING
*/

// command processing hub
procCommand( string cmd, key id ) {
    key user = llGetOwnerKey( id );
    string menu = "Main";
    
    if( cmd == "-" ) {
        return;
    } else {
        string end = procOwnerCommand( cmd, id );
        if( end == "" ) {
            if( cmd == "Back" || cmd == "Main" ) { // go to main menu
                menu = "Main";
            } else if( cmd == "Punish" ) { // go to character picker menu
                menu = "Punish";
            } else if( cmd == "Zap" ) {
                applyZap( 4 );
                menu = "-";
            } else if( cmd == "Stun" ) {
                applyZap( 30 );
                menu = "-";
            } else if( cmd == "Leash" ) {
                menu = "Leash";
            } else if( cmd == "Character" ) {
                menu = "-";
                if( id == llGetOwnerKey(id) ) {
                    getCharSheet( id );
                }
            } else if( cmd == "Role" ) {
                menu = "Role";
            } else if( cmd == "Push" ) {
                llMessageLinked( LINK_SET, 500, "push", llGetOwner() );
                menu = "Main";
            }
            
            else if( cmd == "Leash Grab" ) {
                leashGrab( id );
                menu = "Leash";
            } else if( cmd == "Leash Drop" ) {
                leashGrab( NULL_KEY );
                menu = "Leash";
            } else if( cmd == "-5 Length" ) {
                leashExtend( -5 );
                menu = "Leash";
            } else if( cmd == "+5 Length" ) {
                leashExtend( 5 );
                menu = "Leash";
            } else if( cmd == "-1 Length" ) {
                leashExtend( -1 );
                menu = "Leash";
            } else if( cmd == "+1 Length" ) {
                leashExtend( 1 );
                menu = "Leash";
            } else if( cmd == "Done" ) {
                menu = "-";
            }
            
        } else {
            menu = end;
        }
    }
    
    openMenu( menu, user );
}

// owner only commands
string procOwnerCommand( string cmd, key id ) {
    //debug( "procOwnerCommand: "+ cmd +" : "+ (string)id );
    string output = "";
    if( llGetOwner() == llGetOwnerKey( id ) ) {
        integer index = llListFindList( GL_Loaded_Chars_Index, [ cmd ] );
        if( index != -1 ) {
            output = "-";
            loadChar( llList2Integer( GL_Loaded_Chars_Index, index+1 ) );
        } else if( cmd == "Setup" ) { // go to character picker menu
            output = "Setup";
        } else if( cmd == "RP Chatter" ) { // go to character picker menu
            output = "Chatter";
        } else if( cmd == "Chatter On" ) {
            output = "Setup";
            talkerEnable( TRUE );
        } else if( cmd == "Chatter Off" ) {
            output = "Setup";
            talkerEnable( FALSE );
        }  else if( cmd == "Set Name" ) {
            output = "Text";
            GS_Action = "SetChatTitle";
        }
        
        
        else if( cmd == "RP Titler" ) { // go to character picker menu
            output = "Titler";
        } else if( cmd == "Titler On" ) { // go to character picker menu
            output = "Titler";
            titlerEnable( TRUE );
        } else if( cmd == "Titler Off" ) { // go to character picker menu
            output = "Titler";
            titlerEnable( FALSE );
        } 
        
        else if( cmd == "Refresh" ) { // refresh character list
            output = "Role";
            fetchChars();
        }
        
        else if( cmd == "Set Scent" ) {
            output = "Text";
            GS_Action = "SetScent";
        } else if( cmd == "Set Injury" ) {
            output = "Text";
            GS_Action = "SetInjury";
        } else if( cmd == "Set Status" ) {
            output = "Text";
            GS_Action = "SetStatus";
        } 
        
        
        else if( cmd == "[OOC]/IC" ) {
            output = "Main";
            setIC( TRUE );
        } else if( cmd == "OOC/[IC]" ) {
            output = "Main";
            setIC( FALSE );
        }
        
        
        else if( cmd == "Debug" ) { // go to debug menu
            output = "Debug";
        } else if( cmd == "Debug On" ) {
            output = "Debug";
            llMessageLinked( LINK_SET, 100, "1", "debug" );
        } else if( cmd == "Debug Off" ) {
            output = "Debug";
            llMessageLinked( LINK_SET, 100, "0", "debug" );
        }
    }
    return output;
}

// process custom data entry
procCustomData( string act, string data ) {
    string output = "Main";
    if( act == "SetScent" ) {
        output = "Titler";
        GS_Line_Scent = data;
        llListenRemove( GI_CD_Listen );
        llMessageLinked( LINK_SET, GI_N_Titler, "SetScent|"+ GS_Line_Scent, "Titler" );
        updateLocalData();
    } else if( act == "SetInjury" ) {
        output = "Titler";
        GS_Line_Injury = data;
        llListenRemove( GI_CD_Listen );
        llMessageLinked( LINK_SET, GI_N_Titler, "SetInjury|"+ GS_Line_Injury, "Titler" );
        updateLocalData();
    } else if( act == "SetStatus" ) {
        output = "Titler";
        GS_Line_Status = data;
        llListenRemove( GI_CD_Listen );
        llMessageLinked( LINK_SET, GI_N_Titler, "SetStatus|"+ GS_Line_Status, "Titler" );
        updateLocalData();
    } else if( act == "SetChatTitle" ) {
        output = "Chatter";
        llListenRemove( GI_CD_Listen );
        if( (integer)GS_Rank < 10 ) {
            punishNameSet();
        } else {
            GS_ChatTitle = data;
            updateLocalData();
            updateTalker();
        }
    }
    openMenu( output, llGetOwner() );
}



/*
*   LISTEN HANDLING
*/

// setup listens
integer listenSetup( key id ) {
    //debug( "listenSetup" );
    integer chan;// = 1000 + (integer)llFrand( 1000 );//user2Chan( id, GI_ChanMin, GI_ChanRng );
    integer index = llListFindList( GL_ActiveCUser, [id] );
    if( index == -1 ) {
        chan = 1000 + (integer)llFrand( 1000 );//user2Chan( id, GI_ChanMin, GI_ChanRng );
        GL_ActiveCUser += id;
        GL_ActiveChans += llListen( chan, "", id, "" );
        GL_ActiveCLAct += llGetUnixTime();
        GL_ActiveCLEar += chan;
        //debug( "Listening for: "+ (string)chan +" "+ (string)id );
    } else {
        llListReplaceList( GL_ActiveCLAct, [llGetUnixTime()], index, index );
        chan = llList2Integer( GL_ActiveCLEar, index );
        //debug( "Held for: "+ (string)chan +" "+ (string)id );
    }
    llSetTimerEvent( 60 );
    return chan; 
}

// Kill all the listens
killAllListens() {
    //debug( "killAllListens" );
    integer i;
    integer num = llGetListLength( GL_ActiveChans );
    for( i=0; i<num; i++ ) {
        llListenRemove( llList2Integer( GL_ActiveChans, i ) );
    }
    GL_ActiveCUser = [];
    GL_ActiveChans = [];
    GL_ActiveCLAct = [];
    GL_ActiveCLEar = [];
}

// setup data listen
integer openDataListen() {
    //debug( "openDataListen" );
    llListenRemove( GI_CD_Listen );
    integer chan = 2000 + (integer)llFrand( 1000 );//user2Chan( id, GI_ChanMin, GI_ChanRng );
    GI_CD_Listen = llListen( chan, "", llGetOwner(), "" );
    return chan;
}

//  Generate an int based on a UUID
integer user2Chan(key id, integer min, integer rng ) {
    //debug( "user2Chan: "+ (string)id +" : "+ (string)min +" : "+ (string)rng );
    integer viMult = 1;
    if( min < 0 ) { viMult = -1; }
    return ( min + (viMult * (((integer)("0x"+(string)id) & 0x7FFFFFFF) % rng)));
}


/*
   EVENTS
*/
default {
    state_entry() {
        //debug( "state_entry" );
        llSetText( "", <1,1,1>, 1.0 );
        //llScriptProfiler(PROFILE_SCRIPT_MEMORY);
        //llSetTimerEvent( 5 );
        setup();
        if( llGetAttached() ) {
            init(); // set name for active user
        } else {
            clear(); // set default name for on ground rez
        }
    }
    
    on_rez( integer peram ) {
        //debug( "on_rez" );
        if( !llGetAttached() ) {
            setup();
            clear(); // set default name for on ground rez
        }
    }
    
    attach( key id ) {
        //debug( "attach" );
        if( id ) {
            setup();
            init();
        }
    }
    
    listen( integer chan, string name, key id, string msg ) {
        //debug( "Listen: "+ (string)chan +" "+ name +" "+ msg );
        if( chan < 1000 ) { // huh?
            //debug( "Low Chan Error?" );
        } else if( chan < 2000 ) { // command data
            procCommand( msg, id );
        } else if( chan < 3000 ) { // custom data
            if( GS_Action != "" ) {
                procCustomData( GS_Action, msg );
            }
        }
    }
    
    timer() {
        llSetTimerEvent( 0 );
        updateAppearance( FALSE );
        //llSetText( (string)(llGetUsedMemory()/1024) +" / "+ (string)(llGetMemoryLimit()/1024), <1,1,1>, 1 );
        //llOwnerSay("This script used at most " + (string)llGetSPMaxMemory() + " bytes of memory during my_func.");
    }
    
    touch_start( integer num ) {
        //debug( "tough_start: "+ llDetectedName( 0 ) );
        integer i;
        for( i=0; i < num; ++i ) {
            openMenu( "Main", llDetectedKey( 0 ) );
        }
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        //debug( "link_message: "+ (string)num +" : "+ msg +" : "+ (string)id );
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
        }
    }
    
    changed( integer change ) {
        if( change & CHANGED_INVENTORY ) {
            //debug( "changed Inv" );
            state reset;
        } else if( change & CHANGED_OWNER ) {
            //debug( "changed Own" );
            state reset;
        }
    }
    
}

//  RESET SEQUENCE
state reset {
    on_rez( integer peram ) {
        resetAll();
        state default;
    }

    state_entry() {
        //debug( "reset: State Entry" );
        llSetTimerEvent( 5.0 );
    }
    
    touch_start( integer num ) {
        //debug( "reset: Touch Start" );
        llRegionSayTo( llDetectedKey(0), 0, "Rebooting" );
    }
    
    timer() {
        //debug( "reset: Timer" );
        llSetTimerEvent(0);
        resetAll();
        state default;
    }
    
    changed( integer change ) {
        //debug( "reset: Changed" );
        if( change & CHANGED_INVENTORY ) {
            llSetTimerEvent(5);
        }
    }
    
}
