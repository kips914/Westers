-- Militech "Hope" Sandevistan — Cyber Engine Tweaks helper (optional).
--
-- CET console commands (open the console with the CET overlay key):
--   GetMod("MilitechHope").give()        -- give Tier 5 implant
--   GetMod("MilitechHope").give(2)       -- give Tier 5++ (0 = T5, 1 = T5+, 2 = T5++)
--   GetMod("MilitechHope").quest()       -- show side job stage
--   GetMod("MilitechHope").resetQuest()  -- restart side job "Hope"
--
-- Tier 5++ upgrade modules (1 Discharge, 2 Quick Recharge, 3 New Breath,
-- 4 Phase Shield, 5 Berserk, 6 True Madness):
--   GetMod("MilitechHope").upgrade(1)     -- give module #1
--   GetMod("MilitechHope").upgrades()     -- give all six modules
--   GetMod("MilitechHope").install(5)     -- give (if needed) and install #5 into the equipped Tier 5++
--                                           (2 slots: first a free slot, then they are replaced in turn)
--   GetMod("MilitechHope").modules()      -- show what is installed in the two slots
--   GetMod("MilitechHope").uninstall()    -- take both modules out (back into the backpack)
--   GetMod("MilitechHope").diag()         -- check that TweakXL, redscript, Codeware and the texts work
--   GetMod("MilitechHope").broker()       -- unlock the broker's number (F7) without the card
--   GetMod("MilitechHope").card()         -- give the broker's business card
--   GetMod("MilitechHope").heat()         -- print core temperature
--   GetMod("MilitechHope").cool()         -- cool the core down to 40 C
--   GetMod("MilitechHope").contract()     -- finish the current broker contract
--   GetMod("MilitechHope").mastery()      -- show mastery (activations, level, capacity cost)
--   GetMod("MilitechHope").mastery(40)    -- set the activation count (20 per level, max 100)
--   GetMod("MilitechHope").burnout()      -- trigger a burnout right now (test)
--   GetMod("MilitechHope").warn(2)        -- show the overheat warning (1 = soft, 2 = critical)
--
-- Same thing without this helper:
--   Game.AddToInventory("Items.MilitechHopeSandevistan", 1)

local MilitechHope = {
    version = "1.4.2",
    items = {
        [0] = "Items.MilitechHopeSandevistan",
        [1] = "Items.MilitechHopeSandevistanPlus",
        [2] = "Items.MilitechHopeSandevistanPlusPlus",
    },
    upgradeItems = {
        [1] = "Items.MilitechHopeMod_Discharge",
        [2] = "Items.MilitechHopeMod_QuickCharge",
        [3] = "Items.MilitechHopeMod_NewBreath",
        [4] = "Items.MilitechHopeMod_PhaseShield",
        [5] = "Items.MilitechHopeMod_Berserk",
        [6] = "Items.MilitechHopeMod_TrueMadness",
    },
    upgradeNames = {
        [1] = "Discharge", [2] = "Quick Recharge", [3] = "New Breath",
        [4] = "Phase Shield", [5] = "Berserk", [6] = "True Madness",
    },
    stages = {
        [0] = "not started: drive to Arasaka Waterfront (Watson), level 40+",
        [1] = "active: find the Militech case near the Columbarium (cemetery)",
        [2] = "completed",
    },
    showWindow = false,
}

local function getSystem()
    local container = Game.GetScriptableSystemsContainer()
    if not container then return nil end
    return container:Get("MilitechHope.MilitechHopeSystem")
end

function MilitechHope.give(level)
    level = tonumber(level) or 0
    local item = MilitechHope.items[level] or MilitechHope.items[0]
    Game.AddToInventory(item, 1)
    print("[MilitechHope] Added " .. item)
    return item
end

function MilitechHope.quest()
    local system = getSystem()
    if not system then
        print("[MilitechHope] System not found. Are redscript, Codeware and the mod scripts installed?")
        return nil
    end
    local stage = system:GetStage()
    print("[MilitechHope] Side job stage " .. tostring(stage) .. " - " .. (MilitechHope.stages[stage] or "?"))
    return stage
end

function MilitechHope.resetQuest()
    local system = getSystem()
    if not system then
        print("[MilitechHope] System not found.")
        return
    end
    system:DebugSetStage(0)
    print("[MilitechHope] Side job reset. Drive to Arasaka Waterfront to start it again.")
end

function MilitechHope.upgrade(index)
    index = tonumber(index) or 1
    local item = MilitechHope.upgradeItems[index]
    if not item then
        print("[MilitechHope] Upgrade index must be 1..6")
        return nil
    end
    Game.AddToInventory(item, 1)
    print("[MilitechHope] Added " .. item .. " (" .. MilitechHope.upgradeNames[index] .. ")")
    return item
end

function MilitechHope.upgrades()
    for i = 1, 6 do MilitechHope.upgrade(i) end
