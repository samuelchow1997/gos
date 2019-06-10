local Version = 0.02
local ScriptName = "Vi"

if (myHero.charName ~= "Vi") then 
    return
end

if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
	print("GsoPred. installed Press 2x F6")
	DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronPrediction.lua", COMMON_PATH .. "GamsteronPrediction.lua", function() end)
	while not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") do end
end
    
require('GamsteronPrediction')
require('GamsteronCore')

local LocalGameTimer = Game.Timer
local ControlKeyDown = Control.KeyDown
local ControlKeyUp = Control.KeyUp

local  TS, OB, DMG, SPELLS
local myHero = myHero

local GamCore = _G.GamsteronCore

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

class "Vi"

function Vi:__init()
    ORB, TS, OB, DMG, SPELLS = _G.SDK.Orbwalker, _G.SDK.TargetSelector, _G.SDK.ObjectManager, _G.SDK.Damage, _G.SDK.Spells
    
    self.QData = {Type = _G.SPELLTYPE_LINE, Delay = 0.1, Radius = 75, Range = 725, Speed = 1400, Collision = false, UseBoundingRadius = true}
    self.RData = {Range = 800}

    self.Qchannel = false
	self.Qtimer = LocalGameTimer()

    self:LoadMenu()

    Callback.Add("Tick", function() self:Tick() end)
    Callback.Add("Draw", function() self:Draw() end)
    Callback.Add('WndMsg', function(...) self:WndMsg(...) end)

    ORB:OnPostAttackTick(function(...) self:OnPostAttackTick(...) end)

end

function Vi:LoadMenu()
    BB = MenuElement({type = MENU, id = "bb", name = "Vi"})

    BB:MenuElement({type = MENU, id = "Combo", name = "Combo"})
    BB.Combo:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
    GamCore:OnEnemyHeroLoad(function(hero) BB.Combo.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
    BB.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
    BB.Combo:MenuElement({id = "Num", name = "min Q Range", value = 150, min = 0 , max = 400})
    BB.Combo:MenuElement({id = "UseE", name = "[E]", value = true})

    BB:MenuElement({type = MENU, id = "WaveClear", name = "Wave Clear"})
    BB.WaveClear:MenuElement({id = "UseE", name = "[E]", value = true})


    BB:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
    BB.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
    BB.Drawing:MenuElement({id = "R", name = "Draw [R] Range", value = true})
    BB.Drawing:MenuElement({id = "Num", name = "Draw min Q Range", value = true})


    BB:MenuElement({name ="Author " , drop = {"ty01314"}})

end

function Vi:Draw()
    if myHero.dead then
        return
    end
    if BB.Drawing.Q:Value() and Ready(_Q) then
        Draw.Circle(myHero.pos, 725,Draw.Color(255,255, 162, 000))
    end
    if BB.Drawing.R:Value() and Ready(_R) then
        Draw.Circle(myHero.pos, 800,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end
    if BB.Drawing.Num:Value() and Ready(_Q) then
        Draw.Circle(myHero.pos, BB.Combo.Num:Value(),Draw.Color(255,255, 162, 000))
    end
end

function Vi:Tick()
    if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
        return
    end

    self:Qmanager()

    if ORB.Modes[0] then --combo
        self:Combo()
    elseif ORB.Modes[1] then --harass
        --self:Harass()
    end

end

function Vi:Combo()
    local EnemyHeroes = OB:GetEnemyHeroes(625, false)
    local targetList = {}

    for i = 1, #EnemyHeroes do
        local hero = EnemyHeroes[i]
        local heroName = hero.charName
        if BB.Combo.useon[heroName] and BB.Combo.useon[heroName]:Value() then
            targetList[#targetList + 1] = hero
        end
    end

    local target = TS:GetTarget(targetList)
    if target == nil then return end

    if IsValid(target) then
        if BB.Combo.UseQ:Value() and Ready(_Q) and  self.Qchannel == false 
            and myHero.pos:DistanceTo(target.pos) <= 625 
            and myHero.pos:DistanceTo(target.pos) > BB.Combo.Num:Value() then
            ControlKeyDown(HK_Q)
            self.Qchannel = true
            self.Qtimer = LocalGameTimer()
        end

        if LocalGameTimer() > self.Qtimer + 1.25 and LocalGameTimer() < self.Qtimer + 6 
            and self.Qchannel and Ready(_Q) and BB.Combo.UseQ:Value() then
                local Pred = GetGamsteronPrediction(target, self.QData, myHero)
                if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                    Control.SetCursorPos(Pred.CastPosition)
                    ControlKeyUp(HK_Q)
                    self.Qchannel = false
                end
        end

        
    end
end

local nextETime = 0

function Vi:OnPostAttackTick()
    if nextETime > LocalGameTimer() then return end

    local target = ORB:GetTarget()

    if target == nil then return end

    if target.type == Obj_AI_Hero then
        if BB.Combo.UseE:Value() and Ready(_E) then
            Control.CastSpell(HK_E) 
            ORB:__OnAutoAttackReset()
            nextETime = LocalGameTimer() + 0.2
        end
    elseif target.team == GamCore.TEAM_JUNGLE then
        if BB.WaveClear.UseE:Value() and Ready(_E) then
            Control.CastSpell(HK_E)
            ORB:__OnAutoAttackReset()
            nextETime = LocalGameTimer() + 0.2
        end
    end
end

function Vi:GetAttackTarget()

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

function OnLoad()
    _G[myHero.charName]()
end
