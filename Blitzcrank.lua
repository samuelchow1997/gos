if myHero.charName ~= "Blitzcrank" then return end

local _Blitzcrank = 0.01

local Blitzcrank = {}

function GetDistance(p1, p2)
	local dx, dz = p1.x - p2.x, p1.z - p2.z 
	return math.sqrt(dx * dx + dz * dz)
end

function GetTargetInRange(range)
    local counter = 0
    for k, v in pairs(ObjectManager:GetEnemyHeroes()) do
        if v.isValid and not v.isDead and not v.isInvulnerable then
        --local pos = _G.Prediction.GetUnitPosition(v, 0.25)
            if GetDistance(v, myHero) <= range then
                counter = counter + 1
            end
        end
    end
    return counter
end

function Blitzcrank:__init()
    PrintChat("BBlitzcrank Load!")
    self.Qdata = {delay = 0.25, speed = 1800, range = 925, width = 140}
    self.R = {range = 600}



    self.BlitMenu = Menu("Blitzcrank", "BBlitzcrank")
        self.BlitMenu:sub('combo', 'Combo')
            self.BlitMenu.combo:slider('hitchance', 'Q hitchance', 0,1,0.74,0.01)
            self.BlitMenu.combo:checkbox('useQ', 'use Q', true)
            self.BlitMenu.combo:slider('minRange', 'Min Q Range', 0,925,250,10)
            self.BlitMenu.combo:slider('maxRange', 'Max Q Range', 0,925,925,10)
            self.BlitMenu.combo:checkbox('useE', 'use E', true)
            self.BlitMenu.combo:checkbox('useR', 'use R', true)
            self.BlitMenu.combo:slider('minComboR', 'Min R target', 1,5,1,1)
        self.BlitMenu:sub('harass', 'Harass')
            self.BlitMenu.harass:slider('hitchance', 'Q hitchance', 0,1,0.75,0.01)
            self.BlitMenu.harass:checkbox('useQ', 'use Q', true)
            self.BlitMenu.harass:slider('minRange', 'Min Q Range', 0,925,250,10)
            self.BlitMenu.harass:slider('maxRange', 'Max Q Range', 0,925,925,10)
            self.BlitMenu.harass:checkbox('useE', 'use E', true)
        self.BlitMenu:sub('auto', 'Auto')
            self.BlitMenu.auto:checkbox('useR', 'use R', false)
            self.BlitMenu.auto:slider('minAutoR', 'Min R target', 1,5,3,1)
            self.BlitMenu.auto:sub('antiDash', 'Anti Dash Target')
            for i, Hero in pairs(ObjectManager:GetEnemyHeroes()) do
                self.BlitMenu.auto.antiDash:checkbox(Hero.charName, Hero.charName , false)
            end
            --self.BlitMenu.auto:checkbox('useIG', 'use Ignite', true)
            --self.BlitMenu.auto:checkbox('useComboIG', 'use Ignite Only in Combo', true)

        self.BlitMenu:sub('drawing', 'Drawings')
            self.BlitMenu.drawing:checkbox('drawQ', 'Draw Q', true)
            self.BlitMenu.drawing:checkbox('drawR', 'Draw R', true)
            self.BlitMenu.drawing:checkbox('drawTG', 'Draw Q Target', true)

    --AddEvent(Events.OnBuffGain, 	function(a,b) self:OnBuffGain(a,b) end)
    AddEvent(Events.OnTick,function() self:OnTick() end)
    AddEvent(Events.OnDraw,function() self:OnDraw() end)
    --AddEvent(Events.OnNewPath,function(a,b,c,d) OnWaypoint(a,b,c,d) end)


end

function OnWaypoint(_unit,_path,_isWalk,_dashSpeed)
    if _dashSpeed > 860 and _unit then
        DrawHandler:Circle3D(myHero.position, 50 ,0xffff0000)

        PrintChat("dash")
        for k, v in pairs(_path) do
            PrintChat("x: "..v.x)
            PrintChat("y: "..v.y)
            PrintChat("z: "..v.z)
            pathLo = v
            DrawHandler:Circle3D(v, 100 ,0xffff0000)
        end
    end
end


function Blitzcrank:OnBuffGain(unit,buff)
    if unit.team ~= myHero.team then
        PrintChat("type: ".. unit.type)
        PrintChat("name: ".. buff.name)
        PrintChat("caster: "..buff.caster.charName)
    end
end

function Blitzcrank:OnTick()
    
    if myHero.isDead then return end

    if LegitOrbwalker:GetMode() == "Combo" then
        self:Combo()
    elseif LegitOrbwalker:GetMode() == "Harass" then
        self:Harass()
    end
    self:Auto()

