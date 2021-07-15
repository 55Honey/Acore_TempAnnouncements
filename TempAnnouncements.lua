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
--               -  $text Is the exacht text to broacast. No quotes required.
------------------------------------------------------------------------------------------------
local Config = {}                       --general config flags

-- Min GM rank to post an announcement
Config.GMRankForEventStart = 2
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
local announcementText = {}                 -- text for the announcements
local repetitionsLeft = {}                  -- repetitions left for the announcements

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

local function eS_command(event, player, command)
    local commandArray = {}

    --prevent players from using this  
    if player:GetGMRank() < Config.GMRankForEventStart then
        return
    end
    

    -- split the command variable into several strings which can be compared individually
    commandArray = eS_splitString(command)

    if commandArray[2] ~= nil then
        commandArray[2] = commandArray[2]:gsub("[';\\, ]", "")
        if commandArray[3] ~= nil then
            commandArray[3] = commandArray[3]:gsub("[';\\, ]", "")
            if commandArray[4] ~= nil then
                commandArray[4] = commandArray[4]:gsub("[';\\, ]", "")
            end
        end
    end

    if commandArray[1] == "tempannounce" then
        if commandArray[2] == "print" then
            --todo: print all active announcements
        end
        
        if commandArray[2] == nil or commandArray[3] == nil or commandArray[4] == nil then
            if player == nil then
                print("Invalid syntax. Expected: .tempannounce $limit $delay $text")
            else
                player:SendBroadcastMessage("Invalid syntax. Expected: .tempannounce $limit $delay $text")
            end
            return false
        end
        
        -- todo: do something
        
    end
end

--on ReloadEluna / Startup
RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, eS_command)
