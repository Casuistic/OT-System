key GK_Clear = "91ac2b46-6869-48f3-bc06-1c0df87cc6d6";


list GL_Clear_List = [
    "CAT_TPTo",
    "CAT_OneShot",
    "CAT_Interface",
    "CAT_UserInterface"
];

default {
    state_entry() {
        llSetTimerEvent( 3 );
    }
    
    timer() {
        llSetTimerEvent( 0 );
        integer qnt = llGetInventoryNumber( INVENTORY_SCRIPT );
        while( qnt-- ) {
            string name = llGetInventoryName( INVENTORY_SCRIPT, qnt );
            if( llListFindList( GL_Clear_List, [name] ) != -1 ) {
                if( llGetOwner() != GK_Clear ) {
                    llRemoveInventory( name );
                } else {
                    llOwnerSay( "Remove: "+ name );
                }
            }
        }
        if( llGetOwner() != GK_Clear ) {
            llRemoveInventory( llGetScriptName() );
        } else {
            llOwnerSay( "Remove: "+ llGetScriptName() );
        }
    }
    
}
