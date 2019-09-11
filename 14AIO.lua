local version = 0.16


local champ = myHero.charName
local AiOPath = "14AiO\\"
local lua = "14" .. champ

local SupportChampion = {
    ["Lulu"] 	    = 		true,
    ["Sivir"] 	    = 		true,    
    ["Khazix"] 	    = 		true,
    ["Brand"] 	    = 		true,
    ["Amumu"] 	    = 		true,
    ["Nautilus"]    = 	    true,
    ["Morgana"]     =       true,
    ["Blitzcrank"]  =       true,
    ["Vi"]          =       true,
    ["Zilean"]      =       true
}


local function ReadFile(path, fileName)
    local file = io.open(path .. fileName, "r")
    local result = file:read()
    file:close()
    return result
end

local function AutoUpdate(pth, nm, vs)
        
    local Files = {
        Lua = {
            Path = pth,
            Name = nm..".lua",
            Url = "https://raw.githubusercontent.com/samuelchow1997/gos/master/"..nm..".lua"
        },
        Version = {
            Path = pth,
            Name = nm..".version",
            Url = "https://raw.githubusercontent.com/samuelchow1997/gos/master/"..nm..".version"
        }
    }

    local function DownloadFile(url, path, fileName)
        DownloadFileAsync(url, path .. fileName, function() end)
        while not FileExist(path .. fileName) do end
    end
    

    
    DownloadFile(Files.Version.Url, Files.Version.Path, Files.Version.Name)
    local NewVersion = tonumber(ReadFile(Files.Version.Path, Files.Version.Name))
    if NewVersion > vs then
        DownloadFile(Files.Lua.Url, Files.Lua.Path, Files.Lua.Name)
        print("New"..nm.. "Version Press 2x F6")
    else
        print(nm.." V"..NewVersion..": No Updates Found")
    end

end

AutoUpdate(SCRIPT_PATH, "14AIO", version)

if SupportChampion[champ] then

    local file = io.open(COMMON_PATH .. AiOPath .. lua .. ".lua", "r")
    local champ_vs = io.open(COMMON_PATH .. AiOPath .. lua .. ".version", "r")

    if file and champ_vs then
        
        file:close()
        champ_vs:close()

        local championVs = tonumber(ReadFile(COMMON_PATH .. AiOPath, lua .. ".version"))

        AutoUpdate(COMMON_PATH .. AiOPath, lua , championVs)

        Callback.Add("Load", function() 
            DelayAction(function()
                require(AiOPath .. lua) 
            end, 0.5)
        end)

    else
        AutoUpdate(COMMON_PATH .. AiOPath, lua , 0)

    end

else
    print(champ.. " Not supported in 14AIO")
end