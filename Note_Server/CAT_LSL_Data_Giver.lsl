

integer GI_IDNum_Srv = 9200;
integer GI_IDNum_IO = 9100;



setup() {
    output( "Setting Up Server", 0 );
}


readyProcess() {
    output( "Resetting...", 0 );
}


resetProcess() {
    output( "Processing...", 0 );
    integer qnt = llGetInventoryNumber( INVENTORY_NOTECARD );
}

sendStatus( string status ) {
    llMessageLinked( LINK_ALL_CHILDREN, 9100, "Set_Status", (key)status );
}


processSrvReq( key id, string msg ) {
    output( "Serving...", 0 );
    list data = llParseString2List( msg, ["|"], [] );
    if( llList2String( data, 0 ) == "SRV" && llGetListLength( data ) == 3 ) {
        string sub = llList2String( data, 1 );
        key tar = llList2Key( data, 2 );
        list cards;
        if( llGetAgentSize( tar ) != ZERO_VECTOR ) {
            list roles = ["Agent", "Bounty Hunter", "Guard", "Prisoner", "Medic", "Mechanic", "Unit"];
            integer i;
            integer num = llGetListLength( roles );
            for( i=0; i<num; i++ ) {
                string seek = llList2String( roles, i ) +" "+ sub;
                integer type = llGetInventoryType( seek );
                if( type == INVENTORY_NOTECARD ) {
                    cards += seek;
                    //llGiveInventory( tar, seek );
                }
            }
            if( llGetListLength( cards ) == 0 ) {
                output( "ReqErr:: No Data Found For\n"+sub, 2 );
                sendStatus( "Err" );
                llRegionSayTo( tar, 0, "No Data Found" );
            } else {
                output( "Serving:\n"+sub, 1 );
                sendStatus( "Good" );
                llRegionSayTo( tar, 0, "Serving Data for User" );
                llGiveInventoryList( tar, "Data Request "+ (string)sub, cards );
            }
        } else {
            if( tar == NULL_KEY ) {
                output( "ReqErr:: Target User is Null", 2 );
                sendStatus( "Err" );
            } else {
                output( "ReqErr:: Target User not in Sim", 2 );
                sendStatus( "Err" );
            }
        }
    }
}


output( string msg, integer lev ) {
    llMessageLinked( LINK_ALL_CHILDREN, 9100, msg, (key)((string)lev) );
}


default {
    state_entry() {
        setup();
        output( "Ready", 0 );
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        if( num == GI_IDNum_Srv || num == 100 ) {
            processSrvReq( id, msg );
        }
    }
    
    changed( integer change ) {
        if( change & CHANGED_REGION_START ) {
            readyProcess();
        } else if( change & CHANGED_INVENTORY ) {
            readyProcess();
        }
    }
    
    timer() {
        llSetTimerEvent( 0 );
        resetProcess();
    }
}
