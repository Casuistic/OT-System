key     TRANSPARENT     = "701917a8-d614-471f-13dd-5f4644e36e3c";
key     null_key        = NULL_KEY;
 
key     gFontTexture        = "b2e7394f-5e54-aa12-6e1c-ef327b6bed9e"; 


string gCharIndex  = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"; 


float xs;
float ys;
float xi;
float yi;
float xl;
float yl;

list GL_TextDisplays;
integer GI_BackLight;





setup() {
    writeReady();
}

writeReady() {
    xs = 1.0 / 20;
    ys = 1.0 / 20;
    xi = xs * 2;
    yi = ys * 2;
    xl = 0-(xs*9);
    yl = 0+(ys*9);
}



writeToMesh( integer link, string text ) {
    if( TRUE ) {//llGetLinkName( link ) == ".panel" ) {
        float xo;
        float yo;
        
        integer i;
        for( i=0; i<llGetLinkNumberOfSides( link ); i++ ){
            string char = llGetSubString( text, i, i );
            integer index = -1;
            if( llStringLength( char ) == 1 ) {
                index = llSubStringIndex( gCharIndex, char );
            } else {
                index = 0;
            }
            integer xInd = index % 10;
            integer yInd = index / 10;

            xo = xl + (xi * ( xInd ));
            yo = yl - (yi * ( yInd ));
            llSetLinkPrimitiveParamsFast( link, [
                PRIM_TEXTURE, 
                i, 
                gFontTexture, 
                <xi,yi,0>, 
                <xo,yo,0>, 
                0 ] );
        }
    }
}


writeBlank( integer link ) {
    if( TRUE ) {//llGetLinkName( link ) == ".panel" ) {
        float xo = xl + (xi * 0);
        float yo = yl - (yi * 0);
        
        integer i;
        for( i=0; i<llGetLinkNumberOfSides( link ); i++ ){
            llSetLinkPrimitiveParamsFast( link, [
                PRIM_COLOR, i, <0,0,0>, 1,
                PRIM_TEXTURE, 
                i, 
                gFontTexture, 
                <xi,yi,0>, 
                <xo,yo,0>, 
                0 ] );
        }
    }
}


colourToMesh( integer link, integer num ) {
    list cols = [<1,1,1>, <0,1,0>, <1,1,0>, <1,0,0>, <0,0,1>];
    
    if( TRUE ) {//llGetLinkName( link ) == ".panel" ) {
        float xo = xl + (xi * 0);
        float yo = yl - (yi * 0);
        
        integer i;
        for( i=0; i<llGetLinkNumberOfSides( link ); i++ ){
            llSetLinkPrimitiveParamsFast( link, [
                PRIM_COLOR, i, llList2Vector( cols, num ), 1,
                PRIM_FULLBRIGHT, i, 1,
                PRIM_GLOW, i, 0.2
                ]);
        }
    }
}



/*


*/
string GS_Notecard;

integer GI_QuizServer = 1;
integer GI_ActiveServer = 1;
integer GI_PurgedServer = 1;
integer GI_RejectedServer = 1;

integer GI_Hold = 1;
integer GI_Pass = 1;

list GL_Roles = [ "Prisoner", "Guard", "Medic", "Mechanic", "Unit", "Agent", "Bounty Hunter" ];



mapPrims() {
    integer i = 2;
    integer num = llGetNumberOfPrims();
    for( i=2; i<=num; i++ ) {
        string desc = llList2String( llGetLinkPrimitiveParams( i, [PRIM_DESC] ), 0 );
        if( desc == ".QUIZ" ) {
            GI_QuizServer = i;
        } else if( desc == ".VERIFIED" ) {
            GI_ActiveServer = i;
        } else if( desc == ".ERASED" ) {
            GI_PurgedServer = i;
        } else if( desc == ".REJECTED" ) {
            GI_RejectedServer = i;
        } else if( desc == ".HOLDING" ) {
            GI_Hold = i;
        } else if( desc == ".PASS" ) {
            GI_Pass = i;
        }
    }
    if( GI_QuizServer == 1 || GI_ActiveServer == 1 || GI_PurgedServer == 1 || GI_RejectedServer == 1 ) {
        llOwnerSay( "MISSING LINKS" );
    }
}


