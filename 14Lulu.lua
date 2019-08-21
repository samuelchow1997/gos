local GameHeroCount     = Game.HeroCount
local GameHero          = Game.Hero

local GameMissileCount  = Game.MissileCount
local GameMissile       = Game.Missile

local orbwalker         = _G.SDK.Orbwalker
local TargetSelector    = _G.SDK.TargetSelector

local lastQ = 0
local lastW = 0
local lastE = 0
local lastR = 0
local lastIG = 0
local lastMove = 0

local Enemys =   {}
local Allys  =   {}

require('GamsteronPrediction')

local function IsValid(unit)
    if (unit 
        and unit.valid 
        and unit.isTargetable 
        and unit.alive 
        and unit.visible 
        and unit.networkID 
        and unit.health > 0
        and not unit.dead
    ) then
        return true;
    end
    return false;
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



class "Lulu"

function Lulu:__init()
    print("Lulu init")


    self.Q = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 60, Range = 880, Speed = 1400, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_YASUOWALL} }
    self.W = {Range = 650}
    self.E = {Range = 650}
    self.R = {Range = 900}

    self.channelingSpell = {
        ["Crowstorm"]           = {charName = "FiddleSticks", slot = "R"},
        ["DrainChannel"]        = {charName = "FiddleSticks", slot = "W"},
        ["CaitlynAceintheHole"] = {charName = "Caitlyn", slot = "R"},
        ["GalioW"]              = {charName = "Galio", slot = "W"},
        ["GalioR"]              = {charName = "Galio", slot = "R"},
        ["ReapTheWhirlwind"] = {charName = "Janna", slot = "R"},
        ["KaisaE"] = {charName = "Kaisa", slot = "E"},
        ["KarthusFallenOne"] = {charName = "Karthus", slot = "R"},
        ["KatarinaR"] = {charName = "Katarina", slot = "R"},
        ["MalzaharR"] = {charName = "Malzahar", slot = "R"},
        ["Meditate"] = {charName = "MasterYi", slot = "W"},
        ["MissFortuneBulletTime"] = {charName = "MissFortune", slot = "R"},
        ["NunuW"] = {charName = "Nunu", slot = "W"},
        ["NunuR"] = {charName = "Nunu", slot = "R"},
        ["PantheonE"] = {charName = "Pantheon", slot = "E"},
        ["PantheonR"] = {charName = "Pantheon", slot = "R"},
        ["ShenR"] = {charName = "Shen", slot = "R"},
        ["VarusQ"] = {charName = "Varus", slot = "Q"},
        ["VelkozR"] = {charName = "Velkoz", slot = "R"},
        ["ViQ"] = {charName = "Vi", slot = "Q"},
        ["VladimirE"] = {charName = "Vladimir", slot = "E"},
        ["WarwickRChannel"] = {charName = "Warwick", slot = "R"},
        ["XerathArcanopulseChargeUp"] = {charName = "Xerath", slot = "Q"},
        ["XerathLocusOfPower2"] = {charName = "Xerath", slot = "R"},
        ["JhinR"] = {charName = "Jhin", slot = "R"},
        ["PykeQ"] = {charName = "Pyke", slot = "Q"},
        ["SionQ"] = {charName = "Sion", slot = "Q"},
        ["ZacE"] = {charName = "Zac", slot = "E"},

        --dash winup > .25
        ["GalioE"] = {charName = "Galio", slot = "E"},
        ["UrgotE"] = {charName = "Urgot", slot = "E"}
    }

    self.channelingChamp = {
        ["Lucian"] = {slot = "R"},
        ["TwistedFate"] = {slot = "R"},
        ["Urgot"] = {slot = "W"},
        ["Neeko"] = {slot = "R"},
        ["Swain"] = {slot = "R"}

    }

    self.ChannelingBuffs =          
    {
        ["Lucian"] = function(unit)
            return self:HasBuff(unit, "LucianR")
        end,
        ["TwistedFate"] = function(unit)
            return self:HasBuff(unit, "Destiny")
        end,
        ["Urgot"] = function(unit)
            return self:HasBuff(unit, "UrgotSwap2")
        end,
        ["Neeko"] = function(unit)
            return self:HasBuff(unit, "NeekoR")
        end,
        ["Swain"] = function(unit)
            return self:HasBuff(unit, "SwainR")
        end
    }


    self:LoadMenu()

    OnAllyHeroLoad(function(hero)
        Allys[hero.networkID] = hero
    end)

    OnEnemyHeroLoad(function(hero)
        Enemys[hero.networkID] = hero
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

function Lulu:LoadMenu()
    self.tyMenu = MenuElement({type = MENU, id = "14lulu", name = "14LuLu"})


    self.tyMenu:MenuElement({type = MENU, id = "combo", name = "Combo"})

        self.tyMenu.combo:MenuElement({id = "Q", name = "Use Q Combo", value = true})

        self.tyMenu.combo:MenuElement({id = "hitc", name = "Hit Chance {2=NORMAL 3=HIGH}", value = 2, min = 2, max = 3, step = 1})



    self.tyMenu:MenuElement({type = MENU, id = "harass", name = "Harass"})

        self.tyMenu.harass:MenuElement({id = "Q", name = "Use Q Harass", value = true})

        self.tyMenu.harass:MenuElement({id = "hitc", name = "Hit Chance {2=NORMAL 3=HIGH}", value = 3, min = 2, max = 3, step = 1})


    self.tyMenu:MenuElement({type = MENU, id = "autoW", name = "Auto W Setting"})

        self.tyMenu.autoW:MenuElement({type = MENU, id = "antiDash", name = "Anti Dash On"})
            OnEnemyHeroLoad(function(hero)
                self.tyMenu.autoW.antiDash:MenuElement({id = hero.charName, name = hero.charName, value = true})
            end)

        self.tyMenu.autoW:MenuElement({type = MENU, id = "interrupt", name = "Interrupt On"})
            OnEnemyHeroLoad(function(hero)
                for k, v in pairs(self.channelingSpell) do
                    if v.charName == hero.charName then
                        self.tyMenu.autoW.interrupt:MenuElement({id = k, name = v.charName.." | "..v.slot , value = true})
                    end
                end

                if self.channelingChamp[hero.charName] then
                    self.tyMenu.autoW.interrupt:MenuElement({id = hero.charName, name = hero.charName.." | "..self.channelingChamp[hero.charName].slot , value = true})
                end
            end)


    self.tyMenu:MenuElement({type = MENU, id = "autoE", name = "Auto E Setting"})

        self.tyMenu.autoE:MenuElement({id = "Ehp", name = "If Ally HP < X%", value = 20, min = 1, max = 100, step = 1})

        self.tyMenu.autoE:MenuElement({type = MENU, id = "Eon", name = "Use E On"})

        OnAllyHeroLoad(function(hero)
            self.tyMenu.autoE.Eon:MenuElement({id = hero.charName, name = hero.charName, value = true})
        end)


    self.tyMenu:MenuElement({type = MENU, id = "autoR", name = "Auto R Setting"})

        self.tyMenu.autoR:MenuElement({id = "Rhp", name = "If Ally HP < X%", value = 20, min = 1, max = 100, step = 1})

        self.tyMenu.autoR:MenuElement({id = "Rcount", name = "If Can Knock Up X", value = 3, min = 1, max = 5, step = 1})

        self.tyMenu.autoR:MenuElement({type = MENU, id = "Ron", name = "Use R On"})

        OnAllyHeroLoad(function(hero)
            self.tyMenu.autoR.Ron:MenuElement({id = hero.charName, name = hero.charName, value = true})
        end)
end



function Lulu:Draw()

end

function Lulu:Tick()
    if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
        return
    end

    if orbwalker.Modes[0] then 
        self:Combo()
        self:IG()
    elseif orbwalker.Modes[1] then 
        self:Harass()
    end

    self:AntiDash()
    self:Interrupt()
    self:AutoE()
    self:AutoR()
end

function Lulu:Combo() 
    local target = TargetSelector:GetTarget(self.Q.Range, 1)
    if target and IsValid(target) then
        if self.tyMenu.combo.Q:Value() then
            self:CastQ(target, self.tyMenu.combo.hitc:Value())
        end
    end
end

function Lulu:Harass() 
    local target = TargetSelector:GetTarget(self.Q.Range, 1)
    if target and IsValid(target) then
        if self.tyMenu.harass.Q:Value() then
            self:CastQ(target, self.tyMenu.harass.hitc:Value())
        end
    end
end

function Lulu:CastQ(target, hitchance)
    if Ready(_Q) and lastQ +350 < GetTickCount() and orbwalker:CanMove() then
        local Pred = GetGamsteronPrediction(target, self.Q, myHero)
        if Pred.Hitchance >= hitchance then
            Control.CastSpell(HK_Q, Pred.CastPosition)
            lastQ = GetTickCount()
        end
    end
end

function Lulu:AntiDash()
    if not Ready(_W) or lastW +250 > GetTickCount() or lastR + 800 > GetTickCount() then return end

    for i = 1, GameHeroCount() do
        local hero = GameHero(i)
        if hero.isEnemy and IsValid(hero) and myHero.pos:DistanceTo(hero.pos) < self.W.Range then
            if  self.tyMenu.autoW.antiDash[hero.charName] and self.tyMenu.autoW.antiDash[hero.charName]:Value() then
                if hero.pathing.isDashing and hero.pathing.dashSpeed>0 then
                    print('dash')
                    Control.CastSpell(HK_W, hero.pos)
                    lastW = GetTickCount()
                    return
                end
            end
        end
    end
end

function Lulu:Interrupt()
    if not Ready(_W) or lastW +250 > GetTickCount()  then return end
    for enemyk , enemy in pairs(Enemys) do 
        if enemy.activeSpell.valid  and self.tyMenu.autoW.interrupt[enemy.activeSpell.name] and self.tyMenu.autoW.interrupt[enemy.activeSpell.name]:Value() then
            Control.CastSpell(HK_W, enemy.pos)
            lastW = GetTickCount()
            return
        end

        if self.tyMenu.autoW.interrupt[enemy.charName] and self.tyMenu.autoW.interrupt[enemy.charName]:Value() and self.ChannelingBuffs[enemy.charName] then
            Control.CastSpell(HK_W, enemy.pos)
            lastW = GetTickCount()
            return
        end
    end
end

function Lulu:AutoE()
    if not Ready(_E) or lastE + 150 > GetTickCount() then return end

    for allyK, ally in pairs(Allys) do
        if self.tyMenu.autoE.Eon[ally.charName] and self.tyMenu.autoE.Eon[ally.charName]:Value() then
            if ally.health / ally.maxHealth * 100 < self.tyMenu.autoE.Ehp:Value() then
                if IsValid(ally) and myHero.pos:DistanceTo(ally.pos) < self.E.Range then
                    Control.CastSpell(HK_E, ally.pos)
                    print("cast E "..ally.charName)
                    lastE = GetTickCount()
                    return
                end
            end
        end
    end

end

function Lulu:AutoR()
    if not Ready(_R) or lastR + 150 > GetTickCount() then return end

    for allyK, ally in pairs(Allys) do
        if self.tyMenu.autoR.Ron[ally.charName] and self.tyMenu.autoR.Ron[ally.charName]:Value() then
            if IsValid(ally) and myHero.pos:DistanceTo(ally.pos) < self.R.Range then
                if ally.health / ally.maxHealth * 100 < self.tyMenu.autoR.Rhp:Value() then
                    Control.CastSpell(HK_R, ally.pos)
                    print("cast R "..ally.charName)
                    lastR = GetTickCount()
                    return
                end
            end

            local count = 0
            for enemyk , enemy in pairs(Enemys) do 
                if IsValid(enemy) and enemy.pos:DistanceTo(ally.pos) < 400 then
                    count = count + 1 
                    if count >= self.tyMenu.autoR.Rcount:Value() then
                        Control.CastSpell(HK_R, ally.pos)
                        print("cast R "..ally.charName)
                        lastR = GetTickCount()
                        return
                    end
                end
            end
        end  
    end



end

function Lulu:IG()
    if myHero:GetSpellData(SUMMONER_1).name ~= "SummonerDot" and myHero:GetSpellData(SUMMONER_2).name ~= "SummonerDot" then return end
    if lastIG + 150 > GetTickCount() then return end
    local IGdamage = 50 + 20 * myHero.levelData.lvl
    for enemyk , enemy in pairs(Enemys) do 
        if IsValid(enemy) and enemy.pos:DistanceTo(myHero.pos) < 600 then
            if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and myHero:GetSpellData(SUMMONER_1).currentCd == 0 then
                if IGdamage >= enemy.health then
                    Control.CastSpell(HK_SUMMONER_1, enemy.pos)
                    lastIG = GetTickCount()
                    return
                end
            end
            

            
            if myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and myHero:GetSpellData(SUMMONER_2).currentCd == 0 then
                if IGdamage >= enemy.health then
                    Control.CastSpell(HK_SUMMONER_2, enemy.pos)
                    lastIG = GetTickCount()
                    return
                end
            end
        end
    end
end

function Lulu:HasBuff(unit, name)
    name = name:lower()
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and buff.count > 0 and buff.name:lower() == name then
            return true
        end
    end
    return false
end

Lulu()
