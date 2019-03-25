local Version = 0.04
local ScriptName = "LLeona"

if (myHero.charName ~= "Leona") then 
    return
end

do
    
    local Version = 0.07
    
    local Files = {
        Lua = {
            Path = SCRIPT_PATH,
            Name = "LLeona.lua",
            Url = "https://raw.githubusercontent.com/Pussykate/GoS/master/PussyAIO.lua"
        },
        Version = {
            Path = SCRIPT_PATH,
            Name = "PussyAIO.version",
            Url = "https://raw.githubusercontent.com/Pussykate/GoS/master/PussyAIO.version"
        }
    }
    
    local function AutoUpdate()
        
        local function DownloadFile(url, path, fileName)
            DownloadFileAsync(url, path .. fileName, function() end)
            while not FileExist(path .. fileName) do end
        end
        
        local function ReadFile(path, fileName)
            local file = io.open(path .. fileName, "r")
            local result = file:read()
            file:close()
            return result
        end
        
        DownloadFile(Files.Version.Url, Files.Version.Path, Files.Version.Name)
        local textPos = myHero.pos:To2D()
        local NewVersion = tonumber(ReadFile(Files.Version.Path, Files.Version.Name))
        if NewVersion > Version then
            DownloadFile(Files.Lua.Url, Files.Lua.Path, Files.Lua.Name)
            print("New PussyAIO Version Press 2x F6")
        else
            print(Files.Version.Name .. ": No Updates Found")
        end
    
    end
    
    --AutoUpdate()

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

local ESpells = {
    ["TristanaR"] = {charName = "Tristana", slot = _R, displayName = "[R]Buster Shot"},
    ["VayneCondemn"] = {charName = "Vayne", slot = _E, displayName = "[E]Condemn"},
    ["BlindMonkRKick"] = {charName = "LeeSin", slot = _R, displayName = "[R]Dragon's Rage"}
}
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

local function EnemiesNear(pos)
    local N = 0
    for i = 1,Game.HeroCount()  do
        local hero = Game.Hero(i)    
        if hero.valid and hero.isEnemy and hero.pos:DistanceTo(pos) < 260 then
            N = N + 1
        end
    end
    return N
end

class "Leona"

function Leona:__init()
    ORB, TS, OB, DMG, SPELLS = _G.SDK.Orbwalker, _G.SDK.TargetSelector, _G.SDK.ObjectManager, _G.SDK.Damage, _G.SDK.Spells
    self.LastReset = 0
    self.EData = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 80, Range = 875, Speed = 1200, Collision = false}
    self.RData = {Type = _G.SPELLTYPE_CIRCLE, Delay = 1, Radius = 250, Range = 1200, Speed = math.huge, Collision = false}
    self:LoadMenu()
    Callback.Add("Tick", function() self:Tick() end)
    Callback.Add("Draw", function() self:Draw() end)
end






