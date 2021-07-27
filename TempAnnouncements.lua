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
local repetitionsLeft = {}                  -- amount of repetitions left for the announcements
local minutesBetween = {}                   -- time between two announcements with the same text in minutes
local announcementText = {}                 -- text for the announcements
local eventId = {}

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

local function eS_returnIndex (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return index
        end
    end
    return false
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

local function eS_concatRest(array, firstIndex)
    if array[firstIndex] ~= nil then
        local counter
        for index,value in ipairs(array) do
            if index >= firstIndex then
                if text == nil then
                    text = array[index].." "
                else
                    text = text..array[index].." "
                end
            end
        end
    else
        text = ""
    end
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

local function eS_deleteAnnouncement(id)
    if minutesBetween[id] ~= nil then
        repetitionsLeft[index] = nil
        minutesBetween[index] = nil
        announcementText[index] = nil
        eventId[index] = nil
        CharDBExecute('DELETE FROM `'..Config.customDbName..'`.`temporary_announcements` WHERE `id` = '..id..';')
    end
end

local function eS_doAnnouncement(id, delay, repeats)
    local index = eS_returnIndex(eventId, id)
    SendWorldMessage(announcementText[index])
    if repetitionsLeft[index] == 1 then
        eS_deleteAnnouncement(index)
    else
        repetitionsLeft[index] = repetitionsLeft[index] - 1
        CharDBExecute('UPDATE `'..Config.customDbName..'`.`temporary_announcements` SET repetitions_left = '..repetitionsLeft[index]..';')
    end
end

local function eS_createAnnouncement(delayMin, repeats, text)
    local index = eS_getFreeId()
    local delayMs = delayMin * 60000
    repetitionsLeft[index] = repeats
    minutesBetween[index] = delayMin
    announcementText[index] = text
    eventId[index] = CreateLuaEvent(eS_doAnnouncement, delayMs, repeats)
    CharDBExecute('DELETE FROM `'..Config.customDbName..'`.`temporary_announcements` WHERE `id` = '..index..';')
    CharDBExecute('INSERT INTO `'..Config.customDbName..'`.`temporary_announcements` (`id`, `repetitions_left`, `minutes_between`, `announcement_text`) VALUES ('..index..', '..repetitionsLeft[index]..', '..minutesBetween[index]..', '..announcementText[index]..';')
    return index
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
                if player == nil then
                    print("Deleting event with id: "..eS_deleteAnnouncement(commandArray[3]))
                else
                    player:SendBroadcastMessage("Deleting event with id: "..eS_deleteAnnouncement(commandArray[3]))
                end
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
                print("Invalid syntax. Expected: tempannounce $delay $repetitions $text")
            else
                player:SendBroadcastMessage("Invalid syntax. Expected: tempannounce $delay $repetitions $text")
            end
            return false
        end

        local text = eS_concatRest(commandArray, 4)

        if player == nil then
            print("Creating event with id: "..eS_createAnnouncement(commandArray[2],commandArray[3],text))
        else
            player:SendBroadcastMessage("Creating event with id: "..eS_createAnnouncement(commandArray[2],commandArray[3],text))
        end
        
    end
end

--on ReloadEluna / Startup
RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, eS_command)

CharDBQuery('CREATE DATABASE IF NOT EXISTS `'..Config.customDbName..'`;');
CharDBQuery('CREATE TABLE IF NOT EXISTS `'..Config.customDbName..'`.`temporary_announcements` (`id` INT NOT NULL, `repetitions_left` INT DEFAULT 0, `minutes_between` INT Default 60, `announcement_text` varchar(255), PRIMARY KEY (`id`));');

local Data_SQL = CharDBQuery('SELECT * FROM `'..Config.customDbName..'`.`temporary_announcements`;')
if Data_SQL ~= nil then
    local id
    repeat
        id = Data_SQL:GetUInt32(0)
        repetitionsLeft[id] = Data_SQL:GetUInt32(1)
        minutesBetween[id] = Data_SQL:GetUInt32(2)
        announcementText[id] = Data_SQL:GetString(3)
        eS_createAnnouncement(minutesBetween[id], repetitionsLeft[id], announcementText[id])
        until not Data_SQL:NextRow()
end
