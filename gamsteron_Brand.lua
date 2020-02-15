class "Brand"

function Brand:__init()
    self.ETarget = nil
    self.QData = {Delay = 0.25, Radius = 60, Range = 1085, Speed = 1600, Collision = true, Type = _G.SPELLTYPE_LINE}
    self.WData = {Delay = 0.9, Radius = 260, Range = 880, Speed = math.huge, Collision = false, Type = _G.SPELLTYPE_CIRCLE}
end

function Brand:CreateMenu()
    Menu = MenuElement({name = "Gamsteron Brand", id = "Gamsteron_Brand", type = _G.MENU})
    -- Q
    Menu:MenuElement({name = "Q settings", id = "qset", type = _G.MENU})
    -- KS
    Menu.qset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU})
    Menu.qset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = true})
    Menu.qset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
    Menu.qset.killsteal:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
    -- Auto
    Menu.qset:MenuElement({name = "Auto", id = "auto", type = _G.MENU})
    Menu.qset.auto:MenuElement({id = "stun", name = "Auto Stun", value = true})
    Menu.qset.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
    -- Combo / Harass
    Menu.qset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU})
    Menu.qset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
    Menu.qset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
    Menu.qset.comhar:MenuElement({id = "stun", name = "Only if will stun", value = true})
    Menu.qset.comhar:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
    -- W
    Menu:MenuElement({name = "W settings", id = "wset", type = _G.MENU})
    Menu.wset:MenuElement({id = "disaa", name = "Disable attack if ready or almostReady", value = true})
    -- KS
    Menu.wset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU})
    Menu.wset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = true})
    Menu.wset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
    Menu.wset.killsteal:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
    -- Auto
    Menu.wset:MenuElement({name = "Auto", id = "auto", type = _G.MENU})
    Menu.wset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
    Menu.wset.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
    -- Combo / Harass
    Menu.wset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU})
    Menu.wset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
    Menu.wset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
    Menu.wset.comhar:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
    -- E
    Menu:MenuElement({name = "E settings", id = "eset", type = _G.MENU})
    Menu.eset:MenuElement({id = "disaa", name = "Disable attack if ready or almostReady", value = true})
    -- KS
    Menu.eset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU})
    Menu.eset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = true})
    Menu.eset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 100, min = 1, max = 300, step = 1})
    -- Auto
    Menu.eset:MenuElement({name = "Auto", id = "auto", type = _G.MENU})
    Menu.eset.auto:MenuElement({id = "stun", name = "If Q ready | no collision & W not ready $ mana for Q + E", value = true})
    Menu.eset.auto:MenuElement({id = "passive", name = "If Q not ready & W not ready $ enemy has passive buff", value = true})
    -- Combo / Harass
    Menu.eset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU})
    Menu.eset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
    Menu.eset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
    --R
    Menu:MenuElement({name = "R settings", id = "rset", type = _G.MENU})
    -- Auto
    Menu.rset:MenuElement({name = "Auto", id = "auto", type = _G.MENU})
    Menu.rset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
    Menu.rset.auto:MenuElement({id = "xenemies", name = ">= X enemies near target", value = 2, min = 1, max = 4, step = 1})
    Menu.rset.auto:MenuElement({id = "xrange", name = "< X distance enemies to target", value = 300, min = 100, max = 600, step = 50})
    -- Combo / Harass
    Menu.rset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU})
    Menu.rset.comhar:MenuElement({id = "combo", name = "Use R Combo", value = true})
    Menu.rset.comhar:MenuElement({id = "harass", name = "Use R Harass", value = false})
    Menu.rset.comhar:MenuElement({id = "xenemies", name = ">= X enemies near target", value = 1, min = 1, max = 4, step = 1})
    Menu.rset.comhar:MenuElement({id = "xrange", name = "< X distance enemies to target", value = 300, min = 100, max = 600, step = 50})
end

