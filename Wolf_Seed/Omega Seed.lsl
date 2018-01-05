//  Wolf Seed
//  201801042341


integer GI_Updater_Chan = -9966;

integer GI_Seed_Chan_Base = 2020;
integer GI_Seed_Chan;
integer GI_Active;

string GS_Act_Cmd = "Activate!";





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


setup() {
    GI_Seed_Chan = GI_Seed_Chan_Base + (integer)llFrand( 20202 );
    llSetLinkPrimitiveParamsFast( LINK_SET, [PRIM_TEXT,"",<1,1,1>,1.0] );
    llSetLinkPrimitiveParamsFast( LINK_ROOT, [
            PRIM_NAME,"Tether Collar",
            PRIM_DESC, "Seed Collar"
            ] );
    llListen( GI_Seed_Chan, "", llGetOwner(), "Activate!" );
}


default {
    on_rez(integer detected) {
        llResetScript();
    }
    
    state_entry() {
        setup();
        updateAppearance( TRUE );
        llWhisper(0,"((Please click and activate your collar.))");
    }
    
    touch_start(integer detected) {
        if( llDetectedKey( 0 ) == llGetOwner() ) {
            if( !GI_Active ) {
                llSetTimerEvent( 30 );
                GI_Active = TRUE;
                updateAppearance( TRUE );
                llDialog( llGetOwner(), "Please activate your collar:", [GS_Act_Cmd] , GI_Seed_Chan );
            } else {
                llOwnerSay( "Activaton In progress. Please hold." );
            }
        }
    }
        
    listen(integer Channel, string name, key user, string msg) {
        if( msg == GS_Act_Cmd ) {
            updateAppearance( TRUE );
            llSetTimerEvent( 0 );
            llWhisper(0,"Obedience confirmed. Good... good.....");
            llSleep( 2 );
            llWhisper(0,"Collar setting up... please wait...");
            llSleep( 2 );
            llWhisper(0,"... please wait ...");
            llSleep( 2 );
            llWhisper(0,"Checking The Omega Tether Server for updates... stand by...");
            llRegionSay( GI_Updater_Chan, "GetUpdate|"+(string)llGetOwner()+"|"+(string)llGetPos()+"");
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

