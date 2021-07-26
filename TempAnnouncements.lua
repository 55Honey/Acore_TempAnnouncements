--
--
-- Created by IntelliJ IDEA.
-- User: Silvia
-- Date: 15/07/2021
-- Time: 11:22
-- To change this template use File | Settings | File Templates.
-- Originally created by Honey for Azerothcore
-- requires ElunaLua module


-- This module spawns (custom) NPCs and grants them scripted combat abilities
------------------------------------------------------------------------------------------------
-- ADMIN GUIDE:  -  compile the core with ElunaLua module
--               -  adjust config in this file
--               -  add this script to ../lua_scripts/
------------------------------------------------------------------------------------------------
-- GM GUIDE:     -  Use .tempannounce $limit $delay $text to do repeated server wide announcements.
--               -  $limit is the amount of broadcasts. 0 means until server restart or reload eluna.
--               -  $delay is the time between each repetition in minutes.
--               -  $text Is the exacht text to broacast. No quotes required. Forbidden chars: [];\
------------------------------------------------------------------------------------------------
local Config = {}                       --general config flags

-- Name of Eluna dB scheme
Config.customDbName = "ac_eluna"
-- Min GM rank to post an announcement
Config.GMRankForAnnouncements = 2
-- set to 1 to print error messages to the console. Any other value including nil turns it off.
Config.printErrorsToConsole = 1

------------------------------------------
-- NO ADJUSTMENTS REQUIRED BELOW THIS LINE
------------------------------------------
-- Constants:
local PLAYER_EVENT_ON_COMMAND = 42          -- (event, player, command) - player is nil if command used from console. Can return false
local GOSSIP_EVENT_ON_HELLO = 1             -- (event, player, object) - Object is the Creature/GameObject/Item. Can return false to do default action. For item gossip can return false to stop spell casting.
local GOSSIP_EVENT_ON_SELECT = 2            -- (event, player, object, sender, intid, code, menu_id)
local OPTION_ICON_CHAT = 0

-- Local variables:
local lastAnnouncement = {}                 -- server timestamp when the last announcement happened
local repetitionsLeft = {}                  -- amount of repetitions left for the announcements
local minutesBetween = {}                   -- time between two announcements with the same text in minutes
local announcementText = {}                 -- text for the announcements

local function eS_splitString(inputstr, seperator)
    if seperator == nil then
        seperator = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..seperator.."]+)") do
        table.insert(t, str)
    end
    return t
end

local function eS_getTimeSince(time)
    local dt = GetTimeDiff(time)
    return dt
end

local function eS_getFreeId()
    local n = 1
    while repetitionsLeft[n] == nil do
        n = n + 1
    end
    return n
end

local function eS_listAnnouncements()
    local returnString = ""
    local n = 0
    while n < #repetitionsLeft do
        if repetitionsLeft[n] ~= nil then
            n = n + 1
            returnString = returnString.." / ID:"..n.." delay: "..minutesBetween[n].." shots left: "..repetitionsLeft.." Text: "..announcementText
        end
    end
    return returnString
end

local function eS_deleteAnnouncement()
    --todo: delete announcement entry variables and delete it from db, too
end

local function eS_createAnnouncement(delayMin, text, repetitions)
    -- todo: register event and write it to db
end

local function eS_doAnnouncement()
    -- todo: send the announcement, reduce the counter repetitionsLeft by 1, possibly delete it and update the db
end

local function eS_command(event, player, command)
    local commandArray = {}

    --prevent players from using this  
    if player:GetGMRank() < Config.GMRankForAnnouncements then
        return
    end
    

    -- split the command variable into several strings which can be compared individually
    commandArray = eS_splitString(command)

    if commandArray[2] ~= nil then
        commandArray[2] = commandArray[2]:gsub("[';\\, ]", "")
        if commandArray[3] ~= nil then
            commandArray[3] = commandArray[3]:gsub("[';]", "")
            if commandArray[4] ~= nil then
                commandArray[4] = commandArray[4]:gsub("[;\\]", "")
            end
        end
    end

    if commandArray[1] == "tempannounce" then
        if commandArray[2] == "print" then
            local listOfAnnouncements = eS_listAnnouncements()
            if player == nil then
                print(listOfAnnouncements)
            else
                player:SendBroadcastMessage(listOfAnnouncements)
            end
            return false
        elseif commandArray[2] == "delete" then
            if commandArray[3] ~= nil then
                eS_deleteAnnouncement()
            else
                if player == nil then
                    print("Invalid syntax. Expected: .tempannounce delete $id")
                else
                    player:SendBroadcastMessage("Invalid syntax. Expected: .tempannounce delete $id")
                end
            end
            return false
        elseif commandArray[2] == nil or commandArray[3] == nil or commandArray[4] == nil then
            if player == nil then
                print("Invalid syntax. Expected: tempannounce $delay $text $repetitions")
            else
                player:SendBroadcastMessage("Invalid syntax. Expected: .tempannounce $delay $text $repetitions")
            end
            return false
        end

        eS_createAnnouncement(commandArray[2],commandArray[3],commandArray[4])
        
    end
end

--on ReloadEluna / Startup
RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, eS_command)

CharDBQuery('CREATE DATABASE IF NOT EXISTS `'..Config.customDbName..'`;');
CharDBQuery('CREATE TABLE IF NOT EXISTS `'..Config.customDbName..'`.`temporary_announcements` (`id` INT NOT NULL, `last_announcement` INT NOT NULL, `repetitions_left` INT DEFAULT 0, `minutes_between` INT Default 60, `announcement_text` varchar(255), PRIMARY KEY (`id`));');

local Data_SQL = CharDBQuery('SELECT * FROM `'..Config.customDbName..'`.`temporary_announcements`;')
if Data_SQL ~= nil then
    local id
    repeat
        id = Data_SQL:GetUInt32(0)
        lastAnnouncement[id] = Data_SQL:GetUInt32(1)
        repetitionsLeft[id] = Data_SQL:GetUInt32(2)
        minutesBetween[id] = Data_SQL:GetUInt32(3)
        announcementText[id] = Data_SQL:GetString(4)
    until not Data_SQL:NextRow()
end

-- todo: create events for existing announcements