function Leona:LoadMenu()
    LL = MenuElement({type = MENU, id = "ll", name = "LLeona"})
    
    --combo
    
    LL:MenuElement({type = MENU, id = "Combo", name = "Combo"})
    LL.Combo:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
    GamCore:OnEnemyHeroLoad(function(hero) LL.Combo.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
    LL.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
    LL.Combo:MenuElement({id = "UseW", name = "[W]", value = true})
    LL.Combo:MenuElement({id = "UseE", name = "[E]", value = true})
    LL.Combo:MenuElement({id = "DontE", name = "Dont QER to tower Range Target", value = true})
    LL.Combo:MenuElement({id = "DontEQR", name = "If Target HP > %", value = 20, min = 0, max = 100})
    LL.Combo:MenuElement({id = "UseR", name = "[R]", value = true})
    LL.Combo:MenuElement({id = "MinR", name = "[R] Min R target", value = 1, min = 1, max = 5}) --trying to fix this
    
    --Harass
    LL:MenuElement({type = MENU, id = "Harass", name = "Harass"})
    LL.Harass:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
    GamCore:OnEnemyHeroLoad(function(hero) LL.Harass.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
    LL.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
    LL.Harass:MenuElement({id = "UseW", name = "W", value = true})
    LL.Harass:MenuElement({id = "UseE", name = "E", value = true})
    LL.Harass:MenuElement({id = "DontE", name = "Dont QER to tower Range Target", value = true})

    --Auto
    LL:MenuElement({type = MENU, id = "Auto", name = "Auto"})
    LL.Auto:MenuElement({id = "AutoIG", name = "Auto Ingite KS", value = true})
    LL.Auto:MenuElement({id = "AotoEList", name = "Spell List", type = _G.MENU})
    GamCore:OnEnemyHeroLoad(function(hero) 
        for i, spell in pairs(ESpells) do
            if not ESpells[i] then return end
                if spell.charName == hero.charName and not LL.Auto.AotoEList[i] then
                    LL.Auto.AotoEList:MenuElement({id = hero.charName, name = ""..spell.charName.." ".." | "..spell.displayName, value = true})
                end
        end
    end)

    --Draw
    LL:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
    LL.Drawing:MenuElement({id = "E", name = "Draw [E] Range", value = true})
    LL.Drawing:MenuElement({id = "R", name = "Draw [R] Range", value = true})
    LL.Drawing:MenuElement({id = "Num", name = "Draw Prediction Max Range", value = 100, min = 70 , max = 100})

end

function Leona:Draw()
    if myHero.dead then
        return
    end

    if LL.Drawing.E:Value() and Ready(_E) then
        Draw.Circle(myHero.pos, 875*LL.Drawing.Num:Value()/100,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end
    if LL.Drawing.R:Value() and Ready(_R) then
        Draw.Circle(myHero.pos, 1200*LL.Drawing.Num:Value()/100,Draw.Color(255,255, 162, 000))
    end
end

function Leona:Tick()
    if myHero.dead or HasBuff(myHero,"recall") or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
        return
    end

    if ORB.Modes[0] then --combo
        self:Combo()
    elseif ORB.Modes[1] then --harass
        self:Harass()
    end
    self:Auto()

end

function Leona:Combo()
    local EnemyHeroes = OB:GetEnemyHeroes(1150, false)
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
        if LL.Combo.DontE:Value() and target.health/target.maxHealth > LL.Combo.DontEQR:Value()/100 then
            for i = 1, Game.TurretCount() do        
                local turret = Game.Turret(i)
                if turret.valid and turret.isEnemy and turret.pos:DistanceTo(target.pos) < 800 then
                    return
                end
            end
        end

        if LL.Combo.UseE:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= 875 then
            local Pred = GetGamsteronPrediction(target, self.EData, myHero)
            if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                Control.CastSpell(HK_E, Pred.CastPosition)
            end
        end

        if LL.Combo.UseW:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) <= 325 then
            Control.CastSpell(HK_W)
        end

        if LL.Combo.UseR:Value() and Ready(_R) and myHero.pos:DistanceTo(target.pos) <= 1150 then
            if myHero.pos:DistanceTo(target.pos) < 850*LL.Drawing.Num:Value()/100 and not Ready(_E) and not Ready(_Q) then
                local Pred = GetGamsteronPrediction(target, self.RData, myHero)
                if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                    if EnemiesNear(Pred.CastPosition) >= LL.Combo.MinR:Value() then
                        Control.CastSpell(HK_R, Pred.CastPosition)
                    end
                end
            end
            if myHero.pos:DistanceTo(target.pos) > 800*LL.Drawing.Num:Value()/100 and Ready(_E) and Ready(_Q) then
                local Pred = GetGamsteronPrediction(target, self.RData, myHero)
                if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                    if EnemiesNear(Pred.CastPosition) >= LL.Combo.MinR:Value() then
                        Control.CastSpell(HK_R, Pred.CastPosition)
                    end
                end
            end
        end


        if LL.Combo.UseQ:Value() 
        and Ready(_Q) 
        then
            self:CastQ()
        end


    end

end

function Leona:Harass()
    local EnemyHeroes = OB:GetEnemyHeroes(1150, false)
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

        if LL.Harass.DontE:Value() then
            for i = 1, Game.TurretCount() do        
                local turret = Game.Turret(i)
                if turret.valid and turret.isEnemy and turret.pos:DistanceTo(target.pos) < 800 then
                    --print(target.charName)
                    return
                end
            end
        end

        if LL.Harass.UseE:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= 875 then
            local Pred = GetGamsteronPrediction(target, self.EData, myHero)
            if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                Control.CastSpell(HK_E, Pred.CastPosition)
            end
        end


        if LL.Harass.UseW:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) <= 325 then
            Control.CastSpell(HK_W)
        end

        if LL.Harass.UseQ:Value() and Ready(_Q)  then
            self:CastQ()
        end


    end

end


function Leona:Auto()
    local IGdamage = 50 + 20 * myHero.levelData.lvl
    local target = TS:GetTarget(600)
    if target == nil then return end
    if LL.Auto.AutoIG:Value() then
        if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and myHero:GetSpellData(SUMMONER_1).currentCd == 0 then
            if IGdamage >= target.health then
                Control.CastSpell(HK_SUMMONER_1, target.pos)
            end
        end
        

        if myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and myHero:GetSpellData(SUMMONER_2).currentCd == 0 then
            if IGdamage >= target.health then
                Control.CastSpell(HK_SUMMONER_2, target.pos)
            end
        end
    end
    --if LL.Auto.AutoRR:Value() then

    local EnemyHeroes = OB:GetEnemyHeroes(875, false)
    for i = 1, #EnemyHeroes do
        local hero = EnemyHeroes[i]
        if hero.activeSpell.spellWasCast then
        --print(hero.activeSpell.name)
            if ESpells[hero.activeSpell.name] ~= nil then
                if LL.Auto.AotoEList[hero.charName]:Value() and hero.activeSpell.target == myHero.handle then
                    --print("targed")
                    Control.CastSpell(HK_E, hero.pos)
                end
            end
        end
        
    end

end

function Leona:CastQ()
    local EnemyHeroes = OB:GetEnemyHeroes(275, false)
    if EnemyHeroes ~= nil  and myHero.attackData.state == STATE_WINDDOWN then
        Control.CastSpell(HK_Q)
        ORB:__OnAutoAttackReset()
    end

    if myHero.pathing.isDashing then
        Control.CastSpell(HK_Q)
    end
end

function OnLoad()
    _G[myHero.charName]()
end