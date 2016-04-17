string gNotecard = "Characters";
string gNotecardData;

integer gNotecardLine;

integer gNotecardIndex;
integer gNotecardTotal;

string gCurrentNotecard;
string gCurrentCharacter;

list gNotecardNames;

list gValidProperties = ["name", "vigor", "swiftness", "toughness", "intellect", "cunning"];

string gCharacterData;
string gDataHandles;
string gJsonValue;

key gOwner;//During state_entry the user's key is placed here.
string gOwnerName;//During state_entry the user's name is placed here.

//Helper Functions
integer is_valid_key?(string json, string s){
    /* This function takes a JSON string and a key. If the key exists in the JSON object,
    the function will save it to the constant storage variable gJsonValue, allowing a
    pattern such as string value;if(is_valid_key?(JSON,"key")){value = gJsonValue;} for
    fetching values from JSON objects. This prevents JSON_INVALID from being operated on.*/
    gJsonValue = llJsonGetValue(json, [s]);
    return gJsonValue != JSON_INVALID;
}
request_data(string notecard_name, integer line, string identifier){
    /*This function handles the registration of data handles for HTTP requests*/
    key dataHandle = llGetNotecardLine(notecard_name,line);
    gDataHandles = llJsonSetValue(gDataHandles,[dataHandle], identifier);
}

enumerate_notecards(){
    integer numberOfNotecards = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer i;for(;i < numberOfNotecards;i++){gNotecardNames = gNotecardNames + llGetInventoryName(INVENTORY_NOTECARD,i);}
    gNotecardTotal = numberOfNotecards;
    llOwnerSay(llDumpList2String(gNotecardNames,","));
}

read_notecard(string notecard_name){
    request_data(notecard_name, gNotecardLine, notecard_name);
}
default
{
    on_rez(integer _start_param){llResetScript();}
    changed(integer _change){if (_change & CHANGED_INVENTORY){llResetScript();}}  
    touch_start(integer _num_detected){llResetScript();}
    state_entry(){
        gOwner = llGetOwner();gOwnerName = llKey2Name(gOwner);
        enumerate_notecards();
        
        gCurrentNotecard = llList2String(gNotecardNames, gNotecardIndex);
        read_notecard(gCurrentNotecard);               
    }

    dataserver(key _request_id, string _data){
        string identifier;if(is_valid_key?(gDataHandles,_request_id)){identifier = gJsonValue;}
        if (_data != EOF) { // not at the end of the notecard
            //NotecardData += _data + "\n";
            list arguments = llParseString2List(_data, [":"], []);
            string property = llToLower(llList2String(arguments,0));
            string value = llList2String(arguments, 1);
            if(llListFindList(gValidProperties, [property]) != -1){//This makes sure the property is a valid statistic to set
                if(property == "name"){
                    gCurrentCharacter = value;
                    string character = llList2Json(JSON_OBJECT, [property, value]);
                    gCharacterData = llJsonSetValue(gCharacterData, [JSON_APPEND], character);
                } else {
                    string statistic = llList2Json(JSON_OBJECT, ["name", property,"value", value]);
                    gCharacterData = llJsonSetValue(gCharacterData, [gNotecardIndex,"statistics",JSON_APPEND], statistic);
                }
                    
            } else {
                llOwnerSay("Invalid property: " + property + " in notecard " + gCurrentNotecard);
            }
            ++gNotecardLine;// increase line count
            request_data(gCurrentNotecard,gNotecardLine,"load_characters");//request next line
        } else {
            gNotecardData = "";
            gNotecardLine = 0;
            if (gNotecardIndex < gNotecardTotal-1){
                gNotecardIndex++;
                gCurrentNotecard = llList2String(gNotecardNames, gNotecardIndex);
                read_notecard(gCurrentNotecard);
            } else {
                llOwnerSay("Notecard read done");
                list characters = llJson2List(gCharacterData);
                string output = "[\n";
                integer i;
                integer length = llGetListLength(characters);
                for(;i < length;i++){
                    output += llList2String(characters, i) + "\n";
                }
                output += "]";
                llOwnerSay(output);
            }                
        }
    }
}
