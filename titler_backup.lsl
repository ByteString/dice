/////////////////////////////
//Revenland Die HUD
//Script: Dice
//Simple application, all functionality contained in single script.
/////////////////////////////

//Globals

string gNotecard = "Characters";
string gNotecardData;
integer gNotecardLine;

string gDataURL = "http://cosmos-danube-3000.codio.io/";//This is the location of the web application
//The DataURL does not have a final "/", requiring relative URLs to be used when making requests.

string gDataHandles;//This is a JSON string used to register HTTP request events and track their purpose
//This allows a "character statistics" request to be correlated with the response for better processing.

string gJsonValue;//This value is used by the is_valid_key? function. Calling the function will populate
//this value based on the provided key and JSON object

key gOwner;//During state_entry the user's key is placed here.
string gOwnerName;//During state_entry the user's name is placed here.

integer gOwnerCommandChannel;//This is the channel the owner will issue commands on.
//It is reproducably generated with generate_channel_from() so that it is unique per user.

integer gCharacterSelectChannel = 100;//This is the channel the character select dialog will submit to.
integer gCharacterSelectHandle;//This handle closes the character select dialog after timeout or selection.

integer gRollAnnounceChannel = -52723;//This is a constant channel shared by all HUDs to announce die rolls. A roll_id will be posted here and independently verified by each HUD.

vector gColor = <1.0,1.0,1.0>;//Hovertext color. TODO: Configurable.

string gCharacters = "";//All characters are stored here.
string gDisplayName = "";//Character name, populated from database.
string gStatistics;//Full statistics are stored here in a JSON string.
list gStatisticsDisplay;//This is a list of statistics names for internal use.
integer gStatisticsConfigured;//This flag tracks whether stats are loaded from web server
//It is used to toggle hitpoints/defence display
integer gHitpoints;//This tracks hitpoints which are configured locally at present. TODO: Revisit this.
integer gMaxHitpoints;//This track maximum hitpoints to prevent inflation of base hitpoints using controls.
integer gDefence;//This tracks defence value which is configured locally at present. TODO: Revisit this.
integer gArmor;//This tracks armor values which are user configurable. TODO: Break down displayed defence.

//Helper Functions
integer is_valid_key?(string json, string s){
    /* This function takes a JSON string and a key. If the key exists in the JSON object,
    the function will save it to the constant storage variable gJsonValue, allowing a
    pattern such as string value;if(is_valid_key?(JSON,"key")){value = gJsonValue;} for
    fetching values from JSON objects. This prevents JSON_INVALID from being operated on.*/
    gJsonValue = llJsonGetValue(json, [s]);
    return gJsonValue != JSON_INVALID;
}
integer generate_channel_from(string text){
    /*This function allows a reproducible method of finding a channel based on a user's key*/
    return  ( -2 * (integer)("0x"+llGetSubString(text,-5,-1)) )-235180;
}

//Core Functions
update_display_text(){
    /*When changes are made to displayed statistics, this function is called to update hovertext*/
    string nl = "\n";
    string displayText = "Revenland RP HUD" + nl;
    if(gDisplayName){displayText += "Name: " + gDisplayName + nl;}
    else{ displayText += "Loading...";}
    if(gStatisticsConfigured){
        displayText += "Hitpoints: " + (string)gHitpoints + "/" + (string)gMaxHitpoints+ nl;
        displayText += "Defence: " + (string)gDefence + " (Armor: " + (string)gArmor + ")" + nl;
    }
    llSetText( displayText, gColor, 1.0);
}
request_data(integer line, string identifier){
    /*This function handles the registration of data handles for HTTP requests*/
    key dataHandle = llGetNotecardLine(gNotecard,line);
    gDataHandles = llJsonSetValue(gDataHandles,[dataHandle], identifier);
}
 
