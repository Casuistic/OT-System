//  Wolf Seed
//  201801042242


// UPDATE APPEARANCE
updateAppearance( integer active ) {
    float mod = 0.5;
    integer bright = FALSE;
    float glow = 0.0;
    if( active ) {
        mod = 1;
        bright = TRUE;
        glow = 0.2;
    }

    integer i;
    integer num = llGetNumberOfPrims();
    integer hit = FALSE;
    for( i=1; i<=num; ++i ) {
        if( ".FlagCol" == llList2String( llGetLinkPrimitiveParams( i, [PRIM_DESC] ), 0 ) ) {
            hit = TRUE;
            llSetLinkPrimitiveParamsFast( i, [
                        PRIM_COLOR, ALL_SIDES, <0.4,0.4,0.4>*mod, 1,
                        PRIM_FULLBRIGHT, ALL_SIDES, bright,
                        PRIM_GLOW, ALL_SIDES, glow
                ] );
        }
    }
    if( !hit ) {
        llSetLinkPrimitiveParamsFast( LINK_THIS, [
                        PRIM_COLOR, ALL_SIDES, <0.4,0.4,0.4>*mod, 1,
                        PRIM_FULLBRIGHT, ALL_SIDES, bright,
                        PRIM_GLOW, ALL_SIDES, glow
                ] );
    }
}



integer GI_Chan = 2020;
integer GI_Active;



default {
    on_rez(integer detected) {
        llResetScript();
    }
    
    state_entry() {
        llSetLinkPrimitiveParamsFast( LINK_SET, [PRIM_TEXT,"",<1,1,1>,1.0] );
        llSetLinkPrimitiveParamsFast( LINK_ROOT, [
                PRIM_NAME,"Tether Collar",
                PRIM_DESC, "Seed Collar"
                ] );
        llListen( GI_Chan, "", llGetOwner(), "Activate!" );
        updateAppearance( TRUE );
        llWhisper(0,"((Please click and activate your collar.))");
    }
    
    touch_start(integer detected) {
        if( llDetectedKey( 0 ) == llGetOwner() ) {
            if( !GI_Active ) {
                llSetTimerEvent( 30 );
                GI_Active = TRUE;
                updateAppearance( TRUE );
                llDialog( llGetOwner(), "Please activate your collar:", ["Activate!"] , GI_Chan );
            } else {
                llOwnerSay( "Activaton In progress. Please hold." );
            }
        }
    }
        
    listen(integer Channel, string name, key user, string msg) {
        if(msg == "Activate!") {
            updateAppearance( TRUE );
            llSetTimerEvent( 0 );
            llWhisper(0,"Obedience confirmed. Good... good.....");
            llSleep( 2 );
            llWhisper(0,"Collar setting up... please wait...");
            llSleep( 2 );
            llWhisper(0,"... please wait ...");
            llSleep( 2 );
            llWhisper(0,"Checking The Omega Tether Server for updates... stand by...");
            llRegionSay(-9966, "GetUpdate|"+(string)llGetOwner()+"|"+(string)llGetPos()+"");
            llSetTimerEvent( 60 );
        }
    }
        
    timer() {
        llSetTimerEvent( 0 );
        updateAppearance( FALSE );
        GI_Active = FALSE;
        llWhisper(0,"((Please click and activate your collar.))");
    }
}

