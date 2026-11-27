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
--   GetMod("MilitechHope").broker()       -- unlock the broker's number (F7) without the card
--   GetMod("MilitechHope").card()         -- give the broker's business card
--   GetMod("MilitechHope").heat()         -- print core temperature
--   GetMod("MilitechHope").cool()         -- cool the core down to 40 C
--   GetMod("MilitechHope").contract()     -- finish the current broker contract
--
-- Same thing without this helper:
--   Game.AddToInventory("Items.MilitechHopeSandevistan", 1)

local MilitechHope = {
    version = "1.3.0",
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

registerForEvent("onInit", function()
    print("[MilitechHope] v" .. MilitechHope.version .. " loaded. Console: GetMod(\"MilitechHope\").give()")
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
    end
    ImGui.End()
end)

return MilitechHope
