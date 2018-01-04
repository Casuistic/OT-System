// UI 201



list GL_Users;
list GL_Listens;
list GL_UserMenus;

integer GI_Chan_Owner = 50;
integer GI_Chan_Users = 500;


list GL_MenuOwnerExt = [];
list GL_MenuUsersExt = [];



integer GI_N_MenuRef = 5000;

integer GI_N_MenuPriRef = 5200;
integer GI_N_MenuPubRef = 5100;


integer GI_Debug = FALSE;
debug( string msg ) {
    if( GI_Debug ) {
        string output = llGetScriptName() +": "+ msg;
        llOwnerSay( output );
        llWhisper( -9966, output );
    }
}





openDialog( key id, string menu ) {
    debug( "openDialog: "+ (string)id +" : "+ menu );
    integer chan = GI_Chan_Users;
    list buttons;
    if( id == llGetOwner() ) {
        chan = GI_Chan_Owner;
        buttons += GL_MenuOwnerExt;
    } else {
        buttons += GL_MenuUsersExt;
    }
    
    buttons = [
            "Done", "-", "-"
        ] + buttons;
    
    llDialog( id, "Test Dialog", buttons, chan );
    llMessageLinked( LINK_SET, GN_N_CORE, "setActive", "Event" );
}


openSubDialogue( key id, string msg, list buttons ) {
    debug( "openSubDialogue: "+ (string)id +" : "+ msg +" : "+ llDumpList2String( buttons, " | " ) );
    integer chan = GI_Chan_Users;
    if( id == llGetOwner() ) {
        chan = GI_Chan_Owner;
    }
    buttons = ["Done", "-", "Back"] + buttons;
    llDialog( id, "Test Dialog", buttons, chan );
}


string openChannel( key id ) {
    debug( "openChannel: "+ (string)id );
    integer mark = llListFindList( GL_Users, [id] );
    string menu;
    if( mark == -1 ) {
        debug( "openChannel: New User" );
        menu = "main";
        mark = llGetListLength( GL_Users );
        GL_Users += id;
        GL_UserMenus += [mark, menu];
    } else {
        debug( "openChannel: Existing User" );
        integer index = 1+ llListFindList( GL_UserMenus, [mark] );
        menu = llList2String( GL_UserMenus, index );
    }
    return menu;
}


clearListens() {
    GL_Users = [];
    GL_UserMenus = [];
}


setUserMenu( key id, string menu ) {
    debug( "setUserMenu: "+ (string)id +" : "+ menu );
    integer mark = llListFindList( GL_Users, [id] );
    if( mark == -1 ) { 
        debug( "sUM: Opening Channel" );
        openChannel( id );
    } else {
        debug( "sUM: Found Agent" );
        integer index = llListFindList( GL_UserMenus, [mark] ); 
        if( index != -1 ) {
            debug( "sUM: Found Menu" );
            GL_UserMenus = llListReplaceList( GL_UserMenus, [menu], index+1, index+1 );
        } else {
            debug( "sUM: Added Menu" );
            GL_UserMenus += [mark, menu];
        }
        //openDialog( id, menu );
    }
}



addPriMenu( integer src, string menu ) {
    debug( "addPriMenu: "+ (string)src +" : "+ menu );
    integer index = llListFindList( GL_MenuOwnerExt, [menu] );
    if( index == -1 ) {
        index = llGetListLength( GL_MenuOwnerExt );
        GL_MenuOwnerExt += menu;
    }
    llMessageLinked( src, GI_N_MenuRef, menu +"|"+ (string)(GI_N_MenuPriRef+index), "setPriChan" );
}



addPubMenu( integer src, string menu ) {
    debug( "addPubMenu: "+ (string)src +" : "+ menu );
    integer index = llListFindList( GL_MenuUsersExt, [menu] );
    if( index == -1 ) {
        index = llGetListLength( GL_MenuUsersExt );
        GL_MenuUsersExt += menu;
    }
    llMessageLinked( src, GI_N_MenuRef, menu +"|"+ (string)(GI_N_MenuPubRef+index), "setPubChan" );
}


