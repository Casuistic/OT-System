

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
        update( "Hold "+ (string)llGetInventoryNumber( INVENTORY_NOTECARD ), 1 );
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
