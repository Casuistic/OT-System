

integer GI_Change;




update( string text, integer col ) {
    llMessageLinked( LINK_ROOT, 500+ col, text, NULL_KEY );
}


active() {
    if( !GI_Change ) {
        GI_Change = TRUE;
        update( "Working!", 2 );
    }
    llSetTimerEvent( 5 );
}


procQnt() {
    if ( llGetAgentSize( llGetOwner() ) == ZERO_VECTOR ) {
        return;
    }
    integer qnt = llGetInventoryNumber( INVENTORY_NOTECARD );
    if( qnt >= 25 ) {
        integer i;
        list cards = [];
        for( i=0; i<25; i++ ) {
            cards += llGetInventoryName( INVENTORY_NOTECARD, i );
        }
        integer ts = llGetUnixTime(  );
        if ( llGetAgentSize( llGetOwner() ) == ZERO_VECTOR ) {
            return;
        }
        llGiveInventoryList( llGetOwner(), "Passed: "+ (string)ts, cards );
        for( i=0; i<llGetListLength( cards ); i++ ) {
            llRemoveInventory( llList2String( cards, i ) );
        }
    }
}




default {
    
    state_entry() {
        GI_Change = TRUE;
        update( "Working!", 2 );
        llSetTimerEvent( 2 );
    }
    
    
    changed( integer change ) {
        if( change & CHANGED_INVENTORY ) {
            active();
        }
    }
    
    
    timer() {
        llSetTimerEvent( 0 );
        procQnt();
        update( "Log "+ (string)llGetInventoryNumber( INVENTORY_NOTECARD ), 1 );
        GI_Change = FALSE;
    }
    
    
    link_message( integer src, integer num, string msg, key id ) {
        if( num == 101 ) {
            if( id == "Update" ) {
                active();
            }
        }
    }

}
