local Version = 0.05
local ScriptName = "Thresh"

if (myHero.charName ~= "Thresh") then 
    return
end

do
    local Files = {
        Lua = {
            Path = SCRIPT_PATH,
            Name = "TThresh.lua",
            Url = "https://raw.githubusercontent.com/samuelchow1997/gos/master/TThresh.lua"
        },
        Version = {
            Path = SCRIPT_PATH,
            Name = "TThresh.version",
            Url = "https://raw.githubusercontent.com/samuelchow1997/gos/master/TThresh.version"
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
            print("New TThresh Version Press 2x F6")
        else
            print(Files.Version.Name .. ": No Updates Found")
        end
    
    end
    
    AutoUpdate()

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



class "Thresh"

function Thresh:__init()
    ORB, TS, OB, DMG, SPELLS = _G.SDK.Orbwalker, _G.SDK.TargetSelector, _G.SDK.ObjectManager, _G.SDK.Damage, _G.SDK.Spells
    self.LastReset = 0
    self.QData = {Type = _G.SPELLTYPE_LINE, Delay = 0.5, Radius = 70, Range = 1000, Speed = 1900, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}}
    --Q range 1100 cant hit
    self.EData = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 150, Range = 450, Speed = 1100, Collision = false}
    self:LoadMenu()
    Callback.Add("Tick", function() self:Tick() end)
    Callback.Add("Draw", function() self:Draw() end)
end

