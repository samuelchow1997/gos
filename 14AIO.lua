local version = 0.01

local AiOPath = "14AiO\\"
local lua = "14" .. champ


local Files = {
    Lua = {
        Path = SCRIPT_PATH,
        Name = "14AIO.lua",
        Url = "https://raw.githubusercontent.com/samuelchow1997/gos/master/14AIO.lua"
    },
    Version = {
        Path = SCRIPT_PATH,
        Name = "14AIO.version",
        Url = "https://raw.githubusercontent.com/samuelchow1997/gos/master/14AIO.version"
    }
}


local function AutoUpdate()
        
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
    if NewVersion > version then
        DownloadFile(Files.Lua.Url, Files.Lua.Path, Files.Lua.Name)
        print("New 14AIO Version Press 2x F6")
    else
        print(Files.Version.Name .. ": No Updates Found")
    end

end

AutoUpdate()


local file = io.open(COMMON_PATH .. AiOPath .. lua .. ".lua", "r")

if file then
    print("file")
end