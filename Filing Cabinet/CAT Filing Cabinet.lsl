integer SECRET_NUMBER = -1; // nope!
string SECRET_STRING= "cat"; // nope!
string GU_DB_Url = "http://www.cat.com/cat/cat.php"; // Nope!

string GS_MEM_TAB = "Member_Data";
string GS_CHR_TAB = "Character_Data";
string GS_LOG_TAB = "Character_Event_Log";

key GK_Req_IN;
key GK_Req_LU;
key GK_Req_UP;


integer GI_DB_Chan = -9966;


integer GI_Srv_Chan = -20202020;

integer GI_Base = -100000;
integer GI_Range = 900000;

integer GI_CountDown;

list GL_Colours = [ <0.23,0.23,0.23>, <1,0,0>, <1,1,0>, <0,1,0>, <0,1,1>, <0,0,1>, <1,0,1>, <0,0,0> ];

integer GI_Listen;



key GK_ActiveAgent;
string GS_ActiveAgentName;





list GL_Role_Titles = [ "Prisoner", "Bounty Hunter", "Guard", "Medic", "Mechanic", "Unit" ];// Agent
list GL_Role_Flags = [ "P", "H", "G", "M", "E", "U" ]; // X

key GK_Subject_Id = NULL_KEY; 
string GS_Subject_Name = "None";
integer GI_Subject_Role_Index = 0;
integer GI_Subject_Rank = 0;
string GS_Subject_Crime = "Unknown";
string GS_Subject_Sentence = "Forever";

string GS_NC_Name;



/*
*
*/
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

/*
*
*/
key db_Lookup_Character( key id, string role ) {
    string job = "SELECT id, UUID, Role, Rank, Crime FROM "+ GS_CHR_TAB +" WHERE UUID = '"+ escapeKey(id) +"' AND Role='"+ llEscapeURL( role ) +"' ORDER BY Role";
    llRegionSay( GI_DB_Chan, "job: "+ job );
    return dbRequest( GU_DB_Url, ["ACTION", "Q", "QUERY", job ] );
}

/*
*
*/
key GK_Req_FM;
key db_Lookup_Member( key id ) {
    string job = "SELECT * FROM "+ GS_MEM_TAB +" WHERE UUID = '"+ escapeKey(id) +"'";
    llRegionSay( GI_DB_Chan, "job: "+ job );
    return dbRequest( GU_DB_Url, ["ACTION", "Q", "QUERY", job ] );
}

/*
*
*/
key GK_Req_IM;
key db_Insert_Member( key id, string name ) {
    string job = "INSERT INTO "+ GS_MEM_TAB +" (UUID,SL_Username,Last_Seen) VALUES ('"+(string)id + "','"+ name +"',Now())";
    llRegionSay( GI_DB_Chan, "job: "+ job );
    return dbRequest( GU_DB_Url, ["ACTION", "Q", "QUERY", job ] );
}

/*
*
*/
key db_Insert_Character( key id, string role, integer rank, string crime, string stay ) {
    string job = "INSERT INTO "+ GS_CHR_TAB +" "
                +"(UUID,Role,Rank,Crime,Sentence,DaysToFreedom) VALUES "
                +"('"+ escapeKey(id) + "','" + llEscapeURL(role) + "','"+ llEscapeURL((string)rank) +"','"+ llEscapeURL(crime) +"','"+ llEscapeURL(stay) +"','Never')";
    llRegionSay( GI_DB_Chan, "job: "+ job );
    return dbRequest( GU_DB_Url, ["ACTION", "I", "QUERY", job ] );
}

/*
*   
*/
key db_Update_Character( key id, string role, integer rank, string crime, string stay ) {
    string job = "UPDATE "+ GS_CHR_TAB +" SET "
                +"UUID='"+ escapeKey(id) +"', "
                +"Role='"+llEscapeURL( role )+"',"
                +"Rank='"+llEscapeURL( (string)rank )+"',"
                +"Crime='"+llEscapeURL( crime )+"',"
                +"Sentence='"+llEscapeURL( stay )+"',"
                +"DaysToFreedom='Never' "
    +"WHERE UUID='"+ escapeKey(id) +"' AND Role='"+llEscapeURL( role )+"'";
    llRegionSay( GI_DB_Chan, "job: "+ job );
    return dbRequest( GU_DB_Url, ["ACTION", "U", "QUERY", job ] );
}