//Character Selection Functions
select_character(string body){
    /*This function parses a character list from a JSON web response, allowing the user to
    select the character they wish to load*/
    list characters = llJson2List(body);
    integer i;//This is presumed 0, not initialized in for loop.
    integer length = llGetListLength(characters);
    for(;i < length;i++){
        string json_character = llList2String(characters, i);
        string display_name;
        if(is_valid_key?(json_character,"name")){
            display_name = gJsonValue;
            characters = llListReplaceList(characters, [display_name], i, i);
            gCharacters = llJsonSetValue(gCharacters,[display_name],json_character);
        } else {
            llOwnerSay("Invalid character data. Please contact an admin.");
            state fatal_error;
        }   
    }
    gCharacterSelectHandle = llListen(gCharacterSelectChannel,"",gOwner,"");//Open a listener
    llDialog(gOwner,"Select a character:",characters,gCharacterSelectChannel);//Present character choices
    llSetTimerEvent(30.0);//Set a timer to clos listener in case no option is selected
}
set_display_name(string name){
    gDisplayName = name;
    llSay(0, gOwnerName + " is now known as " + gDisplayName);
    update_display_text();
}
populate_statistics(string body){
    string statistics_string;if(is_valid_key?(body,"statistics")){statistics_string = gJsonValue;}
    //pull statistics from character object
    
    list statistics_list = llJson2List(statistics_string);
    //create list of JSON statistic objects
    integer i;
    integer length = llGetListLength(statistics_list);
    for(;i < length;i++){
        string statistic = llList2String(statistics_list,i);
        string statistic_name;if(is_valid_key?(statistic,"name")){statistic_name = gJsonValue;}
        llOwnerSay("Processing " + statistic_name);
        string statistic_value;if(is_valid_key?(statistic,"value")){statistic_value = gJsonValue;}
        gStatistics = llJsonSetValue(gStatistics,[statistic_name], statistic_value);
        gStatisticsDisplay += statistic_name;
    }
    llOwnerSay("Statistics are now " + gStatistics);
    initialize_hitpoints();
    update_defence();
    gStatisticsConfigured = 1;
    update_display_text();
    llListen(gOwnerCommandChannel, "", "", "");
}
initialize_hitpoints(){
    integer vigor;if(is_valid_key?(gStatistics,"vigor")){vigor = (integer)gJsonValue;}
    integer toughness;if(is_valid_key?(gStatistics,"toughness")){toughness = (integer)gJsonValue;}
    gHitpoints = vigor + toughness;
    gMaxHitpoints = gHitpoints;
    }
update_defence(){
    integer swiftness;if(is_valid_key?(gStatistics,"swiftness")){swiftness = (integer)gJsonValue;}
    integer toughness;if(is_valid_key?(gStatistics,"toughness")){toughness = (integer)gJsonValue;}
    gDefence = swiftness + toughness + gArmor;
    }
    
//Dice Roll Functions
integer roll_d20(){
    return (integer)llFrand(21);
}
string number_with_indefinite_article(integer number){
    if(number == 8 || number == 18 || number == 11){
        return "an " + (string)number;
    } else {
        return "a " + (string)number;
    }
}
    
statistic_roll(string statistic_name){
    integer statistic_value;if(is_valid_key?(gStatistics,statistic_name)){statistic_value = (integer)gJsonValue;}
    integer roll = roll_d20();
    integer total_roll = roll + statistic_value;
    string roll_announcement = gOwnerName + " rolled " + number_with_indefinite_article(total_roll) + " (Rolled " + (string)roll + \
    " + " + (string)statistic_value + " " + statistic_name + ")";
    llOwnerSay(roll_announcement);    
}
damage_roll(string damage_type, string chance_to_hit_modifier_name, string damage_modifier_name){   
    integer chance_to_hit_modifier_value;
    if(is_valid_key?(gStatistics,chance_to_hit_modifier_name)){chance_to_hit_modifier_value = (integer)gJsonValue;}
    integer damage_modifier_value;
    if(is_valid_key?(gStatistics,damage_modifier_name)){damage_modifier_value = (integer)gJsonValue;}
    
    integer roll = roll_d20();
    integer total_roll = roll + chance_to_hit_modifier_value;
    
    string roll_announcement = gOwnerName + " rolled " + number_with_indefinite_article(total_roll) + " (Rolled " + (string)roll + \
    " + " + (string)chance_to_hit_modifier_value + " " + chance_to_hit_modifier_name + " for " + (string)damage_modifier_value + " " + \
    damage_type + " damage)";
    llOwnerSay(roll_announcement);
}
melee_roll(){
    string chance_to_hit_modifier_name = "swiftness";
    string damage_modifier_name = "vigor";
    damage_roll("melee", chance_to_hit_modifier_name, damage_modifier_name);
}
ranged_roll(){
    string chance_to_hit_modifier_name = "swiftness";
    string damage_modifier_name = "cunning";
    damage_roll("ranged", chance_to_hit_modifier_name, damage_modifier_name);
}
magic_roll(){
    string chance_to_hit_modifier_name = "intellect";
    string damage_modifier_name = "intellect";
    damage_roll("magic", chance_to_hit_modifier_name, damage_modifier_name);
}
    