end

function MilitechHope.install(index)
    index = tonumber(index) or 1
    if not MilitechHope.upgradeItems[index] then
        print("[MilitechHope] Upgrade index must be 1..6")
        return
    end
    local system = getSystem()
    if not system then
        print("[MilitechHope] System not found.")
        return
    end
    local result = system:DebugInstallUpgrade(index - 1)
    if result == 0 then
        print("[MilitechHope] Installed " .. MilitechHope.upgradeNames[index])
    elseif result == 1 then
        print("[MilitechHope] Equip the Tier 5++ Hope Sandevistan first.")
    else
        print("[MilitechHope] Could not install the module.")
    end
end

function MilitechHope.modules()
    local system = getSystem()
    if not system then print("[MilitechHope] System not found.") return nil end
    local text = system:DebugGetUpgrades()
    if text == nil or text == "" then
        print("[MilitechHope] No Tier 5++ Hope equipped.")
        return nil
    end
    local names = {}
    for token in string.gmatch(text, "[^,%s]+") do
        local index = tonumber(token)
        table.insert(names, index and (tostring(index) .. " " .. MilitechHope.upgradeNames[index]) or "empty")
    end
    print("[MilitechHope] Slot 1: " .. (names[1] or "empty") .. " | Slot 2: " .. (names[2] or "empty"))
    return text
end

function MilitechHope.uninstall()
    local system = getSystem()
    if not system then print("[MilitechHope] System not found.") return end
    local removed = system:DebugRemoveUpgrades()
    print("[MilitechHope] Modules removed: " .. tostring(removed))
end

-- Checks every part the mod depends on. Returns ok, message.
function MilitechHope.diag(quiet)
    local problems = {}
    local function say(line) if not quiet then print("[MilitechHope] " .. line) end end

    local okRecord, record = pcall(function() return TweakDB:GetRecord("Items.MilitechHopeSandevistan") end)
    if okRecord and record then
        say("TweakXL: OK (implant record found)")
    else
        say("TweakXL: FAIL - the implant record is missing (TweakXL not installed or .tweak not loaded)")
        table.insert(problems, "TweakXL")
    end

    local system = getSystem()
    local okVer, scriptVersion = false, nil
    if system then okVer, scriptVersion = pcall(function() return system:DebugVersion() end) end

    local okCw, cwVersion = pcall(function() return Codeware.Version() end)
    if okCw and cwVersion then
        say("Codeware: OK (" .. tostring(cwVersion) .. ")")
    elseif okVer and scriptVersion then
        say("Codeware: OK (the mod scripts that need it are running)")
    else
        say("Codeware: FAIL - not installed or not loaded (RED4ext / game version mismatch?)")
        table.insert(problems, "Codeware")
    end

    if okVer and scriptVersion then
        say("redscript: OK (mod scripts v" .. tostring(scriptVersion) .. ")")
        if scriptVersion ~= MilitechHope.version then
            say("redscript: WARNING - scripts v" .. tostring(scriptVersion) .. " but CET helper v" .. MilitechHope.version .. " (old files left over?)")
        end
    else
        say("redscript: FAIL - mod scripts are not running. Usually a compile error:")
        say("   open <game>\\r6\\logs\\redscript_rCURRENT.log and look for [ERROR] lines")
        table.insert(problems, "redscript")
    end

    local okText, text = pcall(function() return Game.GetLocalizedTextByKey("MilitechHope-Name") end)
    if not okText then
        say("Texts: could not be checked from CET")
    elseif text and text ~= "" and not string.find(text, "LocKey", 1, true) and text ~= "MilitechHope-Name" then
        say("Texts: OK (" .. text .. ")")
    else
        say("Texts: FAIL - item descriptions will show LocKey#... (needs redscript + Codeware working)")
        table.insert(problems, "texts")
    end

    if #problems == 0 then
        say("Everything works.")
        return true, "OK"
    end
    local message = "Militech Hope: не работает " .. table.concat(problems, ", ") ..
        ". Проверьте r6\\logs\\redscript_rCURRENT.log (CET: GetMod(\"MilitechHope\").diag())"
    return false, message
end

function MilitechHope.card()
    Game.AddToInventory("Items.MilitechHopeDealerCard", 1)
    print("[MilitechHope] Added the broker's business card. Press F7 to call.")
end

function MilitechHope.broker()
    local system = getSystem()
    if not system then print("[MilitechHope] System not found.") return end
    system:DebugUnlockBroker()
    print("[MilitechHope] Broker unlocked. Press F7 to call.")
end

function MilitechHope.heat()
    local system = getSystem()
    if not system then print("[MilitechHope] System not found.") return nil end
    local value = system:DebugGetHeat()
    print(string.format("[MilitechHope] Core temperature: %.1f C", value))
    return value
end

