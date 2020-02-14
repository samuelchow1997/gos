local GameHeroCount     = Game.HeroCount
local GameHero          = Game.Hero
local TableInsert       = _G.table.insert

local GameMissileCount  = Game.MissileCount
local GameMissile       = Game.Missile

local orbwalker         = _G.SDK.Orbwalker
local TargetSelector    = _G.SDK.TargetSelector

local lastQ = 0
local lastW = 0
local lastE = 0
local lastR = 0

local lastMove = 0

local Enemys =   {}
local Allys  =   {}

require('GamsteronPrediction')

local shellSpells = {
    ["NautilusRavageStrikeAttack"]  = {charName = "Nautilus"    ,   slot = "Passive"} ,
    ["RekSaiWUnburrowLockout"]      = {charName = "RekSai"      ,   slot = "W"},
    ["SkarnerPassiveAttack"]        = {charName = "Skarner"     ,   slot = "E Passive"},
    ["WarwickRChannel"]             = {charName = "Warwick"     ,   slot = "R"},  -- need test
    ["XinZhaoQThrust3"]             = {charName = "XinZhao"     ,   slot = "Q3"},
    ["VolibearQAttack"]             = {charName = "Volibear"    ,   slot = "Q"},
    ["LeonaShieldOfDaybreakAttack"] = {charName = "Leona"       ,   slot = "Q"},
    ["GoldCardPreAttack"]           = {charName = "TwistedFate" ,   slot = "GoldW"},
    ["PowerFistAttack"]             = {charName = "Blitzcrank"  ,   slot = "E"},

    ["Frostbite"]               = {charName = "Anivia"      , slot = "E" , delay = 0.25, speed = 1600       , isMissile = true },
    ["AnnieQ"]                  = {charName = "Annie"       , slot = "Q" , delay = 0.25, speed = 1400       , isMissile = true },
    ["BrandE"]                  = {charName = "Brand"       , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["BrandR"]                  = {charName = "Brand"       , slot = "R" , delay = 0.25, speed = 1000       , isMissile = true },   -- to be comfirm brand R delay 0.25 or 0.5
    ["CassiopeiaE"]             = {charName = "Cassiopeia"  , slot = "E" , delay = 0.15, speed = 2500       , isMissile = true },   -- delay to be comfirm
    ["CamilleR"]                = {charName = "Camille"     , slot = "R" , delay = 0.5 , speed = math.huge  , isMissile = false},   -- delay to be comfirm
    ["Feast"]                   = {charName = "Chogath"     , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["DariusExecute"]           = {charName = "Darius"      , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},    -- delay to be comfirm
    ["EliseHumanQ"]             = {charName = "Elise"       , slot = "Q1", delay = 0.25, speed = 2200       , isMissile = true },
    ["EliseSpiderQCast"]        = {charName = "Elise"       , slot = "Q2", delay = 0.25, speed = math.huge  , isMissile = false},
    ["Terrify"]                 = {charName = "FiddleSticks", slot = "Q" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["FiddlesticksDarkWind"]    = {charName = "FiddleSticks", slot = "E" , delay = 0.25, speed = 1100       , isMissile = true },
    ["GangplankQProceed"]       = {charName = "Gangplank"   , slot = "Q" , delay = 0.25, speed = 2600       , isMissile = true },
    ["GarenQAttack"]            = {charName = "Garen"       , slot = "Q" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["GarenR"]                  = {charName = "Garen"       , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["SowTheWind"]              = {charName = "Janna"       , slot = "W" , delay = 0.25, speed = 1600       , isMissile = true },
    ["JarvanIVCataclysm"]       = {charName = "JarvanIV"    , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["JayceToTheSkies"]         = {charName = "Jayce"       , slot = "Q2", delay = 0.25, speed = math.huge  , isMissile = false}, -- seems speed base on distance, lazy to find the forumla , maybe fixed delay
    ["JayceThunderingBlow"]     = {charName = "Jayce"       , slot = "E2", delay = 0.25, speed = math.huge  , isMissile = false},
    ["KatarinaQ"]               = {charName = "Katarina"    , slot = "Q" , delay = 0.25, speed = 1600       , isMissile = true },
    ["KatarinaE"]               = {charName = "Katarina"    , slot = "E" , delay = 0.1 , speed = math.huge  , isMissile = false}, -- delay to be comfirm
    ["NullLance"]               = {charName = "Kassadin"    , slot = "Q" , delay = 0.25, speed = 1400       , isMissile = true },
    ["KhazixQ"]                 = {charName = "Khazix"      , slot = "Q1", delay = 0.25, speed = math.huge  , isMissile = false},
    ["KhazixQLong"]             = {charName = "Khazix"      , slot = "Q2", delay = 0.25, speed = math.huge  , isMissile = false},
    ["BlindMonkRKick"]          = {charName = "LeeSin"      , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["LeblancQ"]                = {charName = "Leblanc"     , slot = "Q" , delay = 0.25, speed = 2000       , isMissile = true },
    ["LeblancRQ"]               = {charName = "Leblanc"     , slot = "RQ", delay = 0.25, speed = 2000       , isMissile = true },
    ["LissandraREnemy"]         = {charName = "Lissandra"   , slot = "R" , delay = 0.5 , speed = math.huge  , isMissile = false},
    ["LucianQ"]                 = {charName = "Lucian"      , slot = "Q" , delay = 0.25, speed = math.huge  , isMissile = false}, --  delay = 0.4 − 0.25 (based on level)
    ["LuluWTwo"]                = {charName = "Lulu"        , slot = "W" , delay = 0.25, speed = 2250       , isMissile = true },
    ["SeismicShard"]            = {charName = "Malphite"    , slot = "Q" , delay = 0.25, speed = 1200       , isMissile = true },
    ["MalzaharE"]               = {charName = "Malzahar"    , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["MalzaharR"]               = {charName = "Malzahar"    , slot = "R" , delay = 0   , speed = math.huge  , isMissile = false},
    ["AlphaStrike"]             = {charName = "MasterYi"    , slot = "Q" , delay = 0   , speed = math.huge  , isMissile = false},
    ["MissFortuneRicochetShot"] = {charName = "MissFortune" , slot = "Q" , delay = 0.25, speed = 1400       , isMissile = true },
    ["NasusW"]                  = {charName = "Nasus"       , slot = "W" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["NautilusGrandLine"]       = {charName = "Nautilus"    , slot = "R" , delay = 0.5 , speed = 1400       , isMissile = true },  -- delay to be comfirm
    ["NunuQ"]                   = {charName = "Nunu"        , slot = "Q" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["OlafRecklessStrike"]      = {charName = "Olaf"        , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["PantheonQ"]               = {charName = "Pantheon"    , slot = "Q" , delay = 0.25, speed = 1500       , isMissile = true },
    ["RekSaiE"]                 = {charName = "RekSai"      , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["RekSaiR"]                 = {charName = "RekSai"      , slot = "R" , delay = 1.5 , speed = math.huge  , isMissile = false},
    ["PuncturingTaunt"]         = {charName = "Rammus"      , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["RenektonExecute"]         = {charName = "Renekton"    , slot = "W1", delay = 0.25, speed = math.huge  , isMissile = false},
    ["RenektonSuperExecute"]    = {charName = "Renekton"    , slot = "W2", delay = 0.25, speed = math.huge  , isMissile = false},
    ["RyzeW"]                   = {charName = "Ryze"        , slot = "W" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["RyzeE"]                   = {charName = "Ryze"        , slot = "E" , delay = 0.25, speed = 3500       , isMissile = true },
    ["Fling"]                   = {charName = "Singed"      , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["SyndraR"]                 = {charName = "Syndra"      , slot = "R" , delay = 0.25, speed = 1400       , isMissile = true },
    ["TwoShivPoison"]           = {charName = "Shaco"       , slot = "E" , delay = 0.25, speed = 1500       , isMissile = true },
    ["SkarnerImpale"]           = {charName = "Skarner"     , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["TahmKenchW"]              = {charName = "TahmKench"   , slot = "W" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["TalonQAttack"]            = {charName = "Talon"       , slot = "Q1", delay = 0.25, speed = math.huge  , isMissile = false},
    ["BlindingDart"]            = {charName = "Teemo"       , slot = "Q" , delay = 0.25, speed = 1500       , isMissile = true },
    ["TristanaR"]               = {charName = "Tristana"    , slot = "R" , delay = 0.25, speed = 2000       , isMissile = true },
    ["TrundlePain"]             = {charName = "Trundle"     , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["ViR"]                     = {charName = "Vi"          , slot = "R" , delay = 0.25, speed = 800        , isMissile = false},
    ["VayneCondemn"]            = {charName = "Vayne"       , slot = "E" , delay = 0.25, speed = 2200       , isMissile = true },
    ["VolibearW"]               = {charName = "Volibear"    , slot = "W" , delay = 0.25, speed = math.huge  , isMissile = true },
    ["VeigarR"]                 = {charName = "Veigar"      , slot = "R" , delay = 0.25, speed = 500        , isMissile = true },
    ["VladimirQ"]               = {charName = "Vladimir"    , slot = "Q" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["SylasR"]                  = {charName = "Sylas"       , slot = "R" , delay = 0.25, speed = 2200       , isMissile = true }

}

local function GetDistanceSquared(vec1, vec2)
    local dx = vec1.x - vec2.x
    local dy = (vec1.z or vec1.y) - (vec2.z or vec2.y)
    return dx * dx + dy * dy
end


local function IsValid(unit)
    return  unit 
            and unit.valid 
            and unit.isTargetable 
            and unit.alive 
            and unit.visible 
            and unit.networkID 
            and unit.health > 0
            and not unit.dead
end

local function Ready(spell)
    return myHero:GetSpellData(spell).currentCd == 0 
    and myHero:GetSpellData(spell).level > 0 
    and myHero:GetSpellData(spell).mana <= myHero.mana 
    and Game.CanUseSpell(spell) == 0
end

local function OnAllyHeroLoad(cb)
    for i = 1, GameHeroCount() do
        local obj = GameHero(i)
        if obj.isAlly then
            cb(obj)
        end
    end
end

local function OnEnemyHeroLoad(cb)
    for i = 1, GameHeroCount() do
        local obj = GameHero(i)
        if obj.isEnemy then
            cb(obj)
        end
    end
end

class "Morgana"

function Morgana:__init()
    print("Morgana init")

    self.Q = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 70, Range = 1175, Speed = 1200, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}}
    self.W = {Type = _G.SPELLTYPE_CIRCLE, Collision = false, Delay = 0.25, Radius = 150, Range = 900, Speed = math.huge}
    self.E = {Range = 800}
    self.R = {Range = 625}

    self:LoadMenu()

    OnAllyHeroLoad(function(hero)
        TableInsert(Allys, hero);
    end)

    OnEnemyHeroLoad(function(hero)
        TableInsert(Enemys, hero);
    end)

    Callback.Add("Tick", function() self:Tick() end)
    Callback.Add("Draw", function() self:Draw() end)


    orbwalker:OnPreMovement(
        function(args)
            if lastMove + 180 > GetTickCount() then
                args.Process = false
            else
                args.Process = true
                lastMove = GetTickCount()
            end
        end 
    )

end

function Morgana:LoadMenu()

    self.tyMenu = MenuElement({type = MENU, id = "14Morgana", name = "14Morgana"})

    self.tyMenu:MenuElement({type = MENU, id = "combo", name = "Combo"})
        self.tyMenu.combo:MenuElement({id = "Q", name = "Use Q Combo", value = true})
        self.tyMenu.combo:MenuElement({id = "R", name = "use R", value = true})
        self.tyMenu.combo:MenuElement({id = "minComboR", name = "Min R target", value = 2, min = 1, max = 5, step = 1})


    self.tyMenu:MenuElement({type = MENU, id = "harass", name = "Harass"})
        self.tyMenu.harass:MenuElement({id = "Q", name = "Use Q Harass", value = true})

    self.tyMenu:MenuElement({type = MENU, id = "auto", name = "Auto Cast"})
        self.tyMenu.auto:MenuElement({id = "Q", name = "Auto Q in Immobile Target", value = true})
        self.tyMenu.auto:MenuElement({id = "W", name = "Auto W in Immobile Target", value = true})
        self.tyMenu.auto:MenuElement({id = "R", name = "Auto R", value = true})
        self.tyMenu.auto:MenuElement({id = "minR", name = "Min auto R target", value = 2, min = 1, max = 5, step = 1})

    self.tyMenu:MenuElement({type = MENU, id = "eSetting", name = "E Setting"})
        self.tyMenu.eSetting:MenuElement({id = "eDelay", name = "Xs before Spell hit", value = 0.2, min = 0, max = 1.5, step = 0.01})
        self.tyMenu.eSetting:MenuElement({type = MENU, id = "blockSpell", name = "Auto E Block Spell"})
        OnEnemyHeroLoad(function(hero)
            for k, v in pairs(shellSpells) do
                if v.charName == hero.charName then
                    self.tyMenu.eSetting.blockSpell:MenuElement({id = k, name = v.charName.." | "..v.slot, value = true})
                end
            end
        end)
        self.tyMenu.eSetting:MenuElement({type = MENU, id = "dash", name = "Auto E If Enemy dash on Ally"})
        OnEnemyHeroLoad(function(hero)
            self.tyMenu.eSetting.dash:MenuElement({id = hero.charName, name = hero.charName, value = false})
        end)
        self.tyMenu.eSetting:MenuElement({type = MENU, id = "useon", name = "Use On"})
        OnAllyHeroLoad(function(hero)
            self.tyMenu.eSetting.useon:MenuElement({id = hero.charName, name = hero.charName, value = true})
        end)

    
    self.tyMenu:MenuElement({type = MENU, id = "misc", name = "Misc Setting"})
        self.tyMenu.misc:MenuElement({id = "maxRange", name = "Max Q Range", value = 1175, min = 0, max = 1175, step = 10})

    self.tyMenu:MenuElement({type = MENU, id = "draw", name = "Draw Setting"})
        self.tyMenu.draw:MenuElement({id = "Q", name = "Draw Q", value = true})
        self.tyMenu.draw:MenuElement({id = "W", name = "Draw W", value = false})
        self.tyMenu.draw:MenuElement({id = "E", name = "Draw E", value = true})
        self.tyMenu.draw:MenuElement({id = "R", name = "Draw R", value = false})

end

function Morgana:Draw()
    if myHero.dead then return  end

    if self.tyMenu.draw.Q:Value() and Ready(_Q) then
        Draw.Circle(myHero.pos, 1175,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end

    if self.tyMenu.draw.W:Value() and Ready(_W) then
        Draw.Circle(myHero.pos, 900,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end

    if self.tyMenu.draw.E:Value() and Ready(_E) then
        Draw.Circle(myHero.pos, 800,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end
    if self.tyMenu.draw.R:Value() and Ready(_R) then
        Draw.Circle(myHero.pos, 625,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end
end


function Morgana:Tick()
    if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
        return
    end

    if orbwalker.Modes[0] then --combo
        self:Combo()
    elseif orbwalker.Modes[1] then --harass
        self:Harass()
    end

    self:BlockSpell()
    self:Auto()

end

function Morgana:CastQ(target, hitc)
    if Ready(_Q) and lastQ +350 < GetTickCount() and orbwalker:CanMove() then
        local Pred = GetGamsteronPrediction(target, self.Q, myHero)
        if Pred.Hitchance >= hitc then
            Control.CastSpell(HK_Q, Pred.CastPosition)
            lastQ = GetTickCount()
            print("cast Q "..GetTickCount())
        end
    end
end

function Morgana:Combo()
    local target = TargetSelector:GetTarget(self.Q.Range, 0)
    if target and IsValid(target) and GetDistanceSquared(myHero.pos, target.pos) < self.tyMenu.misc.maxRange:Value()^2 then
        if self.tyMenu.combo.Q:Value() then
            self:CastQ(target,3)
        end
    end

    if self.tyMenu.combo.R:Value() and Ready(_R) and lastR+350 < GetTickCount() then
        if self:GetTargetAround(625) >= self.tyMenu.combo.minComboR:Value() then
            Control.CastSpell(HK_R)
            lastR = GetTickCount()
            print("cast R")
        end
    end
end

function Morgana:Harass()
    local target = TargetSelector:GetTarget(self.Q.Range, 0)
    if target and IsValid(target) and GetDistanceSquared(myHero.pos, target.pos) < self.tyMenu.misc.maxRange:Value()^2 then
        if self.tyMenu.harass.Q:Value() then
            self:CastQ(target,3)
        end
    end
end

function Morgana:Auto()
    for i = 1, #Enemys do
        local hero = Enemys[i]
        if IsValid(hero) then
            if self.tyMenu.auto.Q:Value() and Ready(_Q) and lastQ +350 < GetTickCount() then
                self:CastQ(hero,4)
            end

            if self.tyMenu.auto.W:Value() and Ready(_W) and lastW +350 < GetTickCount() then
                if self:IsCC(hero) and orbwalker:CanMove() then
                    local Pred = GetGamsteronPrediction(hero, self.W, myHero)
                    print(Pred.Hitchance)
                    if Pred.Hitchance >= 3 then
                        Control.CastSpell(HK_W, Pred.CastPosition)
                        lastW = GetTickCount()
                        print("cast W")
                    end            
                end
            end
        end
    end

    if self.tyMenu.auto.R:Value() and Ready(_R) and lastR+350 < GetTickCount() then
        if self:GetTargetAround(625) >= self.tyMenu.auto.minR:Value() then
            Control.CastSpell(HK_R)
            lastR = GetTickCount()
            print("cast R")
        end
    end
end

function Morgana:BlockSpell()
    if Ready(_E) and lastE +1050 < GetTickCount() then
        local enemys = self:GetEnemys(2000)
    for i = 1, #enemys do
        local hero = enemys[i]
            if hero.activeSpell.valid and shellSpells[hero.activeSpell.name] ~= nil then
                local allyHeros = self:GetAllys(800)
                for x = 1, #allyHeros do
                    local ally = allyHeros[i]

                    if hero.activeSpell.target == ally.handle and self.tyMenu.eSetting.useon[ally.charName]:Value()
                    and self.tyMenu.eSetting.blockSpell[hero.activeSpell.name]:Value() then
                        local dt = hero.pos:DistanceTo(ally.pos)
                        local spell = shellSpells[hero.activeSpell.name]
                        local hitTime = spell.delay + dt/spell.speed
            
                        DelayAction(function()
                                Control.CastSpell(HK_E, ally.pos)
                                print("cast E active")
                        end, (hitTime-self.tyMenu.eSetting.eDelay:Value()))
                        lastE = GetTickCount()
                        return
                    end
                end
            end

            if hero.pathing.isDashing and self.tyMenu.eSetting.dash[hero.charName]:Value() then
                local vct = Vector(hero.pathing.endPos.x,hero.pathing.endPos.y,hero.pathing.endPos.z)
                local allyHeros = self:GetAllys(800)
                for x = 1, #allyHeros do
                    local ally = allyHeros[i]

                    if vct:DistanceTo(ally.pos) < 172 and self.tyMenu.eSetting.useon[ally.charName]:Value() then
                        Control.CastSpell(HK_E)
                        lastE = GetTickCount()
                        print("cast E dash")
                        return
                    end
                end
            end
        end
    end
end

function Morgana:GetTargetAround(range)
    local counter = 0
    for i = 1, #Enemys do
        local hero = Enemys[i]
        if IsValid(hero) then
            local delayPos = hero:GetPrediction(hero.ms,0.25)
            if GetDistanceSquared(myHero.pos, delayPos) < range * range then
                counter = counter + 1
            end
        end
    end
    return counter
end

function Morgana:IsCC(hero)
    local buffs = {
        [5]     =   true,
        [11]    =   true,
        [21]    =   true,
        [22]    =   true,
        [8]     =   true,
        [31]    =   true
    }

    for k = 0, hero.buffCount do
        local buff = hero:GetBuff(k)
        if buff and buff.count > 0 then
            local buffType = buff.type
            if buffs[buffType] then
                return true
            end
        end
    end

    return false
end

function Morgana:GetAllys(range)
    local result = {}
    local mePos = myHero.pos

    for i = 1, #Allys do
        local hero = Allys[i]
        if IsValid(hero) and GetDistanceSquared(mePos, hero.pos) < range * range then
            TableInsert(result, hero)
        end
    end
    return result
end

function Morgana:GetEnemys(range)
    local result = {}
    local mePos = myHero.pos

    for i = 1, #Enemys do
        local hero = Enemys[i]
        if IsValid(hero) and GetDistanceSquared(mePos, hero.pos) < range * range then
            TableInsert(result, hero)
        end
    end
    return result
end

Morgana()