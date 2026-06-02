local json = require("json")
local playerData = {}
local savePath = "extensions/careerAuth/users.json"
local authenticatedPlayers = {}

function onInit()
    MP.RegisterEvent("onPlayerAuth", "onPlayerAuth")
    MP.RegisterEvent("onPlayerChat", "onPlayerChat")
    MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
    
    local file = io.open(savePath, "r")
    if file then
        playerData = json.decode(file:read("*all")) or {}
        file:close()
    end
    print("[CareerAuth] System loaded. Ready to patch Guest names.")
end

function saveUsers()
    local file = io.open(savePath, "w")
    if file then
        file:write(json.encode(playerData))
        file:close()
    end
end

function onPlayerAuth(playerName, playerRole, isGuest, identifiers)
    return nil 
end

function onPlayerChat(playerID, currentGuestName, message)
    if string.sub(message, 1, 9) == "/register" then
        local params = {}
        for word in string.gmatch(string.sub(message, 11), "%S+") do
            table.insert(params, word)
        end
        
        local desiredName = params[1]
        local password = params[2]
        
        if not desiredName or not password then
            MP.SendChatMessage(playerID, "Usage: /register [Username] [Password]")
            return 1
        end
        
        if playerData[desiredName] then
            MP.SendChatMessage(playerID, "That username is already taken.")
            return 1
        end
        
        playerData[desiredName] = password
        saveUsers()
        
        MP.SetPlayerName(playerID, desiredName)
        authenticatedPlayers[playerID] = true
        
        MP.SendChatMessage(playerID, "Registered! Profile switched to: " .. desiredName .. ". Your career progress will now save.")
        return 1
    end

    if string.sub(message, 1, 6) == "/login" then
        local params = {}
        for word in string.gmatch(string.sub(message, 8), "%S+") do
            table.insert(params, word)
        end
        
        local registeredName = params[1]
        local password = params[2]
        
        if not registeredName or not password then
            MP.SendChatMessage(playerID, "Usage: /login [Username] [Password]")
            return 1
        end
        
        if playerData[registeredName] == password then
            MP.SetPlayerName(playerID, registeredName)
            authenticatedPlayers[playerID] = true
            MP.SendChatMessage(playerID, "Logged in! Welcome back " .. registeredName .. ". Progress loaded.")
        else
            MP.SendChatMessage(playerID, "Error: Invalid username or password.")
        end
        return 1
    end

    if not authenticatedPlayers[playerID] then
        MP.SendChatMessage(playerID, "[SYSTEM] Server is in Guest Mode. You must type /login [Name] [Pass] or /register [Name] [Pass] to play.")
        return 1
    end
end

function onPlayerDisconnect(playerID)
    authenticatedPlayers[playerID] = nil
end