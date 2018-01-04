

integer GI_DoorOpen;

key GI_TrigerUser;

integer GI_CState;



setState( integer s ) {
    GI_CState = s;
    if( s == 0  ) {
        llSetLinkPrimitiveParamsFast( LINK_THIS, [
            PRIM_COLOR, ALL_SIDES, <0,0,1>, 0.1,
            PRIM_PHANTOM, FALSE
            ] );
    } else if( s == 1 ) {
        llSetLinkPrimitiveParamsFast( LINK_THIS, [
        `   PRIM_COLOR, ALL_SIDES, <1,0,0>, 0.1,
            PRIM_PHANTOM, FALSE
            ] );
    } else if( s == 2 ) {
        llSetLinkPrimitiveParamsFast( LINK_THIS, [
            PRIM_COLOR, ALL_SIDES, <0,1,0>, 0.1,
            PRIM_PHANTOM, TRUE
            ] );
    }
}


close() {
    GI_TrigerUser = NULL_KEY;
    setState( 1 );
    llSensorRemove();
    llSetTimerEvent( 0 );
}

open( key id ) {
    GI_TrigerUser = id;
    setState( 2 );
    llSensorRepeat( "", "", AGENT, 3, PI, 3 );
    llSetTimerEvent( 30 );
}

reject() {
    if( GI_CState != 2 ) {
        setState( 0 );
    }
    llSetTimerEvent( 3 );
}




default {
    
    state_entry() {
        integer x = 10;
        integer y = 100;
        float start = (x * y) - ((y/10)*4);
        float length = y / 5;
        llSetTextureAnim( ANIM_ON | SMOOTH | PING_PONG | LOOP, ALL_SIDES, x, y, start, length, 10 );
        setState( 1 );
    }

    touch_start( integer num ) {
        integer i;
        for( i=0; i<num; i++ ) {
            open( llDetectedKey( i ) );
            return;
            //reject( );
        }
    }
    
    sensor( integer num ) {
        integer i;
        for( i=0; i<num; i++ ) {
            if( llDetectedKey( i ) == GI_TrigerUser ) {
                return;
            }
        }
        close();
    }
    
    no_sensor() {
        close();
    }
    
    timer() {
        close();
    }
}
