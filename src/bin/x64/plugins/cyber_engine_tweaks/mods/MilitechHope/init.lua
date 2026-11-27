-- Militech "Hope" Sandevistan — Cyber Engine Tweaks helper (optional).
--
-- CET console commands (open the console with the CET overlay key):
--   GetMod("MilitechHope").give()        -- give Tier 5 implant
--   GetMod("MilitechHope").give(2)       -- give Tier 5++ (0 = T5, 1 = T5+, 2 = T5++)
--   GetMod("MilitechHope").quest()       -- show side job stage
--   GetMod("MilitechHope").resetQuest()  -- restart side job "Hope"
--
-- Same thing without this helper:
--   Game.AddToInventory("Items.MilitechHopeSandevistan", 1)

local MilitechHope = {
    version = "1.0.0",
    items = {
        [0] = "Items.MilitechHopeSandevistan",
        [1] = "Items.MilitechHopeSandevistanPlus",
        [2] = "Items.MilitechHopeSandevistanPlusPlus",
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
    end
    ImGui.End()
end)

return MilitechHope
