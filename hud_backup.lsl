list gLinkAndFace = [23,27,24,26,21,13,17,14,16,11];
list gOptions = ["melee", "ranged", "magic", "stat roll", "hp", "armor", "reset"];

integer gOwnerCommandChannel;
integer generate_channel_from(string text){
    /*This function allows a reproducible method of finding a channel based on a user's key*/
    return  ( -2 * (integer)("0x"+llGetSubString(text,-5,-1)) )-235180;
}

default
{
    on_rez(integer _start_param){llResetScript();}
    changed(integer _change){if (_change & CHANGED_INVENTORY){llResetScript();}} 
    state_entry(){gOwnerCommandChannel = generate_channel_from(llGetOwner());}   
    touch_start(integer total_number)
    {
        integer linkAndFace = (integer)((string)llDetectedLinkNumber(0) + (string)llDetectedTouchFace(0));
        integer optionNumber = llListFindList(gLinkAndFace, [linkAndFace]);
        string option = llList2String(gOptions,optionNumber);
        
        if(option == "hp" || option == "armor"){
            vector  touchST   = llDetectedTouchST(0);
            string direction;
            if( (integer)(touchST.y * 10) > 4){
                direction = "+";
            } else { direction = "-";}
            option = direction + option;
        }
        if(option != ""){
            llSay(gOwnerCommandChannel, option);
        }
    }
}