/*
*
*/
string escapeKey( key uuid ) {
    string output = llEscapeURL( uuid );
    integer index;
    while( (index = llSubStringIndex( output, "%2D" )) != -1 ) {
        output = llInsertString( llDeleteSubString( output, index, index+2 ), index, "-" );
    }
    return output;
}


string getSentence() {
    list options = [ 
            "Forever", "10^12 Years", "Eternity", 
            "Endless", "Indefinite", "In Perpetuity",
            "Permanent", "Evermore", "Forevermore",
            "in perpetuum", "Perpetual", "Everlasting"
            ];
    integer index = (integer)llFrand( llGetListLength( options ) );
    return llList2String( options, index );
}


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


integer verifyUser( key id ) {
    if( llSameGroup( id ) ) {
        return TRUE;
    }
    return FALSE;
}


integer verifyObject( key id ) {
    if( llSameGroup( id ) ) {
        return TRUE;
    }
    return FALSE;
}


openDrawer( integer open ) {
    integer i;
    integer link = 0;
    if( open ) {
        link = 2 + ( (integer)llFrand( (llGetNumberOfPrims()-1) ) );
        llTriggerSound( "8658a6a6-c175-69c5-8eb8-c78de8a2ef52", 1 );
    } else {
        llTriggerSound( "b33b1f37-2144-7e53-e77d-4465327838a7", 1 );
    }
    for( i=2; i<=llGetNumberOfPrims(); i++ ) {
        vector pos = llList2Vector( llGetLinkPrimitiveParams( i, [PRIM_POS_LOCAL] ), 1 );
        if( i==link ) {
            pos.y = -0.5;
        } else {
            pos.y = -0.02;
        }
        pos.z = 0.01+(0.418*(i-3));
        llSetLinkPrimitiveParamsFast( i, [PRIM_POS_LOCAL, pos] );
    }
}


openBox( integer open ) {
    if( open ) {
        llAllowInventoryDrop( TRUE );
        llSetClickAction( CLICK_ACTION_OPEN );
        GI_CountDown = 15;
        llSetTimerEvent( 5 );
    } else {
        llAllowInventoryDrop( FALSE );
        llSetClickAction( CLICK_ACTION_NONE );
        llSetTimerEvent( 0 );
    }
}


setDisplay( integer face, integer text, string msg ) {
    vector fCol = llList2Vector( GL_Colours, face );
    vector tCol = llList2Vector( GL_Colours, text );
    llSetLinkPrimitiveParamsFast( LINK_THIS, [
                PRIM_COLOR, 0, fCol, 1,
                PRIM_TEXT, msg, tCol, 1
            ] );
}


cleanInv() {
    integer qnt = llGetInventoryNumber( INVENTORY_NOTECARD );
    while( qnt-- ) {
        llRemoveInventory( llGetInventoryName( INVENTORY_NOTECARD, qnt ) );
    }
}


returnInv( key id ) {
    integer qnt = llGetInventoryNumber( INVENTORY_NOTECARD );
    list cards;
    while( qnt-- ) {
        cards += llGetInventoryName( INVENTORY_NOTECARD, qnt );
    }
    if( llGetListLength( cards ) != 0 ) {
        llGiveInventoryList( id, "Rejected Cards: "+ (string)llGetTimestamp(), cards );
    }
}


