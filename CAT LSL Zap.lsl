integer GI_N_Dialog = 8100;
integer GI_N_Relay = 8200;
integer GI_N_Speaker = 8300;
integer GI_N_GoTo = 8400;
integer GI_N_Titler = 8500;
//integer GI_N_Interface = 8900;
integer GI_N_Zapper = 8800;
integer GI_N_Leash = 8700;
integer GN_N_CORE = 8600;


integer GN_N_DB = 8950;



integer GI_ZapCount;

integer GI_ZapTotal;

integer GI_ZapRecover;



zapStart( integer count ) {
    llRequestPermissions( llGetOwner(), PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS );
    if( GI_ZapCount == 0 ) {
        llSetTimerEvent( 0.5 );
    }
    
    GI_ZapCount += count;
    GI_ZapTotal += count;
    if( GI_ZapCount >= 30 ) {
        GI_ZapCount = 30;
    }
    if( GI_ZapTotal >= 15 ) {
        GI_ZapRecover = 30;
    }
}



zap() {
    llMessageLinked( LINK_SET, GN_N_CORE, "Zap|Active", "Status" );
    llTakeControls(
        CONTROL_FWD |
        CONTROL_BACK |
        CONTROL_LEFT |
        CONTROL_RIGHT |
        CONTROL_ROT_LEFT |
        CONTROL_ROT_RIGHT |
        CONTROL_UP |
        CONTROL_DOWN |
        CONTROL_LBUTTON |
        CONTROL_ML_LBUTTON ,
        TRUE, FALSE
        );
    
    llParticleSystem([
                        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                        PSYS_PART_FLAGS, PSYS_PART_FOLLOW_VELOCITY_MASK | PSYS_PART_EMISSIVE_MASK,
                        PSYS_PART_MAX_AGE,0.75,
                        PSYS_PART_START_COLOR, <1.0,0.95,1>,
                        PSYS_PART_END_COLOR, <1,1,1>,
                        PSYS_PART_START_SCALE,<0.15,0.15,0>,
                        PSYS_PART_END_SCALE,<0.20,0.20,0>, 
                        PSYS_SRC_BURST_RATE, 0.1,
                        PSYS_SRC_ACCEL, <0,0,0>,
                        PSYS_SRC_BURST_PART_COUNT,5,
                        PSYS_SRC_BURST_RADIUS,.01,
                        PSYS_SRC_BURST_SPEED_MIN,.2,
                        PSYS_SRC_BURST_SPEED_MAX,.4,
                        PSYS_SRC_INNERANGLE,1.54, 
                        PSYS_SRC_OUTERANGLE,1.54,
                        PSYS_SRC_OMEGA, <0,0,0>,
                        PSYS_SRC_MAX_AGE, 0,
                        PSYS_SRC_TEXTURE, "1a62b9cf-8372-f1ee-6ae1-a78e39847aff",
                        PSYS_PART_START_GLOW, 0.5,
                        PSYS_PART_END_GLOW, 0.5,
                        PSYS_PART_START_ALPHA, 1.0,
                        PSYS_PART_END_ALPHA, 0.5
                        ]);
                        
    llStartAnimation( "Zap" );
    llLoopSound("4546cdc8-8682-6763-7d52-2c1e67e8257d",0.25);
}


zapRecover() {
    llMessageLinked( LINK_SET, GN_N_CORE, "Zap|Recover", "Status" );
    llStopSound();
    llParticleSystem([]);
    GI_ZapTotal = 0;
    llStartAnimation( "Stungunned" );
    llStopAnimation( "Zap" );
}


zapStop() {
    llMessageLinked( LINK_SET, GN_N_CORE, "Zap|Done", "Status" );
    llStopSound();
    llParticleSystem([]);
    llSetTimerEvent( 0 );
    llReleaseControls();
    GI_ZapTotal = 0;
    llStopAnimation( "Zap" );
    llStopAnimation( "Stungunned" );
    
}


setup( key id ) {
    llRequestPermissions( id, PERMISSION_TRIGGER_ANIMATION );
}


integer GI_Debug = FALSE;
debug( string msg ) {
    if( GI_Debug ) {
        string output = llGetScriptName() +": "+ msg;
        llOwnerSay( output );
        llWhisper( -9999, output );
    }
}


default {
    state_entry() {
        setup( llGetOwner() );
    }
    
    attach( key id ) {
        if( id != NULL_KEY ) {
            setup( id );
        }
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        if( num == GI_N_Zapper ) {
            if( id == "do_zap" ) {
                zapStart( (integer)msg );
            } else if( id == "debug" ) {
                GI_Debug = (integer)msg;
            }
        }
    }
    
    run_time_permissions( integer flag ) {
        if( flag & PERMISSION_TAKE_CONTROLS ) {
            zap();
        }
    }
    
    timer() {
        debug( "Time: "+ (string)GI_ZapCount +" : "+ (string)GI_ZapRecover );
        if( 0 == GI_ZapCount ) {
            if( 0 >= GI_ZapRecover ) {
                zapStop();
            } else if( GI_ZapRecover == 30 ) {
                zapRecover();
            }
            GI_ZapRecover -= 1;
        } else {
            GI_ZapCount -= 1;
        }
    }
}
