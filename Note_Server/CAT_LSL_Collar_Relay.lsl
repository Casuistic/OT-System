
integer GI_IDNum_Srv = 9200;
integer GI_IDNum_IO = 9100;



integer GI_Chan_Server = 9;

integer GI_ListenA;



key GK_SoundErr = "f123cda7-f8ed-38b2-9c45-ad9a8507c0b4";


setup() {
    setOut( "Running Setup", <1,1,0> );
    llListenRemove( GI_ListenA );
    GI_ListenA = llListen( GI_Chan_Server, "", "", "" );
    setOut( "Setup Done", <1,1,0> );
}

setOut( string text, vector col ) {
    llSetLinkPrimitiveParamsFast( LINK_THIS, [PRIM_TEXT, text, col, 1.0]);
    llSetTimerEvent( 5.0 );
}

forwardToSrv( string name, key id, string msg ) {
    llMessageLinked( LINK_SET, GI_IDNum_Srv, msg, id );
}


update( string text, integer col ) {
    llMessageLinked( LINK_ROOT, 500+ col, text, NULL_KEY );
}


default {
    state_entry() {
        setup();
    }

    listen( integer chan, string name, key id, string msg ) {
        llOwnerSay( "Got: "+ msg );
        if( chan == GI_Chan_Server ) {
            update( "Serving!", 1 );
            forwardToSrv( name, id, msg );
            llSetTimerEvent( 3 );
        } else {
            update( "Serving?", 2 );
            setOut( "UME: "+ msg, <1,0,0> );
            llSetTimerEvent( 3 );
        }
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        if( num == GI_IDNum_IO || num == 100 ) {
            if( msg == "reset" ) {
                llResetScript();
            } else if( msg == "Set_Status" ) {
                if( id == (key)"Good" ) {
                    update( " VALID  ", 2 );
                    llSetColor( <0,1,0>, ALL_SIDES );
                    llSetTimerEvent( 5.0 );
                } else if( id == (key)"Err" ) {
                    update( " ERROR  ", 3 );
                    llSetColor( <1,0,0>, ALL_SIDES );
                    llTriggerSound( GK_SoundErr, 1 );
                    llSetTimerEvent( 5.0 );
                }
            } else {
                setOut( msg, <0,0,1> );
            }
        }
    }
    
    timer() {
        setOut( "", <1,1,1> );
        update( " Online ", 1 );
        llSetColor( <1,1,0>, ALL_SIDES );
        llSetTimerEvent( 0 );
    }
}