procCard( key id ) {
    string text = "None";
    list buttons = ["Done"];
    integer qnt = llGetInventoryNumber( INVENTORY_NOTECARD );
    if( qnt != 0 ) {
        GS_NC_Name = llGetInventoryName( INVENTORY_NOTECARD, 0 );
        list data = procNoteName( GS_NC_Name );
        integer index = llListFindList( GL_Role_Titles, [llList2String( data, 0 )] );
        if( llGetListLength( data ) == 2 && (index != -1 || llList2String(data,0) == "Quiz" ) && llList2Key( data, 1 ) != NULL_KEY && llList2Key( data, 1 ) != "" ) {
            llOwnerSay( llList2String( data,0 ) +" : "+ llList2String( data,1 ) );
            if( index == -1 ) {
                GI_Subject_Role_Index = index;
                GK_Subject_Id = (string)llList2Key( data, 1 );
                GS_Subject_Name = catGetName( GK_Subject_Id );
                text =
                    "Quiz\n"
                    +"Subject: "+ GS_Subject_Name +"\n"
                    +"Membership Approval\n"
                    ;
                buttons = [" Approve ", " Reject ", "Done"];
            } else {
                string title_A;
                string title_B;
                if( index == 0 ) {
                    GI_Subject_Rank = 1;
                    title_A = "Crime";
                    title_B = "Sentence";
                    GS_Subject_Crime = "Undefirned";
                    GS_Subject_Sentence = getSentence();
                } else {
                    GI_Subject_Rank = 10;
                    title_A = "Contract";
                    title_B = "Duration";
                    GS_Subject_Crime = "Unread";
                    GS_Subject_Sentence = getSentence();
                }
                GI_Subject_Role_Index = index;
                GK_Subject_Id = (string)llList2Key( data, 1 );
                GS_Subject_Name = catGetName( GK_Subject_Id );
                text = 
                    "Subject: "+ GS_Subject_Name +"\n"
                    +"Role: "+ llList2String( GL_Role_Titles, GI_Subject_Role_Index ) +"\n"
                    +"Rank: "+ (string)GI_Subject_Rank +"\n"
                    +title_A +": "+ GS_Subject_Crime +"\n"
                    +title_B +": "+ GS_Subject_Sentence +"\n"
                    ;
                buttons = ["Approve", "Reject", "Done"];
            }
        } else {
            text = "Something is not quite right about this notecard\n";
            if( (index == -1 && llList2String(data,0) != "Quiz" ) ) {
                text += "Unable to type this card.\n";
                text += "Available Types are as follows:\n";
                text += "["+ llDumpList2String( GL_Role_Titles, ", " ) +"]";
                text += "NC Data: "+ llDumpList2String( data, ", " );
            } else if( llList2Key( data, 1 ) == NULL_KEY || llList2Key( data, 1 ) == "" ) {
                text += "Unable to verify key!\n";
                text += "Key returned null or empty\n";
                text += "NC Data: "+ llDumpList2String( data, ", " );
            } else if( llGetListLength( data ) != 2 ) {
                text += "Notecard Format Error\n";
                text += "Format Should be \"<role> <key>\"\n";
                text += "Or \"<key> Quiz\"";
                text += "NC Data: "+ llDumpList2String( data, ", " );
            } else {
                text += "Unknown Failure State\n";
                text += "I have no idea, save this notecard and give it to Sophist!\n";
                text += "NC Data: "+ llDumpList2String( data, ", " );
            }
            buttons = ["-", "Reject", "Done"];
        }
    }
    llDialog( id, text, buttons, getChan( llGetKey(), GI_Base, GI_Range ) );
    llSetTimerEvent( 60 );
}

/*
*    
*/
list procNoteName( string name ) {
    list data = llParseString2List( name, [" "], [] );
    if( llGetListLength( data ) == 2 ) {
        if( llList2String( data, 1 ) == "Quiz" ) {
            data = [llList2String(data,1), llList2String(data,0) ];
        }
        return data;
    } else if( llGetListLength( data ) == 3 ) {
        if( llList2String( data, 0 ) == "Bounty" && llList2String( data, 1 ) == "Hunter" ) {
            data = llListReplaceList( data, ["Bounty Hunter"], 0, 1 );
            return data;
        }
    }
    return data;
}

findServer() {
    //resetListens();
    sayOpen( NULL_KEY, "open_call" );
}

