local Version = 0.02
local ScriptName = "Vi"


    
require('GamsteronPrediction')

local GameHeroCount     = Game.HeroCount
local GameHero          = Game.Hero
local TableInsert       = _G.table.insert
local orbwalker         = _G.SDK.Orbwalker
local TargetSelector    = _G.SDK.TargetSelector
local LocalGameTimer = Game.Timer
local ControlKeyDown = Control.KeyDown
local ControlKeyUp = Control.KeyUp

local myHero = myHero

local lastQdown = 0
local lastQup = 0

local lastE = 0
local lastR = 0
local lastIG = 0
local lastMove = 0

local Enemys =   {}
local Allys  =   {}

local function GetDistanceSquared(vec1, vec2)
    local dx = vec1.x - vec2.x
    local dy = (vec1.z or vec1.y) - (vec2.z or vec2.y)
    return dx * dx + dy * dy
end


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


class "Vi"

function Vi:__init()
    
    self.QData = {Type = _G.SPELLTYPE_LINE, Delay = 0.1, Radius = 75, Range = 725, Speed = 1400, Collision = false}
    self.RData = {Range = 800}

    self.Qchannel = false
	self.Qtimer = LocalGameTimer()

    self:LoadMenu()

    OnAllyHeroLoad(function(hero)
        TableInsert(Allys, hero);
    end)

    OnEnemyHeroLoad(function(hero)
        TableInsert(Enemys, hero);
    end)

    Callback.Add("Tick", function() self:Tick() end)
    Callback.Add("Draw", function() self:Draw() end)
    Callback.Add('WndMsg', function(...) self:WndMsg(...) end)

    orbwalker:OnPostAttackTick(function(...) self:OnPostAttackTick(...) end)

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

function Vi:LoadMenu()
    self.tyMenu = MenuElement({type = MENU, id = "14Vi", name = "14Vi"})

    self.tyMenu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
    self.tyMenu.Combo:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
    OnEnemyHeroLoad(function(hero) self.tyMenu.Combo.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
    self.tyMenu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
    self.tyMenu.Combo:MenuElement({id = "Num", name = "min Q Range", value = 150, min = 0 , max = 400})
    self.tyMenu.Combo:MenuElement({id = "UseE", name = "[E]", value = true})

    self.tyMenu:MenuElement({type = MENU, id = "WaveClear", name = "Wave Clear"})
    self.tyMenu.WaveClear:MenuElement({id = "UseE", name = "[E]", value = true})


    self.tyMenu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
    self.tyMenu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
    self.tyMenu.Drawing:MenuElement({id = "R", name = "Draw [R] Range", value = true})
    self.tyMenu.Drawing:MenuElement({id = "Num", name = "Draw min Q Range", value = true})

end

function Vi:Draw()
    if myHero.dead then
        return
    end
    if self.tyMenu.Drawing.Q:Value() and Ready(_Q) then
        Draw.Circle(myHero.pos, 725,Draw.Color(255,255, 162, 000))
    end
    if self.tyMenu.Drawing.R:Value() and Ready(_R) then
        Draw.Circle(myHero.pos, 800,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end
    if self.tyMenu.Drawing.Num:Value() and Ready(_Q) then
        Draw.Circle(myHero.pos, self.tyMenu.Combo.Num:Value(),Draw.Color(255,255, 162, 000))
    end
end

function Vi:Tick()
    if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
        return
    end

    self:Qmanager()

    if orbwalker.Modes[0] then --combo
        self:Combo()
    elseif orbwalker.Modes[1] then --harass
        --self:Harass()
    end

end

function Vi:Combo()
    local targetList = {}
    local target

    for i = 1, #Enemys do
        local enemy = Enemys[i]
        local heroName = enemy.charName
        if self.tyMenu.Combo.useon[heroName] and self.tyMenu.Combo.useon[heroName]:Value() then
            targetList[#targetList + 1] = enemy
        end
    end

    target = self:GetTarget(targetList, self.QData.Range)
    
    if target and IsValid(target) then
        if self.tyMenu.Combo.UseQ:Value() and Ready(_Q) and  self.Qchannel == false 
            and myHero.pos:DistanceTo(target.pos) <= 625 and lastQdown + 150 < GetTickCount()
            and myHero.pos:DistanceTo(target.pos) > self.tyMenu.Combo.Num:Value() then
            ControlKeyDown(HK_Q)
            lastQdown = GetTickCount()
            self.Qchannel = true
            self.Qtimer = LocalGameTimer()
        end

        if LocalGameTimer() > self.Qtimer + 1.25 and LocalGameTimer() < self.Qtimer + 6 
            and self.Qchannel and Ready(_Q) and self.tyMenu.Combo.UseQ:Value() and  lastQup + 150 < GetTickCount() then
                local Pred = GetGamsteronPrediction(target, self.QData, myHero)
                if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                    Control.SetCursorPos(Pred.CastPosition)
                    ControlKeyUp(HK_Q)
                    lastQup = GetTickCount()
                    self.Qchannel = false
                end
        end

        
    end
end

local nextETime = 0

function Vi:OnPostAttackTick()
    if nextETime > LocalGameTimer() then return end

    local target = orbwalker:GetTarget()

    if target == nil then return end

    if target.type == Obj_AI_Hero then
        if self.tyMenu.Combo.UseE:Value() and Ready(_E) then
            Control.CastSpell(HK_E) 
            orbwalker:__OnAutoAttackReset()
            nextETime = LocalGameTimer() + 0.2
        end
    elseif target.team == 300 then
        if self.tyMenu.WaveClear.UseE:Value() and Ready(_E) then
            Control.CastSpell(HK_E)
            orbwalker:__OnAutoAttackReset()
            nextETime = LocalGameTimer() + 0.2
        end
    end
end


function Vi:Qmanager()
    for i=1, myHero.buffCount do
        local buff = myHero:GetBuff(i)
        if buff.name == "ViQ" and buff.duration >0 then
            self.Qchannel = true
            return
        end
    end
    self.Qchannel = false
end

function Vi:WndMsg(msg, wParam)
    if msg == 256 and wParam == 81 then
        if Ready(_Q) then
            self.Qchannel = true
            self.Qtimer = LocalGameTimer()
        end
    end
end

function Vi:GetTarget(list, range)
    local targetList = {}

    for i = 1, #list do
        local hero = list[i]
        if GetDistanceSquared(hero.pos, myHero.pos) < range * range then
            targetList[#targetList + 1] = hero
        end
    end

    return TargetSelector:GetTarget(targetList)
end

Vi()