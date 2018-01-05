string GS_CollarName = "Tether Collar";


integer GI_DoorOpen;

key GI_TrigerUser;

integer GI_CState;

integer GI_Desk_Base = 100;
integer GI_Desk_Rng = 100;



key GK_Main = NULL_KEY;


/*
*   UUID TO INT
*   Ised for channel gen & desc secure
*/
integer user2Chan(key id, integer min, integer rng ) {
    integer viMult = 1;
    if( min < 0 ) { viMult = -1; }
    return ( min + (viMult * (((integer)("0x"+(string)id) & 0x7FFFFFFF) % rng)));
}

/*
    Generate String Verificastion Hash
*/
string genHash( string fa, string fb, string ff, string fr, key id ) {
    return llGetSubString( llMD5String( fa +":"+ fb +":"+ ff +":"+ fr, user2Chan( id, GI_Desk_Base, GI_Desk_Rng ) ), 0, 12 );
}

/*
*   Verify Valid Desc
*/
integer verifyDesc( string desc, key id ) {
    list data = llCSV2List( desc );
    if( llGetListLength( data ) >= 6 ) {
        string hash = llList2String( data, -1 );
        // 0 is always versionl 
        // 1,2,3,4 must be flags 
        // -1 is always hash
        if( hash == genHash( llList2String( data, 1 ), llList2String( data, 2 ), llList2String( data, 3 ), llList2String( data, 4 ), id ) ) {
            return TRUE;
        }
    }
    return FALSE;
}

/*
*   Find Collar on target user
*/
list findCollar( key id ) {
    list data = llGetAttachedList( id );
    integer count = llGetListLength( data );
    while( count-- ) {
        key pid = llList2Key( data, count );
        list data = llGetObjectDetails( pid, [OBJECT_NAME, OBJECT_DESC] );
        if( llList2String( data, 0 ) == GS_CollarName && verifyDesc( llList2String( data, 1 ), id ) ) {
            return data;
        }
    }
    return ["NCF"];
}

/*
*   Find Collar Based Rank on target
*/
integer getRank( key id ) {
    list data = findCollar( id );
    if( llGetListLength( data ) != 1 ) {
        return llList2Integer( llCSV2List( llList2String( data, 1 ) ), 4 );
    }
    return 0;
}








setState( integer s ) {
    GI_CState = s;
    integer x = 360;
    integer y = 1;
    float start = (x*(y-1))+(x*0.3);
    float length = x * 0.2;
    float rate = x * 0.2;
    if( s == 0  ) {
        //llVolumeDetect( FALSE );
        llSetTextureAnim( ANIM_ON | SMOOTH | PING_PONG | LOOP, ALL_SIDES, x, y, start, length, rate );
        llSetLinkPrimitiveParamsFast( LINK_THIS, [
            PRIM_COLOR, ALL_SIDES, <0,0,1>, 0.15,
            PRIM_PHANTOM, FALSE
            ] );
    } else if( s == 1 ) {
        //llVolumeDetect( FALSE );
        llSetTextureAnim( ANIM_ON | SMOOTH | PING_PONG | LOOP, ALL_SIDES, x, y, start, length, rate );
        llSetLinkPrimitiveParamsFast( LINK_THIS, [
        `   PRIM_COLOR, ALL_SIDES, <1,0,0>, 0.15,
            PRIM_PHANTOM, FALSE
            ] );
    } else if( s == 2 ) {
        //llVolumeDetect( TRUE );
        llSetTextureAnim( ANIM_ON | SMOOTH | PING_PONG | LOOP, ALL_SIDES, x, y, start, length, rate );
        llSetLinkPrimitiveParamsFast( LINK_THIS, [
            PRIM_COLOR, ALL_SIDES, <0,1,0>, 0.15,
            PRIM_PHANTOM, TRUE
            ] );
    }
}


open( key id ) {
    GI_TrigerUser = id;
    setState( 2 );
    llSensorRepeat( "", "", AGENT, 3, PI, 3 );
    llSetTimerEvent( 30 );
}


close() {
    GI_TrigerUser = NULL_KEY;
    setState( 0 );
    llSensorRemove();
    llSetTimerEvent( 0 );
}


reject() {
    if( GI_CState != 2 ) {
        setState( 1 );
    }
    llSetTimerEvent( 3 );
}






default {
    
    state_entry() {
        close();
    }
    
    on_rez( integer peram ) {
        llStopSound();
        llLoopSound( "2c6a3cce-61a6-17bd-c19a-58795efaac9c", 0.3 );
    }
        
    
    collision_start( integer num ) {
        integer i;
        vector pos = llGetPos();
        rotation rot = llGetRot();
        for( i==0; i<num; ++i ) {
            key id = llDetectedKey( i );
            vector loc = llDetectedPos( i );
            vector ang = ((loc-pos) / rot);
            if( ang.x >= 0 ) {
                GK_Main = id;
                open( id );
                return;
            } else if( getRank( id ) >= 5 ) {
                GK_Main = id;
                open( id );
                return;
            } else {
                reject();
                return;
            }
        }
    }
    
    
    touch_start( integer num ) {
        integer i;
        vector pos = llGetPos();
        rotation rot = llGetRot();
        for( i==0; i<num; ++i ) {
            key id = llDetectedKey( i );
            vector loc = llDetectedPos( i );
            if( llVecDist( loc, pos ) <= 5 ) {
                vector ang = ((loc-pos) / rot);
                if( ang.x >= 0 ) {
                    GK_Main = id;
                    open( id );
                    return;
                } else if( getRank( id ) >= 5 ) {
                    GK_Main = id;
                    open( id );
                    return;
                } else {
                    reject();
                    return;
                }
            } else {
                llRegionSayTo( id, 0, "You are too far away to manipulate the field" );
            }
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
        llSetTimerEvent(0);
        close();
    }
}