resetListens() {
    //llSay( 0, "Listen Open" );
    llListenRemove( GI_Listen );
    integer chan = getChan( llGetKey(), GI_Base, GI_Range );
    GI_Listen = llListen( chan, "", "", "" );
}

integer getChan( key id, integer start, integer range ) {
    integer mod = 1;
    if( start < 0 ) {
        mod = -1; 
    }
    return ( start + ( mod * (( (integer)( "0x" + (string)id ) & 0x7FFFFFFF) % range )));
}

sayOpen( key id, string msg ) {
    llRegionSay( GI_Srv_Chan, msg );
}

integer sendFiles( key id, string inv ) {
    if( llGetInventoryType( inv ) == INVENTORY_NOTECARD && llList2Vector( llGetObjectDetails( id, [OBJECT_POS] ), 0 ) != ZERO_VECTOR ) {
        llGiveInventory( id, inv );
        llRemoveInventory( inv );
        return TRUE;
    }
    return FALSE;
}



processFailure( integer status, string body ) {
    if( status != 200 ) {
        if( status == 404 ) {
            llInstantMessage( GK_ActiveAgent, "404 Error. Server may be down." );
            } else if( status == 504 ) {
            llInstantMessage( GK_ActiveAgent, "504 Error. Server may be down." );
        } else {
            llInstantMessage( GK_ActiveAgent, "Unknown Server Error." );
            llInstantMessage( GK_ActiveAgent, "Please Report this Error to Sophist" );
        }
        llInstantMessage( GK_ActiveAgent, "Character May Not be Available Right Away but shall be reprocessed automatically." );
        llRegionSay( GI_DB_Chan, "Err: Status: "+ (string)status );
    } else if( llGetSubString( body, 0, 2 ) == "NAK" ){
        llInstantMessage( GK_ActiveAgent, "Internal Error" );
        llInstantMessage( GK_ActiveAgent, "Please Report this Error to Sophist" );
    }
    findServer();
}


/*
*   DEFAULT STATE
*/
default {
    on_rez( integer peram ) {
        state reset;
    }
    
    state_entry() {
        openDrawer( 0 );
        llSetClickAction( CLICK_ACTION_TOUCH );
        llSetTimerEvent( 5 );
    }
    
    timer() {
        llSetTimerEvent( 0 );
        setDisplay( 0, 0, "" );
    }
    
    touch( integer num ) {
        while( num-- ) {
            key id = llDetectedKey( 0 );
            if( verifyUser( id ) ) {
                GK_ActiveAgent = id;
                GS_ActiveAgentName = catGetName( id );
                state open;
            }
        }
        setDisplay( 1, 2, "Authorised Bureaucrats Only!" );
        llSetTimerEvent( 2 );
    }

}

/*
*   OPEN STATE
*/
state open {
    on_rez( integer peram ) {
        state reset;
    }
    
    state_entry() {
        llSetTimerEvent( 0 );
        setDisplay( 0, 1, "In Use By: "+ GS_ActiveAgentName +"\nAdd New File" );
        openDrawer( 1 );
        openBox( TRUE );
        llSetTimerEvent( 5 );
    }
    
    state_exit() {
        openBox( FALSE );
    }
    
    timer() {
        GI_CountDown -= 5;
        if( GI_CountDown <= 0 ) {
            state default;
        }
    }
    
    changed( integer change ) {
        llOwnerSay( (string)change );
        if( change & CHANGED_INVENTORY || change & CHANGED_ALLOWED_DROP ) {
            if( llGetInventoryNumber( INVENTORY_NOTECARD ) != 0 ) {
                state process;
            }
        }
    }
}