function Brand:Tick()
    -- Is Attacking
    if SDKOrbwalker:IsAutoAttacking() then
        return
    end
    -- Q
    if SDKSpell:IsReady(_Q, {q = 0.5, w = 0.53, e = 0.53, r = 0.33}) then
        -- KS
        if Menu.qset.killsteal.enabled:Value() then
            local baseDmg = 50
            local lvlDmg = 30 * myHero:GetSpellData(_Q).level
            local apDmg = myHero.ap * 0.55
            local qDmg = baseDmg + lvlDmg + apDmg
            local minHP = Menu.qset.killsteal.minhp:Value()
            if qDmg > minHP then
                local enemyList = AIO:GetEnemyHeroes(1050)
                for i = 1, #enemyList do
                    local qTarget = enemyList[i]
                    if qTarget.health > minHP and qTarget.health < SDKDamage:CalculateDamage(myHero, qTarget, DAMAGE_TYPE_MAGICAL, qDmg) then
                        if AIO:Cast(HK_Q, qTarget, self.QData, Menu.qset.killsteal.hitchance:Value() + 1) then
                            return
                        end
                    end
                end
            end
        end
        -- Combo Harass
        if (SDKOrbwalker.Modes[ORBWALKER_MODE_COMBO] and Menu.qset.comhar.combo:Value()) or (SDKOrbwalker.Modes[ORBWALKER_MODE_HARASS] and Menu.qset.comhar.harass:Value()) then
            if Game.Timer() < SDKSpell.EkTimer + 1 and Game.Timer() > SDKSpell.ETimer + 0.33 and AIO:IsValidHero(self.ETarget) and self.ETarget:GetCollision(self.QData.Radius, self.QData.Speed, self.QData.Delay) == 0 then
                if AIO:Cast(HK_Q, self.ETarget, self.QData, Menu.qset.comhar.hitchance:Value() + 1) then
                    return
                end
            end
            local blazeList = {}
            local enemyList = AIO:GetEnemyHeroes(1050)
            for i = 1, #enemyList do
                local unit = enemyList[i]
                if SDKBuff:GetBuffDuration(unit, "brandablaze") > 0.5 and unit:GetCollision(self.QData.Radius, self.QData.Speed, self.QData.Delay) == 0 then
                    blazeList[#blazeList + 1] = unit
                end
            end
            if AIO:Cast(HK_Q, SDKTarget:GetTarget(blazeList, 1), self.QData, Menu.qset.comhar.hitchance:Value() + 1) then
                return
            end
            if not Menu.qset.comhar.stun:Value() and Game.Timer() > SDKSpell.WkTimer + 1.33 and Game.Timer() > SDKSpell.EkTimer + 0.77 and Game.Timer() > SDKSpell.RkTimer + 0.77 then
                if AIO:Cast(HK_Q, SDKTarget:GetTarget(AIO:GetEnemyHeroes(1050), 1), self.QData, Menu.qset.comhar.hitchance:Value() + 1) then
                    return
                end
            end
            -- Auto
        elseif Menu.qset.auto.stun:Value() then
            if Game.Timer() < SDKSpell.EkTimer + 1 and Game.Timer() < SDKSpell.ETimer + 1 and AIO:IsValidHero(self.ETarget) and self.ETarget:GetCollision(self.QData.Radius, self.QData.Speed, self.QData.Delay) == 0 then
                if AIO:Cast(HK_Q, self.ETarget, self.QData, Menu.qset.auto.hitchance:Value() + 1) then
                    return
                end
            end
            local blazeList = {}
            local enemyList = AIO:GetEnemyHeroes(1050)
            for i = 1, #enemyList do
                local unit = enemyList[i]
                if unit and SDKBuff:GetBuffDuration(unit, "brandablaze") > 0.5 and unit:GetCollision(self.QData.Radius, self.QData.Speed, self.QData.Delay) == 0 then
                    blazeList[#blazeList + 1] = unit
                end
            end
            if AIO:Cast(HK_Q, SDKTarget:GetTarget(blazeList, 1), self.QData, Menu.qset.auto.hitchance:Value() + 1) then
                return
            end
        end
    end
    -- E
    if SDKSpell:IsReady(_E, {q = 0.33, w = 0.53, e = 0.5, r = 0.33}) then
        -- antigap
        local enemyList = AIO:GetEnemyHeroes(635)
        for i = 1, #enemyList do
            local unit = enemyList[i]
            if unit and unit.distance < 300 and AIO:Cast(HK_E, unit) then
                return
            end
        end
        -- KS
        if Menu.eset.killsteal.enabled:Value() then
            local baseDmg = 50
            local lvlDmg = 20 * myHero:GetSpellData(_E).level
            local apDmg = myHero.ap * 0.35
            local eDmg = baseDmg + lvlDmg + apDmg
            local minHP = Menu.eset.killsteal.minhp:Value()
            if eDmg > minHP then
                for i = 1, #enemyList do
                    local unit = enemyList[i]
                    if unit and unit.health > minHP and unit.health < SDKDamage:CalculateDamage(myHero, unit, DAMAGE_TYPE_MAGICAL, eDmg) and AIO:Cast(HK_E, unit) then
                        return
                    end
                end
            end
        end
        -- Combo / Harass
        if (SDKOrbwalker.Modes[ORBWALKER_MODE_COMBO] and Menu.eset.comhar.combo:Value()) or (SDKOrbwalker.Modes[ORBWALKER_MODE_HARASS] and Menu.eset.comhar.harass:Value()) then
            local blazeList = {}
            for i = 1, #enemyList do
                local unit = enemyList[i]
                if unit and SDKBuff:GetBuffDuration(unit, "brandablaze") > 0.33 then
                    blazeList[#blazeList + 1] = unit
                end
            end
            local eTarget = SDKTarget:GetTarget(blazeList, 1)
            if eTarget and AIO:Cast(HK_E, eTarget) then
                self.ETarget = eTarget
                return
            end
            if Game.Timer() > SDKSpell.QkTimer + 0.77 and Game.Timer() > SDKSpell.WkTimer + 1.33 and Game.Timer() > SDKSpell.RkTimer + 0.77 then
                eTarget = SDKTarget:GetTarget(enemyList, 1)
                if eTarget and AIO:Cast(HK_E, eTarget) then
                    self.ETarget = eTarget
                    return
                end
            end
            -- Auto
        elseif myHero:GetSpellData(_Q).level > 0 and myHero:GetSpellData(_W).level > 0 then
            -- EQ -> if Q ready | no collision & W not ready $ mana for Q + E
            if Menu.eset.auto.stun:Value() and myHero.mana > myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_E).mana then
                if (Game.CanUseSpell(_Q) == 0 or myHero:GetSpellData(_Q).currentCd < 0.75) and not(Game.CanUseSpell(_W) == 0 or myHero:GetSpellData(_W).currentCd < 0.75) then
                    local blazeList = {}
                    local enemyList = AIO:GetEnemyHeroes(635)
                    for i = 1, #enemyList do
                        local unit = enemyList[i]
                        if unit and SDKBuff:GetBuffDuration(unit, "brandablaze") > 0.33 then
                            blazeList[#blazeList + 1] = unit
                        end
                    end
                    local eTarget = SDKTarget:GetTarget(blazeList, 1)
                    if eTarget and eTarget:GetCollision(self.QData.Radius, self.QData.Speed, self.QData.Delay) == 0 and AIO:Cast(HK_E, eTarget) then
                        return
                    end
                    if Game.Timer() > SDKSpell.QkTimer + 0.77 and Game.Timer() > SDKSpell.WkTimer + 1.33 and Game.Timer() > SDKSpell.RkTimer + 0.77 then
                        eTarget = SDKTarget:GetTarget(enemyList, 1)
                        if eTarget and eTarget:GetCollision(self.QData.Radius, self.QData.Speed, self.QData.Delay) == 0 and AIO:Cast(HK_E, eTarget) then
                            self.ETarget = eTarget
                            return
                        end
                    end
                end
            end
            -- Passive -> If Q not ready & W not ready $ enemy has passive buff
            if Menu.eset.auto.passive:Value() and not(Game.CanUseSpell(_Q) == 0 or myHero:GetSpellData(_Q).currentCd < 0.75) and not(Game.CanUseSpell(_W) == 0 or myHero:GetSpellData(_W).currentCd < 0.75) then
                local blazeList = {}
                local enemyList = AIO:GetEnemyHeroes(670)
                for i = 1, #enemyList do
                    local unit = enemyList[i]
                    if unit and SDKBuff:GetBuffDuration(unit, "brandablaze") > 0.33 then
                        blazeList[#blazeList + 1] = unit
                    end
                end
                local eTarget = SDKTarget:GetTarget(blazeList, 1)
                if eTarget and AIO:Cast(HK_E, eTarget) then
                    self.ETarget = eTarget
                    return
                end
            end
        end
    end
    -- W
    if SDKSpell:IsReady(_W, {q = 0.33, w = 0.5, e = 0.33, r = 0.33}) then
        -- KS
        if Menu.wset.killsteal.enabled:Value() then
            local baseDmg = 30
            local lvlDmg = 45 * myHero:GetSpellData(_W).level
            local apDmg = myHero.ap * 0.6
            local wDmg = baseDmg + lvlDmg + apDmg
            local minHP = Menu.wset.killsteal.minhp:Value()
            if wDmg > minHP then
                local enemyList = AIO:GetEnemyHeroes(950)
                for i = 1, #enemyList do
                    local wTarget = enemyList[i]
                    if wTarget and wTarget.health > minHP and wTarget.health < SDKDamage:CalculateDamage(myHero, wTarget, DAMAGE_TYPE_MAGICAL, wDmg) and AIO:Cast(HK_W, wTarget, self.WData, Menu.wset.killsteal.hitchance:Value() + 1) then
                        return;
                    end
                end
            end
        end
        -- Combo / Harass
        if (SDKOrbwalker.Modes[ORBWALKER_MODE_COMBO] and Menu.wset.comhar.combo:Value()) or (SDKOrbwalker.Modes[ORBWALKER_MODE_HARASS] and Menu.wset.comhar.harass:Value()) then
            local blazeList = {}
            local enemyList = AIO:GetEnemyHeroes(950)
            for i = 1, #enemyList do
                local unit = enemyList[i]
                if SDKBuff:GetBuffDuration(unit, "brandablaze") > 1.33 then
                    blazeList[#blazeList + 1] = unit
                end
            end
            local wTarget = SDKTarget:GetTarget(blazeList, 1)
            if wTarget and AIO:Cast(HK_W, wTarget, self.WData, Menu.wset.comhar.hitchance:Value() + 1) then
                return
            end
            if Game.Timer() > SDKSpell.QkTimer + 0.77 and Game.Timer() > SDKSpell.EkTimer + 0.77 and Game.Timer() > SDKSpell.RkTimer + 0.77 then
                wTarget = SDKTarget:GetTarget(enemyList, 1)
                if wTarget and AIO:Cast(HK_W, wTarget, self.WData, Menu.wset.comhar.hitchance:Value() + 1) then
                    return
                end
            end
            -- Auto
        elseif Menu.wset.auto.enabled:Value() then
            for i = 1, 3 do
                local blazeList = {}
                local enemyList = AIO:GetEnemyHeroes(1200 - (i * 100))
                for j = 1, #enemyList do
                    local unit = enemyList[j]
                    if unit and SDKBuff:GetBuffDuration(unit, "brandablaze") > 1.33 then
                        blazeList[#blazeList + 1] = unit
                    end
                end
                local wTarget = SDKTarget:GetTarget(blazeList, 1);
                if wTarget then
                    if AIO:Cast(HK_W, wTarget, self.WData, Menu.wset.auto.hitchance:Value() + 1) then
                        return
                    end
                end
                if Game.Timer() > SDKSpell.QkTimer + 0.77 and Game.Timer() > SDKSpell.EkTimer + 0.77 and Game.Timer() > SDKSpell.RkTimer + 0.77 then
                    wTarget = SDKTarget:GetTarget(enemyList, 1)
                    if wTarget then
                        if AIO:Cast(HK_W, wTarget, self.WData, Menu.wset.auto.hitchance:Value() + 1) then
                            return
                        end
                    end
                end
            end
        end
    end
    -- R
    if SDKSpell:IsReady(_R, {q = 0.33, w = 0.33, e = 0.33, r = 0.5}) then
        -- Combo / Harass
        if (SDKOrbwalker.Modes[ORBWALKER_MODE_COMBO] and Menu.rset.comhar.combo:Value()) or (SDKOrbwalker.Modes[ORBWALKER_MODE_HARASS] and Menu.rset.comhar.harass:Value()) then
            local enemyList = AIO:GetEnemyHeroes(750)
            local xRange = Menu.rset.comhar.xrange:Value()
            local xEnemies = Menu.rset.comhar.xenemies:Value()
            for i = 1, #enemyList do
                local count = 0
                local rTarget = enemyList[i]
                if rTarget then
                    for j = 1, #enemyList do
                        if i ~= j then
                            local unit = enemyList[j]
                            if unit and rTarget.pos:DistanceTo(unit.pos) < xRange then
                                count = count + 1
                            end
                        end
                    end
                    if count >= xEnemies and AIO:Cast(HK_R, rTarget) then
                        return
                    end
                end
            end
            -- Auto
        elseif Menu.rset.auto.enabled:Value() then
            local enemyList = AIO:GetEnemyHeroes(750)
            local xRange = Menu.rset.auto.xrange:Value()
            local xEnemies = Menu.rset.auto.xenemies:Value()
            for i = 1, #enemyList do
                local count = 0
                local rTarget = enemyList[i]
                if rTarget then
                    for j = 1, #enemyList do
                        if i ~= j then
                            local unit = enemyList[j]
                            if unit and rTarget.pos:DistanceTo(unit.pos) < xRange then
                                count = count + 1
                            end
                        end
                    end
                    if count >= xEnemies and AIO:Cast(HK_R, rTarget) then
                        return
                    end
                end
            end
        end
    end
end

function Brand:CanMove()
    if not SDKSpell:CheckSpellDelays({q = 0.2, w = 0.2, e = 0.2, r = 0.2}) then
        return false
    end
    return true
end

function Brand:CanAttack()
    if not SDKSpell:CheckSpellDelays({q = 0.33, w = 0.33, e = 0.33, r = 0.33}) then
        return false
    end
    -- LastHit, LaneClear
    if not SDKOrbwalker.Modes[ORBWALKER_MODE_COMBO] and not SDKOrbwalker.Modes[ORBWALKER_MODE_HARASS] then
        return true
    end
    -- W
    local wData = myHero:GetSpellData(_W);
    if Menu.wset.disaa:Value() and wData.level > 0 and myHero.mana > wData.mana and (Game.CanUseSpell(_W) == 0 or wData.currentCd < 1) then
        return false
    end
    -- E
    local eData = myHero:GetSpellData(_E);
    if Menu.eset.disaa:Value() and eData.level > 0 and myHero.mana > eData.mana and (Game.CanUseSpell(_E) == 0 or eData.currentCd < 1) then
        return false
    end
    return true
end