getExtMenus() {
    debug( "getExtMenus" );
    GL_MenuOwnerExt = [];
    GL_MenuUsersExt = [];
    llMessageLinked( LINK_ALL_CHILDREN, GI_N_MenuRef, "getMenu", "getMenu" );
}




/*
*   LISTEN HANDLING
*/

integer GI_ChanMin = 500000; // channel gen base
integer GI_ChanRng = 100000; // channel gen range

string GS_Action = ""; // custom data entry action holder

/*
integer GI_CD_Listen; // custom data listen

// open listen data
list GL_ActiveCUser;
list GL_ActiveChans;
list GL_ActiveCLAct;
list GL_ActiveCLEar;
// END OF CHAN GEN



// setup listens
integer listenSetup( key id ) {
    debug( "listenSetup" );
    integer chan;// = 1000 + (integer)llFrand( 1000 );//user2Chan( id, GI_ChanMin, GI_ChanRng );
    integer index = llListFindList( GL_ActiveCUser, [id] );
    if( index == -1 ) {
        chan = 1000 + (integer)llFrand( 1000 );//user2Chan( id, GI_ChanMin, GI_ChanRng );
        GL_ActiveCUser += id;
        GL_ActiveChans += llListen( chan, "", id, "" );
        GL_ActiveCLAct += llGetUnixTime();
        GL_ActiveCLEar += chan;
        debug( "Listening for: "+ (string)chan +" "+ (string)id );
    } else {
        llListReplaceList( GL_ActiveCLAct, [llGetUnixTime()], index, index );
        chan = llList2Integer( GL_ActiveCLEar, index );
        debug( "Held for: "+ (string)chan +" "+ (string)id );
    }
    llSetTimerEvent( 60 );
    return chan; 
}

// setup data listen
integer openDataListen() {
    debug( "openDataListen" );
    llListenRemove( GI_CD_Listen );
    integer chan = 2000 + (integer)llFrand( 1000 );//user2Chan( id, GI_ChanMin, GI_ChanRng );
    GI_CD_Listen = llListen( chan, "", llGetOwner(), "" );
    return chan;
}

//  Generate an int based on a UUID
integer user2Chan(key id, integer min, integer rng ) {
    debug( "user2Chan: "+ (string)id +" : "+ (string)min +" : "+ (string)rng );
    integer viMult = 1;
    if( min < 0 ) { viMult = -1; }
    return ( min + (viMult * (((integer)("0x"+(string)id) & 0x7FFFFFFF) % rng)));
}

// Kill all the listens
killAllListens() {
    debug( "killAllListens" );
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
*/


procOwnerCmd( string msg, key id ) {
    debug( "procOwnerCmd: "+ msg +" : "+ (string)id );
    string menu = "main";
    integer index = llListFindList( GL_Users, [id] );
    if( index == -1 ) {
        debug( "Listen: User Not Found" );
        return;
    }
    index = llListFindList( GL_UserMenus, [index] );
    if( index == -1 ) {
        debug( "Listen: User Menu Not Found" );
        return;
    }
    
    menu = llList2String( GL_UserMenus, index+1 );
            
    if( menu == "main" ) {
        debug( "Listen: Menu is Main" );
        index = llListFindList( GL_MenuOwnerExt, [msg] );
        if( index != -1 ) {
            setUserMenu( id, msg );
            llMessageLinked( LINK_SET, GI_N_MenuPriRef+index, "menuOption|"+ (string)id +"|"+ msg, "selectMenu" );
        } else {
            debug( "Listen: Menu Option Unknown" );
        }
    } else {
        debug( "Listen: Menu isn't Main" );
        index = llListFindList( GL_MenuOwnerExt, [menu] );
        if( index != -1 ) {
            llMessageLinked( LINK_SET, GI_N_MenuPriRef+index, "menuOption|"+ (string)id +"|"+ msg, "selectMenu" );
        }
    }
}




