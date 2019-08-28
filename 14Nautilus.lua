require 'MapPositionGOS'

if (myHero.charName ~= "Nautilus") then 
    return
end



if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
	print("GsoPred. installed Press 2x F6")
	--DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronPrediction.lua", COMMON_PATH .. "GamsteronPrediction.lua", function() end)
	while not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") do end
end
    
require('GamsteronPrediction')

local  TS, OB, DMG, SPELLS
local myHero = myHero
local LocalGameTimer = Game.Timer
GamCore = _G.GamsteronCore

local lineQ

local function IsValid(unit)
    if (unit 
        and unit.valid 
        and unit.isTargetable 
        and unit.alive 
        and unit.visible 
        and unit.networkID 
        and unit.health > 0) then
        return true;
    end
    return false;
end

local function Ready(spell)
    return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana and Game.CanUseSpell(spell) == 0
end

class "Nautilus"

function Nautilus:__init()
    ORB, TS, OB, DMG, SPELLS = _G.SDK.Orbwalker, _G.SDK.TargetSelector, _G.SDK.ObjectManager, _G.SDK.Damage, _G.SDK.Spells
    self.LastReset = 0
    self.QData = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 90, Range = 1000, Speed = 2000, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}, UseBoundingRadius = true}
    self:LoadMenu()
    Callback.Add("Tick", function() self:Tick() end)
    Callback.Add("Draw", function() self:Draw() end)
end






function Nautilus:LoadMenu()
    LL = MenuElement({type = MENU, id = "ll", name = "Nautilus"})
    
    --combo
    
    LL:MenuElement({type = MENU, id = "Combo", name = "Combo"})
    LL.Combo:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
    GamCore:OnEnemyHeroLoad(function(hero) LL.Combo.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
    LL.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
    LL.Combo:MenuElement({id = "UseW", name = "[W]", value = true})
    LL.Combo:MenuElement({id = "UseE", name = "[E]", value = true})
    
    --Harass
    LL:MenuElement({type = MENU, id = "Harass", name = "Harass"})
    LL.Harass:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
    GamCore:OnEnemyHeroLoad(function(hero) LL.Harass.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
    LL.Harass:MenuElement({id = "UseQ", name = "Q", value = true})

    --Auto
    LL:MenuElement({type = MENU, id = "Auto", name = "Auto"})
    LL.Auto:MenuElement({id = "AutoIG", name = "Auto Ingite KS", value = true})


    --Draw
    LL:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
    LL.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})


end

function Nautilus:Draw()
    if myHero.dead then
        return
    end
--[[
    if lineQ ~= nil then
        lineQ:__draw(1)
    end
--]]

    if LL.Drawing.Q:Value() and Ready(_Q) then
        Draw.Circle(myHero.pos, 1000,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end

end


local NextTick = GetTickCount()
function Nautilus:Tick()
    if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
        return
    end

    self:Auto()
    if NextTick > GetTickCount() then return end
    ORB:SetMovement(true)
    if ORB.Modes[0] then --combo
        self:Combo()
    elseif ORB.Modes[1] then --harass
        self:Harass()
    end

end

function Nautilus:Combo()
    local EnemyHeroes = OB:GetEnemyHeroes(1100, false)
    local targetList = {}

    for i = 1, #EnemyHeroes do
        local hero = EnemyHeroes[i]
        local heroName = hero.charName
        if LL.Combo.useon[heroName] and LL.Combo.useon[heroName]:Value() then
            targetList[#targetList + 1] = hero
        end
    end
    local target = TS:GetTarget(targetList)
    if target == nil then return end


    if IsValid(target) then
        if LL.Combo.UseQ:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) <= 1100 then

            local Pred = GetGamsteronPrediction(target, self.QData, myHero)
            if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                lineQ = LineSegment(Pred.CastPosition, Pred.CastPosition:Extended(myHero.pos, myHero.pos:DistanceTo(target.pos)))
                if MapPosition:intersectsWall(lineQ) then
                    return
                end
                NextTick = GetTickCount() + 750
                ORB:SetMovement(false)
                Control.CastSpell(HK_Q, Pred.CastPosition)
                print("cast Q")
            end
        end

        if LL.Combo.UseW:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) <= 325 then
            NextTick = GetTickCount() + 100
            Control.CastSpell(HK_W)
            print("cast W")

        end



        if LL.Combo.UseE:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= 325 then
            NextTick = GetTickCount() + 850
            Control.CastSpell(HK_E)
            print("cast E")
        end


    end

end

function Nautilus:Harass()
    local EnemyHeroes = OB:GetEnemyHeroes(1100, false)
    local targetList = {}

    for i = 1, #EnemyHeroes do
        local hero = EnemyHeroes[i]
        local heroName = hero.charName
        if LL.Harass.useon[heroName] and LL.Harass.useon[heroName]:Value() then
            targetList[#targetList + 1] = hero
        end
    end
    local target = TS:GetTarget(targetList)
    if target == nil then return end

    if IsValid(target) then

        if LL.Harass.UseQ:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) <= 1100 then
            local Pred = GetGamsteronPrediction(target, self.QData, myHero)
            if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                lineQ = LineSegment(Pred.CastPosition, Pred.CastPosition:Extended(myHero.pos, myHero.pos:DistanceTo(target.pos)))
                if MapPosition:intersectsWall(lineQ) then
                    return
                end
                NextTick = GetTickCount() + 250
                ORB:SetMovement(false)
                Control.CastSpell(HK_Q, Pred.CastPosition)
                print("cast Q")
            end
        end

    end

end


function Nautilus:Auto()
    if ORB.Modes[0] then --combo

        local IGdamage = 50 + 20 * myHero.levelData.lvl
        local target = TS:GetTarget(600)
        if target == nil then return end
        
        if LL.Auto.AutoIG:Value() then
            if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and myHero:GetSpellData(SUMMONER_1).currentCd == 0 then
                if IGdamage >= target.health then
                    NextTick = GetTickCount() + 250
                    Control.CastSpell(HK_SUMMONER_1, target.pos)
                    print("cast ig")

                end
            end
            

            if myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and myHero:GetSpellData(SUMMONER_2).currentCd == 0 then
                if IGdamage >= target.health then
                    NextTick = GetTickCount() + 250
                    Control.CastSpell(HK_SUMMONER_2, target.pos)
                    print("cast ig")

                end
            end
        end
    end
end


function OnLoad()
    _G[myHero.charName]()
end