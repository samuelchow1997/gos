local version = 0.02

if (myHero.charName ~= "Morgana") then 
    return
end
local ORB, TS, OB, DMG, SPELLS = _G.SDK.Orbwalker, _G.SDK.TargetSelector, _G.SDK.ObjectManager, _G.SDK.Damage, _G.SDK.Spells
GamCore = _G.GamsteronCore


local shellSpells = {
    ["SowTheWind"] = {charName = "Janna", slot = "W"},
    ["Terrify"] = {charName = "Fiddlesticks", slot = "Q"},
    ["FiddlesticksDarkWind"] = {charName = "Fiddlesticks", slot = "E"},
    ["LuluWTwo"] = {charName = "Lulu", slot = "W"},
    ["NautilusRavageStrikeAttack"]= {charName = "Nautilus", slot = "Passive"} ,
    ["NautilusGrandLine"]= {charName = "Nautilus", slot = "R"},
    ["TahmKenchW"]= {charName = "TahmKench", slot = "W"},
    ["VayneCondemn"]= {charName = "Vayne", slot = "E"},
    ["jayceThunderingBlow"]= {charName = "Jayce", slot = "E"},
    ["BlindMonkRKick"] = {charName = "LeeSin", slot = "R"},
    ["LissandraREnemy"]= {charName = "Lissandra", slot = "R"},
    ["SeismicShard"] ={charName = "Malphite", slot = "Q"},
    ["MalzaharR"]= {charName = "Malzahar", slot = "R"},
    ["NasusW"] = {charName = "Nasus", slot = "W"},
    ["RekSaiWUnburrowLockout"] = {charName = "RekSai", slot = "W"},
    ["PuncturingTaunt"]= {charName = "Rammus", slot = "E"},
    ["RyzeW"]= {charName = "Ryze", slot = "W"},
    ["Fling"] = {charName = "Singed", slot = "W"},
    ["SkarnerImpale"]  = {charName = "Skarner", slot = "R"},
    ["SkarnerPassiveAttack"] = {charName = "Skarner", slot = "E Passive"},
    ["Blinding Dart"] = {charName = "Teemo", slot = "Q"},
    ["TristanaR"] = {charName = "Tristana", slot = "R"},
    ["WarwickRChannel"] = {charName = "Warwick", slot = "R"},  -- need test
    ["XinZhaoQThrust3"] = {charName = "XinZhao", slot = "Q3"},
    ["VolibearQAttack"] = {charName = "Volibear", slot = "Q"},
    ["ViR"] = {charName = "Vi", slot = "R"},
    ["LeonaShieldOfDaybreakAttack"] = {charName = "Leona", slot = "Q"}
}
function OnLoad()
    MM = MenuElement({type = MENU, id = "MM", name = "Morgana E"})

    MM:MenuElement({type = MENU, id = "spell", name = "Spells"})
    GamCore:OnEnemyHeroLoad(function(hero) 
        for k, v in pairs(shellSpells) do
            if v.charName == hero.charName then
                MM.spell:MenuElement({id = k, name = v.charName.." | "..v.slot , value = true})
            end
        end
    end)

    MM:MenuElement({type = MENU, id = "dash", name = "track dash on"})
    GamCore:OnEnemyHeroLoad(function(hero) MM.dash:MenuElement({id = hero.charName, name = hero.charName, value = false}) end)

    MM:MenuElement({type = MENU, id = "ally", name = "Use E "})
    GamCore:OnAllyHeroLoad(function(hero) MM.ally:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
end

function OnDraw()
    local EnemyHeroes = OB:GetEnemyHeroes(2800, false)
    for i = 1, #EnemyHeroes do
        local hero = EnemyHeroes[i]
        if hero.activeSpell.valid and shellSpells[hero.activeSpell.name] ~= nil then
            local AllyHeroes = OB:GetAllyHeroes(800)
            for i = 1, #AllyHeroes do
                local ally = AllyHeroes[i]
                if hero.activeSpell.target == ally.handle and MM.ally[ally.charName]:Value() and MM.spell[hero.activeSpell.name]:Value() then
                    Control.CastSpell(HK_E, ally)
                end
            end
        end

        if hero.pathing.isDashing and MM.dash[hero.charName]:Value() then
            local vct = Vector(hero.pathing.endPos.x,hero.pathing.endPos.y,hero.pathing.endPos.z)
            local AllyHeroes = OB:GetAllyHeroes(800)
            for i = 1, #AllyHeroes do
                local ally = AllyHeroes[i]
                if vct:DistanceTo(ally.pos) < 172 then
                    Control.CastSpell(HK_E, ally)
                end
            end
        end
    end
end