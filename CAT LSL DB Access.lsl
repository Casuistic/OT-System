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





integer GI_Debug = FALSE;
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
            llMessageLinked( LINK_SET, GN_N_HData, act +"|"+ (string)(i+1) +"|"+ (string)num +"|"+ llList2String( data, i ), "Char_Data" );
            //llOwnerSay( act +"|"+ (string)(i+1) +"|"+ (string)num +"|"+ llList2String( data, i ) );
        }
    } else {
        debug( "procData: Act Unknown: ["+ act +"]" );
    }
}


procAction( string act ) {
    debug( "procAction ["+ act +"]" );
    integer index = llListFindList( GL_Action_Queue, [act] );
    if( index == -1 ) {
        GL_Action_Queue += act;
        
        if( GK_Req == NULL_KEY || GK_Req == "" ) {
            procNextAction();
        }
    }
}


procNextAction() {
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

// integer GI_Action_Count;
// list GL_Action_Queue;

default {

    link_message( integer src, integer num, string msg, key id ) {
        if( num == 100 || num == GN_N_DB ) {
            if( id == "http_act" ) {
                debug( "LM: ["+ msg +"] ["+ (string)id +"]" );
                procAction( msg );
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
                //llSay(0,"the internet exploded!! "+ (string)status );
                debug( "http_response Err: ["+ body +"] ["+ (string)status +"]" );
                llSetTimerEvent( 10 );
            } else {
                debug( "http_response Loaded: "+ body );
                GL_Action_Queue = llDeleteSubList( GL_Action_Queue, 0, 0 );
                body = llStringTrim( body, STRING_TRIM );
                string ack = llGetSubString( body, 0, 2 );
                if( ack == "NAK" ) {
                    // handle nak
                } else {
                    procData( act, llGetSubString( body, 3, -1 ) );
                }
            }
        }
    }
    
    
    timer() {
        if( GK_Req == NULL_KEY ) {
            procNextAction();
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
