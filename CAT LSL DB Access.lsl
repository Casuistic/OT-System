integer SECRET_NUMBER = 0; // nope!
string SECRET_STRING= "cat"; // nope!
string GU_DB_Url = "http://www.cat.net/cat/cat.php"; // nope!

string GS_MEM_TAB = "Member_Data";
string GS_CHR_TAB = "Character_Data";
string GS_LOG_TAB = "Character_Event_Log";







integer GI_N_Dialog = 8100;
integer GI_N_Relay = 8200;
integer GI_N_Speaker = 8300;
integer GI_N_GoTo = 8400;
integer GI_N_Titler = 8500;
integer GI_N_Interface = 8900;
integer GI_N_Zapper = 8800;
integer Gi_N_Leash = 8700;

integer GN_N_HData = 8600;
integer GN_N_DB = 8950;




string GS_Act;
key GK_Req;

integer GI_Action_Count;
list GL_Action_Queue;


integer GI_ActiveChar = -1;
list GL_Loaded_Chars_Index = []; // indexing list
list GL_Loaded_Chars_Data_A = []; // DB char data
list GL_Loaded_Chars_Data_B = []; // local only char data




list GL_RoleCols = [ 
    "G", <1,0,0>, <0.5,0,0>, // Guard
    "E", <1,0.5,0>, <0.5,0.25,0>, // Mechanic
    "M", <0,1,0.5>, <0,0.25,0.25>, // Medic
    "P", <0.2,0.5,1>, <0.15,0.15,0.35>, // Inmate
    "U", <1,0,1>, <0.25,0,0.25>, // Unit
    "X", <1,1,1>, <0.25,0.25,0.25>, // Agent
    "H", <1,1,0>, <0.5,0.5,0> // Bounty Hunter
];

list GL_Roles = [ 
    "Entity", 
    "P", "Prisoner",
    "G", "Guard", 
    "E", "Mechanic",
    "M", "Medic",
    "U", "Unit",
    "H", "Hunter",
    "X", "Agent"
];

