key GK_Clear = "91ac2b46-6869-48f3-bc06-1c0df87cc6d6";

integer GI_DB_Chan = -9966;

list GL_Clear_List = [
    "CAT_TPTo",
    "CAT_OneShot",
    "CAT_Interface",
    "CAT_UserInterface",
    "The Omega Seed",
    "OT Seed"
];

list GL_CAT_Scripts = [];
list GL_OT_Scripts = [];



fixLinkSet() {
    string seek = " ..:: DJ Wolfy ::.. (WMorningstar Resident)'s Omega Collar";
    integer i;
    integer num = llGetNumberOfPrims( );
    for( i=2; i<=num; i++ ) {
        if( llGetLinkName( i ) == seek ) {
            llSetLinkPrimitiveParamsFast( i, [PRIM_NAME, "Core", PRIM_DESC, ".FlagCol"] );
        }
    }
}

purgeOldScripts() {
    integer qnt = llGetInventoryNumber( INVENTORY_SCRIPT );
    while( qnt-- ) {
        string name = llGetInventoryName( INVENTORY_SCRIPT, qnt );
        if( llListFindList( GL_Clear_List, [name] ) != -1 ) {
            if( llGetOwner() != GK_Clear ) {
                //llWhisper( GI_DB_Chan, "Remove: "+ name );
                llRemoveInventory( name );
            } else {
                llOwnerSay( "Remove: "+ name );
            }
        } else {
            integer index = llSubStringIndex( name, "_" );
            if( index != -1 ) {
                string pre = llGetSubString( name, 0, index );
                if( pre == "OT_" ) {
                    GL_OT_Scripts += llGetSubString( name, index+1, -1 );
                } else if( pre == "CAT_" ) {
                    GL_CAT_Scripts += llGetSubString( name, index+1, -1 );
                }
            }
        }
    }
    
    integer i;
    for( i=0; i<llGetListLength( GL_CAT_Scripts ); i++ ) {
        if( llListFindList( GL_OT_Scripts, llList2List( GL_CAT_Scripts, i, i ) ) != -1 ) {
            string sub = "CAT_"+ llList2String( GL_CAT_Scripts, i );
            if( llGetInventoryType( sub ) != INVENTORY_NONE ) { 
                //llWhisper( GI_DB_Chan, "CAT Purge: "+ sub );
                llRemoveInventory( sub );
            }
        }
    }
} 

selfTerminate() {
    if( llGetOwner() != GK_Clear ) {
        llRemoveInventory( llGetScriptName() );
    } else {
        llOwnerSay( "Remove: "+ llGetScriptName() );
    }
}



default {
    state_entry() {
        fixLinkSet();
        llSetTimerEvent( 10 );
    }
    
    timer() {
        llSetTimerEvent( 0 );
        purgeOldScripts();
        
        llWhisper( 0, "Rebooting System" );
        integer qnt = llGetInventoryNumber( INVENTORY_SCRIPT );
        while( qnt-- ) {
            //llOwnerSay( "Enable: "+ llGetInventoryName( INVENTORY_SCRIPT, qnt ) );
            llSetScriptState( llGetInventoryName( INVENTORY_SCRIPT, qnt ), TRUE );
        }
        llWhisper( 0, "Reboot Complete!" );
     
        selfTerminate();
    }
    
    changed( integer change ) {
        if( change & CHANGED_INVENTORY ) {
            llResetScript();
        }
    }
    
}