end

function Blitzcrank:OnDraw()
    if not myHero.isDead then
        if myHero.spellbook:CanUseSpell(SpellSlot.Q)==0 and self.BlitMenu.drawing.drawQ:get() then
            DrawHandler:Circle3D(myHero.position, self.BlitMenu.combo.maxRange:get(),0xFFE1A000)
            DrawHandler:Circle3D(myHero.position, self.BlitMenu.combo.minRange:get(),0x64E1A000)
        end
        if myHero.spellbook:CanUseSpell(SpellSlot.R)==0 and self.BlitMenu.drawing.drawR:get() then
            DrawHandler:Circle3D(myHero.position, 600 ,0xffffffff)
        end
        if self.BlitMenu.drawing.drawTG:get() then
            local target = LegitOrbwalker:GetTarget(925)
            if target ~= nil then
                DrawHandler:Circle3D(target.position, target.boundingRadius ,0xffff0000)
            end
        end
    end
end


function Blitzcrank:Combo()
    local target = LegitOrbwalker:GetTarget(925)
    if not target then return end
    if target.isTargetable and not target.isInvulnerable then
        if  self.BlitMenu.combo.useQ:get() and myHero.spellbook:CanUseSpell(SpellSlot.Q)==0 and GetDistance(myHero,target) < self.BlitMenu.combo.maxRange:get() and GetDistance(myHero,target) > self.BlitMenu.combo.minRange:get() then

            local infoDream = _G.Prediction.GetPrediction(target, self.Qdata, myHero)
            if infoDream and infoDream.castPosition and infoDream.hitChance >= self.BlitMenu.combo.hitchance:get() and not infoDream:minionCollision(1) and not infoDream:windWallCollision()  then
                --PrintChat(infoDream.hitChance)
                myHero.spellbook:CastSpell(SpellSlot.Q, infoDream.castPosition)
            end
        end


        if self.BlitMenu.combo.useE:get() and myHero.spellbook:CanUseSpell(SpellSlot.E)==0 then
            local Erange = myHero.characterIntermediate.attackRange + target.boundingRadius + myHero.boundingRadius
            if target.buffManager:HasBuff("rocketgrab2") or  GetDistance(myHero,target) <= Erange then
                myHero.spellbook:CastSpell(SpellSlot.E,myHero.networkId)
            end
        end

        if self.BlitMenu.combo.useR:get() and myHero.spellbook:CanUseSpell(SpellSlot.R)==0 then
            if GetTargetInRange(self.R.range) >= self.BlitMenu.combo.minComboR:get() then
                myHero.spellbook:CastSpell(SpellSlot.R,myHero.networkId)
            end
        end

    end
end

function Blitzcrank:Harass()
    local target = LegitOrbwalker:GetTarget(925)
    if not target then return end

    if target.isTargetable and not target.isInvulnerable then
        if  self.BlitMenu.harass.useQ:get() and myHero.spellbook:CanUseSpell(SpellSlot.Q)==0 and GetDistance(myHero,target) < self.BlitMenu.harass.maxRange:get() and GetDistance(myHero,target) > self.BlitMenu.harass.minRange:get() then

            local infoDream = _G.Prediction.GetPrediction(target, self.Qdata, myHero)
            if infoDream and infoDream.castPosition and infoDream.hitChance >= self.BlitMenu.harass.hitchance:get() and not infoDream:minionCollision(1) and not infoDream:windWallCollision()  then
                myHero.spellbook:CastSpell(SpellSlot.Q, infoDream.castPosition)
            end
        end

        if self.BlitMenu.harass.useE:get() and myHero.spellbook:CanUseSpell(SpellSlot.E)==0 then
            local Erange = myHero.characterIntermediate.attackRange + target.boundingRadius + myHero.boundingRadius
            if target.buffManager:HasBuff("rocketgrab2") or  GetDistance(myHero,target) <= Erange then
                myHero.spellbook:CastSpell(SpellSlot.E,myHero.networkId)
            end
        end
    end
end

function Blitzcrank:Auto()
    if self.BlitMenu.auto.useR:get() and myHero.spellbook:CanUseSpell(SpellSlot.R)==0 then
        if GetTargetInRange(self.R.range) >= self.BlitMenu.auto.minAutoR:get() then
            myHero.spellbook:CastSpell(SpellSlot.R,myHero.networkId)
        end
    end

end





function OnLoad()

	if not _G.Prediction then LoadPaidScript(PaidScript.DREAM_PRED)  end

    Blitzcrank:__init()
end