default {
    state_entry() {
        debug( "State Entry" );
        llScriptProfiler(PROFILE_SCRIPT_MEMORY);
        llSetTimerEvent( 5 );
        llListen( GI_Chan_Owner, "", llGetOwner(), "" );
        llListen( GI_Chan_Users, "", "", "" );
        getExtMenus();
    }
    
    on_rez( integer peram ) {
        debug( "On Rez" );
        llScriptProfiler(PROFILE_SCRIPT_MEMORY);
        clearListens();
        if( llGetAttached() != 0 ) {
            getExtMenus();
        }
    }
    

    touch( integer num ) {
        debug( "Touch" );
        openDialog( llDetectedKey(0), openChannel( llDetectedKey( 0 ) ) );
    }
    
    
    link_message( integer src, integer num, string msg, key id ) {
        if( src != llGetLinkNumber() ){
            debug( "LM: "+ (string)num +" : "+ msg +" : "+ (string)id );
            if( num == GI_N_MenuRef ) {
                if( id == "addPriMenu" ) {
                    addPriMenu( src, msg );
                    return;
                } else if( id == "addPubMenu" ) {
                    addPubMenu( src, msg );
                    return;
                } else if( id == "openMenu" ) {
                    list data = llParseStringKeepNulls( msg, ["|"], [] );
                    msg = "";
                    if( llList2String( data, 0 ) == "menu" ) {
                        openSubDialogue( llList2Key( data, 1 ), "Text", llList2List( data, 2, -1 ) );
                    }
                } else {
                    debug( "Li: Rejected : "+ (string)num +" : "+ msg +" : "+ (string)id );
                }
            }
        }
    }
    
    
    listen( integer chan, string name, key id, string msg ) {
        debug( "Listen: "+ (string)chan +" : "+ msg +" : "+ (string)id );
        if( msg == "-" ) {
            // remove listen
            return;
        } else if( msg == "Done" ) {
            // remove listen
            return;
        } else if( msg == "Back" ) {
            setUserMenu( id, "main" );
            openDialog( id, "main" );
            return;
        }
        
        
        
        if( chan == GI_Chan_Owner && id == llGetOwner() ) {
            procOwnerCmd( msg, id );
        } else if( chan == GI_Chan_Users ) {
            debug( "Listen > User: "+ (string)chan +"/"+ (string)GI_Chan_Users +" : "+ msg +" : "+ (string)id );
            string menu = "main";
            integer index = llListFindList( GL_Users, [id] );
            if( index == -1 ) {
                debug( "Listen: User Not Found" );
                return;
            }
            index = llListFindList( GL_UserMenus, [index] );
            if( index == -1 ) {
                debug( "Listen: User Menu Not Found" );
                return;
            }
            menu = llList2String( GL_UserMenus, index+1 );
            
            if( menu == "main" ) {
                debug( "Listen: Menu is Main" );
                index = llListFindList( GL_MenuUsersExt, [msg] );
                if( index != -1 ) {
                    setUserMenu( id, msg );
                    llMessageLinked( LINK_SET, GI_N_MenuPubRef+index, "menuOption|"+ (string)id +"|"+ msg, "selectMenu" );
                } else {
                    debug( "Listen: Menu Option Unknown" );
                }
            } else {
                debug( "Listen: Menu isn't Main" );
                index = llListFindList( GL_MenuUsersExt, [menu] );
                llMessageLinked( LINK_SET, GI_N_MenuPubRef+index, "menuOption|"+ (string)id +"|"+ msg, "selectMenu" );
            }
            
            
            if( index != -1 ) {
                debug( "Listen: Process Command" );
            } else {
                // something has gone wrong!
                debug( "Listen: UserMenu not logged" );
            }
        }
    }
    
    
    timer() {
        //debug( "Timer" );
        integer per = (integer)(((float)llGetSPMaxMemory() / (float)llGetMemoryLimit()) * 100);
        llSetText( (string)per +"% Mem Usage", <1,1,1>, 1.0 );
    }
}
