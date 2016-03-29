list gOptions = ["reset", "armor", "hp", "stat roll", "magic", "ranged", "melee"];
integer gToggleView;
integer gOwnerCommandChannel;

integer generate_channel_from(string text){
    /*This function allows a reproducible method of finding a channel based on a user's key*/
    return  ( -2 * (integer)("0x"+llGetSubString(text,-5,-1)) )-235180;
}
default
{
    on_rez(integer _start_param){llResetScript();}
    changed(integer _change){if (_change & CHANGED_INVENTORY){llResetScript();}}
    state_entry()
    {
        gOwnerCommandChannel = generate_channel_from(llGetOwner());//PROD
        llSetText("Melee\nRanged\nMagic\nStat Roll\n- HP +\n- Armor +\nReset",<1.0,1.0,1.0>,1.0);
    }

    touch_start(integer _num_detected)
    {
        if (llDetectedLinkNumber(0) != LINK_ROOT){
            vector  touchST   = llDetectedTouchST(0);
            integer selectionNumber = (integer)(touchST.y * 10.0);
            string option = llList2String(gOptions,selectionNumber);
            if (option == "armor" || option == "hp"){
                string direction;
                if( (integer)(touchST.x * 10) > 4){
                    direction = "+";
                } else { direction = "-";}
                option = direction + option;
            }
            llSay(gOwnerCommandChannel,option);
        } else {
            llSetLinkPrimitiveParams(LINK_ALL_CHILDREN, [PRIM_COLOR, ALL_SIDES, <0.0,1.0,0.0>,gToggleView = !gToggleView]);
        }
    }
}
