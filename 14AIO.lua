local version = 0.02


local champ = myHero.charName
local AiOPath = "14AiO\\"
local lua = "14" .. champ

local SupportChampionVersion = {
	["Lulu"] 	= 		0.01

}



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
    
    local function ReadFile(path, fileName)
        local file = io.open(path .. fileName, "r")
        local result = file:read()
        file:close()
        return result
    end
    
    DownloadFile(Files.Version.Url, Files.Version.Path, Files.Version.Name)
    local NewVersion = tonumber(ReadFile(Files.Version.Path, Files.Version.Name))
    if NewVersion > vs then
        DownloadFile(Files.Lua.Url, Files.Lua.Path, Files.Lua.Name)
        print("New"..nm.. "Version Press 2x F6")
    else
        print(Files.Version.Name .. ": No Updates Found")
    end

end

AutoUpdate(SCRIPT_PATH, "14AIO", version)

if SupportChampionVersion[champ] then

    local file = io.open(COMMON_PATH .. AiOPath .. lua .. ".lua", "r")

    if file then
        AutoUpdate(COMMON_PATH .. AiOPath, lua , SupportChampionVersion[champ])

        Callback.Add("Load", function() require(AiOPath .. lua) end)

    else
        AutoUpdate(COMMON_PATH .. AiOPath, lua , 0)
    end

else
    print(champ.. " Not supported in 14AIO")
end