integer processNext() {
    integer qnt = llGetInventoryNumber( INVENTORY_NOTECARD );
    if( qnt != 0 ) {
        if( llStringLength( GS_Notecard ) >= 1 ) {
            passData( GS_Notecard );
            holdData( GS_Notecard );
            integer valid = validNote( GS_Notecard );
            if( valid == 2 ) {
                logQuiz( GS_Notecard );
            } else if( valid == 1 ) {`
                verifyData( GS_Notecard, llGetInventoryKey( GS_Notecard ) );
            } else {
                reject( GS_Notecard );
            }
        } else {
            GS_Notecard = llGetInventoryName( INVENTORY_NOTECARD, 0 );
        }
    }
    return qnt;
}


verifyData( string name, key id ) {
    //llOwnerSay( "Verify: "+ name );
    llMessageLinked( LINK_ALL_CHILDREN, 600, name, id );
}

passData( string note ) {
    llGiveInventory( llGetLinkKey( GI_Pass ), note );
}

holdData( string note ) {
    llGiveInventory( llGetLinkKey( GI_Hold ), note );
}

transfer( string note ) {
    //llOwnerSay( "Transfer: "+ note );
    GS_Notecard = "";
    llGiveInventory( llGetLinkKey( GI_ActiveServer ), note );
    llSleep( 0.2 );
    llRemoveInventory( note );
}


reject( string note ) {
    //llOwnerSay( "Reject: "+ note );
    GS_Notecard = "";
    llGiveInventory( llGetLinkKey( GI_RejectedServer ), note );
    llSleep( 0.2 );
    llRemoveInventory( note );
}


purge( string note ) {
    //llOwnerSay( "Purge: "+ note );
    GS_Notecard = "";
    llGiveInventory( llGetLinkKey( GI_PurgedServer ), note );
    llSleep( 0.2 );
    llRemoveInventory( note );
}


logQuiz( string note ) {
    //llOwnerSay( "Quiz: "+ note );
    GS_Notecard = "";
    llGiveInventory( llGetLinkKey( GI_QuizServer ), note );
    llSleep( 0.2 );
    llRemoveInventory( note );
}


integer validNote( string note ) {
    //llOwnerSay( "CValid: "+ note );
    list data = llParseString2List( note, [" "], [] );
    if( llListFindList( GL_Roles, [llDumpList2String( llList2List( data, 0, -2 ), " " )] ) != -1 && llStringLength( llList2String( data, -1 ) ) >= 3 ) {
        return 1;
    } else if( llListFindList( data, ["Quiz"] ) != -1 ) {
        return 2;
    }
    return 0;
}

run() {
    if( processNext() ){
        writeToMesh( LINK_THIS, "Proc..." );
        llSetTimerEvent( 3 );
        return;
    }
    colourToMesh( LINK_THIS, 1 );
    writeToMesh( LINK_THIS, " !Idle! " );
    llSetTimerEvent(0);
}


default {
    state_entry() {
        llSetLinkPrimitiveParamsFast( LINK_SET, [PRIM_TEXT, "", <1,1,1>, 1.0] );
        setup();
        mapPrims();
        run();
    }
    
    changed( integer change ) {
        if( change & CHANGED_LINK ) {
            mapPrims();
        }
        
        if( change & CHANGED_INVENTORY || change & CHANGED_ALLOWED_DROP ) {
            if( llStringLength( GS_Notecard ) == 0 ) {
                llSetTimerEvent( 3 );
                colourToMesh( LINK_THIS, 2 );
                writeToMesh( LINK_THIS, "!Active!" );
            } else {
                llOwnerSay( "Nope!" );
            }
        }
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        //llSetText( msg, <1,1,1>, 1.0 );
        if( num >= 500 && num <= 510 ) {
            num -= 500;
            colourToMesh( src, num );
            writeToMesh( src, msg );
        } else if( num >= 700 && num <= 710 ) {
            if( msg != GS_Notecard ) { 
                llOwnerSay( "Out of bounds!" );
            } else if( num == 701 ) {
                transfer( GS_Notecard );
            } else if( num == 702 ) {
                purge( GS_Notecard );
            } else {
                reject( GS_Notecard );
            }
        }
    }
    
    timer() {
        run();
    }

}
