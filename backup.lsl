/////////////////////////////
//Revenland Die HUD
//Script: Dice
//Simple application, all functionality contained in single script.
/////////////////////////////
//Globals
string gDataURL = "http://cosmos-danube-3000.codio.io";
string gDataHandles;
string gJsonValue;
integer gFatalError;

key gOwner;
string gOwnerName;

integer gCharacterSelectChannel = 100;
integer gCharacterSelectHandle;

integer gRollAnnounceChannel = -52723;

vector gColor = <1.0,1.0,1.0>;
string gDisplayName = "";
string gStatistics;
list gStatisticsDisplay;

//Functions
integer is_valid_key?(string json, string s){
    gJsonValue = llJsonGetValue(json, [s]);
    return gJsonValue != JSON_INVALID;
}
update_display_text(){
    string nl = "\n";
    string displayText = "Revenland RP HUD" + nl;
    if(gDisplayName){displayText += "Name: " + gDisplayName + nl;}
    else{ displayText += "Loading...";}
    
    llSetText(  displayText, gColor, 1.0);
}
make_request(string path, list options, string body, string identifier){
    key dataHandle = llHTTPRequest(gDataURL + path, options, body);
    gDataHandles = llJsonSetValue(gDataHandles,[dataHandle], identifier);
}
select_character(string body){
    list characters = llJson2List(body);
    integer i;
    integer length = llGetListLength(characters);
    for(;i < length;i++){
        string json_character = llList2String(characters, i);
        string display_name;
        if(is_valid_key?(json_character,"display_name")){
            display_name = gJsonValue;
            characters = llListReplaceList(characters, [display_name], i, i);
            //llOwnerSay(llDumpList2String(characters,","));//DEBUG
        } else {
            gFatalError = 1;
        }   
    }
    if(gFatalError){
        llOwnerSay("Encountered invalid character data, please contact an admin.");   
    } else {
       gCharacterSelectHandle = llListen(gCharacterSelectChannel,"",gOwner,"");
        llDialog(gOwner,"Select a character:",characters,gCharacterSelectChannel);
        llSetTimerEvent(30.0);
    }
}
set_display_name(string name){
    gDisplayName = name;
    llSay(0, gOwnerName + " is now known as " + gDisplayName);
    update_display_text();
}
announce_roll(string body){
    //{"id":8,"roll":17,"modifier_value":10,"modifier_type":"valor",
    //"note":"Byte rolled a 27 (Rolled 17 + 10 valor)","character_id":1}
    string roll_id; if(is_valid_key?(body,"id")){roll_id = gJsonValue;}
    string roll_note; if(is_valid_key?(body,"note")){roll_note = gJsonValue;}
    string temp = llGetObjectName();
    llSetObjectName(">");
    llOwnerSay(roll_note);
    llSetObjectName(temp);
    llSleep(1.0);
}

default
{
    changed(integer _change){if (_change & CHANGED_INVENTORY){llResetScript();}}
    
    state_entry(){
        gOwner = llGetOwner();
        gOwnerName = llKey2Name(gOwner);
        update_display_text();
        list params = [HTTP_METHOD,"GET"];
        make_request("/characters",params,"","characters");
    }

    touch_start(integer _total_number){
        //if(llDetectedKey(0) == gOwner){llResetScript();}
         list params = [HTTP_METHOD,"GET"];
        make_request("/characters/Byte/roll/valor", params, "", "roll");
    }
    
    http_response(key _request_id, integer _status, list _metadata, string _body){
        //Body is received with id
        //List of registered ids is checked for event type
        //Event type retrieved, body handled based on event type. 
        string identifier;
        if(is_valid_key?(gDataHandles,_request_id)){identifier = gJsonValue;}
        //llOwnerSay(identifier);//DEBUG
        llOwnerSay(_body);//DEBUG
        
        if(identifier == "characters"){
            if(_status == 404){
                llOwnerSay("Character select failed: No characters");
            } else {
            select_character(_body);
            }
        }
        if(identifier == "roll"){
            announce_roll(_body);
        }
    }
    
    listen(integer _channel, string _name, key _id, string _message){
        if(_channel == gCharacterSelectChannel){
            llListenRemove(gCharacterSelectHandle);
            llSetTimerEvent(0.0);
            set_display_name(_message);
            list params = [HTTP_METHOD,"GET"];
            make_request("/characters/" + gDisplayName, params, "", "statistics");
        }
    }
    timer(){
        llListenRemove(gCharacterSelectHandle);
        llSetTimerEvent(0.0);
    }
}
