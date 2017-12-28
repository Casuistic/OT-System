integer GI_N_Dialog = 8100;
integer GI_N_Relay = 8200;
integer GI_N_Speaker = 8300;
integer GI_N_GoTo = 8400;
integer GI_N_Titler = 8500;
integer GI_N_Interface = 8900;
integer GI_N_Zapper = 8800;
integer Gi_N_Leash = 8700;

integer GN_N_HData = 8600;



string GS_Rank = "00";
string GS_Flag = "P";
string GS_Mark = "Ω";
string GS_Num = "00000";

string GS_Space = " - ";

string GS_Crime = "Unknown";

vector GV_Colour = <0.5,0.5,0.5>;


integer GI_Mood = FALSE;
integer GI_Enabled = TRUE;


list GL_TitleBlocks = [];


string GS_Line_Scent = "";
string GS_Line_Injury = "";
string GS_Line_Status = "";


map() {
    integer i;
    integer num = llGetNumberOfPrims();
    GL_TitleBlocks = [];
    for( i = 2; i <= num; i++ ) {
        if( llToLower( llGetSubString( llGetLinkName( i ), 0, 4 ) ) == ".text" ) {
            GL_TitleBlocks += i;
        }
    }
}


setIC() {
    if( GI_Enabled ) {
        integer i;
        integer num = llGetListLength( GL_TitleBlocks );
        
        if( num >= 1 ) {
            string end = "\n \n \n \n \n \n \n \n \n \n \n \n \n \n \n \n ";
            string subText = "";
            if( GS_Line_Scent != "" ) {
                subText += "\nScent: "+ GS_Line_Scent;
            }
            if( GS_Line_Injury != "" ) {
                subText += "\nInjury: "+ GS_Line_Injury;
            }
            if( GS_Line_Status != "" ) {
                subText += "\nStatus: "+ GS_Line_Status;
            }
            //string text = GS_Mark + GS_Rank +" "+ GS_Flag + GS_Space + GS_Num +"\nCrime: "+ GS_Crime;
            string text = GS_Mark + GS_Space + GS_Flag + GS_Space + GS_Num;// +"\nCrime: "+ GS_Crime;
            setText( llList2Integer( GL_TitleBlocks, 0 ), text + subText + llGetSubString( end, 0, ((num-(i-2))*2) ), GV_Colour, 1.0 );
        }
    } else {
        setText( llList2Integer( GL_TitleBlocks, 0 ), "", GV_Colour, 1 );
    }
}


integer setText( integer link, string text, vector col, float alpha ) {
    if( llToLower( llGetSubString( llGetLinkName( link ), 0, 4 ) ) == ".text" ) {
        llSetLinkPrimitiveParamsFast( link, [ PRIM_TEXT, text, col, alpha ] );
        return TRUE;
    }
    return FALSE;
}


setOOC() {
    integer i;
    integer num = llGetListLength( GL_TitleBlocks );
    
    if( llGetListLength( GL_TitleBlocks ) >= 1 ) {
        string end = "\n \n \n \n \n \n \n \n \n \n \n \n \n \n \n \n ";
    
        vector col = <0.5,0.5,0.5>;
        string text = "OOC";
        
        llSetLinkPrimitiveParamsFast( llList2Integer( GL_TitleBlocks, 0 ), [
                PRIM_TEXT, text + llGetSubString( end, 0, ((num-(i-2))*2) ), col, 1 ] );

        for( i=1; i<num; ++i ) {
            text = "";
            col = ZERO_VECTOR;
            llSetLinkPrimitiveParamsFast( llList2Integer( GL_TitleBlocks, i ), [PRIM_TEXT, text, col, 1] );
        }
    }
}


update() {
    if( GI_Enabled ) {
        if( GI_Mood ) {
            setIC();
        } else {
            setOOC();
        }
    } else {
        setText( llList2Integer( GL_TitleBlocks, 0 ), "", GV_Colour, 1 );
    }
}


setup() {
    debug( "setup" );
    map();
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
        setup();
        llSetTimerEvent( 2 );
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        if( num == 100 || num == GI_N_Titler ) {
            debug( "Link_Message: "+ (string)id +" : "+ msg );
            if( id == "Titler" ) {
                debug( "Adjusting Title" );
                list data = llParseStringKeepNulls( msg, ["|"], [] );
                string token = llList2String( data, 0 );
                if( token == "SetScent" ) {
                    GS_Line_Scent = llDumpList2String( llList2List( data, 1, -1 ), "|" );
                    debug( "Set Scent: "+ GS_Line_Scent );
                } else if( token == "SetInjury" ) {
                    GS_Line_Injury = llDumpList2String( llList2List( data, 1, -1 ), "|" );
                    debug( "Set Injury: "+ GS_Line_Injury );
                } else if( token == "SetStatus" ) {
                    GS_Line_Status = llDumpList2String( llList2List( data, 1, -1 ), "|" );
                    debug( "Set Status: "+ GS_Line_Status );
                } else if( token == "reset" ) {
                    setup();
                } else if( token == "setMood" ) {
                    GI_Mood = (integer)llList2String( data, 1 );
                    llSetTimerEvent( 2 );
                } else if( token == "setCrime" ) {
                    GS_Crime = llList2String( data, 1 );
                    llSetTimerEvent( 2 );
                } else if( token == "setName" ) {
                    GS_Num = llList2String( data, 1 );
                    llSetTimerEvent( 2 );
                } else if( token == "setRank" ) {
                    string r = llList2String( data, 1 );
                    if( llStringLength( r ) < 2 ) {
                        r = "0"+ r;
                    }
                    GS_Rank = r;
                    llSetTimerEvent( 2 );
                } else if( token == "setFlag" ) {
                    GS_Flag = llList2String( data, 1 );
                    llSetTimerEvent( 2 );
                } else if( token == "setCol" ) {
                    GV_Colour = (vector)llList2String( data, 1 );
                    llSetTimerEvent( 2 );
                } else if( token == "setSpace" ) {
                    GS_Space = llList2String( data, 1 );
                    llSetTimerEvent( 2 );
                } else if( token == "enable" ) {
                    GI_Enabled = (integer)llList2String( data, 1 );
                    update( );
                }
                llSetTimerEvent( 2 );
            } else if( id == "set_mood" ) {
                GI_Mood = (integer)msg;
                llSetTimerEvent( 2 );
            } else {
                llOwnerSay( "Ouh Oh? "+ msg +" : "+ (string)id );
            } // end of old system
            
        }
    }
    
    
    timer() {
        llSetTimerEvent( 0 );
        update();
    }
    
    
}
