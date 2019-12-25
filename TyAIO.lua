local Version = '0.01b'
local SupportedChampions, AIO, Menu, HP, ORB, TS, OB, DMG, SPELLS, myHero, IsValid, Ready, IsInRange
local GameTimer, GameMissile, GameMissileCount
local ControlKeyUp, ControlKeyDown
local TEAM_JUNGLE

-- update
do
    local Files = {
        Lua = {
            Path = SCRIPT_PATH,
            Name = "TyAIO.lua",
            Url = "https://raw.githubusercontent.com/samuelchow1997/gos/master/TyAIO.lua"
        },
        Version = {
            Path = SCRIPT_PATH,
            Name = "TyAIO.version",
            Url = "https://raw.githubusercontent.com/samuelchow1997/gos/master/TyAIO.version"
        },
    }
    
    local function AutoUpdate()
        
        local function DownloadFile(url, path, fileName)
            DownloadFileAsync(url, path .. fileName, function() end)
            while not FileExist(path .. fileName) do end
        end
        
        local function Trim(s)
            local from = s:match"^%s*()"
            return from > #s and "" or s:match(".*%S", from)
        end
        
        local function ReadFile(path)
            local result = {}
            local file = io.open(path, "r")
            if file then
                for line in file:lines() do
                    local str = Trim(line)
                    if #str > 0 then
                        table.insert(result, str)
                    end
                end
                file:close()
            end
            return result
        end
        
        DownloadFile(Files.Version.Url, Files.Version.Path, Files.Version.Name)
        local NewVersion = ReadFile(Files.Version.Path, Files.Version.Name)
        if #NewVersion > 0 and NewVersion[1] ~= Version then
            DownloadFile(Files.Lua.Url, Files.Lua.Path, Files.Lua.Name)
            print("New TyAIO Version Press 2x F6")
        else
            print(Files.Version.Name .. ": No Updates Found")
        end
    end
    
    --AutoUpdate()
end

-- locals
do
    myHero = _G.myHero
    GameTimer = _G.Game.Timer
    GameMissile = _G.Game.Missile
    GameMissileCount = _G.Game.MissileCount
    ControlKeyUp = _G.Control.KeyUp
    ControlKeyDown = _G.Control.KeyDown
    TEAM_JUNGLE = 300
end

-- requires
do
    SupportedChampions =
    {
        ["Kaisa"] = true,
        ["Sivir"] = true,
        ["Amumu"] = true,
        ["Khazix"] = true,
        ["Orianna"] = true,
        ["Vi"] = true,
        ["Kennen"] = true,
        ["Leona"] = true,
        ["Morgana"] = true,
        ["Nautilus"] = true,
        ["Thresh"] = true,
        ["Yasuo"] = true,
    }
    
    if _G.TyAIOLoaded then return end _G.TyAIOLoaded = true
    
    if not SupportedChampions[myHero.charName] then return end
    
    if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
        print("GsoPred. installed Press 2x F6")
        DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-EXT/master/Common/GamsteronPrediction.lua", COMMON_PATH .. "GamsteronPrediction.lua", function() end)
        while not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") do end
    end
    require('GamsteronPrediction')
end

-- methods
do
    function IsValid (unit)
        return unit and unit.valid and unit.isTargetable and unit.alive and unit.visible and unit.networkID and unit.health > 0
    end
    
    function Ready (spell)
        return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana and Game.CanUseSpell(spell) == 0
    end
    
    function IsInRange (v1, v2, range)
        v1 = v1.pos or v1
        v2 = v2.pos or v2
        local dx = v1.x - v2.x
        local dz = (v1.z or v1.y) - (v2.z or v2.y)
        if dx * dx + dz * dz <= range * range then
            return true
        end
        return false
    end
end

-- aio
do
    AIO = {}
    
    -- action
    do
        AIO.Action = {Tasks = {}}
        
        function AIO.Action:Start()
            Callback.Add('Draw', function()
                for i, task in pairs(self.Tasks) do
                    if os.clock() >= task[2] then
                        if task[1]() or os.clock() >= task[3] then
                            table.remove(self.Tasks, i)
                        end
                    end
                end
            end)
        end
        
        function AIO.Action:Add(task, startTime, endTime)
            startTime = startTime or 0
            endTime = endTime or 10000
            table.insert(self.Tasks, {task, os.clock() + startTime, os.clock() + startTime + endTime})
        end
    end
    
    -- buff
    do
        AIO.Buff = {CachedBuffs = {}, }
        
        function AIO.Buff:Start()
            Callback.Add("Tick", function()
                self.CachedBuffs = {}
            end)
        end
        
        function AIO.Buff:CreateBuffs(unit)
            local result = {}
            for i = 0, unit.buffCount do
                local buff = unit:GetBuff(i)
                if buff and buff.count > 0 then
                    result[buff.name:lower()] =
                    {
                        Type = buff.type,
                        StartTime = buff.startTime,
                        ExpireTime = buff.expireTime,
                        Duration = buff.duration,
                        Stacks = buff.stacks,
                        Count = buff.count,
                    }
                end
            end
            return result
        end
        
        function AIO.Buff:GetBuffDuration(unit, name)
            name = name:lower()
            local id = unit.networkID
            if self.CachedBuffs[id] == nil then self.CachedBuffs[id] = self:CreateBuffs(unit) end
            if self.CachedBuffs[id][name] then
                return self.CachedBuffs[id][name].Duration
            end
            return 0
        end
        
        function AIO.Buff:GetBuff(unit, name)
            name = name:lower()
            local id = unit.networkID
            if self.CachedBuffs[id] == nil then self.CachedBuffs[id] = self:CreateBuffs(unit) end
            return self.CachedBuffs[id][name]
        end
        
        function AIO.Buff:HasBuffContainsName(unit, str)
            str = str:lower()
            local id = unit.networkID
            if self.CachedBuffs[id] == nil then self.CachedBuffs[id] = self:CreateBuffs(unit) end
            for name, buff in pairs(self.CachedBuffs[id]) do
                if name:find(str) then
                    return true
                end
            end
            return false
        end
        
        function AIO.Buff:ContainsBuffs(unit, arr)
            local id = unit.networkID
            if self.CachedBuffs[id] == nil then self.CachedBuffs[id] = self:CreateBuffs(unit) end
            for i = 1, #arr do
                local name = arr[i]:lower()
                if self.CachedBuffs[id][name] then
                    return true
                end
            end
            return false
        end
        
        function AIO.Buff:HasBuff(unit, name)
            name = name:lower()
            local id = unit.networkID
            if self.CachedBuffs[id] == nil then self.CachedBuffs[id] = self:CreateBuffs(unit) end
            if self.CachedBuffs[id][name] then
                return true
            end
            return false
        end
        
        function AIO.Buff:HasBuffTypes(unit, types)
            local id = unit.networkID
            if self.CachedBuffs[id] == nil then self.CachedBuffs[id] = self:CreateBuffs(unit) end
            for name, buff in pairs(self.CachedBuffs[id]) do
                if types[buff.Type] then
                    return true
                end
            end
            return false
        end
        
        function AIO.Buff:GetBuffCount(unit, name)
            name = name:lower()
            local id = unit.networkID
            if self.CachedBuffs[id] == nil then self.CachedBuffs[id] = self:CreateBuffs(unit) end
            if self.CachedBuffs[id][name] then
                return self.CachedBuffs[id][name].Count
            end
            return 0
        end
    end
    
    -- object
    do
        AIO.Object =
        {
            AllyBuildings = {},
            EnemyBuildings = {},
            AllyHeroesInGame = {},
            EnemyHeroesInGame = {},
            EnemyHeroCb = {},
            AllyHeroCb = {},
            HeroNames =
            {
                ['aatrox'] = true,
                ['ahri'] = true,
                ['akali'] = true,
                ['alistar'] = true,
                ['amumu'] = true,
                ['anivia'] = true,
                ['annie'] = true,
                ['ashe'] = true,
                ['aurelionsol'] = true,
                ['azir'] = true,
                ['bard'] = true,
                ['blitzcrank'] = true,
                ['brand'] = true,
                ['braum'] = true,
                ['caitlyn'] = true,
                ['camille'] = true,
                ['cassiopeia'] = true,
                ['chogath'] = true,
                ['corki'] = true,
                ['darius'] = true,
                ['diana'] = true,
                ['draven'] = true,
                ['drmundo'] = true,
                ['ekko'] = true,
                ['elise'] = true,
                ['evelynn'] = true,
                ['ezreal'] = true,
                ['fiddlesticks'] = true,
                ['fiora'] = true,
                ['fizz'] = true,
                ['galio'] = true,
                ['gangplank'] = true,
                ['garen'] = true,
                ['gnar'] = true,
                ['gragas'] = true,
                ['graves'] = true,
                ['hecarim'] = true,
                ['heimerdinger'] = true,
                ['illaoi'] = true,
                ['irelia'] = true,
                ['ivern'] = true,
                ['janna'] = true,
                ['jarvaniv'] = true,
                ['jax'] = true,
                ['jayce'] = true,
                ['jhin'] = true,
                ['jinx'] = true,
                ['kaisa'] = true,
                ['kalista'] = true,
                ['karma'] = true,
                ['karthus'] = true,
                ['kassadin'] = true,
                ['katarina'] = true,
                ['kayle'] = true,
                ['kayn'] = true,
                ['kennen'] = true,
                ['khazix'] = true,
                ['kindred'] = true,
                ['kled'] = true,
                ['kogmaw'] = true,
                ['leblanc'] = true,
                ['leesin'] = true,
                ['leona'] = true,
                ['lissandra'] = true,
                ['lucian'] = true,
                ['lulu'] = true,
                ['lux'] = true,
                ['malphite'] = true,
                ['malzahar'] = true,
                ['maokai'] = true,
                ['masteryi'] = true,
                ['missfortune'] = true,
                ['monkeyking'] = true,
                ['mordekaiser'] = true,
                ['morgana'] = true,
                ['nami'] = true,
                ['nasus'] = true,
                ['nautilus'] = true,
                ['neeko'] = true,
                ['nidalee'] = true,
                ['nocturne'] = true,
                ['nunu'] = true,
                ['olaf'] = true,
                ['orianna'] = true,
                ['ornn'] = true,
                ['pantheon'] = true,
                ['poppy'] = true,
                ['pyke'] = true,
                ['qiyana'] = true,
                ['quinn'] = true,
                ['rakan'] = true,
                ['rammus'] = true,
                ['reksai'] = true,
                ['renekton'] = true,
                ['rengar'] = true,
                ['riven'] = true,
                ['rumble'] = true,
                ['ryze'] = true,
                ['sejuani'] = true,
                ['shaco'] = true,
                ['shen'] = true,
                ['shyvana'] = true,
                ['singed'] = true,
                ['sion'] = true,
                ['sivir'] = true,
                ['skarner'] = true,
                ['sona'] = true,
                ['soraka'] = true,
                ['swain'] = true,
                ['sylas'] = true,
                ['syndra'] = true,
                ['tahmkench'] = true,
                ['taliyah'] = true,
                ['talon'] = true,
                ['taric'] = true,
                ['teemo'] = true,
                ['thresh'] = true,
                ['tristana'] = true,
                ['trundle'] = true,
                ['tryndamere'] = true,
                ['twistedfate'] = true,
                ['twitch'] = true,
                ['udyr'] = true,
                ['urgot'] = true,
                ['varus'] = true,
                ['vayne'] = true,
                ['veigar'] = true,
                ['velkoz'] = true,
                ['vi'] = true,
                ['viktor'] = true,
                ['vladimir'] = true,
                ['volibear'] = true,
                ['warwick'] = true,
                ['xayah'] = true,
                ['xerath'] = true,
                ['xinzhao'] = true,
                ['yasuo'] = true,
                ['yorick'] = true,
                ['yuumi'] = true,
                ['zac'] = true,
                ['zed'] = true,
                ['ziggs'] = true,
                ['zilean'] = true,
                ['zoe'] = true,
                ['zyra'] = true,
            },
        }
        
        function AIO.Object:Start()
            for i = 1, Game.ObjectCount() do
                local object = Game.Object(i)
                if object then
                    local type = object.type
                    if type == Obj_AI_Barracks or type == Obj_AI_Nexus then
                        if object.isEnemy then
                            table.insert(self.EnemyBuildings, object)
                        elseif object.isAlly then
                            table.insert(self.AllyBuildings, object)
                        end
                    end
                end
            end
            AIO.Action:Add(function()
                local success = false
                for i = 1, Game.HeroCount() do
                    local args = self:GetHeroData(Game.Hero(i))
                    if args.valid and args.isAlly and self.AllyHeroesInGame[args.networkID] == nil then
                        self.AllyHeroesInGame[args.networkID] = true
                        for j, func in pairs(self.AllyHeroCb) do
                            func(args)
                        end
                    end
                    if args.valid and args.isEnemy and self.EnemyHeroesInGame[args.networkID] == nil then
                        self.EnemyHeroesInGame[args.networkID] = true
                        for j, func in pairs(self.EnemyHeroCb) do
                            func(args)
                        end
                        success = true
                    end
                end
                return success
            end, 0, 100)
        end
        
        function AIO.Object:GetHeroData(obj)
            if obj == nil then
                return {}
            end
            local id = obj.networkID
            if id == nil or id <= 0 then
                return {}
            end
            local name = obj.charName
            if name == nil or self.HeroNames[name:lower()] == nil then
                return {}
            end
            local Team = obj.team
            local IsEnemy = obj.isEnemy
            local IsAlly = obj.isAlly
            if Team == nil or Team < 100 or Team > 200 or IsEnemy == nil or IsAlly == nil or IsEnemy == IsAlly then
                return {}
            end
            return
            {
                valid = true,
                isEnemy = IsEnemy,
                isAlly = IsAlly,
                networkID = id,
                charName = name,
                team = Team,
            }
        end
        
        function AIO.Object:OnAllyHeroLoad
            (cb)
            table.insert(self.AllyHeroCb, cb)
        end
        
        function AIO.Object:OnEnemyHeroLoad
            (cb)
            table.insert(self.EnemyHeroCb, cb)
        end
    end
