  
require('GamsteronPrediction')
local GameHeroCount     = Game.HeroCount
local GameHero          = Game.Hero
local TableInsert       = _G.table.insert

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


class "Khazix"

function Khazix:__init()

    self.Q = {Range = 325}
    self.W = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 70, Range = 1000, Speed = 1650, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}}
    self.E = {Type = _G.SPELLTYPE_CIRCLE, Delay = 0, Radius = 120, Range = 700, Speed = 1000, Collision = false}

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






function Khazix:LoadMenu()
    self.tyMenu = MenuElement({type = MENU, id = "14Khazix", name = "Khazix"})
    
    --combo
    
    self.tyMenu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
    self.tyMenu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
    self.tyMenu.Combo:MenuElement({id = "UseW", name = "[W]", value = true})
    self.tyMenu.Combo:MenuElement({id = "range", name = "Max Cast W In range", value = 1000, min = 1, max = 1000, step = 1})
    self.tyMenu.Combo:MenuElement({id = "UseE", name = "[E]", value = true})
    
    --jungle
    self.tyMenu:MenuElement({type = MENU, id = "Jungle", name = "Jungle"})
    self.tyMenu.Jungle:MenuElement({id = "UseQ", name = "[Q]", value = true})
    self.tyMenu.Jungle:MenuElement({id = "UseW", name = "[W]", value = true})




    --Draw
    self.tyMenu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
    self.tyMenu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
    self.tyMenu.Drawing:MenuElement({id = "W", name = "Draw [W] Range", value = true})
    self.tyMenu.Drawing:MenuElement({id = "E", name = "Draw [E] Range", value = true})


end


function Khazix:Draw()
    if myHero.dead then
        return
    end


    if self.tyMenu.Drawing.Q:Value() and Ready(_Q) then
        Draw.Circle(myHero.pos, self.QData.Range,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end

    if self.tyMenu.Drawing.W:Value() and Ready(_W) then
        Draw.Circle(myHero.pos, self.WData.Range,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end

    if self.tyMenu.Drawing.E:Value() and Ready(_E) then
        Draw.Circle(myHero.pos, self.EData.Range,Draw.Color(80 ,0xFF,0xFF,0xFF))
    end
end



function Khazix:Tick()
    if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
        return
    end

    self:UpdateSpell()

    if orbwalker.Modes[0] then --combo
        self:Combo()
    elseif orbwalker.Modes[3] then --jungle
        self:Jungle()
    end

end

function Khazix:UpdateSpell()


    if myHero:GetSpellData(0).name == "KhazixQLong" then
        self.Q.Range = 375
    end

    if myHero:GetSpellData(1).name == "KhazixWLong" then
        self.W.Type = _G.SPELLTYPE_CONE
    end

    if myHero:GetSpellData(2).name == "KhazixELong" then
        self.E.Range = 900
    end
end

function Khazix:Combo()

    if self.tyMenu.Combo.UseQ:Value() then
        local target = self:GetHeroTarget(self.Q.Range)
        if target ~= nil then
            self:CastQ(target)
        end
    end

    if self.tyMenu.Combo.UseW:Value() then
        local target = self:GetHeroTarget(self.W.Range)
        if target ~= nil then
            self:CastW(target)
        end
    end

    if self.tyMenu.Combo.UseE:Value()  then
        local target = self:GetHeroTarget(self.E.Range)
        if target ~= nil then
            self:CastE()
        end
    end


end

function Khazix:Jungle()
    local target = orbwalker:GetTarget()
    if target ~= nil then
        if self.tyMenu.Jungle.UseQ:Value() and Ready(_Q) then
            self:CastQ(target)
            return
        end

        if self.tyMenu.Jungle.UseW:Value() and Ready(_W) and orbwalker:CanMove() then
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

    if myHero.pos:DistanceTo(target.pos) <= self.QData.Range and ORB:CanMove() then
        Control.CastSpell(HK_Q, target)
        NextTick = GetTickCount() + 350
        --print("cast Q")
    end
end


function Khazix:CastW(target)
    if not Ready(_W) then return end

    local Pred = GetGamsteronPrediction(target, self.WData, myHero)
    if Pred.Hitchance >= _G.HITCHANCE_HIGH then
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
    if Pred.Hitchance >= _G.HITCHANCE_HIGH then
        NextTick = GetTickCount() + 450
        ORB:SetMovement(false)
        ORB:SetAttack(false)
        Control.CastSpell(HK_E, Pred.CastPosition)
        --print("cast E")

    end


end



function OnLoad()
    _G[myHero.charName]()
end