function Thresh:LoadMenu()
    TT = MenuElement({type = MENU, id = "bb", name = "TThresh"})

    TT:MenuElement({type = MENU, id = "Q", name = "[Q]"})
    TT.Q:MenuElement({name =" " , drop = {"Combo Settings"}})
    TT.Q:MenuElement({id = "Combo", name = "Use on Combo", value = true})
    TT.Q:MenuElement({name = "Combo list:", id = "ComboOn", type = _G.MENU})
    GamCore:OnEnemyHeroLoad(function(hero) TT.Q.ComboOn:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
    TT.Q:MenuElement({name =" " , drop = {"Harrass Settings"}})
    TT.Q:MenuElement({id = "Harass", name = "Use on Harass", value = true})
    TT.Q:MenuElement({name = "Harass list:", id = "HarassOn", type = _G.MENU})
    GamCore:OnEnemyHeroLoad(function(hero) TT.Q.HarassOn:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
    --TT.Q:MenuElement({name =" " , drop = {"Misc Settings"}})
    --TT.Q:MenuElement({id = "Auto", name = "Auto Use on Immobile", value = true})

    TT:MenuElement({type = MENU, id = "E", name = "[E]"})
    TT.E:MenuElement({name =" " , drop = {"Combo Settings"}})
    TT.E:MenuElement({id = "Combo", name = "Use on Combo", value = true})
    TT.E:MenuElement({name =" " , drop = {"Harrass Settings"}})
    TT.E:MenuElement({id = "Harass", name = "Use on Harass", value = true})
    TT.E:MenuElement({name =" " , drop = {"Misc Settings"}})
    TT.E:MenuElement({id = "Auto", name = "Disable autoAttack if E ready", value = true})
    TT.E:MenuElement({id = "AntiE", name = "Anti Dash", type = _G.MENU})
    GamCore:OnEnemyHeroLoad(function(hero) TT.E.AntiE:MenuElement({id = hero.charName, name = hero.charName, value = false}) end)
    TT.E:MenuElement({id = "Grass", name = "Anti Dash from Grass(beta)", value = false})

    TT.E:MenuElement({id = "AutoE", name = "Auto Pull E on ", type = _G.MENU})
    GamCore:OnEnemyHeroLoad(function(hero) TT.E.AutoE:MenuElement({id = hero.charName, name = hero.charName, value = false}) end)

    TT:MenuElement({type = MENU, id = "R", name = "[R]"})
    TT.R:MenuElement({name =" " , drop = {"Combo Settings"}})
    TT.R:MenuElement({id = "Combo", name = "Use on Combo", value = true})
    TT.R:MenuElement({id = "Count", name = "When X Enemies Around", value = 2, min = 1, max = 5, step = 1})
    TT.R:MenuElement({name = " ", drop = {"Misc"}})
    TT.R:MenuElement({id = "Auto", name = "Auto Use When X Enemies Around", value = 3, min = 1, max = 5, step = 1})


    TT:MenuElement({type = MENU, id = "Auto", name = "Ignite"})
    TT.Auto:MenuElement({id = "AutoIG", name = "Auto Ingite KS", value = true})

    TT:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
    TT.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
    TT.Drawing:MenuElement({id = "E", name = "Draw [E] Range", value = true})

end

function Thresh:Draw()
    if myHero.dead then
        return

    
    end
    if TT.Drawing.Q:Value() and Ready(_Q) then
        Draw.Circle(myHero.pos, 1100,Draw.Color(255,255, 162, 000))
    end
    if TT.Drawing.E:Value() and Ready(_E) then
        Draw.Circle(myHero.pos, 450,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end
    --[[
    local target = TS:GetTarget(1000)
    if target == nil then return end
    local flayTowards = self:GetPosE(target.pos)      
    Draw.Circle(flayTowards, 20,Draw.Color(80 ,0xFF,0xFF,0xFF))

    pos = target:GetPrediction(2265, 0.7)
    Draw.Circle(pos, 20,Draw.Color(80 ,0xFF,0xFF,0xFF))
    Draw.Circle(flayTowards, 20,Draw.Color(80 ,0xFF,0xFF,0xFF))
    --]]
    --self:AntiE()

end

local NextTick = GetTickCount()
function Thresh:Tick()
    if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
        return
    end
    self:AntiE()
    self:Auto()
    if NextTick > GetTickCount() then return end

    if Ready(_E) and TT.E.Auto:Value() then
        ORB:SetAttack(false)
    else
        ORB:SetAttack(true)
    end

    if ORB.Modes[0] then --combo
        self:Combo()
    elseif ORB.Modes[1] then --harass
        self:Harass()
    end

    self:AutoE()

end

function Thresh:Combo()
    local EnemyHeroes = OB:GetEnemyHeroes(1000, false)
    local targetList = {}

    for i = 1, #EnemyHeroes do
        local hero = EnemyHeroes[i]
        local heroName = hero.charName
        if TT.Q.ComboOn[heroName] and TT.Q.ComboOn[heroName]:Value() then
            targetList[#targetList + 1] = hero
        end
    end

    local target = TS:GetTarget(targetList)
    if target == nil then return end
    if IsValid(target) then
        if TT.Q.Combo:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) <= 1000 then
            local Pred = GetGamsteronPrediction(target, self.QData, myHero)
            if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                NextTick = GetTickCount() + 500
                Control.CastSpell(HK_Q, Pred.CastPosition)
            end
        end

        if TT.E.Combo:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= 450 then
            pre = self:GetPosE(target.pos)
            Control.CastSpell(HK_E, pre)
        end

    end

    local nearby = #OB:GetEnemyHeroes(450, false)

    if Ready(_R) and TT.R.Combo:Value() and nearby >= TT.R.Count:Value() then
        Control.CastSpell(HK_R, pre)
    end

end

function Thresh:Harass()
    local EnemyHeroes = OB:GetEnemyHeroes(1000, false)
    local targetList = {}

    for i = 1, #EnemyHeroes do
        local hero = EnemyHeroes[i]
        local heroName = hero.charName
        if TT.Q.HarassOn[heroName] and TT.Q.HarassOn[heroName]:Value() then
            targetList[#targetList + 1] = hero
        end
    end

    local target = TS:GetTarget(targetList)
    if target == nil then return end
    if IsValid(target) then
        if TT.Q.Harass:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) <= 1000 then
            local Pred = GetGamsteronPrediction(target, self.QData, myHero)
            if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                NextTick = GetTickCount() + 500
                Control.CastSpell(HK_Q, Pred.CastPosition)
            end
        end

        if TT.E.Combo:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= 450 then
            pre = self:GetPosE(target.pos)
            Control.CastSpell(HK_E, pre)
        end

    end
end

function Thresh:Auto()
    local nearby = #OB:GetEnemyHeroes(450, false)
    if Ready(_R) and nearby >= TT.R.Auto:Value() then
        Control.CastSpell(HK_R)
    end


    local IGdamage = 50 + 20 * myHero.levelData.lvl
    local target = TS:GetTarget(600)
    if target == nil then return end
    if TT.Auto.AutoIG:Value() then
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
end

function Thresh:AutoE()
    local EnemyHeroes = OB:GetEnemyHeroes(470, false)
    if next(EnemyHeroes) == nil then  return  end
    for i = 1, #EnemyHeroes do
        local target = EnemyHeroes[i]
        local heroName = target.charName
        if TT.E.AutoE[heroName] and TT.E.AutoE[heroName]:Value() then
            pre = self:GetPosE(target.pos)
            Control.CastSpell(HK_E, pre)
        end
    end

end

function Thresh:AntiE()
    local EnemyHeroes = OB:GetEnemyHeroes(620, false)
    if next(EnemyHeroes) == nil then  return  end
        for i = 1, #EnemyHeroes do
        local target = EnemyHeroes[i]
        local heroName = target.charName
        if TT.E.AntiE[heroName] and TT.E.AntiE[heroName]:Value() then
    
            if target.pathing.isDashing and target.pathing.dashSpeed>600 then
                if TT.E.Grass:Value() and  target.activeSpell.spellWasCast and target.activeSpell.startTime<Game.Timer() then       --is activeSpell from Grass
                    --print("start "..target.activeSpell.startTime)
                    --print("timer "..Game.Timer())
                    pos = target:GetPrediction(target.pathing.dashSpeed, 0.75)
                    pre = self:GetPosE(pos)
                    Control.CastSpell(HK_E, pre)
                else
                    pos = target:GetPrediction(target.pathing.dashSpeed, 0.35)
                    pre = self:GetPosE(pos)
                    Control.CastSpell(HK_E, pre)
                end
            end
        end
    end

end

function Thresh:GetPosE(pos, mode)
	local push = mode == "Push" and true or false
	--	
	return myHero.pos:Extended(pos, self.EData.Range * (push and 1 or -1))
end

function OnLoad()
    Thresh()
end