announce_roll(string body){
    string roll_id; if(is_valid_key?(body,"id")){roll_id = gJsonValue;}
    string roll_note; if(is_valid_key?(body,"note")){roll_note = gJsonValue;}
    string temp = llGetObjectName();
    llSetObjectName(">");
    llOwnerSay(roll_note);
    llSay(gRollAnnounceChannel,body);
    llSetObjectName(temp);
    llSleep(1.0);
}

default
{
    on_rez(integer _start_param){llResetScript();}
    changed(integer _change){if (_change & CHANGED_INVENTORY){llResetScript();}}  
    state_entry(){
        gOwner = llGetOwner();
        gOwnerName = llKey2Name(gOwner);
        llListen(gRollAnnounceChannel,"","","");
        
        gOwnerCommandChannel = generate_channel_from(llGetOwner());//PROD
        
        update_display_text();
        list params = [HTTP_METHOD,"GET"];
        llOwnerSay("Loading notecard...");
        request_data(gNotecardLine,"load_characters");
    }

    touch_start(integer _total_number){if(llDetectedKey(0) == gOwner){llResetScript();}}
    dataserver(key _request_id, string _data){
        //llOwnerSay("DataServer Response: " + _data);
        string identifier;if(is_valid_key?(gDataHandles,_request_id)){identifier = gJsonValue;}
        if(identifier == "load_characters"){
            if (_data != EOF) {    // not at the end of the notecard
                gNotecardData += _data;
                ++gNotecardLine;                // increase line count
                request_data(gNotecardLine,"load_characters");
            } else {llOwnerSay("Data: " + gNotecardData);select_character(gNotecardData);}
        }
    }
    
    listen(integer _channel, string _name, key _id, string _message){
        if(_channel == gCharacterSelectChannel){
            llListenRemove(gCharacterSelectHandle);
            llSetTimerEvent(0.0);
            set_display_name(_message);
            string character;if(is_valid_key?(gCharacters,_message)){character = gJsonValue;}
            populate_statistics(character);
        } else if(_channel == gOwnerCommandChannel){
            if(llGetOwnerKey(_id) == gOwner){
                if(llListFindList(gStatisticsDisplay,[_message]) != -1){
                    list params = [HTTP_METHOD,"GET"];
                    statistic_roll(_message);
                } else {
                    if(_message == "melee"){
                        melee_roll();
                    }
                    if(_message == "ranged"){
                        ranged_roll();
                    }
                    if(_message == "magic"){
                        magic_roll();
                    }
                    if(_message == "stat roll"){
                            llDialog(gOwner, "Select a statistic", \
                            gStatisticsDisplay, gOwnerCommandChannel);
                    }
                    if(_message == "+hp"){gHitpoints += 1;update_display_text();}
                    if(_message == "-hp"){gHitpoints -= 1;update_display_text();}
                    if(_message == "+armor"){gArmor += 1;update_defence();update_display_text();}
                    if(_message == "-armor"){gArmor -= 1;update_defence();update_display_text();}
                    if(_message == "reset"){llResetScript();}
                }
            } else { llOwnerSay("Someone else is using your private HUD channel. Advise an admin.");}
        } else if (_channel == gRollAnnounceChannel){
                        //Another HUD has declared a roll. We need to verify before announcing.
                        string roll = _message;
                        integer roll_id;if(is_valid_key?(roll,"id")){roll_id = (integer)gJsonValue;}
                        llOwnerSay("Looking up roll");
                        list params = [HTTP_METHOD,"GET"];
                        //make_request("/roll_records/" + (string)roll_id,\
                        //params, "", "roll_verify");
        }
    }
    timer(){
        llListenRemove(gCharacterSelectHandle);
        llSetTimerEvent(0.0);
    }
}

state fatal_error{
    state_entry(){llOwnerSay("Fatal Error: Click titler to reset.");}
    touch_start(integer _numDetected){llResetScript();}
}
