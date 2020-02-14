if myHero.charName ~= "Kennen" then return end
require "DamageLib"
require('GamsteronPrediction')

-- SpellDatas
local Q = {delay = 0.2,range = 1050,speed = 1650,icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/f/f5/Thundering_Shuriken.png"}
local W = {range = 750,icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/d/db/Electrical_Surge.png"}
local E = {icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/7/76/Lightning_Rush.png"}
local R = {range = 550,icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/e/e9/Slicing_Maelstrom.png"}
local Qdata = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 50, Range = 1050, Speed = 1650, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}}

-- Menu
local KennenMenu = MenuElement({type = MENU, id = "KennenMenu", name = "Kennen"})
--Combo
KennenMenu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
KennenMenu.Combo:MenuElement({type = PARAM, id = "Q", name = "Use Q", value = true})
KennenMenu.Combo:MenuElement({type = PARAM, id = "W", name = "Use W", value = true})
KennenMenu.Combo:MenuElement({type = PARAM, id = "WS", name = "Only Stun with W", value = true})
KennenMenu.Combo:MenuElement({type = PARAM, id = "R", name = "Use R", value = true})
KennenMenu.Combo:MenuElement({type = PARAM, id = "RS", name = "Min. Enemies To Use Ult", value = 2,min=1,max=5,leftIcon = R.icon})
--Harass
KennenMenu:MenuElement({type = MENU, id = "Harass", name = "Harass Menu"})
KennenMenu.Harass:MenuElement({type = PARAM, id = "Q", name = "Use Q", value = true})
KennenMenu.Harass:MenuElement({type = PARAM, id = "W", name = "Use W", value = true})
KennenMenu.Harass:MenuElement({type = PARAM, id = "WS", name = "Only Stun with W", value = true})
--AutoStun
KennenMenu:MenuElement({type = MENU, id = "AutoStun", name = "AutoStun"})
KennenMenu.AutoStun:MenuElement({type = PARAM, id = "Q", name = "Use Q", value = false})
KennenMenu.AutoStun:MenuElement({type = PARAM, id = "W", name = "Use W", value = false})
--KillSecure
KennenMenu:MenuElement({type = MENU, id = "KillSecure", name = " KillSecure"})
KennenMenu.KillSecure:MenuElement({type = PARAM, id = "Q", name = "Use Q", value = true})
KennenMenu.KillSecure:MenuElement({type = PARAM, id = "W", name = "Use W", value = true})
--Items
KennenMenu:MenuElement({type = MENU, id = "Item", name = " Item Usage"})
KennenMenu.Item:MenuElement({type = PARAM, id = "GLP800", name = "Use Hextech GLP-800 in Combo", value = true})
KennenMenu.Item:MenuElement({type = PARAM, id = "Protobelt01", name = "Gapclose With Protobelt-01", value = true})
--
local items={Zhonya=3157,GLP800=3030,Protobelt01=3152}
local ItemSlots={ITEM_1,ITEM_2,ITEM_3,ITEM_4,ITEM_5,ITEM_6,ITEM_7}
local ItemHotKeys={HK_ITEM_1,HK_ITEM_2,HK_ITEM_3,HK_ITEM_4,HK_ITEM_5,HK_ITEM_6,HK_ITEM_7}
--
local function GetNumberOfTableElements(table)
	local kkk=0
	if table then
		if table[1] then
			for k,v in pairs(table) do
				kkk=kkk+1
			end
		end
	end
	return kkk
end

local function EnemiesNearMe(r)
	local r=r or 550
	local enemies={}
	for i=1,Game.HeroCount() do
		local hero=Game.Hero(i)
		if hero.isEnemy then
			if hero.distance<=r then
				table.insert(enemies,hero)
			end
		end
	end
	return enemies
end

local function GetCD(x)
	return myHero:GetSpellData(x).currentCd
end

local function GetItemHotKey(item)
	for i=1,7 do
		if item==ItemSlots[i] then
			return ItemHotKeys[i]
		end
	end
end

local function GetItemSlot(itemID)
	local itemm
	for i=1,7 do
		local slot=ItemSlots[i]
		local item=myHero:GetItemData(slot)
		local foundItem=false
		if item.itemID==itemID and GetCD(slot)==0 then
			itemm=slot
			foundItem=true
		end
		if foundItem then
			break
		end
	end
	return itemm
end

local function CastQ(who)
	if who then
		if not who.dead and not who.isImmune then
			if Game.CanUseSpell(_Q)==READY and who.distance<=Q.range then
				local Pred = GetGamsteronPrediction(who, Qdata , myHero)
				if Pred.Hitchance >= _G.HITCHANCE_HIGH then
					Control.CastSpell(HK_Q, Pred.CastPosition)
				end
			end
		end
	end
	return false
end

local function CanQ(who)
	if who then
		if Game.CanUseSpell(_Q)==READY and who.distance<=Q.range then
			return true
		end
	end
	return false
end

local function GetMarks(hero)
	local stacks=0
	if hero then
		for i=1,hero.buffCount do
			local buff=hero:GetBuff(i)
			if buff.name=="kennenmarkofstorm" then
				if buff.duration>0 then
					stacks=buff.count
				end
			end
		end
	end
	return stacks
end
--
local target=nil
function OnTick()
	target=_G.SDK.TargetSelector:GetTarget(1050)
	if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and target then
		local protobelt=GetItemSlot(items.Protobelt01)
		if target.distance<=980 then
			local glp800=GetItemSlot(items.GLP800)
			if KennenMenu.Combo.R:Value() and Game.CanUseSpell(_R)==READY and GetNumberOfTableElements(EnemiesNearMe())>=KennenMenu.Combo.RS:Value() then
				Control.CastSpell(HK_R)
			elseif KennenMenu.Combo.Q:Value() and CanQ(target) then
				CastQ(target)
			elseif KennenMenu.Item.GLP800:Value() and glp800 and target.distance<=700 then
				local glp800k=GetItemHotKey(glp800)
				Control.CastSpell(glp800k,target)
			elseif KennenMenu.Combo.W:Value() and Game.CanUseSpell(_W)==READY and target.distance<=W.range then
				if KennenMenu.Combo.WS:Value() then
					if GetMarks(target)>1 then
						Control.CastSpell(HK_W)
					end
				elseif GetMarks(target)>0 then
					Control.CastSpell(HK_W)
				end
			end
		elseif protobelt and KennenMenu.Item.GLP800:Value() and target.distance<=800 and target.distance>=200 then
			local protobeltK=GetItemHotKey(protobelt)
			Control.CastSpell(protobeltK,target)
		end
	end
	if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] and target then
		if KennenMenu.Harass.Q:Value() and CanQ(target) then
			CastQ(target)
		elseif KennenMenu.Harass.W:Value() and Game.CanUseSpell(_W)==READY and target.distance<=W.range then
			if KennenMenu.Harass.WS:Value() then
				if GetMarks(target)>1 then
					Control.CastSpell(HK_W)
				end
			elseif GetMarks(target)>0 then
				Control.CastSpell(HK_W)
			end
		end
	end
	--
	if KennenMenu.AutoStun.Q:Value() or KennenMenu.AutoStun.W:Value() then
		if Game.CanUseSpell(_W)==READY or Game.CanUseSpell(_Q)==READY then
			for i=1,Game.HeroCount() do
				local hero=Game.Hero(i)
				if hero.isEnemy then
					if not hero.dead and not hero.isImmortal then
						if GetMarks(hero)>1 then
							if KennenMenu.Combo.W:Value() and Game.CanUseSpell(_W)==READY and target.distance<=W.range then
								Control.CastSpell(HK_W)
							elseif KennenMenu.AutoStun.Q:Value() and CanQ(hero) then
								CastQ(hero)
							end
						end
					end
				end
			end
		end
	end
	--
	if KennenMenu.KillSecure.Q:Value() or KennenMenu.KillSecure.W:Value() then
		for i=1,Game.HeroCount() do
			local hero=Game.Hero(i)
			if hero.distance<=Q.range and hero.isEnemy and not hero.dead and not hero.isImmortal then
				if KennenMenu.KillSecure.Q:Value() and Game.CanUseSpell(_Q)==READY and CanQ(hero) and getdmg("Q",hero)>hero.health then
					CastQ(hero)
				elseif KennenMenu.KillSecure.W:Value() and Game.CanUseSpell(_W)==READY and GetMarks(hero)>0 then
					if hero.distance<=W.range and getdmg("W",hero,myHero,2)>hero.health then
						Control.CastSpell(HK_W)
					end
				end
			end
		end
	end
end
print("External Kennen v.1.01 Loaded!")