/*
*    
*/
state process {
    on_rez( integer peram ) {
        state reset;
    }
        
    state_entry() {
        llSetTimerEvent( 0 );
        setDisplay( 0, 1, "In Use By: "+ GS_ActiveAgentName +"\nProcess" );
        openDrawer( 1 );
        resetListens();
        procCard( GK_ActiveAgent );
    }
    
    listen( integer chan, string name, key id, string msg ) {
        llOwnerSay( name +" : "+ msg );
        if( msg == "verify" && verifyObject( id ) ) {
            if( sendFiles( id, GS_NC_Name ) ) {
                GS_NC_Name = "";
                procCard( GK_ActiveAgent );
            }
            GS_NC_Name = "";
        } else if( msg == "Approve" ) {
            GK_Req_LU = db_Lookup_Character( GK_Subject_Id, llList2String( GL_Role_Flags, GI_Subject_Role_Index ) );
        } else if( msg == "Reject" ) {
            llRemoveInventory( GS_NC_Name );
            llSleep( 0.2 );
            procCard( GK_ActiveAgent );
        } else if( msg == " Approve " ) {
            GK_Req_FM = db_Lookup_Member( GK_Subject_Id );
        } else if( msg == " Reject " ) {
            llRemoveInventory( GS_NC_Name );
            llSleep(0.2);
            procCard( GK_ActiveAgent );
        } else if( msg == "Done" ) {
            state reset;
        }
    }

    http_response( key req, integer status, list meta, string body ) {
        //llRegionSay( GI_DB_Chan, "rsp: "+ body );
        if( req == GK_Req_LU ) {
            body = llStringTrim( body, STRING_TRIM );
            if( status == 200 && llGetSubString( body, 0, 2 ) == "ACK" ) {
                if( llStringLength( body ) == 3 ) {
                    GK_Req_IN = db_Insert_Character( 
                            GK_Subject_Id, 
                            llList2String( GL_Role_Flags, GI_Subject_Role_Index ),
                            GI_Subject_Rank,
                            GS_Subject_Crime,
                            GS_Subject_Sentence
                        );
                } else {
                    GK_Req_UP = db_Update_Character( 
                            GK_Subject_Id, 
                            llList2String( GL_Role_Flags, GI_Subject_Role_Index ),
                            GI_Subject_Rank,
                            GS_Subject_Crime,
                            GS_Subject_Sentence
                        );
                }
            } else {
                processFailure( status, body );
            }
        } 
        //    INSERT
        else if( req == GK_Req_IN || req == GK_Req_UP ) {
            body = llStringTrim( body, STRING_TRIM );
            if( llGetSubString( body, 0, 2 ) == "ACK" ) {
                findServer();
            } else {
                processFailure( status, body );
            }
        } 
        // FIND MEMBER
        else if( req == GK_Req_FM ) {
            body = llStringTrim( body, STRING_TRIM );
            if( status == 200 && llGetSubString( body, 0, 2 ) == "ACK" ) {
                if( llStringLength( body ) == 3 ) {
                    GK_Req_IM = db_Insert_Member( GK_Subject_Id, catGetName( GK_Subject_Id ) );
                } else {
                    findServer();
                }
            } else {
                processFailure( status, body );
            }
        // INSERT MEMBER
        } else if( req == GK_Req_IM ) {
            body = llStringTrim( body, STRING_TRIM );
            if( status == 200 && llGetSubString( body, 0, 2 ) == "ACK" ) {
                findServer();
            } else {
                processFailure( status, body );
            }
        }
        
        else {
            llOwnerSay( "OUPS: "+ body );
        }
    }
    
    
    touch( integer num ) {
        while( num-- ) {
            key id = llDetectedKey( num );
            if( id == GK_ActiveAgent ) {
                procCard( id );
            } else {
                llInstantMessage( id, "Processing in Progress" );
            }
        }
    }
    
    timer() {
        llSetTimerEvent( 0 );
        state reset;
    }
}

/*
*   RESET STATE
*/
state reset {
    on_rez( integer peram ) {
        llResetScript();
    }
    
    state_entry( ) {
        setDisplay( 0, 0, "" );
        openBox( FALSE );
        openDrawer( FALSE );
        if( GK_ActiveAgent ) {
            returnInv( GK_ActiveAgent );
            GK_ActiveAgent = NULL_KEY;
        }
        cleanInv();
        llResetScript();
    }
}