function copyFile(sourcePath, destinationPath)
	-- copy text file to destination file
    local sourceFile = io.open(sourcePath, "r")
    if not sourceFile then
        return false, "Failed to open source file"
    end
    local content = sourceFile:read("*all")
    sourceFile:close()

    local destinationFile = io.open(destinationPath, "w")
    if not destinationFile then
        return false, "Failed to open destination file"
    end
    destinationFile:write(content)
    destinationFile:close()

    return true
end

function getParentDirectory(path)
    local trimmedPath = path:gsub("[\\/]+$", "")
    local parentPath = trimmedPath:match("^(.*)[\\/].-$")
    return parentPath
end

local OS = reaper.GetOS()
local info = debug.getinfo(1, 'S')
local script_path = info.source:match [[^@?(.*[\/])[^\/]-$]]
local settingspath = getParentDirectory(script_path) .. "/ReaWhisper settings"
local settingsfilename = "settings.lua.txt"
local settingsfile = script_path .. settingsfilename
local customsettingsfile = settingspath .."/" .. settingsfilename


--now read custom settings:
if not reaper.file_exists(customsettingsfile) then
	-- if custom settings does not exist, create one
	reaper.RecursiveCreateDirectory(settingspath, 0) -- create directory
	local result = copyFile(settingsfile, customsettingsfile) -- copy default settings file to custom settings file
	if not result then 
		reaper.MB("Error creating custom settings file. ", "Error", 0)
	end
end

-- just open the settings lua file for manual editing for now
if OS == "OSX32" or OS == "OSX64" or OS == "macOS-arm64" then
    os.execute('open "" "' .. customsettingsfile .. '"')
elseif OS == "Win32" or OS == "Win64" then
    os.execute('start "" "' .. customsettingsfile .. '"')
else
    os.execute('xdg-open "' .. customsettingsfile .. '"')
end