list GL_Ranktitles = [
    0, "Non-Entity",
    1, "Visitor|P|Prisoner",
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




integer GI_Debug = TRUE;
debug( string msg ) {
    if( GI_Debug ) {
        llOwnerSay( llGetScriptName() +": "+ msg );
    }
}




key dbRequest( string url, list l ) {
    integer i;
    string body;
    integer len = llGetListLength(l) & 0xFFFE; // make it even
    for( i=0; i<len; i+=2 ) {
        string v_name = llList2String( l, i );
        string v_val = llList2String( l, i+1 );
        if( i>0 ) {
            body += "&";
        }
        body += llEscapeURL( v_name ) +"="+ llEscapeURL( v_val );
    }
    string hash = llMD5String( body + llEscapeURL( SECRET_STRING ), SECRET_NUMBER );
    return llHTTPRequest(url+"?hash="+hash,[HTTP_METHOD,"POST",HTTP_MIMETYPE,"application/x-www-form-urlencoded"],body);
}


key db_Lookup_Character( key id ) {
    string job = "SELECT id, Role, Rank, Crime, Sentence, DaysToFreedom, Note FROM "+ GS_CHR_TAB +" WHERE UUID = '"+ escapeKey(id) +"' ORDER BY id, Role";
    return dbRequest( GU_DB_Url, ["ACTION", "Q", "QUERY", job ] );
}


string escapeKey( key uuid ) {
    string output = llEscapeURL( uuid );
    integer index;
    while( (index = llSubStringIndex( output, "%2D" )) != -1 ) {
        output = llInsertString( llDeleteSubString( output, index, index+2 ), index, "-" );
    }
    return output;
}


procData( string act, string msg ) {
    debug( "procData ["+ act +"] ["+ msg +"]" );
    if ( act == "Load_Char" ){
        list data = llParseString2List( llGetSubString(llStringTrim( msg, STRING_TRIM ), 1, -2 ), [">\n<"], [] );
        integer i;
        integer num = llGetListLength( data );
        for( i=0; i<num; i++ ) {
            insertChar( llList2String( data, i ) );
            llMessageLinked( LINK_SET, GN_N_HData, act +"|"+ (string)(i+1) +"|"+ (string)num +"|"+ llList2String( data, i ), "Char_Data" );
        }
        dumpChars();
    } else {
        debug( "procData: Act Unknown: ["+ act +"]" );
    }
}


procHTTPAction( string act ) {
    debug( "procAction ["+ act +"]" );
    integer index = llListFindList( GL_Action_Queue, [act] );
    if( index == -1 ) {
        GL_Action_Queue += act;
        if( GK_Req == NULL_KEY || GK_Req == "" ) {
            procNextHTTPAction();
        }
    }
}


procNextHTTPAction() {
    debug( "procNextAction" );
    if( llGetListLength( GL_Action_Queue ) == 0 ) {
        llSetTimerEvent( 0 );
        debug( "procNextAction: Done" );
    } else {
        llSetTimerEvent( 3 );
        string act = llList2String( GL_Action_Queue, 0 );
        if( act == "Load_Char" ) {
            GS_Act = act;
            GK_Req = db_Lookup_Character( llGetOwner() );
        } else {
            GL_Action_Queue = llDeleteSubList( GL_Action_Queue, 0, 0 );
            debug( "procNextAction: Act Unknown ["+ act +"]" );
        }
    }
}





dumpChars() {
    integer i;
    integer num = llGetListLength( GL_Loaded_Chars_Index );
    for( i=0; i<num; i+=2 ) {
        integer marker = llList2Integer( GL_Loaded_Chars_Index, i+1 );
        integer indexA = llListFindList( GL_Loaded_Chars_Data_A, [marker] );
        integer indexB = llListFindList( GL_Loaded_Chars_Data_B, [marker] );
        if( indexA == -1 || indexB == -1 ) {
            debug( "dumpChars: WTF?" );
        }
        llOwnerSay( 
                "Dump: "+ llList2String( GL_Loaded_Chars_Index, i ) 
                +" : "+ (string)marker
                +" : "+ llList2String( GL_Loaded_Chars_Data_A, indexA+1 )
                +" : "+ llList2String( GL_Loaded_Chars_Data_B, indexB+1 )
                );
    }
}


string convertIDNToNum( integer idn, integer rank ) {
    string fid = (string)((403+idn) + (10000*rank) );
    return llGetSubString( "000000", llStringLength(fid), 6 ) + fid;
}


string getRole( string flag ) {
    integer index = 1 + llListFindList( GL_Roles, [flag] );
    return llList2String( GL_Roles, index );
}

//   insert character into local data
//   user role as refferance
insertChar( string msg ) {
    debug( "insertChar "+ msg );
    // 1|P|1|Being%20a%20Stupid%20Fucking%20Cat|Eternity|Never
    list data = llParseString2List( msg, ["|"], [] );
    integer marker = (integer)llList2String( data, 0 );
    integer index = llListFindList( GL_Loaded_Chars_Data_A, [marker] );
    string fid = llList2String( data, 1 ) +"-"+ convertIDNToNum( marker, (integer)llList2String( data, 2 ) );
    if( index == -1 ) {
        debug( "Inserting: "+ (string)marker );
        GL_Loaded_Chars_Index += [fid, marker];
        GL_Loaded_Chars_Data_A += [marker, getRole( llList2String( data, 1 ) ) +"|"+ llList2String( data, 1 ) +"|"+ llDumpList2String( llList2List( data,2,-1 ), "|" ) ];
        GL_Loaded_Chars_Data_B += [marker, "|||"];
    } else {
        debug( "Updating: "+ (string)marker );
        GL_Loaded_Chars_Data_A = llListReplaceList( GL_Loaded_Chars_Data_A, 
            [ 
                    //llDumpList2String( llList2List( data,2,-1 ), "|" )
                    getRole( llList2String( data, 1 ) ) 
                    +"|"+ llList2String( data, 1 ) 
                    +"|"+ llDumpList2String( llList2List( data,2,-1 ), "|" )
                ], index+1, index+1 );
    }
    
    if( marker == GI_ActiveChar ) {
        //loadChar( GI_ActiveChar );
    }
}


procDataLookup( string act ) {
    integer index = llListFindList( GL_Loaded_Chars_Index, [act] );
    string output = act;
    if( index != -1 ) {
        integer marker = llList2Integer( GL_Loaded_Chars_Index, index+1 );
        index = llListFindList( GL_Loaded_Chars_Data_A, [marker] );
        if( index != -1 ) {
            output += "|"+ llList2String( GL_Loaded_Chars_Data_A, marker );
        } else {
            output += "|"+ llList2String( GL_Loaded_Chars_Data_A, 0 );
        }
        index = llListFindList( GL_Loaded_Chars_Data_B, [marker] );
        if( index != -1 ) {
            output += "|"+ llList2String( GL_Loaded_Chars_Data_B, marker );
        } else {
            output += "|"+ llList2String( GL_Loaded_Chars_Data_B, 0 );
        }
    }
    llOwnerSay( "Lookup: "+ output );
    //llMessageLinked( LINK_SET, GN_N_HData, act +"|"+ (string)(i+1) +"|"+ (string)num +"|"+ llList2String( data, i ), "Char_Data" );
}


// integer GI_Action_Count;
// list GL_Action_Queue;
default {

    link_message( integer src, integer num, string msg, key id ) {
        if( num == 100 || num == GN_N_DB ) {
            if( id == "http_act" ) {
                debug( "LM: ["+ msg +"] ["+ (string)id +"]" );
                procHTTPAction( msg );
            } else if( id == "fetch_data" ) {
                debug( "LM: ["+ msg +"] ["+ (string)id +"]" );
                procDataLookup( msg );
            } else if( id == "debug" ) {
                if( msg == "debug:Enable" ) {
                    GI_Debug = TRUE;
                    debug( "Link_Message: Debug Enabled" );
                } else {
                    debug( "Link_Message: Debug Enabled" );
                    GI_Debug = TRUE;
                }
            }
        }
    }
    
    
    http_response( key req, integer status, list meta, string body ) {
        if( req == GK_Req ) {
            string act = GS_Act;
            GK_Req = NULL_KEY;
            GS_Act = "";
            if ( status != 200 ) {
                llOwnerSay( "the internet exploded!! There has been a server error" );
                debug( "http_response Err: ["+ body +"] ["+ (string)status +"]" );
                llSetTimerEvent( 10 );
            } else {
                debug( "http_response Loaded: "+ body );
                GL_Action_Queue = llDeleteSubList( GL_Action_Queue, 0, 0 );
                body = llStringTrim( body, STRING_TRIM );
                string ack = llGetSubString( body, 0, 2 );
                if( ack == "NAK" ) {
                    // Handle NAK
                    llOwnerSay( "Something went wrong. NAK Error" );
                } else {
                    procData( act, llGetSubString( body, 3, -1 ) );
                }
            }
        }
    }
    
    
    timer() {
        if( GK_Req == NULL_KEY ) {
            procNextHTTPAction();
        } else if( GI_Action_Count <= 6 ){
            GI_Action_Count += 1;
        } else {
            debug( "timer Abort: ["+ (string)GK_Req +"] ["+ GS_Act +"]" );
            GK_Req = NULL_KEY;
            GS_Act = "";
            GL_Action_Queue = llDeleteSubList( GL_Action_Queue, 0, 0 );
        }
    }
    
}
