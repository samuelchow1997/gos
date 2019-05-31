
if (myHero.charName ~= "Amumu") then 
    return
end



if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
	print("GsoPred. installed Press 2x F6")
	DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronPrediction.lua", COMMON_PATH .. "GamsteronPrediction.lua", function() end)
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

class "Amumu"

function Amumu:__init()
    ORB, TS, OB, DMG, SPELLS = _G.SDK.Orbwalker, _G.SDK.TargetSelector, _G.SDK.ObjectManager, _G.SDK.Damage, _G.SDK.Spells
    self.QData = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 80, Range = 1100, Speed = 2000, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}}
    self:LoadMenu()
    Callback.Add("Tick", function() self:Tick() end)
    Callback.Add("Draw", function() self:Draw() end)
end






function Amumu:LoadMenu()
    LL = MenuElement({type = MENU, id = "ll", name = "14 Amumu"})
    
    --combo
    
    LL:MenuElement({type = MENU, id = "Combo", name = "Combo"})
    LL.Combo:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
    GamCore:OnEnemyHeroLoad(function(hero) LL.Combo.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
    LL.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
    LL.Combo:MenuElement({id = "UseE", name = "[E]", value = true})
    LL.Combo:MenuElement({id = "UseR", name = "[R]", value = true})
    LL.Combo:MenuElement({id = "Count", name = "When Can Hit X Enemies ", value = 2, min = 1, max = 5, step = 1})

    --Harass
    LL:MenuElement({type = MENU, id = "Harass", name = "Harass"})
    LL.Harass:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
    GamCore:OnEnemyHeroLoad(function(hero) LL.Harass.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
    LL.Harass:MenuElement({id = "UseQ", name = "Q", value = true})

    --wave clean
    LL:MenuElement({type = MENU, id = "WaveClean", name = "Wave Clean (span E No checking for minion)"})
    LL.WaveClean:MenuElement({id = "UseE", name = "E", value = true})


    --Auto
    LL:MenuElement({type = MENU, id = "Auto", name = "Auto"})
    LL.Auto:MenuElement({id = "UseR", name = "[R]", value = true})
    LL.Auto:MenuElement({id = "Count", name = "When Can Hit X Enemies ", value = 3, min = 1, max = 5, step = 1})


    --Draw
    LL:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
    LL.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
    
    LL.Drawing:MenuElement({type = MENU, id = "QColor", name = "Q Range Color"})
    LL.Drawing.QColor:MenuElement({id = "T", name = "Transparency ", value = 255, min = 0, max = 255, step = 1})
    LL.Drawing.QColor:MenuElement({id = "R", name = "Red ", value = 150, min = 0, max = 255, step = 1})
    LL.Drawing.QColor:MenuElement({id = "G", name = "Grean ", value = 150, min = 0, max = 255, step = 1})
    LL.Drawing.QColor:MenuElement({id = "B", name = "Blue ", value = 150, min = 0, max = 255, step = 1})


    LL.Drawing:MenuElement({id = "E", name = "Draw [E] Range", value = true})

    LL.Drawing:MenuElement({type = MENU, id = "EColor", name = "E Range Color"})
    LL.Drawing.EColor:MenuElement({id = "T", name = "Transparency ", value = 255, min = 0, max = 255, step = 1})
    LL.Drawing.EColor:MenuElement({id = "R", name = "Red ", value = 150, min = 0, max = 255, step = 1})
    LL.Drawing.EColor:MenuElement({id = "G", name = "Grean ", value = 150, min = 0, max = 255, step = 1})
    LL.Drawing.EColor:MenuElement({id = "B", name = "Blue ", value = 150, min = 0, max = 255, step = 1})


    LL.Drawing:MenuElement({id = "R", name = "Draw [R] Range", value = true})

    LL.Drawing:MenuElement({type = MENU, id = "RColor", name = "R Range Color"})
    LL.Drawing.RColor:MenuElement({id = "T", name = "Transparency ", value = 255, min = 0, max = 255, step = 1})
    LL.Drawing.RColor:MenuElement({id = "R", name = "Red ", value = 150, min = 0, max = 255, step = 1})
    LL.Drawing.RColor:MenuElement({id = "G", name = "Grean ", value = 150, min = 0, max = 255, step = 1})
    LL.Drawing.RColor:MenuElement({id = "B", name = "Blue ", value = 150, min = 0, max = 255, step = 1})


end

function Amumu:Draw()
    if myHero.dead then
        return
    end


    if LL.Drawing.Q:Value() and Ready(_Q) then
        Draw.Circle(myHero.pos, 1100,Draw.Color(LL.Drawing.QColor.T:Value() ,LL.Drawing.QColor.R:Value(),LL.Drawing.QColor.G:Value(),LL.Drawing.QColor.B:Value()))
    end

    if LL.Drawing.E:Value() and Ready(_E) then
        Draw.Circle(myHero.pos, 350,Draw.Color(LL.Drawing.EColor.T:Value() ,LL.Drawing.EColor.R:Value(),LL.Drawing.EColor.G:Value(),LL.Drawing.EColor.B:Value()))
    end
    if LL.Drawing.R:Value() and Ready(_R) then
        Draw.Circle(myHero.pos, 550,Draw.Color(LL.Drawing.RColor.T:Value() ,LL.Drawing.RColor.R:Value(),LL.Drawing.RColor.G:Value(),LL.Drawing.RColor.B:Value()))
    end
end


local NextTick = GetTickCount()
function Amumu:Tick()
    if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
        return
    end

    self:AutoR()
    if NextTick > GetTickCount() then return end
    ORB:SetMovement(true)
    if ORB.Modes[0] then --combo
        self:Combo()
    elseif ORB.Modes[1] then --harass
        self:Harass()
    elseif ORB.Modes[2] then --harass
        self:WaveClean()
    end

end

function Amumu:Combo()
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
                NextTick = GetTickCount() + 250
                ORB:SetMovement(false)
                Control.CastSpell(HK_Q, Pred.CastPosition)
            end
        end


        if LL.Combo.UseE:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= 350 then
            local delayPos = target:GetPrediction(target.ms,0.25)
            if delayPos:DistanceTo(myHero.pos) <= 350 then
                Control.CastSpell(HK_E)
            end
        end

        if LL.Combo.UseR:Value() and Ready(_R)  then
            self:CastR(LL.Combo.Count:Value())
        end
    end

end

function Amumu:Harass()
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
                NextTick = GetTickCount() + 250
                ORB:SetMovement(false)
                Control.CastSpell(HK_Q, Pred.CastPosition)
            end
        end

    end

end

function Amumu:WaveClean()
    if LL.WaveClean.UseE:Value() and Ready(_E) then 
        Control.CastSpell(HK_E)
    end
end

function Amumu:CastR(number)
    local count = 0

    local EnemyHeroes = OB:GetEnemyHeroes()
    for i = 1, #EnemyHeroes do
        local hero = EnemyHeroes[i]
        local delayPos = hero:GetPrediction(hero.ms,0.25)
        if delayPos:DistanceTo(myHero.pos) <= 550 then
            count = count + 1
        end
    end

    if count >= number then
        Control.CastSpell(HK_R)
    end

end

function Amumu:AutoR()
    if LL.Auto.UseR:Value() and Ready(_R)  then
        self:CastR(LL.Auto.Count:Value())
    end
end

function OnLoad()
    _G[myHero.charName]()
end