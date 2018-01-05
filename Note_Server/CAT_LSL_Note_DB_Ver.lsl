integer SECRET_NUMBER = 0; // nope!
string SECRET_STRING= "cat"; // nope!
string GU_DB_Url = "http://www.cat.net/cat/catdb.php"; // nope!

string GS_MEM_TAB = "Member_Data";
string GS_CHR_TAB = "Character_Data";
string GS_LOG_TAB = "Character_Event_Log";



list GL_Roles = [ "Prisoner", "Guard", "Medic", "Mechanic", "Unit", "Agent", "Bounty Hunter", "Hunter" ];

list GL_RoleFlagIndex = [ 0, "P", 1, "G", 2, "M", 3, "E", 4, "U", 5, "X", 6, "H", 7, "H" ];


string GS_Notecard;
integer GI_Type;

key GK_Req;
key GK_Ins;
key GK_Mem;



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


string escapeKey( key uuid ) {
    string output = llEscapeURL( uuid );
    integer index;
    while( (index = llSubStringIndex( output, "%2D" )) != -1 ) {
        output = llInsertString( llDeleteSubString( output, index, index+2 ), index, "-" );
    }
    return output;
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


key db_Insert_Character( key id, string role, integer rank, string crime, string stay ) {
    string job = "INSERT INTO "+ GS_CHR_TAB +" "
                +"(UUID,Role,Rank,Crime,Sentence,DaysToFreedom) VALUES "
                +"('"+ escapeKey(id) + "','" + llEscapeURL(role) + "','"+ (string)rank +"','"+ llEscapeURL(crime) +"','"+ llEscapeURL(stay) +"','Never')";
    return dbRequest( GU_DB_Url, ["ACTION", "I", "QUERY", job ] );
}


key db_Insert_Member( key id, string name ) {
    string job = "INSERT INTO "+ GS_MEM_TAB +" (UUID,SL_Username,Last_Seen) VALUES ('"+(string)id + "','"+ name +"',Now())";
    return dbRequest( GU_DB_Url, ["ACTION", "I", "QUERY", job ] );
}


key db_SeekQuiz( key id ) {
    string job = "SELECT UUID FROM "+ GS_MEM_TAB +" WHERE UUID = '"+ escapeKey(id) +"'";
    llOwnerSay( job );
    return dbRequest( GU_DB_Url, ["ACTION", "Q", "QUERY", job ] ); 
}


key db_SeekRole( key id, string flag ) {
    string job = "SELECT UUID, Role FROM "+ GS_CHR_TAB +" WHERE UUID='"+ escapeKey(id) +"' AND Role='"+ llEscapeURL( flag ) +"'";
    llOwnerSay( job );
    return dbRequest( GU_DB_Url, ["ACTION", "Q", "QUERY", job ] ); 
}


integer procNext() {
    integer qnt = llGetInventoryNumber( INVENTORY_NOTECARD );
    if( qnt != 0 ) {
        if( GS_Notecard != "" && GI_Type != 0 ) {
            llOwnerSay( "Reprocess: "+ GS_Notecard );
            startProc();
            llSetTimerEvent( 15 );
        } else {
            string name = llGetInventoryName( INVENTORY_NOTECARD, 0 );
            llOwnerSay( "Process: "+ name );
            integer valid = validNote( name );
            if( valid ) {
                GS_Notecard = name;
                GI_Type = valid;
                startProc();
                llSetTimerEvent( 15 );
            } else {
                purge( name );
                llSetTimerEvent( 3 );
            }
        }
    }
    return qnt;
}

startProc() {
    if( GI_Type == 1 ) {
        list data = formatNote( GS_Notecard );
        GK_Req = db_SeekRole( llList2Key( data, 1 ), llList2Key( data, 0 ) );
    } else if( GI_Type == 2 ) {
        list data = llParseString2List( GS_Notecard, [" "], [] );
        //GK_Req = db_SeekQuiz( (key)"27ba04ef-297e-4b29-fdfb-942b47985ec7" );// llList2Key( data, 0 ) );
        integer index = llListFindList( data, ["Quiz"] );
        if( index == 1 ) {
            GK_Req = db_SeekQuiz( llList2Key( data, 0 ) );
        } else {
            GK_Req = db_SeekQuiz( llList2Key( data, 1 ) );
        }
    }
}



list formatNote( string name ) {
    list data = llParseStringKeepNulls( name, [" "], [] );
    if( llList2String( data, 0 ) == "Bounty" && llList2String( data, 1 ) == "Hunter" ) {
        data = llListReplaceList( data, ["Bounty Hunter"], 0, 1 );
    }
    
    integer index = llListFindList( GL_Roles, llList2List( data, 0, 0 ) );
    if( index != -1 ) {
        index = llListFindList( GL_RoleFlagIndex, [index] );
        if( index != -1 ) {
            data = llListReplaceList( data, [llList2String( GL_RoleFlagIndex, index+1 )], 0, 0 );
        } else {
            data = llListReplaceList( data, ["A"], 0, 0 );
        }
    } else {
        data = llListReplaceList( data, ["A"], 0, 0 );
    }

    return data;
}


runRoleCheck( list data ) {
    //llOwnerSay( "[ "+ llDumpList2String( data, " | " ) +" ]" );
    if( llGetListLength( data ) == 0 ) {
        list info = formatNote( GS_Notecard );
        integer rank = 10;
        if( llList2String( info, 0 ) == "P" ) {
            rank = 1;
        } else if( llList2String( info, 0 ) == "A" ) {
            rank = 0;
        }
        GK_Ins = db_Insert_Character( llList2Key( info, 1 ), llList2String( info, 0 ), 10, "??", "??" );
        llSetTimerEvent( 15 );
    } else {
        purge( GS_Notecard );
        GS_Notecard = "";
        GI_Type = 0;
        llSetTimerEvent( 3 );
    }
}


runQuizCheck( list data ) {
    //llOwnerSay( "[ "+ llDumpList2String( data, " | " ) +" ]" );
    if( llGetListLength( data ) == 0 ) {
        list data = llParseString2List( GS_Notecard, [" "], [] );
        integer index = llListFindList( data, ["Quiz"] );
        key id = NULL_KEY;
        if( index == 1 ) {
            id = llList2Key( data, 0 );
        } else if( index == 0 ) {
            id = llList2Key( data, 1 );
        }
        string name = catGetName( id );
        GK_Mem = db_Insert_Member( id, name );
        llSetTimerEvent( 15 );
    } else {
        purge( GS_Notecard );
        GS_Notecard = "";
        GI_Type = 0;
        llSetTimerEvent( 3 );
    }
}


purge( string name ) {
    if( llGetInventoryType( name ) == INVENTORY_NOTECARD ) {
        llRemoveInventory( name );
        llMessageLinked( LINK_THIS, 101, "", "Update" );
    }
}


integer validNote( string note ) {
    list data = llParseString2List( note, [" "], [] );
    if( llListFindList( GL_Roles, [llDumpList2String( llList2List( data, 0, -2 ), " " )] ) != -1 && llStringLength( llList2String( data, -1 ) ) >= 3 ) {
        return 1;
    } else if( llListFindList( data, ["Quiz"] ) != -1 ) {
        return 2;
    }
    return 0;
}


default {
    state_entry() {
        llSetLinkPrimitiveParams( LINK_SET, [PRIM_TEXT, "", <1,1,1>, 1] );
        llSetTimerEvent( 5 );
    }
    
    changed( integer flag ) {
        if( flag & CHANGED_INVENTORY ) {
            llSetTimerEvent( 5 );
        }
    }
    
    http_response( key req, integer status, list meta, string body ) {
        if( req == GK_Req ) {
            if( status != 200 ) {
                llSay( 0, "Err:: External Server Error" );
                llOwnerSay( "Srv Error: "+ (string)status );
                return;
            } else {
                body = llStringTrim( body, STRING_TRIM );
                string lead = llGetSubString( body, 0, 2 );
                if( lead != "ACK" ) {
                    llSay( 0, "Err: NAK Recieved" );
                    llOwnerSay( "Srv Error: "+ lead );
                } else {
                    if( GI_Type == 1 ) {
                        if( llStringLength( body ) == 3 ) {
                            runRoleCheck( [] );
                        } else {
                            runRoleCheck( llParseString2List( llGetSubString( body, 4, -2 ), [">\n<"], [] ) );
                        }
                        return;
                    } else if( GI_Type == 2 ) {
                        if( llStringLength( body ) == 3 ) {
                            runQuizCheck( [] );
                        } else {
                            runQuizCheck( llParseString2List( llGetSubString( body, 4, -2 ), [">\n<"], [] ) );
                        }
                        return;
                    }
                }
            }
        }
    }

    timer() {
        if( !procNext() ) {
            llSetTimerEvent( 0 );
            return;
        }
    }
}
