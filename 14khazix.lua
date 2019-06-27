
if (myHero.charName ~= "Khazix") then 
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

local targetList = {}

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

class "Khazix"

function Khazix:__init()
    ORB, TS, OB, DMG, SPELLS = _G.SDK.Orbwalker, _G.SDK.TargetSelector, _G.SDK.ObjectManager, _G.SDK.Damage, _G.SDK.Spells

    self.QData = {Range = 325}
    self.WData = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 70, Range = 1000, Speed = 1650, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}}
    self.EData = {Type = _G.SPELLTYPE_CIRCLE, Delay = 0, Radius = 270, Range = 700, Speed = 1000, Collision = false}

    self:LoadMenu()
    Callback.Add("Tick", function() self:Tick() end)
    Callback.Add("Draw", function() self:Draw() end)
end






function Khazix:LoadMenu()
    LL = MenuElement({type = MENU, id = "ll", name = "Khazix"})
    
    --combo
    
    LL:MenuElement({type = MENU, id = "Combo", name = "Combo"})
    LL.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
    LL.Combo:MenuElement({id = "UseW", name = "[W]", value = true})
    LL.Combo:MenuElement({id = "UseE", name = "[E]", value = true})
    
    --jungle
    LL:MenuElement({type = MENU, id = "Jungle", name = "Jungle"})
    LL.Jungle:MenuElement({id = "UseQ", name = "[Q]", value = true})
    LL.Jungle:MenuElement({id = "UseW", name = "[W]", value = true})




    --Draw
    LL:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
    LL.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
    LL.Drawing:MenuElement({id = "W", name = "Draw [W] Range", value = true})
    LL.Drawing:MenuElement({id = "E", name = "Draw [E] Range", value = true})


end
local lastCursor = nil

function Khazix:Draw()
    if myHero.dead then
        return
    end
    
    --Draw.Circle(Game.mousePos(), 300,Draw.Color(80 ,0xFF,0xFF,0xFF))

    if LL.Drawing.Q:Value() and Ready(_Q) then
        Draw.Circle(myHero.pos, self.QData.Range,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end

    if LL.Drawing.W:Value() and Ready(_W) then
        Draw.Circle(myHero.pos, self.WData.Range,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end

    if LL.Drawing.E:Value() and Ready(_E) then
        Draw.Circle(myHero.pos, self.EData.Range,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end
end


local NextTick = GetTickCount()

function Khazix:Tick()
    if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
        return
    end

    self:UpdateSpell()
    if NextTick > GetTickCount() then return end

    ORB:SetMovement(true)
    ORB:SetAttack(true)

    if ORB.Modes[0] then --combo
        self:Combo()
    elseif ORB.Modes[3] then --jungle
        self:Jungle()
    end

end

function Khazix:UpdateSpell()


    if myHero:GetSpellData(0).name == "KhazixQLong" then
        self.QData.Range = 375
    end

    if myHero:GetSpellData(1).name == "KhazixWLong" then
        self.WData.Type = _G.SPELLTYPE_CONE
    end

    if myHero:GetSpellData(2).name == "KhazixELong" then
        self.EData.Range = 900
    end
end

function Khazix:Combo()

    if LL.Combo.UseQ:Value() then
        local target = self:GetHeroTarget(self.QData.Range)
        if target ~= nil then
            self:CastQ(target)
        end
    end

    if LL.Combo.UseW:Value() then
        local target = self:GetHeroTarget(self.WData.Range)
        if target ~= nil then
            self:CastW(target)
        end
    end

    if LL.Combo.UseE:Value()  then
        local target = self:GetHeroTarget(self.EData.Range)
        if target ~= nil then
            self:CastE(target)
        end
    end


end

function Khazix:Jungle()
    local target = ORB:GetTarget()
    if target ~= nil then
        if LL.Jungle.UseQ:Value() and Ready(_Q) then
            self:CastQ(target)
            return
        end

        if LL.Jungle.UseW:Value() and Ready(_W) and ORB:CanMove(myHero) then
            Control.CastSpell(HK_W, target)
        end
    end
end


function Khazix:GetHeroTarget(range)
    local EnemyHeroes = OB:GetEnemyHeroes(range, false)
    local target = TS:GetTarget(EnemyHeroes)

    return target
end

function Khazix:CastQ(target)
    if not Ready(_Q) then return end

    if myHero.pos:DistanceTo(target.pos) <= self.QData.Range and ORB:CanMove(myHero) then
        Control.CastSpell(HK_Q, target)
        NextTick = GetTickCount() + 350
        --print("cast Q")
    end
end


function Khazix:CastW(target)
    if not Ready(_W) then return end

    local Pred = GetGamsteronPrediction(target, self.WData, myHero)
    if Pred.Hitchance >= _G.HITCHANCE_NORMAL then
        NextTick = GetTickCount() + 350
        ORB:SetMovement(false)
        ORB:SetAttack(false)
        lastCursor = Game.mousePos()
        Control.SetCursorPos(Pred.CastPosition)

        DelayAction(function() 
            Control.CastSpell(HK_W, Pred.CastPosition)
            --print("cast W "..GetTickCount())

            DelayAction(function()
                Control.SetCursorPos(lastCursor)
                --print(GetTickCount())
            end, 0.1)

        end, 0.01)


    end


end

function Khazix:CastE(target)
    if not Ready(_E) then return end
    local Pred = GetGamsteronPrediction(target, self.EData, myHero)
    print(Pred.Hitchance)
    if Pred.Hitchance >= _G.HITCHANCE_HIGH then
        NextTick = GetTickCount() + 450
        ORB:SetMovement(false)
        ORB:SetAttack(false)
        Control.CastSpell(HK_E, Pred.CastPosition)
        print("cast E")

    end


end



function OnLoad()
    _G[myHero.charName]()
end