end

class "Kaisa"
do
    local NextTick = GetTickCount()
    
    function Kaisa:__init()
        self.WData = {Type = _G.SPELLTYPE_LINE, Delay = 0.4, Radius = 100, Range = 3000, Speed = 1750, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}}
        self:LoadMenu()
        Callback.Add("Tick", function() self:Tick() end)
        Callback.Add("Draw", function() self:Draw() end)
    end
    
    function Kaisa:LoadMenu()
        Menu = MenuElement({type = MENU, id = "KaisaByTy", name = "Kaisa"})
        --combo
        Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
        Menu.Combo:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(args) Menu.Combo.useon:MenuElement({id = args.charName, name = args.charName, value = true}) end)
        Menu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
        Menu.Combo:MenuElement({id = "UseW", name = "[W]", value = true})
        --Auto
        Menu:MenuElement({type = MENU, id = "Auto", name = "Auto"})
        Menu.Auto:MenuElement({id = "UseQ", name = "[Q]", value = true})
        --Draw
        Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
        Menu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
        Menu.Drawing:MenuElement({type = MENU, id = "QColor", name = "Q Range Color"})
        Menu.Drawing.QColor:MenuElement({id = "T", name = "Transparency ", value = 255, min = 0, max = 255, step = 1})
        Menu.Drawing.QColor:MenuElement({id = "R", name = "Red ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.QColor:MenuElement({id = "G", name = "Grean ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.QColor:MenuElement({id = "B", name = "Blue ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing:MenuElement({id = "W", name = "Draw [W] Range", value = true})
        Menu.Drawing:MenuElement({type = MENU, id = "WColor", name = "W Range Color"})
        Menu.Drawing.WColor:MenuElement({id = "T", name = "Transparency ", value = 255, min = 0, max = 255, step = 1})
        Menu.Drawing.WColor:MenuElement({id = "R", name = "Red ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.WColor:MenuElement({id = "G", name = "Grean ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.WColor:MenuElement({id = "B", name = "Blue ", value = 150, min = 0, max = 255, step = 1})
    end
    
    function Kaisa:Draw()
        if myHero.dead then
            return
        end
        
        if Menu.Drawing.Q:Value() then
            Draw.Circle(myHero.pos, 600, Draw.Color(Menu.Drawing.QColor.T:Value(), Menu.Drawing.QColor.R:Value(), Menu.Drawing.QColor.G:Value(), Menu.Drawing.QColor.B:Value()))
        end
        
        if Menu.Drawing.W:Value() and Ready(_W) then
            
            Draw.Circle(myHero.pos, 3000, Draw.Color(Menu.Drawing.WColor.T:Value(), Menu.Drawing.WColor.R:Value(), Menu.Drawing.WColor.G:Value(), Menu.Drawing.WColor.B:Value()))
        end
    end
    
    function Kaisa:Tick()
        if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
            return
        end
        
        if NextTick > GetTickCount() then return end
        ORB:SetMovement(true)
        ORB:SetAttack(true)
        
        if ORB.Modes[0] then --combo
            self:Combo()
        end
        self:AutoQ()
    end
    
    function Kaisa:Combo()
        if Menu.Combo.UseQ:Value() and Ready(_Q) then
            self:CastQ()
        end
        
        local EnemyHeroes = OB:GetEnemyHeroes(3000, false)
        local targetList = {}
        
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            local heroName = hero.charName
            if Menu.Combo.useon[heroName] and Menu.Combo.useon[heroName]:Value() then
                targetList[#targetList + 1] = hero
            end
        end
        
        local target = TS:GetTarget(targetList)
        if target and IsValid(target) then
            if Menu.Combo.UseW:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) <= 3000 then
                local Pred = GetGamsteronPrediction(target, self.WData, myHero)
                if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                    NextTick = GetTickCount() + 500
                    ORB:SetMovement(false)
                    ORB:SetAttack(false)
                    Control.CastSpell(HK_W, Pred.CastPosition)
                end
            end
        end
    end
    
    function Kaisa:CastQ()
        local EnemyHeroes = OB:GetEnemyHeroes(600, false)
        local targetList = {}
        
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            local heroName = hero.charName
            if Menu.Combo.useon[heroName] and Menu.Combo.useon[heroName]:Value() then
                targetList[#targetList + 1] = hero
            end
        end
        
        local target = TS:GetTarget(targetList)
        if target and IsValid(target) then
            if myHero.pos:DistanceTo(target.pos) <= 600 then
                NextTick = GetTickCount() + 100
                Control.CastSpell(HK_Q)
            end
        end
    end
    
    function Kaisa:AutoQ()
        if Menu.Auto.UseQ:Value() and Ready(_Q) then
            self:CastQ()
        end
    end
end

class "Sivir"
do
    local NextTick = GetTickCount()
    
    function Sivir:__init()
        self.version = 0.04
        self.shellSpells = {
            ["NautilusRavageStrikeAttack"] = {charName = "Nautilus", slot = "Passive"},
            ["RekSaiWUnburrowLockout"] = {charName = "RekSai", slot = "W"},
            ["SkarnerPassiveAttack"] = {charName = "Skarner", slot = "E Passive"},
            ["WarwickRChannel"] = {charName = "Warwick", slot = "R"}, -- need test
            ["XinZhaoQThrust3"] = {charName = "XinZhao", slot = "Q3"},
            ["VolibearQAttack"] = {charName = "Volibear", slot = "Q"},
            ["LeonaShieldOfDaybreakAttack"] = {charName = "Leona", slot = "Q"},
            ["GoldCardPreAttack"] = {charName = "TwistedFate", slot = "GoldW"},
            ["PowerFistAttack"] = {charName = "Blitzcrank", slot = "E"},
            
            ["Frostbite"] = {charName = "Anivia", slot = "E", delay = 0.25, speed = 1600, isMissile = true},
            ["AnnieQ"] = {charName = "Annie", slot = "Q", delay = 0.25, speed = 1400, isMissile = true},
            ["BrandE"] = {charName = "Brand", slot = "E", delay = 0.25, speed = math.huge, isMissile = false},
            ["BrandR"] = {charName = "Brand", slot = "R", delay = 0.25, speed = 1000, isMissile = true}, -- to be comfirm brand R delay 0.25 or 0.5
            ["CassiopeiaE"] = {charName = "Cassiopeia", slot = "E", delay = 0.15, speed = 2500, isMissile = true}, -- delay to be comfirm
            ["CamilleR"] = {charName = "Camille", slot = "R", delay = 0.5, speed = math.huge, isMissile = false}, -- delay to be comfirm
            ["Feast"] = {charName = "Chogath", slot = "R", delay = 0.25, speed = math.huge, isMissile = false},
            ["DariusExecute"] = {charName = "Darius", slot = "R", delay = 0.25, speed = math.huge, isMissile = false}, -- delay to be comfirm
            ["EliseHumanQ"] = {charName = "Elise", slot = "Q1", delay = 0.25, speed = 2200, isMissile = true},
            ["EliseSpiderQCast"] = {charName = "Elise", slot = "Q2", delay = 0.25, speed = math.huge, isMissile = false},
            ["Terrify"] = {charName = "FiddleSticks", slot = "Q", delay = 0.25, speed = math.huge, isMissile = false},
            ["FiddlesticksDarkWind"] = {charName = "FiddleSticks", slot = "E", delay = 0.25, speed = 1100, isMissile = true},
            ["GangplankQProceed"] = {charName = "Gangplank", slot = "Q", delay = 0.25, speed = 2600, isMissile = true},
            ["GarenQAttack"] = {charName = "Garen", slot = "Q", delay = 0.25, speed = math.huge, isMissile = false},
            ["GarenR"] = {charName = "Garen", slot = "E", delay = 0.25, speed = math.huge, isMissile = false},
            ["SowTheWind"] = {charName = "Janna", slot = "W", delay = 0.25, speed = 1600, isMissile = true},
            ["JarvanIVCataclysm"] = {charName = "JarvanIV", slot = "R", delay = 0.25, speed = math.huge, isMissile = false},
            ["JayceToTheSkies"] = {charName = "Jayce", slot = "Q2", delay = 0.25, speed = math.huge, isMissile = false}, -- seems speed base on distance, lazy to find the forumla , maybe fixed delay
            ["JayceThunderingBlow"] = {charName = "Jayce", slot = "E2", delay = 0.25, speed = math.huge, isMissile = false},
            ["KatarinaQ"] = {charName = "Katarina", slot = "Q", delay = 0.25, speed = 1600, isMissile = true},
            ["KatarinaE"] = {charName = "Katarina", slot = "E", delay = 0.1, speed = math.huge, isMissile = false}, -- delay to be comfirm
            ["NullLance"] = {charName = "Kassadin", slot = "Q", delay = 0.25, speed = 1400, isMissile = true},
            ["KhazixQ"] = {charName = "Khazix", slot = "Q1", delay = 0.25, speed = math.huge, isMissile = false},
            ["KhazixQLong"] = {charName = "Khazix", slot = "Q2", delay = 0.25, speed = math.huge, isMissile = false},
            ["BlindMonkRKick"] = {charName = "LeeSin", slot = "R", delay = 0.25, speed = math.huge, isMissile = false},
            ["LeblancQ"] = {charName = "Leblanc", slot = "Q", delay = 0.25, speed = 2000, isMissile = true},
            ["LeblancRQ"] = {charName = "Leblanc", slot = "RQ", delay = 0.25, speed = 2000, isMissile = true},
            ["LissandraREnemy"] = {charName = "Lissandra", slot = "R", delay = 0.5, speed = math.huge, isMissile = false},
            ["LucianQ"] = {charName = "Lucian", slot = "Q", delay = 0.25, speed = math.huge, isMissile = false}, --  delay = 0.4 − 0.25 (based on level)
            ["LuluWTwo"] = {charName = "Lulu", slot = "W", delay = 0.25, speed = 2250, isMissile = true},
            ["SeismicShard"] = {charName = "Malphite", slot = "Q", delay = 0.25, speed = 1200, isMissile = true},
            ["MalzaharE"] = {charName = "Malzahar", slot = "E", delay = 0.25, speed = math.huge, isMissile = false},
            ["MalzaharR"] = {charName = "Malzahar", slot = "R", delay = 0, speed = math.huge, isMissile = false},
            ["AlphaStrike"] = {charName = "MasterYi", slot = "Q", delay = 0, speed = math.huge, isMissile = false},
            ["MissFortuneRicochetShot"] = {charName = "MissFortune", slot = "Q", delay = 0.25, speed = 1400, isMissile = true},
            ["NasusW"] = {charName = "Nasus", slot = "W", delay = 0.25, speed = math.huge, isMissile = false},
            ["NautilusGrandLine"] = {charName = "Nautilus", slot = "R", delay = 0.5, speed = 1400, isMissile = true}, -- delay to be comfirm
            ["NunuQ"] = {charName = "Nunu", slot = "Q", delay = 0.25, speed = math.huge, isMissile = false},
            ["OlafRecklessStrike"] = {charName = "Olaf", slot = "E", delay = 0.25, speed = math.huge, isMissile = false},
            ["PantheonQ"] = {charName = "Pantheon", slot = "Q", delay = 0.25, speed = 1500, isMissile = true},
            ["RekSaiE"] = {charName = "RekSai", slot = "E", delay = 0.25, speed = math.huge, isMissile = false},
            ["RekSaiR"] = {charName = "RekSai", slot = "R", delay = 1.5, speed = math.huge, isMissile = false},
            ["PuncturingTaunt"] = {charName = "Rammus", slot = "E", delay = 0.25, speed = math.huge, isMissile = false},
            ["RenektonExecute"] = {charName = "Renekton", slot = "W1", delay = 0.25, speed = math.huge, isMissile = false},
            ["RenektonSuperExecute"] = {charName = "Renekton", slot = "W2", delay = 0.25, speed = math.huge, isMissile = false},
            ["RyzeW"] = {charName = "Ryze", slot = "W", delay = 0.25, speed = math.huge, isMissile = false},
            ["RyzeE"] = {charName = "Ryze", slot = "E", delay = 0.25, speed = 3500, isMissile = true},
            ["Fling"] = {charName = "Singed", slot = "E", delay = 0.25, speed = math.huge, isMissile = false},
            ["SyndraR"] = {charName = "Syndra", slot = "R", delay = 0.25, speed = 1400, isMissile = true},
            ["TwoShivPoison"] = {charName = "Shaco", slot = "E", delay = 0.25, speed = 1500, isMissile = true},
            ["SkarnerImpale"] = {charName = "Skarner", slot = "R", delay = 0.25, speed = math.huge, isMissile = false},
            ["TahmKenchW"] = {charName = "TahmKench", slot = "W", delay = 0.25, speed = math.huge, isMissile = false},
            ["TalonQAttack"] = {charName = "Talon", slot = "Q1", delay = 0.25, speed = math.huge, isMissile = false},
            ["BlindingDart"] = {charName = "Teemo", slot = "Q", delay = 0.25, speed = 1500, isMissile = true},
            ["TristanaR"] = {charName = "Tristana", slot = "R", delay = 0.25, speed = 2000, isMissile = true},
            ["TrundlePain"] = {charName = "Trundle", slot = "R", delay = 0.25, speed = math.huge, isMissile = false},
            ["ViR"] = {charName = "Vi", slot = "R", delay = 0.25, speed = 800, isMissile = false},
            ["VayneCondemn"] = {charName = "Vayne", slot = "E", delay = 0.25, speed = 2200, isMissile = true},
            ["VolibearW"] = {charName = "Volibear", slot = "W", delay = 0.25, speed = math.huge, isMissile = true},
            ["VeigarR"] = {charName = "Veigar", slot = "R", delay = 0.25, speed = 500, isMissile = true},
            ["VladimirQ"] = {charName = "Vladimir", slot = "Q", delay = 0.25, speed = math.huge, isMissile = false},
        }
        self.missileData = {
            ["RocketGrabMissile"] = {charName = "Blitzcrank", slot = "Q"},
            ["ThreshQMissile"] = {charName = "Blitzcrank", slot = "Q"},
        }
        self:CreateMenu()
        Callback.Add("Draw", function() self:Draw() end)
    end
    
    function Sivir:CreateMenu()
        Menu = MenuElement({type = MENU, id = "SivirByTy", name = "Sivir E"})
        Menu:MenuElement({type = MENU, id = "spell", name = "Spells"})
        Menu:MenuElement({type = MENU, id = "dash", name = "track dash on"})
        AIO.Object:OnEnemyHeroLoad(function(args)
            for k, v in pairs(self.shellSpells) do
                if v.charName == args.charName then
                    Menu.spell:MenuElement({id = k, name = v.charName.." | "..v.slot, value = true})
                end
            end
        end)
        AIO.Object:OnEnemyHeroLoad(function(args)
            Menu.dash:MenuElement({id = args.charName, name = args.charName, value = false})
        end)
    end
    
    function Sivir:Draw()
        if NextTick > GetTickCount() then return end
        
        local EnemyHeroes = OB:GetEnemyHeroes(2800, false)
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            if hero.activeSpell.valid and self.shellSpells[hero.activeSpell.name] ~= nil then
                if hero.activeSpell.target == myHero.handle and Menu.spell[hero.activeSpell.name]:Value() then
                    Control.CastSpell(HK_E)
                    NextTick = GetTickCount() + 250
                    return
                end
                
            end
            
            if hero.pathing.isDashing and Menu.dash[hero.charName]:Value() then
                local vct = Vector(hero.pathing.endPos.x, hero.pathing.endPos.y, hero.pathing.endPos.z)
                print("dash"..hero.charName)
                print(vct:DistanceTo(myHero.pos))
                if vct:DistanceTo(myHero.pos) < 172 then
                    print("Use E on"..ally.charName)
                    Control.CastSpell(HK_E)
                    NextTick = GetTickCount() + 250
                    return
                end
                
            end
        end
        --[[
        for i = 1, GameMissileCount() do
            local missile = GameMissile(i)
 
            if(missile.self.missileData.owner > 0) and missile.pos:DistanceTo()<1500 and missile.self.missileData.name:find("ThreshQMissile") then
                --local vctstart = Vector(missile.self.missileData.startPos.x,missile.self.missileData.startPos.y,missile.self.missileData.startPos.z)
                --local vctend = Vector(missile.self.missileData.endPos.x,missile.self.missileData.endPos.y,missile.self.missileData.endPos.z)
                print("Distance"..missile.pos:DistanceTo())
                Draw.Circle(missile.pos,missile.self.missileData.width);
                --Draw.Circle(vctstart,missile.self.missileData.width);
                --Draw.Circle(vctend,missile.self.missileData.width);
                --print("bd"..myHero.boundingRadius)
 
                print("Name: "..missile.self.missileData.name)
                print(missile.self.missileData.width)
                local dis = 0.25 * missile.self.missileData.speed
                print ("dis"..dis)
                local AllyHeroes = OB:GetAllyHeroes(800)
                for i = 1, #AllyHeroes do
                    local ally = AllyHeroes[i]
                    if missile.pos:DistanceTo(ally.pos)+ally.boundingRadius < missile.self.missileData.width + dis  and Menu.ally[ally.charName]:Value() then
 
                        print("Use E on"..ally.charName)
                        Control.CastSpell(HK_E, ally)
                        print("dd"..missile.pos:DistanceTo(ally.pos)+ally.boundingRadius)
                        print("range"..missile.self.missileData.width +dis)
                        NextTick = GetTickCount()  + 1000
                    end
                end
            end
        end
    --]]
    end
end

class "Amumu"
do
    local NextTick = GetTickCount()
    
    function Amumu:__init()
        self.lineQ = nil
        self.QData = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 80, Range = 1100, Speed = 2000, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}}
        self:LoadMenu()
        Callback.Add("Tick", function() self:Tick() end)
        Callback.Add("Draw", function() self:Draw() end)
    end
    
    function Amumu:LoadMenu()
        Menu = MenuElement({type = MENU, id = "AmumuByTy", name = "14 Amumu"})
        --combo
        Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
        Menu.Combo:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(args) Menu.Combo.useon:MenuElement({id = args.charName, name = args.charName, value = true}) end)
        Menu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
        Menu.Combo:MenuElement({id = "UseE", name = "[E]", value = true})
        Menu.Combo:MenuElement({id = "UseR", name = "[R]", value = true})
        Menu.Combo:MenuElement({id = "Count", name = "When Can Hit X Enemies ", value = 2, min = 1, max = 5, step = 1})
        --Harass
        Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
        Menu.Harass:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(args) Menu.Harass.useon:MenuElement({id = args.charName, name = args.charName, value = true}) end)
        Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
        --wave clean
        Menu:MenuElement({type = MENU, id = "WaveClean", name = "Wave Clean (span E No checking for minion)"})
        Menu.WaveClean:MenuElement({id = "UseE", name = "E", value = true})
        --Auto
        Menu:MenuElement({type = MENU, id = "Auto", name = "Auto"})
        Menu.Auto:MenuElement({id = "UseR", name = "[R]", value = true})
        Menu.Auto:MenuElement({id = "Count", name = "When Can Hit X Enemies ", value = 3, min = 1, max = 5, step = 1})
        --Draw
        Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
        Menu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
        Menu.Drawing:MenuElement({type = MENU, id = "QColor", name = "Q Range Color"})
        Menu.Drawing.QColor:MenuElement({id = "T", name = "Transparency ", value = 255, min = 0, max = 255, step = 1})
        Menu.Drawing.QColor:MenuElement({id = "R", name = "Red ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.QColor:MenuElement({id = "G", name = "Grean ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.QColor:MenuElement({id = "B", name = "Blue ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing:MenuElement({id = "E", name = "Draw [E] Range", value = true})
        Menu.Drawing:MenuElement({type = MENU, id = "EColor", name = "E Range Color"})
        Menu.Drawing.EColor:MenuElement({id = "T", name = "Transparency ", value = 255, min = 0, max = 255, step = 1})
        Menu.Drawing.EColor:MenuElement({id = "R", name = "Red ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.EColor:MenuElement({id = "G", name = "Grean ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.EColor:MenuElement({id = "B", name = "Blue ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing:MenuElement({id = "R", name = "Draw [R] Range", value = true})
        Menu.Drawing:MenuElement({type = MENU, id = "RColor", name = "R Range Color"})
        Menu.Drawing.RColor:MenuElement({id = "T", name = "Transparency ", value = 255, min = 0, max = 255, step = 1})
        Menu.Drawing.RColor:MenuElement({id = "R", name = "Red ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.RColor:MenuElement({id = "G", name = "Grean ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.RColor:MenuElement({id = "B", name = "Blue ", value = 150, min = 0, max = 255, step = 1})
    end
    
    function Amumu:Draw()
        if myHero.dead then
            return
        end
        
        if Menu.Drawing.Q:Value() and Ready(_Q) then
            Draw.Circle(myHero.pos, 1100, Draw.Color(Menu.Drawing.QColor.T:Value(), Menu.Drawing.QColor.R:Value(), Menu.Drawing.QColor.G:Value(), Menu.Drawing.QColor.B:Value()))
        end
        
        if Menu.Drawing.E:Value() and Ready(_E) then
            Draw.Circle(myHero.pos, 350, Draw.Color(Menu.Drawing.EColor.T:Value(), Menu.Drawing.EColor.R:Value(), Menu.Drawing.EColor.G:Value(), Menu.Drawing.EColor.B:Value()))
        end
        
        if Menu.Drawing.R:Value() and Ready(_R) then
            Draw.Circle(myHero.pos, 550, Draw.Color(Menu.Drawing.RColor.T:Value(), Menu.Drawing.RColor.R:Value(), Menu.Drawing.RColor.G:Value(), Menu.Drawing.RColor.B:Value()))
        end
    end
    
    function Amumu:Tick()
        if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
            return
        end
        
        self:AutoR()
        if NextTick > GetTickCount() then return end
        ORB:SetMovement(true)
        if ORB.Modes[0] then --combo
            self:Combo()
        elseif ORB.Modes[1] then --harass
            self:Harass()
        elseif ORB.Modes[2] then --harass
            self:WaveClean()
        end
    end
    
    function Amumu:Combo()
        local EnemyHeroes = OB:GetEnemyHeroes(1100, false)
        local targetList = {}
        
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            local heroName = hero.charName
            if Menu.Combo.useon[heroName] and Menu.Combo.useon[heroName]:Value() then
                targetList[#targetList + 1] = hero
            end
        end
        local target = TS:GetTarget(targetList)
        if target == nil then return end
        
        if IsValid(target) then
            if Menu.Combo.UseQ:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) <= 1100 then
                
                local Pred = GetGamsteronPrediction(target, self.QData, myHero)
                if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                    NextTick = GetTickCount() + 250
                    ORB:SetMovement(false)
                    Control.CastSpell(HK_Q, Pred.CastPosition)
                end
            end
            
            if Menu.Combo.UseE:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= 350 then
                local delayPos = target:GetPrediction(target.ms, 0.25)
                if delayPos:DistanceTo(myHero.pos) <= 350 then
                    Control.CastSpell(HK_E)
                end
            end
            
            if Menu.Combo.UseR:Value() and Ready(_R) then
                self:CastR(Menu.Combo.Count:Value())
            end
        end
        
    end
    
    function Amumu:Harass()
        local EnemyHeroes = OB:GetEnemyHeroes(1100, false)
        local targetList = {}
        
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            local heroName = hero.charName
            if Menu.Harass.useon[heroName] and Menu.Harass.useon[heroName]:Value() then
                targetList[#targetList + 1] = hero
            end
        end
        local target = TS:GetTarget(targetList)
        if target == nil then return end
        
        if IsValid(target) then
            
            if Menu.Harass.UseQ:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) <= 1100 then
                local Pred = GetGamsteronPrediction(target, self.QData, myHero)
                if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                    self.lineQ = LineSegment(Pred.CastPosition, Pred.CastPosition:Extended(myHero.pos, myHero.pos:DistanceTo(target.pos)))
                    NextTick = GetTickCount() + 250
                    ORB:SetMovement(false)
                    Control.CastSpell(HK_Q, Pred.CastPosition)
                end
            end
            
        end
        
    end
    
    function Amumu:WaveClean()
        if Menu.WaveClean.UseE:Value() and Ready(_E) then
            Control.CastSpell(HK_E)
        end
    end
    
    function Amumu:CastR(number)
        local count = 0
        
        local EnemyHeroes = OB:GetEnemyHeroes()
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            local delayPos = hero:GetPrediction(hero.ms, 0.25)
            if delayPos:DistanceTo(myHero.pos) <= 550 then
                count = count + 1
            end
        end
        
        if count >= number then
            Control.CastSpell(HK_R)
        end
    end
    
    function Amumu:AutoR()
        if Menu.Auto.UseR:Value() and Ready(_R) then
            self:CastR(Menu.Auto.Count:Value())
        end
    end
end

class "Khazix"
do
    local lastCursor = nil
    local NextTick = GetTickCount()
    
    function Khazix:__init()
        self.QData = {Range = 325}
        self.WData = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 70, Range = 1000, Speed = 1650, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}}
        self.EData = {Type = _G.SPELLTYPE_CIRCLE, Delay = 0, Radius = 270, Range = 700, Speed = 1000, Collision = false}
        
        self:LoadMenu()
        Callback.Add("Tick", function() self:Tick() end)
        Callback.Add("Draw", function() self:Draw() end)
    end
    
    function Khazix:LoadMenu()
        Menu = MenuElement({type = MENU, id = "KhazixByTy", name = "Khazix"})
        --combo
        Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
        Menu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
        Menu.Combo:MenuElement({id = "UseW", name = "[W]", value = true})
        Menu.Combo:MenuElement({id = "UseE", name = "[E]", value = true})
        --jungle
        Menu:MenuElement({type = MENU, id = "Jungle", name = "Jungle"})
        Menu.Jungle:MenuElement({id = "UseQ", name = "[Q]", value = true})
        Menu.Jungle:MenuElement({id = "UseW", name = "[W]", value = true})
        --Draw
        Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
        Menu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
        Menu.Drawing:MenuElement({id = "W", name = "Draw [W] Range", value = true})
        Menu.Drawing:MenuElement({id = "E", name = "Draw [E] Range", value = true})
    end
    
    function Khazix:Draw()
        if myHero.dead then
            return
        end
        
        --Draw.Circle(Game.mousePos(), 300,Draw.Color(80 ,0xFF,0xFF,0xFF))
        
        if Menu.Drawing.Q:Value() and Ready(_Q) then
            Draw.Circle(myHero.pos, self.QData.Range, Draw.Color(80, 0xFF, 0xFF, 0xFF))
        end
        
        if Menu.Drawing.W:Value() and Ready(_W) then
            Draw.Circle(myHero.pos, self.WData.Range, Draw.Color(80, 0xFF, 0xFF, 0xFF))
        end
        
        if Menu.Drawing.E:Value() and Ready(_E) then
            Draw.Circle(myHero.pos, self.EData.Range, Draw.Color(80, 0xFF, 0xFF, 0xFF))
        end
    end
    
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
        if Menu.Combo.UseQ:Value() then
            local target = self:GetHeroTarget(self.QData.Range)
            if target ~= nil then
                self:CastQ(target)
            end
        end
        
        if Menu.Combo.UseW:Value() then
            local target = self:GetHeroTarget(self.WData.Range)
            if target ~= nil then
                self:CastW(target)
            end
        end
        
        if Menu.Combo.UseE:Value() then
            local target = self:GetHeroTarget(self.EData.Range)
            if target ~= nil then
                self:CastE(target)
            end
        end
    end
    
    function Khazix:Jungle()
        local target = ORB:GetTarget()
        if target ~= nil then
            if Menu.Jungle.UseQ:Value() and Ready(_Q) then
                self:CastQ(target)
                return
            end
            
            if Menu.Jungle.UseW:Value() and Ready(_W) and ORB:CanMove(myHero) then
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
end

class "Orianna"
do
    local ballPos = {pos = myHero.pos, ground = false, selfball = false, canW = true}
    local lastRTick = 0
    local lastQTick = 0
    local lastEWTick = 0
    
    function Orianna:__init()
        self.QData = {
            Type = _G.SPELLTYPE_LINE,
            Delay = 0, Radius = 130,
            Range = 1250, Speed = 1400,
            Collision = true,
            MaxCollision = 0,
            CollisionTypes = {_G.COLLISION_YASUOWALL},
            UseBoundingRadius = true
            
        }
        self.WData = {
            Radius = 225
        }
        self.EData = {
            Delay = 0,
            Radius = 130,
            Range = 1100,
            Speed = 1850
        }
        self.RData = {
            Delay = 0.75,
            Radius = 370
        }
        
        self:LoadMenu()
        
        Callback.Add("Tick", function() self:Tick() end)
        Callback.Add("Draw", function() self:Draw() end)
    end
    
    function Orianna:LoadMenu()
        Menu = MenuElement({type = MENU, id = "14", name = "14Orianna"})
        Menu:MenuElement({type = MENU, id = "combo", name = "Combo"})
        Menu.combo:MenuElement({id = "UseQ", name = "Q", value = true})
        Menu.combo:MenuElement({id = "UseW", name = "W", value = false})
        Menu.combo:MenuElement({id = "UseE", name = "E", value = true})
        Menu.combo:MenuElement({id = "UseR", name = "R", value = true})
        Menu.combo:MenuElement({id = "Rmax", name = "Only Use R if taret HP < X % ", value = 50, min = 0, max = 100, step = 1})
        Menu.combo:MenuElement({id = "Rmin", name = "Only Use R if taret HP > X % ", value = 10, min = 0, max = 100, step = 1})
        Menu.combo:MenuElement({name = "Use R on:", id = "useon", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(args) Menu.AutoQ.useon:MenuElement({id = args.charName, name = args.charName, value = true}) end)
        Menu:MenuElement({type = MENU, id = "harass", name = "Harass"})
        Menu.harass:MenuElement({id = "UseQ", name = "Q", value = true})
        Menu:MenuElement({type = MENU, id = "AutoQ", name = "Auto Q"})
        Menu.AutoQ:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(args) Menu.AutoQ.useon:MenuElement({id = args.charName, name = args.charName, value = true}) end)
        Menu.AutoQ:MenuElement({id = "UseQ", name = "Q", value = true})
        Menu:MenuElement({type = MENU, id = "AutoR", name = "Auto R"})
        Menu.AutoR:MenuElement({id = "Count", name = "When Can Hit X Enemies ", value = 3, min = 1, max = 5, step = 1})
        Menu:MenuElement({type = MENU, id = "AutoW", name = "Auto W"})
        Menu.AutoW:MenuElement({id = "Count", name = "When Can Hit X Enemies ", value = 2, min = 1, max = 5, step = 1})
        Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
        Menu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
        Menu.Drawing:MenuElement({type = MENU, id = "QColor", name = "Q Range Color"})
        Menu.Drawing.QColor:MenuElement({id = "T", name = "Transparency ", value = 255, min = 0, max = 255, step = 1})
        Menu.Drawing.QColor:MenuElement({id = "R", name = "Red ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.QColor:MenuElement({id = "G", name = "Grean ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.QColor:MenuElement({id = "B", name = "Blue ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing:MenuElement({id = "E", name = "Draw [E] Range", value = true})
        Menu.Drawing:MenuElement({type = MENU, id = "EColor", name = "E Range Color"})
        Menu.Drawing.EColor:MenuElement({id = "T", name = "Transparency ", value = 255, min = 0, max = 255, step = 1})
        Menu.Drawing.EColor:MenuElement({id = "R", name = "Red ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.EColor:MenuElement({id = "G", name = "Grean ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.EColor:MenuElement({id = "B", name = "Blue ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing:MenuElement({id = "ball", name = "Draw Ball Pos", value = true})
        Menu.Drawing:MenuElement({type = MENU, id = "BColor", name = "Ball Color"})
        Menu.Drawing.BColor:MenuElement({id = "T", name = "Transparency ", value = 255, min = 0, max = 255, step = 1})
        Menu.Drawing.BColor:MenuElement({id = "R", name = "Red ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.BColor:MenuElement({id = "G", name = "Grean ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.BColor:MenuElement({id = "B", name = "Blue ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing:MenuElement({id = "W", name = "Draw [W] Range", value = true})
        Menu.Drawing:MenuElement({type = MENU, id = "WColor", name = "W Range Color"})
        Menu.Drawing.WColor:MenuElement({id = "T", name = "Transparency ", value = 255, min = 0, max = 255, step = 1})
        Menu.Drawing.WColor:MenuElement({id = "R", name = "Red ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.WColor:MenuElement({id = "G", name = "Grean ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.WColor:MenuElement({id = "B", name = "Blue ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing:MenuElement({id = "R", name = "Draw [R] Range", value = true})
        Menu.Drawing:MenuElement({type = MENU, id = "RColor", name = "R Range Color"})
        Menu.Drawing.RColor:MenuElement({id = "T", name = "Transparency ", value = 255, min = 0, max = 255, step = 1})
        Menu.Drawing.RColor:MenuElement({id = "R", name = "Red ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.RColor:MenuElement({id = "G", name = "Grean ", value = 150, min = 0, max = 255, step = 1})
        Menu.Drawing.RColor:MenuElement({id = "B", name = "Blue ", value = 150, min = 0, max = 255, step = 1})
    end
    
    function Orianna:Tick()
        if lastQTick + 50 < GetTickCount() then
            ORB:SetAttack(true)
            ORB:SetMovement(true)
        end
        
        self:LoadBallPos()
        
        if lastQTick + 150 > GetTickCount() then return end
        if lastRTick + 800 > GetTickCount() then return end
        if lastEWTick + 300 > GetTickCount() then return end
        
        ballPos.canW = true
        
        if ORB.Modes[0] then --combo
            self:Combo()
        elseif ORB.Modes[1] then --harass
            self:Harass()
        end
        
        self:AutoQ()
        self:AutoR()
        self:AutoW()
    end
    
    function Orianna:Draw()
        if ballPos.pos then
            if Menu.Drawing.ball:Value() then
                Draw.Circle(ballPos.pos, 133, Draw.Color(Menu.Drawing.BColor.T:Value(), Menu.Drawing.BColor.R:Value(), Menu.Drawing.BColor.G:Value(), Menu.Drawing.BColor.B:Value()))
            end
            if Menu.Drawing.W:Value() and Ready(_W) then
                Draw.Circle(ballPos.pos, self.WData.Radius, Draw.Color(Menu.Drawing.WColor.T:Value(), Menu.Drawing.WColor.R:Value(), Menu.Drawing.WColor.G:Value(), Menu.Drawing.WColor.B:Value()))
            end
            if Menu.Drawing.R:Value() and Ready(_R) then
                Draw.Circle(ballPos.pos, self.RData.Radius, Draw.Color(Menu.Drawing.RColor.T:Value(), Menu.Drawing.RColor.R:Value(), Menu.Drawing.RColor.G:Value(), Menu.Drawing.RColor.B:Value()))
            end
        end
        if Menu.Drawing.Q:Value() and Ready(_Q) then
            Draw.Circle(myHero.pos, 825, Draw.Color(Menu.Drawing.QColor.T:Value(), Menu.Drawing.QColor.R:Value(), Menu.Drawing.QColor.G:Value(), Menu.Drawing.QColor.B:Value()))
        end
        
        if Menu.Drawing.E:Value() and Ready(_E) then
            Draw.Circle(myHero.pos, self.EData.Range, Draw.Color(Menu.Drawing.EColor.T:Value(), Menu.Drawing.EColor.R:Value(), Menu.Drawing.EColor.G:Value(), Menu.Drawing.EColor.B:Value()))
        end
        --print(myHero.pos:DistanceTo(ballPos.pos))
    end
    
    function Orianna:Combo()
        local EnemyHeroes = OB:GetEnemyHeroes(self.QData.Range, false)
        
        local target = TS:GetTarget(EnemyHeroes)
        if target == nil then return end
        
        if IsValid(target) then
            if Menu.combo.UseQ:Value() then
                self:CastQ(target)
            end
            
            if Menu.combo.UseW:Value() and Ready(_W) and ballPos.pos:DistanceTo(target.pos) <= self.WData.Radius and ballPos.canW then
                --print("cast W")
                lastEWTick = GetTickCount()
                Control.CastSpell(HK_W)
            end
            --GetCollision = function(source (Object), castPos (Vector), predPos (Vector), speed (integer), delay (float (seconds)), radius (integer), collisionTypes (table), skipID (integer))
            
            if Menu.combo.UseE:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= self.EData.Range and myHero.pos:DistanceTo(ballPos.pos) > 10 then
                local isWall, collisionObjects, collisionCount = GetCollision(ballPos.pos, myHero.pos, myHero.pos, self.EData.speed, 0, 40, {_G.COLLISION_ENEMYHERO})
                
                if collisionCount >= 1 then
                    lastEWTick = GetTickCount()
                    Control.CastSpell(HK_E, myHero)
                    --print("cast E")
                    
                end
            end
            
            if Menu.combo.UseR:Value() and Ready(_R) and self:GetHP(target) <= Menu.combo.Rmax:Value() and self:GetHP(target) >= Menu.combo.Rmin:Value() then
                local delayPos = target:GetPrediction(target.ms, 0.75)
                if delayPos:DistanceTo(ballPos.pos) <= 370 then
                    lastRTick = GetTickCount()
                    Control.CastSpell(HK_R)
                    --print("cast R")
                    
                end
            end
        end
    end
    
    function Orianna:Harass()
        local EnemyHeroes = OB:GetEnemyHeroes(self.QData.Range, false)
        
        local target = TS:GetTarget(EnemyHeroes)
        if target == nil then return end
        
        if IsValid(target) then
            if Menu.harass.UseQ:Value() then
                self:CastQ(target)
            end
        end
    end
    
    function Orianna:AutoQ()
        local EnemyHeroes = OB:GetEnemyHeroes(self.QData.Range, false)
        local targetList = {}
        
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            local heroName = hero.charName
            if Menu.AutoQ.useon[heroName] and Menu.AutoQ.useon[heroName]:Value() then
                targetList[#targetList + 1] = hero
            end
        end
        local target = TS:GetTarget(targetList)
        if target == nil then return end
        
        if IsValid(target) then
            if Menu.AutoQ.UseQ:Value() then
                self:CastQ(target)
            end
        end
    end
    
    function Orianna:AutoW()
        if Ready(_W) and ballPos.canW then
            local count = 0
            local EnemyHeroes = OB:GetEnemyHeroes()
            for i = 1, #EnemyHeroes do
                local hero = EnemyHeroes[i]
                if hero.pos:DistanceTo(ballPos.pos) <= self.WData.Radius then
                    count = count + 1
                end
            end
            
            if count >= Menu.AutoW.Count:Value() then
                lastEWTick = GetTickCount()
                Control.CastSpell(HK_W)
                --print("Auo W")
                
            end
        end
    end
    
    function Orianna:AutoR()
        if Ready(_R) and ballPos.canW then
            local count = 0
            local EnemyHeroes = OB:GetEnemyHeroes()
            for i = 1, #EnemyHeroes do
                local hero = EnemyHeroes[i]
                local delayPos = hero:GetPrediction(hero.ms, 0.75)
                if delayPos:DistanceTo(ballPos.pos) <= 370 then
                    count = count + 1
                end
            end
            
            if count >= Menu.AutoR.Count:Value() then
                lastRTick = GetTickCount()
                Control.CastSpell(HK_R)
                --print("Auto R")
                
            end
        end
    end
    
    function Orianna:CastQ(target)
        if lastQTick + 100 > GetTickCount() then return end
        if Ready(_Q) and myHero.pos:DistanceTo(target.pos) <= self.QData.Range then
            local Pred = GetGamsteronPrediction(target, self.QData, ballPos)
            if Pred.Hitchance >= _G.HITCHANCE_HIGH
                and myHero.pos:DistanceTo(Pred.CastPosition) <= 825
                then
                lastQTick = GetTickCount()
                ORB:SetAttack(false)
                ORB:SetMovement(false)
                Control.CastSpell(HK_Q, Pred.CastPosition)
                ballPos.canW = false
                --print("cast Q")
                
            end
        end
    end
    
    function Orianna:LoadBallPos()
        for i = 1, GameMissileCount() do
            local missile = GameMissile(i)
            if missile.missileData.name == "OrianaIzuna" then
                --local vetor  = Vector(missile.missileData.endPos.x, missile.missileData.endPos.y, missile.missileData.endPos.z)
                local vetor = missile.pos
                ballPos.pos = vetor
                ballPos.ground = true
                ballPos.selfball = false
                ballPos.canW = false
            end
        end
        
        local EnemyHeroes = OB:GetAllyHeroes()
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            for i = 1, hero.buffCount do
                local buff = hero:GetBuff(i)
                if buff.name == "orianaghostself" or buff.name == "orianaghost" then
                    if buff.count > 0 then
                        ballPos.pos = hero.pos
                        ballPos.ground = false
                        ballPos.selfball = false
                    end
                end
            end
        end
        
        if ballPos.ground and myHero.pos:DistanceTo(ballPos.pos) <= 130 then
            
            ballPos.selfball = true
            ballPos.ground = false
        end
        
        if ballPos.ground and myHero.pos:DistanceTo(ballPos.pos) >= 1250 then
            ballPos.selfball = true
            ballPos.ground = false
        end
        
        if ballPos.selfball then
            ballPos.pos = myHero.pos
        end
    end
    
    function Orianna:GetHP(target)
        return target.health / target.maxHealth * 100
    end
end

class "Vi"
do
    local nextETime = 0
    local Version = 0.02
    local ScriptName = "Vi"
    
    function Vi:__init()
        self.QData = {Type = _G.SPELLTYPE_LINE, Delay = 0.1, Radius = 75, Range = 725, Speed = 1400, Collision = false, UseBoundingRadius = true}
        self.RData = {Range = 800}
        
        self.Qchannel = false
        self.Qtimer = GameTimer()
        
        self:LoadMenu()
        
        Callback.Add("Tick", function() self:Tick() end)
        Callback.Add("Draw", function() self:Draw() end)
        Callback.Add('WndMsg', function(...) self:WndMsg(...) end)
        
        ORB:OnPostAttackTick(function(...) self:OnPostAttackTick(...) end)
    end
    
    function Vi:LoadMenu()
        Menu = MenuElement({type = MENU, id = "bb", name = "Vi"})
        Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
        Menu.Combo:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(args) Menu.Combo.useon:MenuElement({id = args.charName, name = args.charName, value = true}) end)
        Menu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
        Menu.Combo:MenuElement({id = "Num", name = "min Q Range", value = 150, min = 0, max = 400})
        Menu.Combo:MenuElement({id = "UseE", name = "[E]", value = true})
        Menu:MenuElement({type = MENU, id = "WaveClear", name = "Wave Clear"})
        Menu.WaveClear:MenuElement({id = "UseE", name = "[E]", value = true})
        Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
        Menu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
        Menu.Drawing:MenuElement({id = "R", name = "Draw [R] Range", value = true})
        Menu.Drawing:MenuElement({id = "Num", name = "Draw min Q Range", value = true})
        Menu:MenuElement({name = "Author ", drop = {"ty01314"}})
    end
    
    function Vi:Draw()
        if myHero.dead then
            return
        end
        if Menu.Drawing.Q:Value() and Ready(_Q) then
            Draw.Circle(myHero.pos, 725, Draw.Color(255, 255, 162, 000))
        end
        if Menu.Drawing.R:Value() and Ready(_R) then
            Draw.Circle(myHero.pos, 800, Draw.Color(80, 0xFF, 0xFF, 0xFF))
        end
        if Menu.Drawing.Num:Value() and Ready(_Q) then
            Draw.Circle(myHero.pos, Menu.Combo.Num:Value(), Draw.Color(255, 255, 162, 000))
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
            if Menu.Combo.useon[heroName] and Menu.Combo.useon[heroName]:Value() then
                targetList[#targetList + 1] = hero
            end
        end
        
        local target = TS:GetTarget(targetList)
        if target == nil then return end
        
        if IsValid(target) then
            if Menu.Combo.UseQ:Value() and Ready(_Q) and self.Qchannel == false
                and myHero.pos:DistanceTo(target.pos) <= 625
                and myHero.pos:DistanceTo(target.pos) > Menu.Combo.Num:Value() then
                ControlKeyDown(HK_Q)
                self.Qchannel = true
                self.Qtimer = GameTimer()
            end
            
            if GameTimer() > self.Qtimer + 1.25 and GameTimer() < self.Qtimer + 6
                and self.Qchannel and Ready(_Q) and Menu.Combo.UseQ:Value() then
                local Pred = GetGamsteronPrediction(target, self.QData, myHero)
                if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                    Control.SetCursorPos(Pred.CastPosition)
                    ControlKeyUp(HK_Q)
                    self.Qchannel = false
                end
            end
        end
    end
    
    function Vi:OnPostAttackTick()
        if nextETime > GameTimer() then return end
        
        local target = ORB:GetTarget()
        
        if target == nil then return end
        
        if target.type == Obj_AI_Hero then
            if Menu.Combo.UseE:Value() and Ready(_E) then
                Control.CastSpell(HK_E)
                ORB:__OnAutoAttackReset()
                nextETime = GameTimer() + 0.2
            end
        elseif target.team == TEAM_JUNGLE then
            if Menu.WaveClear.UseE:Value() and Ready(_E) then
                Control.CastSpell(HK_E)
                ORB:__OnAutoAttackReset()
                nextETime = GameTimer() + 0.2
            end
        end
    end
    
    function Vi:Qmanager()
        for i = 1, myHero.buffCount do
            local buff = myHero:GetBuff(i)
            if buff.name == "ViQ" and buff.duration > 0 then
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
                self.Qtimer = GameTimer()
            end
        end
    end
end

class "Kennen"
do
    local Q = {delay = 0.2, range = 1050, speed = 1650, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/f/f5/Thundering_Shuriken.png"}
    local W = {range = 750, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/d/db/Electrical_Surge.png"}
    local E = {icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/7/76/Lightning_Rush.png"}
    local R = {range = 550, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/e/e9/Slicing_Maelstrom.png"}
    local Qdata = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 50, Range = 1050, Speed = 1650, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}}
    local items = {Zhonya = 3157, GLP800 = 3030, Protobelt01 = 3152}
    local ItemSlots = {ITEM_1, ITEM_2, ITEM_3, ITEM_4, ITEM_5, ITEM_6, ITEM_7}
    local ItemHotKeys = {HK_ITEM_1, HK_ITEM_2, HK_ITEM_3, HK_ITEM_4, HK_ITEM_5, HK_ITEM_6, HK_ITEM_7}
    
    local function GetNumberOfTableElements(table)
        local kkk = 0
        if table then
            if table[1] then
                for k, v in pairs(table) do
                    kkk = kkk + 1
                end
            end
        end
        return kkk
    end
    
    local function EnemiesNearMe(r)
        local r = r or 550
        local enemies = {}
        for i = 1, Game.HeroCount() do
            local hero = Game.Hero(i)
            if hero.isEnemy then
                if hero.distance <= r then
                    table.insert(enemies, hero)
                end
            end
        end
        return enemies
    end
    
    local function GetCD(x)
        return myHero:GetSpellData(x).currentCd
    end
    
    local function GetItemHotKey(item)
        for i = 1, 7 do
            if item == ItemSlots[i] then
                return ItemHotKeys[i]
            end
        end
    end
    
    local function GetItemSlot(itemID)
        local itemm
        for i = 1, 7 do
            local slot = ItemSlots[i]
            local item = myHero:GetItemData(slot)
            local foundItem = false
            if item.itemID == itemID and GetCD(slot) == 0 then
                itemm = slot
                foundItem = true
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
                if Game.CanUseSpell(_Q) == READY and who.distance <= Q.range then
                    local Pred = GetGamsteronPrediction(who, Qdata, myHero)
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
            if Game.CanUseSpell(_Q) == READY and who.distance <= Q.range then
                return true
            end
        end
        return false
    end
    
    local function GetMarks(hero)
        local stacks = 0
        if hero then
            for i = 1, hero.buffCount do
                local buff = hero:GetBuff(i)
                if buff.name == "kennenmarkofstorm" then
                    if buff.duration > 0 then
                        stacks = buff.count
                    end
                end
            end
        end
        return stacks
    end
    
    function Kennen:__init()
        require "DamageLib"
        self:CreateMenu()
        Callback.Add("Tick", function() self:Tick() end)
        print("External Kennen v.1.01 Loaded!")
    end
    
    function Kennen:CreateMenu()
        -- Menu
        Menu = MenuElement({type = MENU, id = "KennenByTy", name = "Kennen"})
        --Combo
        Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
        Menu.Combo:MenuElement({type = PARAM, id = "Q", name = "Use Q", value = true})
        Menu.Combo:MenuElement({type = PARAM, id = "W", name = "Use W", value = true})
        Menu.Combo:MenuElement({type = PARAM, id = "WS", name = "Only Stun with W", value = true})
        Menu.Combo:MenuElement({type = PARAM, id = "R", name = "Use R", value = true})
        Menu.Combo:MenuElement({type = PARAM, id = "RS", name = "Min. Enemies To Use Ult", value = 2, min = 1, max = 5, leftIcon = R.icon})
        --Harass
        Menu:MenuElement({type = MENU, id = "Harass", name = "Harass Menu"})
        Menu.Harass:MenuElement({type = PARAM, id = "Q", name = "Use Q", value = true})
        Menu.Harass:MenuElement({type = PARAM, id = "W", name = "Use W", value = true})
        Menu.Harass:MenuElement({type = PARAM, id = "WS", name = "Only Stun with W", value = true})
        --AutoStun
        Menu:MenuElement({type = MENU, id = "AutoStun", name = "AutoStun"})
        Menu.AutoStun:MenuElement({type = PARAM, id = "Q", name = "Use Q", value = false})
        Menu.AutoStun:MenuElement({type = PARAM, id = "W", name = "Use W", value = false})
        --KillSecure
        Menu:MenuElement({type = MENU, id = "KillSecure", name = " KillSecure"})
        Menu.KillSecure:MenuElement({type = PARAM, id = "Q", name = "Use Q", value = true})
        Menu.KillSecure:MenuElement({type = PARAM, id = "W", name = "Use W", value = true})
        --Items
        Menu:MenuElement({type = MENU, id = "Item", name = " Item Usage"})
        Menu.Item:MenuElement({type = PARAM, id = "GLP800", name = "Use Hextech GLP-800 in Combo", value = true})
        Menu.Item:MenuElement({type = PARAM, id = "Protobelt01", name = "Gapclose With Protobelt-01", value = true})
    end
    
    function Kennen:Tick()
        local target = TS:GetTarget(1050)
        if ORB.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and target then
            local protobelt = GetItemSlot(items.Protobelt01)
            if target.distance <= 980 then
                local glp800 = GetItemSlot(items.GLP800)
                if Menu.Combo.R:Value() and Game.CanUseSpell(_R) == READY and GetNumberOfTableElements(EnemiesNearMe()) >= Menu.Combo.RS:Value() then
                    Control.CastSpell(HK_R)
                elseif Menu.Combo.Q:Value() and CanQ(target) then
                    CastQ(target)
                elseif Menu.Item.GLP800:Value() and glp800 and target.distance <= 700 then
                    local glp800k = GetItemHotKey(glp800)
                    Control.CastSpell(glp800k, target)
                elseif Menu.Combo.W:Value() and Game.CanUseSpell(_W) == READY and target.distance <= W.range then
                    if Menu.Combo.WS:Value() then
                        if GetMarks(target) > 1 then
                            Control.CastSpell(HK_W)
                        end
                    elseif GetMarks(target) > 0 then
                        Control.CastSpell(HK_W)
                    end
                end
            elseif protobelt and Menu.Item.GLP800:Value() and target.distance <= 800 and target.distance >= 200 then
                local protobeltK = GetItemHotKey(protobelt)
                Control.CastSpell(protobeltK, target)
            end
        end
        if ORB.Modes[_G.SDK.ORBWALKER_MODE_HARASS] and target then
            if Menu.Harass.Q:Value() and CanQ(target) then
                CastQ(target)
            elseif Menu.Harass.W:Value() and Game.CanUseSpell(_W) == READY and target.distance <= W.range then
                if Menu.Harass.WS:Value() then
                    if GetMarks(target) > 1 then
                        Control.CastSpell(HK_W)
                    end
                elseif GetMarks(target) > 0 then
                    Control.CastSpell(HK_W)
                end
            end
        end
        --
        if Menu.AutoStun.Q:Value() or Menu.AutoStun.W:Value() then
            if Game.CanUseSpell(_W) == READY or Game.CanUseSpell(_Q) == READY then
                for i = 1, Game.HeroCount() do
                    local hero = Game.Hero(i)
                    if hero.isEnemy then
                        if not hero.dead and not hero.isImmortal then
                            if GetMarks(hero) > 1 then
                                if Menu.Combo.W:Value() and Game.CanUseSpell(_W) == READY and target.distance <= W.range then
                                    Control.CastSpell(HK_W)
                                elseif Menu.AutoStun.Q:Value() and CanQ(hero) then
                                    CastQ(hero)
                                end
                            end
                        end
                    end
                end
            end
        end
        --
        if Menu.KillSecure.Q:Value() or Menu.KillSecure.W:Value() then
            for i = 1, Game.HeroCount() do
                local hero = Game.Hero(i)
                if hero.distance <= Q.range and hero.isEnemy and not hero.dead and not hero.isImmortal then
                    if Menu.KillSecure.Q:Value() and Game.CanUseSpell(_Q) == READY and CanQ(hero) and getdmg("Q", hero) > hero.health then
                        CastQ(hero)
                    elseif Menu.KillSecure.W:Value() and Game.CanUseSpell(_W) == READY and GetMarks(hero) > 0 then
                        if hero.distance <= W.range and getdmg("W", hero, myHero, 2) > hero.health then
                            Control.CastSpell(HK_W)
                        end
                    end
                end
            end
        end
    end
end

class "Leona"
do
    local Version = 0.05
    local ScriptName = "LLeona"
    local NextTick = GetTickCount()
    local ESpells = {
        ["TristanaR"] = {charName = "Tristana", slot = _R, displayName = "[R]Buster Shot"},
        ["VayneCondemn"] = {charName = "Vayne", slot = _E, displayName = "[E]Condemn"},
        ["BlindMonkRKick"] = {charName = "LeeSin", slot = _R, displayName = "[R]Dragon's Rage"},
    }
    
    local function EnemiesNear(pos)
        local N = 0
        for i = 1, Game.HeroCount() do
            local hero = Game.Hero(i)
            if hero.valid and hero.isEnemy and hero.pos:DistanceTo(pos) < 260 then
                N = N + 1
            end
        end
        return N
    end
    
    function Leona:__init()
        self.LastReset = 0
        self.EData = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 80, Range = 875, Speed = 1200, Collision = false}
        self.RData = {Type = _G.SPELLTYPE_CIRCLE, Delay = 1, Radius = 250, Range = 1200, Speed = math.huge, Collision = false}
        self:LoadMenu()
        Callback.Add("Tick", function() self:Tick() end)
        Callback.Add("Draw", function() self:Draw() end)
    end
    
    function Leona:LoadMenu()
        Menu = MenuElement({type = MENU, id = "LeonaByTy", name = "LLeona"})
        --combo
        Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
        Menu.Combo:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(hero) Menu.Combo.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
        Menu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
        Menu.Combo:MenuElement({id = "UseW", name = "[W]", value = true})
        Menu.Combo:MenuElement({id = "UseE", name = "[E]", value = true})
        Menu.Combo:MenuElement({id = "DontE", name = "Dont QER to tower Range Target", value = true})
        Menu.Combo:MenuElement({id = "DontEQR", name = "If Target HP > %", value = 20, min = 0, max = 100})
        Menu.Combo:MenuElement({id = "UseR", name = "[R]", value = true})
        Menu.Combo:MenuElement({id = "MinR", name = "[R] Min R target", value = 1, min = 1, max = 5}) --trying to fix this
        --Harass
        Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
        Menu.Harass:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(hero) Menu.Harass.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
        Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
        Menu.Harass:MenuElement({id = "UseW", name = "W", value = true})
        Menu.Harass:MenuElement({id = "UseE", name = "E", value = true})
        Menu.Harass:MenuElement({id = "DontE", name = "Dont QER to tower Range Target", value = true})
        --Auto
        Menu:MenuElement({type = MENU, id = "Auto", name = "Auto"})
        Menu.Auto:MenuElement({id = "AutoIG", name = "Auto Ingite KS", value = true})
        Menu.Auto:MenuElement({id = "AotoEList", name = "Spell List", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(hero)
            for i, spell in pairs(ESpells) do
                if not ESpells[i] then
                    return
                end
                if spell.charName == hero.charName and not Menu.Auto.AotoEList[i] then
                    Menu.Auto.AotoEList:MenuElement({id = hero.charName, name = ""..spell.charName.." " .. " | "..spell.displayName, value = true})
                end
            end
        end)
        --Draw
        Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
        Menu.Drawing:MenuElement({id = "E", name = "Draw [E] Range", value = true})
        Menu.Drawing:MenuElement({id = "R", name = "Draw [R] Range", value = true})
        --Menu.Drawing:MenuElement({id = "Num", name = "Draw Prediction Max Range", value = 100, min = 70 , max = 100})
        Menu:MenuElement({type = MENU, id = "Version", name = "Version: "..Version, type = SPACE})
    end
    
    function Leona:Draw()
        if myHero.dead then
            return
        end
        
        if Menu.Drawing.E:Value() and Ready(_E) then
            Draw.Circle(myHero.pos, 875, Draw.Color(80, 0xFF, 0xFF, 0xFF))
        end
        if Menu.Drawing.R:Value() and Ready(_R) then
            Draw.Circle(myHero.pos, 1200, Draw.Color(255, 255, 162, 000))
        end
    end
    
    function Leona:Tick()
        if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
            return
        end
        
        self:Auto()
        if NextTick > GetTickCount() then return end
        ORB:SetMovement(true)
        if ORB.Modes[0] then --combo
            self:Combo()
        elseif ORB.Modes[1] then --harass
            self:Harass()
        end
    end
    
    function Leona:Combo()
        local EnemyHeroes = OB:GetEnemyHeroes(1150, false)
        local targetList = {}
        
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            local heroName = hero.charName
            if Menu.Combo.useon[heroName] and Menu.Combo.useon[heroName]:Value() then
                targetList[#targetList + 1] = hero
            end
        end
        local target = TS:GetTarget(targetList)
        if target == nil then return end
        
        if IsValid(target) then
            if Menu.Combo.DontE:Value() and target.health / target.maxHealth > Menu.Combo.DontEQR:Value() / 100 then
                for i = 1, Game.TurretCount() do
                    local turret = Game.Turret(i)
                    if turret.valid and turret.isEnemy and turret.pos:DistanceTo(target.pos) < 800 then
                        return
                    end
                end
            end
            
            if Menu.Combo.UseE:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= 875 then
                local Pred = GetGamsteronPrediction(target, self.EData, myHero)
                if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                    NextTick = GetTickCount() + 250
                    ORB:SetMovement(false)
                    Control.CastSpell(HK_E, Pred.CastPosition)
                end
            end
            
            if Menu.Combo.UseW:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) <= 325 then
                Control.CastSpell(HK_W)
            end
            
            if Menu.Combo.UseR:Value() and Ready(_R) and myHero.pos:DistanceTo(target.pos) <= 1150 then
                if myHero.pos:DistanceTo(target.pos) < 850 and not Ready(_E) and not Ready(_Q) then
                    local Pred = GetGamsteronPrediction(target, self.RData, myHero)
                    if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                        if EnemiesNear(Pred.CastPosition) >= Menu.Combo.MinR:Value() then
                            NextTick = GetTickCount() + 250
                            ORB:SetMovement(false)
                            Control.CastSpell(HK_R, Pred.CastPosition)
                        end
                    end
                end
                if myHero.pos:DistanceTo(target.pos) > 800 and Ready(_E) and Ready(_Q) then
                    local Pred = GetGamsteronPrediction(target, self.RData, myHero)
                    if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                        if EnemiesNear(Pred.CastPosition) >= Menu.Combo.MinR:Value() then
                            NextTick = GetTickCount() + 250
                            ORB:SetMovement(false)
                            Control.CastSpell(HK_R, Pred.CastPosition)
                        end
                    end
                end
            end
            
            if Menu.Combo.UseQ:Value()
                and Ready(_Q)
                then
                self:CastQ()
            end
        end
    end
    
    function Leona:Harass()
        local EnemyHeroes = OB:GetEnemyHeroes(1150, false)
        local targetList = {}
        
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            local heroName = hero.charName
            if Menu.Harass.useon[heroName] and Menu.Harass.useon[heroName]:Value() then
                targetList[#targetList + 1] = hero
            end
        end
        local target = TS:GetTarget(targetList)
        if target == nil then return end
        
        if IsValid(target) then
            if Menu.Harass.DontE:Value() then
                for i = 1, Game.TurretCount() do
                    local turret = Game.Turret(i)
                    if turret.valid and turret.isEnemy and turret.pos:DistanceTo(target.pos) < 800 then
                        return
                    end
                end
            end
            
            if Menu.Harass.UseE:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= 875 then
                local Pred = GetGamsteronPrediction(target, self.EData, myHero)
                if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                    NextTick = GetTickCount() + 250
                    ORB:SetMovement(false)
                    Control.CastSpell(HK_E, Pred.CastPosition)
                end
            end
            
            if Menu.Harass.UseW:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) <= 325 then
                Control.CastSpell(HK_W)
            end
            
            if Menu.Harass.UseQ:Value() and Ready(_Q) then
                self:CastQ()
            end
        end
    end
    
    function Leona:Auto()
        local IGdamage = 50 + 20 * myHero.levelData.lvl
        local target = TS:GetTarget(600)
        if target == nil then return end
        if Menu.Auto.AutoIG:Value() then
            if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and myHero:GetSpellData(SUMMONER_1).currentCd == 0 then
                if IGdamage >= target.health then
                    Control.CastSpell(HK_SUMMONER_1, target.pos)
                end
            end
            
            if myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and myHero:GetSpellData(SUMMONER_2).currentCd == 0 then
                if IGdamage >= target.health then
                    Control.CastSpell(HK_SUMMONER_2, target.pos)
                end
            end
        end
        
        local EnemyHeroes = OB:GetEnemyHeroes(875, false)
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            if hero.activeSpell.spellWasCast then
                if ESpells[hero.activeSpell.name] ~= nil then
                    if Menu.Auto.AotoEList[hero.charName]:Value() and hero.activeSpell.target == myHero.handle then
                        Control.CastSpell(HK_E, hero.pos)
                    end
                end
            end
        end
    end
    
    function Leona:CastQ()
        local EnemyHeroes = OB:GetEnemyHeroes(275, false)
        if EnemyHeroes ~= nil and myHero.attackData.state == STATE_WINDDOWN then
            Control.CastSpell(HK_Q)
            ORB:__OnAutoAttackReset()
        end
        
        if myHero.pathing.isDashing then
            Control.CastSpell(HK_Q)
        end
    end
end

class "Morgana"
do
    local version = 0.03
    local shellSpells = {
        ["SowTheWind"] = {charName = "Janna", slot = "W"},
        ["Terrify"] = {charName = "FiddleSticks", slot = "Q"},
        ["FiddlesticksDarkWind"] = {charName = "FiddleSticks", slot = "E"},
        ["LuluWTwo"] = {charName = "Lulu", slot = "W"},
        ["NautilusRavageStrikeAttack"] = {charName = "Nautilus", slot = "Passive"},
        ["NautilusGrandLine"] = {charName = "Nautilus", slot = "R"},
        ["TahmKenchW"] = {charName = "TahmKench", slot = "W"},
        ["VayneCondemn"] = {charName = "Vayne", slot = "E"},
        ["jayceThunderingBlow"] = {charName = "Jayce", slot = "E"},
        ["BlindMonkRKick"] = {charName = "LeeSin", slot = "R"},
        ["LissandraREnemy"] = {charName = "Lissandra", slot = "R"},
        ["SeismicShard"] = {charName = "Malphite", slot = "Q"},
        ["MalzaharR"] = {charName = "Malzahar", slot = "R"},
        ["NasusW"] = {charName = "Nasus", slot = "W"},
        ["RekSaiWUnburrowLockout"] = {charName = "RekSai", slot = "W"},
        ["PuncturingTaunt"] = {charName = "Rammus", slot = "E"},
        ["RyzeW"] = {charName = "Ryze", slot = "W"},
        ["Fling"] = {charName = "Singed", slot = "W"},
        ["SkarnerImpale"] = {charName = "Skarner", slot = "R"},
        ["SkarnerPassiveAttack"] = {charName = "Skarner", slot = "E Passive"},
        ["Blinding Dart"] = {charName = "Teemo", slot = "Q"},
        ["TristanaR"] = {charName = "Tristana", slot = "R"},
        ["WarwickRChannel"] = {charName = "Warwick", slot = "R"}, -- need test
        ["XinZhaoQThrust3"] = {charName = "XinZhao", slot = "Q3"},
        ["VolibearQAttack"] = {charName = "Volibear", slot = "Q"},
        ["ViR"] = {charName = "Vi", slot = "R"},
        ["LeonaShieldOfDaybreakAttack"] = {charName = "Leona", slot = "Q"},
        ["GoldCardPreAttack"] = {charName = "TwistedFate", slot = "GoldW"},
        ["RenektonSuperExecute"] = {charName = "Renekton", slot = "SuperW"},
        ["RenektonExecute"] = {charName = "Renekton", slot = "W"},
    }
    
    function Morgana:__init()
        self:CreateMenu()
        Callback.Add("Draw", function() self:Draw() end)
    end
    
    function Morgana:CreateMenu()
        Menu = MenuElement({type = MENU, id = "Menu", name = "Morgana E"})
        Menu:MenuElement({type = MENU, id = "spell", name = "Spells"})
        AIO.Object:OnEnemyHeroLoad(function(hero)
            for k, v in pairs(shellSpells) do
                if v.charName == hero.charName then
                    Menu.spell:MenuElement({id = k, name = v.charName.." | "..v.slot, value = true})
                end
            end
        end)
        Menu:MenuElement({type = MENU, id = "dash", name = "track dash on"})
        AIO.Object:OnEnemyHeroLoad(function(hero) Menu.dash:MenuElement({id = hero.charName, name = hero.charName, value = false}) end)
        Menu:MenuElement({type = MENU, id = "ally", name = "Use E "})
        AIO.Object:OnAllyHeroLoad(function(hero) Menu.ally:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
    end
    
    function Morgana:Draw()
        local EnemyHeroes = OB:GetEnemyHeroes(2800, false)
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            if hero.activeSpell.valid and shellSpells[hero.activeSpell.name] ~= nil then
                local AllyHeroes = OB:GetAllyHeroes(800)
                for i = 1, #AllyHeroes do
                    local ally = AllyHeroes[i]
                    --print(hero.charName)
                    if hero.activeSpell.target == ally.handle and Menu.ally[ally.charName]:Value() and Menu.spell[hero.activeSpell.name]:Value() then
                        Control.CastSpell(HK_E, ally)
                    end
                end
            end
            
            if hero.pathing.isDashing and Menu.dash[hero.charName]:Value() then
                local vct = Vector(hero.pathing.endPos.x, hero.pathing.endPos.y, hero.pathing.endPos.z)
                local AllyHeroes = OB:GetAllyHeroes(800)
                for i = 1, #AllyHeroes do
                    local ally = AllyHeroes[i]
                    --print("dash"..hero.charName)
                    print(vct:DistanceTo(ally.pos))
                    if vct:DistanceTo(ally.pos) < 172 then
                        --print("Use E on"..ally.charName)
                        Control.CastSpell(HK_E, ally)
                    end
                end
            end
        end
    end
end

class "Nautilus"
do
    local lineQ
    local NextTick = GetTickCount()
    
    function Nautilus:__init()
        require 'MapPositionGOS'
        self.LastReset = 0
        self.QData = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 80, Range = 1100, Speed = 2000, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}}
        self:LoadMenu()
        Callback.Add("Tick", function() self:Tick() end)
        Callback.Add("Draw", function() self:Draw() end)
    end
    
    function Nautilus:LoadMenu()
        Menu = MenuElement({type = MENU, id = "NautilusByTy", name = "Nautilus"})
        --combo
        Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
        Menu.Combo:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(hero) Menu.Combo.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
        Menu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
        Menu.Combo:MenuElement({id = "UseW", name = "[W]", value = true})
        Menu.Combo:MenuElement({id = "UseE", name = "[E]", value = true})
        --Harass
        Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
        Menu.Harass:MenuElement({name = "Use spell on:", id = "useon", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(hero) Menu.Harass.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
        Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
        --Auto
        Menu:MenuElement({type = MENU, id = "Auto", name = "Auto"})
        Menu.Auto:MenuElement({id = "AutoIG", name = "Auto Ingite KS", value = true})
        --Draw
        Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
        Menu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
    end
    
    function Nautilus:Draw()
        if myHero.dead then
            return
        end
        --[[
        if lineQ ~= nil then
            lineQ:__draw(1)
        end
    --]]
        if Menu.Drawing.Q:Value() and Ready(_Q) then
            Draw.Circle(myHero.pos, 1100, Draw.Color(80, 0xFF, 0xFF, 0xFF))
        end
    end
    
    function Nautilus:Tick()
        if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
            return
        end
        
        self:Auto()
        if NextTick > GetTickCount() then return end
        ORB:SetMovement(true)
        if ORB.Modes[0] then --combo
            self:Combo()
        elseif ORB.Modes[1] then --harass
            self:Harass()
        end
    end
    
    function Nautilus:Combo()
        local EnemyHeroes = OB:GetEnemyHeroes(1100, false)
        local targetList = {}
        
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            local heroName = hero.charName
            if Menu.Combo.useon[heroName] and Menu.Combo.useon[heroName]:Value() then
                targetList[#targetList + 1] = hero
            end
        end
        
        local target = TS:GetTarget(targetList)
        if target and IsValid(target) then
            if Menu.Combo.UseQ:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) <= 1100 then
                
                local Pred = GetGamsteronPrediction(target, self.QData, myHero)
                if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                    lineQ = LineSegment(Pred.CastPosition, Pred.CastPosition:Extended(myHero.pos, myHero.pos:DistanceTo(target.pos)))
                    if MapPosition:intersectsWall(lineQ) then
                        return
                    end
                    NextTick = GetTickCount() + 250
                    ORB:SetMovement(false)
                    Control.CastSpell(HK_Q, Pred.CastPosition)
                end
            end
            
            if Menu.Combo.UseW:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) <= 325 then
                Control.CastSpell(HK_W)
            end
            
            if Menu.Combo.UseE:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= 325 then
                Control.CastSpell(HK_E)
            end
        end
    end
    
    function Nautilus:Harass()
        local EnemyHeroes = OB:GetEnemyHeroes(1100, false)
        local targetList = {}
        
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            local heroName = hero.charName
            if Menu.Harass.useon[heroName] and Menu.Harass.useon[heroName]:Value() then
                targetList[#targetList + 1] = hero
            end
        end
        
        local target = TS:GetTarget(targetList)
        if target and IsValid(target) then
            if Menu.Harass.UseQ:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) <= 1100 then
                local Pred = GetGamsteronPrediction(target, self.QData, myHero)
                if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                    lineQ = LineSegment(Pred.CastPosition, Pred.CastPosition:Extended(myHero.pos, myHero.pos:DistanceTo(target.pos)))
                    if MapPosition:intersectsWall(lineQ) then
                        return
                    end
                    NextTick = GetTickCount() + 250
                    ORB:SetMovement(false)
                    Control.CastSpell(HK_Q, Pred.CastPosition)
                end
            end
        end
    end
    
    function Nautilus:Auto()
        local IGdamage = 50 + 20 * myHero.levelData.lvl
        local target = TS:GetTarget(600)
        if target and Menu.Auto.AutoIG:Value() then
            if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and myHero:GetSpellData(SUMMONER_1).currentCd == 0 then
                if IGdamage >= target.health then
                    Control.CastSpell(HK_SUMMONER_1, target.pos)
                end
            end
            if myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and myHero:GetSpellData(SUMMONER_2).currentCd == 0 then
                if IGdamage >= target.health then
                    Control.CastSpell(HK_SUMMONER_2, target.pos)
                end
            end
        end
    end
end

class "Thresh"
do
    local Version = 0.15
    local Patch = 9.13
    local ScriptName = "Thresh"
    local NextTick = GetTickCount()
    
    function Thresh:__init()
        self.LastReset = 0
        self.QData = {Type = _G.SPELLTYPE_LINE, Delay = 0.5, Radius = 70, Range = 1000, Speed = 1900, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}, UseBoundingRadius = true}
        --Q range 1100 cant hit
        self.EData = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 150, Range = 450, Speed = 1100, Collision = false}
        self:LoadMenu()
        Callback.Add("Tick", function() self:Tick() end)
        Callback.Add("Draw", function() self:Draw() end)
    end
    
    function Thresh:LoadMenu()
        Menu = MenuElement({type = MENU, id = "ThreshByTy", name = "TThresh"})
        Menu:MenuElement({type = MENU, id = "Q", name = "[Q]"})
        Menu.Q:MenuElement({name = " ", drop = {"Combo Settings"}})
        Menu.Q:MenuElement({id = "Combo", name = "Use on Combo", value = true})
        Menu.Q:MenuElement({name = "Combo list:", id = "ComboOn", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(hero) Menu.Q.ComboOn:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
        Menu.Q:MenuElement({name = " ", drop = {"Harrass Settings"}})
        Menu.Q:MenuElement({id = "Harass", name = "Use on Harass", value = true})
        Menu.Q:MenuElement({name = "Harass list:", id = "HarassOn", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(hero) Menu.Q.HarassOn:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
        --Menu.Q:MenuElement({name =" " , drop = {"Misc Settings"}})
        --Menu.Q:MenuElement({id = "Auto", name = "Auto Use on Immobile", value = true})
        Menu:MenuElement({type = MENU, id = "E", name = "[E]"})
        Menu.E:MenuElement({name = " ", drop = {"Combo Settings"}})
        Menu.E:MenuElement({id = "Combo", name = "Use on Combo", value = true})
        Menu.E:MenuElement({name = " ", drop = {"Harrass Settings"}})
        Menu.E:MenuElement({id = "Harass", name = "Use on Harass", value = true})
        Menu.E:MenuElement({name = " ", drop = {"Misc Settings"}})
        Menu.E:MenuElement({id = "Auto", name = "Disable autoAttack if E ready", value = true})
        Menu.E:MenuElement({id = "AntiE", name = "Anti Dash", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(hero) Menu.E.AntiE:MenuElement({id = hero.charName, name = hero.charName, value = false}) end)
        --Menu.E:MenuElement({id = "Grass", name = "Anti Dash from Grass(beta)", value = false})
        Menu.E:MenuElement({id = "AutoE", name = "Auto Pull E on ", type = _G.MENU})
        AIO.Object:OnEnemyHeroLoad(function(hero) Menu.E.AutoE:MenuElement({id = hero.charName, name = hero.charName, value = false}) end)
        Menu:MenuElement({type = MENU, id = "R", name = "[R]"})
        Menu.R:MenuElement({name = " ", drop = {"Combo Settings"}})
        Menu.R:MenuElement({id = "Combo", name = "Use on Combo", value = true})
        Menu.R:MenuElement({id = "Count", name = "When X Enemies Around", value = 2, min = 1, max = 5, step = 1})
        Menu.R:MenuElement({name = " ", drop = {"Misc"}})
        Menu.R:MenuElement({id = "Auto", name = "Auto Use When X Enemies Around", value = 3, min = 1, max = 5, step = 1})
        Menu:MenuElement({type = MENU, id = "Auto", name = "Ignite"})
        Menu.Auto:MenuElement({id = "AutoIG", name = "Auto Ingite KS", value = true})
        Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
        Menu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
        Menu.Drawing:MenuElement({id = "E", name = "Draw [E] Range", value = true})
        Menu:MenuElement({name = "Patch : ", drop = {Patch}})
        Menu:MenuElement({name = "Version ", drop = {Version}})
    end
    
    function Thresh:Draw()
        if myHero.dead then
            return
        end
        
        self:AntiE()
        
        if Menu.Drawing.Q:Value() and Ready(_Q) then
            Draw.Circle(myHero.pos, 1000, Draw.Color(255, 255, 162, 000))
        end
        if Menu.Drawing.E:Value() and Ready(_E) then
            Draw.Circle(myHero.pos, 465, Draw.Color(80, 0xFF, 0xFF, 0xFF))
        end
        --[[
        local target = TS:GetTarget(1000)
        if target == nil then return end
        local flayTowards = self:GetPosE(target.pos)      
        Draw.Circle(flayTowards, 20,Draw.Color(80 ,0xFF,0xFF,0xFF))
 
        pos = target:GetPrediction(2265, 0.7)
        Draw.Circle(pos, 20,Draw.Color(80 ,0xFF,0xFF,0xFF))
        Draw.Circle(flayTowards, 20,Draw.Color(80 ,0xFF,0xFF,0xFF))
        --]]
    end
    
    function Thresh:Tick()
        if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
            return
        end
        
        self:Auto()
        
        if NextTick > GetTickCount() then return end
        
        self:AntiE()
        
        if Ready(_E) and Menu.E.Auto:Value() then
            ORB:SetAttack(false)
        else
            ORB:SetAttack(true)
        end
        
        if ORB.Modes[0] then --combo
            self:Combo()
        elseif ORB.Modes[1] then --harass
            self:Harass()
        end
        
        self:AutoE()
    end
    
    function Thresh:Combo()
        local EnemyHeroes = OB:GetEnemyHeroes(1000, false)
        local targetList = {}
        
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            local heroName = hero.charName
            if Menu.Q.ComboOn[heroName] and Menu.Q.ComboOn[heroName]:Value() then
                targetList[#targetList + 1] = hero
            end
        end
        
        local target = TS:GetTarget(targetList)
        if target == nil then return end
        if IsValid(target) then
            if Menu.Q.Combo:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) <= 1000 then
                local Pred = GetGamsteronPrediction(target, self.QData, myHero)
                if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                    NextTick = GetTickCount() + 500
                    Control.CastSpell(HK_Q, Pred.CastPosition)
                end
            end
            
            if Menu.E.Combo:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= 450 then
                pre = self:GetPosE(target.pos)
                Control.CastSpell(HK_E, pre)
            end
            
        end
        
        local nearby = #OB:GetEnemyHeroes(420, false)
        
        if Ready(_R) and Menu.R.Combo:Value() and nearby >= Menu.R.Count:Value() then
            Control.CastSpell(HK_R)
        end
    end
    
    function Thresh:Harass()
        local EnemyHeroes = OB:GetEnemyHeroes(1000, false)
        local targetList = {}
        
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            local heroName = hero.charName
            if Menu.Q.HarassOn[heroName] and Menu.Q.HarassOn[heroName]:Value() then
                targetList[#targetList + 1] = hero
            end
        end
        
        local target = TS:GetTarget(targetList)
        if target == nil then return end
        if IsValid(target) then
            if Menu.Q.Harass:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) <= 1000 then
                local Pred = GetGamsteronPrediction(target, self.QData, myHero)
                if Pred.Hitchance >= _G.HITCHANCE_HIGH then
                    NextTick = GetTickCount() + 500
                    Control.CastSpell(HK_Q, Pred.CastPosition)
                end
            end
            
            if Menu.E.Combo:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= 450 then
                pre = self:GetPosE(target.pos)
                Control.CastSpell(HK_E, pre)
            end
        end
    end
    
    function Thresh:Auto()
        local nearby = #OB:GetEnemyHeroes(420, false)
        if Ready(_R) and nearby >= Menu.R.Auto:Value() then
            Control.CastSpell(HK_R)
        end
        
        local IGdamage = 50 + 20 * myHero.levelData.lvl
        local EnemyHeroes = OB:GetEnemyHeroes(600, false)
        if next(EnemyHeroes) == nil then return end
        for i = 1, #EnemyHeroes do
            local target = EnemyHeroes[i]
            
            if Menu.Auto.AutoIG:Value() then
                if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and myHero:GetSpellData(SUMMONER_1).currentCd == 0 then
                    if IGdamage >= target.health then
                        Control.CastSpell(HK_SUMMONER_1, target.pos)
                    end
                end
                
                if myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and myHero:GetSpellData(SUMMONER_2).currentCd == 0 then
                    if IGdamage >= target.health then
                        Control.CastSpell(HK_SUMMONER_2, target.pos)
                    end
                end
            end
        end
    end
    
    function Thresh:AutoE()
        local EnemyHeroes = OB:GetEnemyHeroes(465, false)
        if next(EnemyHeroes) == nil then return end
        for i = 1, #EnemyHeroes do
            local target = EnemyHeroes[i]
            local heroName = target.charName
            if Ready(_E) and Menu.E.AutoE[heroName] and Menu.E.AutoE[heroName]:Value() then
                pre = self:GetPosE(target.pos)
                NextTick = GetTickCount() + 250
                Control.CastSpell(HK_E, pre)
            end
        end
    end
    
    function Thresh:AntiE()
        local EnemyHeroes = OB:GetEnemyHeroes(475, false)
        if next(EnemyHeroes) == nil then return end
        for i = 1, #EnemyHeroes do
            local target = EnemyHeroes[i]
            local heroName = target.charName
            if Ready(_E) and Menu.E.AntiE[heroName] and Menu.E.AntiE[heroName]:Value() then
                
                if target.pathing.isDashing and target.pathing.dashSpeed > 870 then
                    
                    local delay = 0.25 + (475 - target.pos:DistanceTo()) / 1100
                    --print(delay)
                    local pos = target:GetPrediction(target.pathing.dashSpeed, delay)
                    local pre = self:GetPosE(pos)
                    NextTick = GetTickCount() + 250
                    --print(target.pathing.dashSpeed)
                    Control.CastSpell(HK_E, pre)
                    
                end
            end
        end
    end
    
    function Thresh:GetPosE(pos, mode) --RMAN
        local push = mode == "Push" and true or false
        --
        return myHero.pos:Extended(pos, self.EData.Range * (push and 1 or - 1))
    end
end

class "Yasuo"
do
    _G.ObjectManager = AIO.Object
    _G.BuffManager = AIO.Buff
    _G.IsInRange = IsInRange
    _G.Ready = Ready
    
    -- ENCRYPTED
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local function dec(data)
        data = string.gsub(data, '[^'..b..'=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r, f = '', (b:find(x) - 1)
            for i = 6, 1, -1 do
                r = r..(f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
            end
            return r
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c = 0
            for i = 1, 8 do
                c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0)
            end
            return string.char(c)
        end))
    end
    assert(load(dec("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"), nil, "bt", _ENV))()
end

function OnLoad()
    ORB, TS, OB, DMG, SPELLS, HP = _G.SDK.Orbwalker, _G.SDK.TargetSelector, _G.SDK.ObjectManager, _G.SDK.Damage, _G.SDK.Spells, _G.SDK.HealthPrediction
    _G[myHero.charName]()
    AIO.Action:Start()
    AIO.Object:Start()
    AIO.Buff:Start()
end