function MilitechHope.cool()
    local system = getSystem()
    if not system then print("[MilitechHope] System not found.") return end
    system:DebugSetHeat(40.0)
    print("[MilitechHope] Core cooled down to 40 C.")
end

function MilitechHope.contract()
    local system = getSystem()
    if not system then print("[MilitechHope] System not found.") return end
    system:DebugCompleteContract()
    print("[MilitechHope] Current contract marked as done. Call the broker (F7) for the reward.")
end

function MilitechHope.mastery(uses)
    local system = getSystem()
    if not system then print("[MilitechHope] System not found.") return nil end
    if uses ~= nil then
        system:DebugSetMastery(math.floor(tonumber(uses) or 0))
    end
    local count = system:DebugGetMastery()
    local level = math.min(5, math.floor(count / 20))
    print(string.format("[MilitechHope] Mastery: %d activations, level %d, capacity cost %d", count, level, 50 - 3 * level))
    return count
end

function MilitechHope.burnout()
    local system = getSystem()
    if not system then print("[MilitechHope] System not found.") return end
    system:DebugBurnout()
    print("[MilitechHope] Burnout triggered (close the console).")
end

function MilitechHope.warn(kind)
    local system = getSystem()
    if not system then print("[MilitechHope] System not found.") return end
    system:DebugWarning(math.floor(tonumber(kind) or 2))
    print("[MilitechHope] Warning queued (needs Hope equipped).")
end

registerForEvent("onInit", function()
    print("[MilitechHope] v" .. MilitechHope.version .. " loaded. Console: GetMod(\"MilitechHope\").give()")
end)

-- One automatic check per game session: if the scripts did not compile,
-- tell the player right away instead of silently showing LocKey texts.
local sessionCheck = { done = false, timer = 0.0 }

registerForEvent("onUpdate", function(dt)
    if sessionCheck.done then return end
    local okPlayer, player = pcall(function() return Game.GetPlayer() end)
    if not okPlayer or not player then sessionCheck.timer = 0.0 return end
    local okPre, preGame = pcall(function() return Game.GetSystemRequestsHandler():IsPreGame() end)
    if okPre and preGame then sessionCheck.timer = 0.0 return end
    sessionCheck.timer = sessionCheck.timer + dt
    if sessionCheck.timer < 8.0 then return end
    sessionCheck.done = true
    local okDiag, ok, message = pcall(MilitechHope.diag, true)
    if okDiag and not ok then
        print("[MilitechHope] " .. message)
        pcall(function() player:SetWarningMessage(message) end)
    end
end)

registerForEvent("onOverlayOpen", function() MilitechHope.showWindow = true end)
registerForEvent("onOverlayClose", function() MilitechHope.showWindow = false end)

registerForEvent("onDraw", function()
    if not MilitechHope.showWindow then return end
    if ImGui.Begin("Militech Hope Sandevistan", ImGuiWindowFlags.AlwaysAutoResize) then
        if ImGui.Button("Give Tier 5") then MilitechHope.give(0) end
        ImGui.SameLine()
        if ImGui.Button("Tier 5+") then MilitechHope.give(1) end
        ImGui.SameLine()
        if ImGui.Button("Tier 5++") then MilitechHope.give(2) end
        ImGui.Separator()
        if ImGui.Button("Quest stage") then MilitechHope.quest() end
        ImGui.SameLine()
        if ImGui.Button("Reset quest") then MilitechHope.resetQuest() end
        ImGui.Separator()
        ImGui.Text("Tier 5++ modules (install = give + put into the slot)")
        for i = 1, 6 do
            if ImGui.Button("Install " .. MilitechHope.upgradeNames[i]) then MilitechHope.install(i) end
            if i % 3 ~= 0 then ImGui.SameLine() end
        end
        if ImGui.Button("Give all modules") then MilitechHope.upgrades() end
        ImGui.SameLine()
        if ImGui.Button("Unlock broker (F7)") then MilitechHope.broker() end
        ImGui.SameLine()
        if ImGui.Button("Cool down") then MilitechHope.cool() end
        if ImGui.Button("Show modules") then MilitechHope.modules() end
        ImGui.SameLine()
        if ImGui.Button("Remove modules") then MilitechHope.uninstall() end
        ImGui.SameLine()
        if ImGui.Button("Diagnostics") then MilitechHope.diag() end
        ImGui.Separator()
        if ImGui.Button("Mastery") then MilitechHope.mastery() end
        ImGui.SameLine()
        if ImGui.Button("Mastery +20") then
            local system = getSystem()
            if system then MilitechHope.mastery(system:DebugGetMastery() + 20) end
        end
        ImGui.SameLine()
        if ImGui.Button("Test warning") then MilitechHope.warn(2) end
        ImGui.SameLine()
        if ImGui.Button("Test burnout") then MilitechHope.burnout() end
    end
    ImGui.End()
end)

return MilitechHope
