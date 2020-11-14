--[[
    First Release By Storm Team (Raau,Martin) @ 14.Nov.2020    
]]

if Player.CharName ~= "Morgana" then return end

require("common.log")
module("Storm Morgana", package.seeall, log.setup)

local clock = os.clock
local insert, sort = table.insert, table.sort
local huge, min, max, abs = math.huge, math.min, math.max, math.abs

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Morgana = {}

local spells = {
    Q = Spell.Skillshot({
        Slot = Enums.SpellSlots.Q,
        Range = 1300,
        Radius = 140,
        Delay = 0.25,
        Speed = 1200,
        Collisions = { Heroes = true, Minions = true, WindWall = true },
        Type = "Linear",
        UseHitbox = true
    }),
    W = Spell.Skillshot({
        Slot = Enums.SpellSlots.W,
        Range = 900,
        Radius = 200,
        Delay = 0.25,
        Type = "Circular",
    }),
    E = Spell.Targeted({
        Slot = Enums.SpellSlots.E,
        Range = 800,
        Delay = 0
    }),
    R = Spell.Active({
        Slot = Enums.SpellSlots.R,
        Range = 575,
        Delay = 0.35,
    }),
}

local function GameIsAvailable()
    return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end


function Morgana.IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell) and spells[spell]:IsReady()
end
local lastTick = 0
function Morgana.OnTick()    
    if not GameIsAvailable() then return end 

    local gameTime = Game.GetTime()
    if gameTime < (lastTick + 0.25) then return end
    lastTick = gameTime    

    if Morgana.Auto() then return end
    if not Orbwalker.CanCast() then return end

    local ModeToExecute = Morgana[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute()
    end
end
function Morgana.OnDraw() 
    local playerPos = Player.Position
    local pRange = Orbwalker.GetTrueAutoAttackRange(Player)   
    

    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(playerPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color")) 
        end
    end
end

function Morgana.GetTargets(range)
    return {TS:GetTarget(range, true)}
end

function Morgana.ComboLogic(mode)
    if Morgana.IsEnabledAndReady("Q", mode) then
        local qChance = Menu.Get(mode .. ".ChanceQ")
        for k, qTarget in ipairs(Morgana.GetTargets(spells.Q.Range)) do
            if spells.Q:CastOnHitChance(qTarget, qChance) then
                return
            end
        end
    end
    if Morgana.IsEnabledAndReady("W", mode) then
        local wChance = Menu.Get(mode .. ".ChanceW")
        for k, wTarget in ipairs(Morgana.GetTargets(spells.W.Range)) do
            if spells.W:CastOnHitChance(wTarget, wChance) then
                return
            end
        end
    end
end
function Morgana.HarassLogic(mode)
    local PM = Player.Mana / Player.MaxMana * 100
    local SettedMana = Menu.Get("Harass.Mana")
    if SettedMana > PM then 
        return 
        end
        if Morgana.IsEnabledAndReady("Q", mode) then
            local qChance = Menu.Get(mode .. ".ChanceQ")
            for k, qTarget in ipairs(Morgana.GetTargets(spells.Q.Range)) do
                if spells.Q:CastOnHitChance(qTarget, qChance) then
                    return
                end
            end
        end
        if Morgana.IsEnabledAndReady("W", mode) then
            local wChance = Menu.Get(mode .. ".ChanceW")
            for k, wTarget in ipairs(Morgana.GetTargets(spells.W.Range)) do
                if spells.W:CastOnHitChance(wTarget, wChance) then
                    return
                end
            end
        end
end
---@param source AIBaseClient
---@param spell SpellCast
function Morgana.OnInterruptibleSpell(source, spell, danger, endT, canMove)
    if not (source.IsEnemy and Menu.Get("Misc.IntQ") and spells.Q:IsReady() and danger > 2) then return end

    spells.Q:CastOnHitChance(source, Enums.HitChance.VeryHigh)
end

function Morgana.Auto() 
  
end

function Morgana.Combo()  Morgana.ComboLogic("Combo")  end
function Morgana.Harass() Morgana.HarassLogic("Harass") end



function Morgana.LoadMenu()

    Menu.RegisterMenu("StormMorgana", "Storm Morgana", function()
        Menu.ColumnLayout("cols", "cols", 2, true, function()
            Menu.ColoredText("Combo", 0xFFD700FF, true)
            Menu.Checkbox("Combo.UseQ",   "Use [Q]", true) 
            Menu.Slider("Combo.ChanceQ", "HitChance [Q]", 0.7, 0, 1, 0.05)   
            Menu.Checkbox("Combo.UseW",   "Use [W]", true)
            Menu.Slider("Combo.ChanceW", "HitChance [W]", 0.7, 0, 1, 0.05)   
            Menu.Checkbox("Combo.UseE",   "Use [E]", true)
            Menu.NextColumn()

            Menu.ColoredText("Harass", 0xFFD700FF, true)
            Menu.Slider("Harass.Mana", "Mana Percent ", 50,0, 100)
            Menu.Checkbox("Harass.UseQ",   "Use [Q]", true)   
            Menu.Slider("Harass.ChanceQ", "HitChance [Q]", 0.85, 0, 1, 0.05)
            Menu.Checkbox("Harass.UseW",   "Use [W]", false)
            Menu.Slider("Harass.ChanceW", "HitChance [W]", 0.85, 0, 1, 0.05)
              
        end)
        Menu.Separator()

        Menu.ColoredText("Misc Options", 0xFFD700FF, true)      
        Menu.Checkbox("Misc.IntQ", "Use [Q] Interrupt", true)        
        Menu.Separator()

        Menu.ColoredText("Draw Options", 0xFFD700FF, true)
        Menu.Checkbox("Drawing.Q.Enabled",   "Draw [Q] Range")
        Menu.ColorPicker("Drawing.Q.Color", "Draw [Q] Color", 0x118AB2FF)     
        Menu.Checkbox("Drawing.W.Enabled",   "Draw [W] Range")
        Menu.ColorPicker("Drawing.W.Color", "Draw [W] Color", 0x118AB2FF)    
        Menu.Checkbox("Drawing.R.Enabled",   "Draw [R] Range")
        Menu.ColorPicker("Drawing.R.Color", "Draw [R] Color", 0x118AB2FF)     
    end)     
end

function OnLoad()
    Morgana.LoadMenu()
    for eventName, eventId in pairs(Enums.Events) do
        if Morgana[eventName] then
            EventManager.RegisterCallback(eventId, Morgana[eventName])
        end
    end    
    return true
end