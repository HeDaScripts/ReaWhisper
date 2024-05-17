--[[
* ReaScript Name: ReaWhisper
* Author: HeDa
* Author URI: https://reaper.hector-corcin.com
* Repository URI: https://github.com//HeDaScripts/ReaWhisper
* Licence: MIT
* Version: 0.1.0

* v0.1.0 (2024-05-17)
	+ Basic script to run OpenAI Whisper from REAPER.
	Simple version with manual options from settings.lua.txt file.
	It launches whisper command to transcribe the audio of a selected item
	into a srt file, and then import the srt into a track in REAPER. 
	The track is the next track of the item's track. so you may want to create 
	an empty track after the track to transcribe first.

--]]

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

first_time = false
-- read default settings file:
local info = debug.getinfo(1, 'S')
local script_path = info.source:match [[^@?(.*[\/])[^\/]-$]]
local settingspath = getParentDirectory(script_path) .. "/ReaWhisper settings"
local settingsfilename = "settings.lua.txt"
local settingsfile = script_path .. settingsfilename
local customsettingsfile = settingspath .."/" .. settingsfilename
if reaper.file_exists(settingsfile) then
	dofile(settingsfile)
else
	reaper.MB("Error reading default settings file. ", "Error", 0)
end
--now read custom settings:
if reaper.file_exists(customsettingsfile) then
	dofile(customsettingsfile)
else
	-- if custom settings does not exist, create one
	reaper.RecursiveCreateDirectory(settingspath, 0) -- create directory
	local result = copyFile(settingsfile, customsettingsfile) -- copy default settings file to custom settings file
	if not result then 
		reaper.MB("Error creating custom settings file. ", "Error", 0)
	end
	if reaper.file_exists(customsettingsfile) then 
		reaper.MB("First time use. Configure your settings file.", "Info", 0)
		first_time = true
		-- just open the settings lua file for manual editing for now
		if OS == "OSX32" or OS == "OSX64" or OS == "macOS-arm64" then
			os.execute('open "" "' .. customsettingsfile .. '"')
		elseif OS == "Win32" or OS == "Win64" then
			os.execute('start "" "' .. customsettingsfile .. '"')
		else
			os.execute('xdg-open "' .. customsettingsfile .. '"')
		end
	end
end

-- whisper executable path
whisperbin = path..venvpath.."/bin/whisper"


function print_debug(text)
	-- debug to console window
	if showdebug then 
		print(text)
	end
end


function print(text)
	-- print to console window
	reaper.ShowConsoleMsg("\n")
	if text then
		reaper.ShowConsoleMsg(text)
	else
		reaper.ShowConsoleMsg("nil")
	end
end

		
function GetFilename(file)
	if file then
		local fullpath = file:gsub("[\\/]+$", "")
		local fileFolder = fullpath:match("^(.*[\\/])") or ""
		local filename = fullpath:match("([^\\/]+)$") or ""
		local fileExtension = filename:match("^.+(%..+)$") or ""
		local filenameWithoutExt = filename:match("^(.*)%.") or filename
		return fileFolder, filenameWithoutExt, fileExtension
	end
end


function CreateTextItem(starttime, endtime, notetext)
	-- insert empty item 
	reaper.GetSet_LoopTimeRange(1, 0, starttime, endtime, 0) -- define the time range for the empty item
	reaper.Main_OnCommand(40142, 0)                   -- insert empty item
	local emptyitem = reaper.GetSelectedMediaItem(0, 0)
	reaper.Main_OnCommand(40020, 0)                   -- remove time selection
	item = reaper.GetSelectedMediaItem(0, 0)          -- get the selected item
	reaper.SetMediaItemPosition(item, starttime, true)
	reaper.SetMediaItemLength(item, endtime - starttime, true)
	
	-- set text note
	local retval, string = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", notetext, true)
	
	reaper.SetEditCurPos(endtime, false, false) -- moves cursor
	reaper.Main_OnCommand(40289, 0)          -- unselect all items
	return emptyitem
end


function DeleteItem(track, item)
	if track and item then 
		reaper.DeleteTrackMediaItem(track, item)
	end
end


function ReadFile(which)
	if reaper.file_exists(which) then
		local f = io.open(which)
		local file = {}
		local k = 1
		for line in f:lines() do
			file[k] = line
			k = k + 1
		end
		f:close()
		return file
	else
		return nil
	end
end


function ImportSRT(itemsrt)
	-- very old function to import srt files into REAPER. It probably needs to be done better.
	items = {}
	lines = {}
	sourcefilename, source_path, srtfile, offset = Path_FromItem(itemsrt)
	local itemstart = reaper.GetMediaItemInfo_Value(itemsrt, "D_POSITION")
	itemstart = itemstart - offset
	local itemlength = reaper.GetMediaItemInfo_Value(itemsrt, "D_LENGTH")
	itemlength = itemlength + offset
	local itemend = itemstart + itemlength
	srttable = ReadFile(srtfile)
	if srtfile then
		local num = 0
		for f, s in ipairs(srttable) do
			if s ~= nil then
				if string.find(s, '-->') then
					sh, sm, ss, sms, eh, em, es, ems = s:match("(.*):(.*):(.*),(.*)%-%->(.*):(.*):(.*),(.*)")
					if sh then
						positionStart = tonumber(sh) * 3600 + tonumber(sm) * 60 + tonumber(ss) + (tonumber(sms) / 1000)
						positionEnd = tonumber(eh) * 3600 + tonumber(em) * 60 + tonumber(es) + (tonumber(ems) / 1000)
						table.insert(items, { ["positionStart"] = positionStart, ["positionEnd"] = positionEnd, ["lines"] = {}, })
						num = num + 1
						endsub = nil
						i = 0
						while not endsub do
							i = i + 1
							line = srttable[f + i]
							if line ~= "\r" and line ~= "\n" and line ~= "" then
								table.insert(items[num].lines, line)
							else
								endsub = true
							end
						end
					end
				end
			end
		end
	end
	for j, k in ipairs(items) do
		local textline = ""
		for a, line in ipairs(k.lines) do
			textline = textline .. line .. "\n"
		end
		CreateTextItem(k.positionStart + itemstart, k.positionEnd + itemstart, textline)
	end
end


function Path_FromItem(item)
	if item then
		local take = reaper.GetActiveTake(item)
		if take then
			local PCMsource = reaper.GetMediaItemTake_Source(take)
			local sourcefilename = reaper.GetMediaSourceFileName(PCMsource)
			local source_path, source_file, source_extension = GetFilename(sourcefilename)
			local srtfile = source_path .. output_format.."/" .. source_file .. "." .. output_format
			local offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
			return sourcefilename, source_path, srtfile, offset
		end
	end
	return nil, nil, nil, nil
end


function whisper(item)
	local sourcefilename, source_path, srtfile, offset = Path_FromItem(item)
	local generate = true
	if srtfile then
		if reaper.file_exists(srtfile) then
			generate = false
			local yesno = reaper.ShowMessageBox(".srt file found. Regenerate?", "Already transcribed", 4)
			if yesno == 6 then -- yes
				generate = true
				os.remove(srtfile)
			end
		end
	end
		
	-- run whisper command
	command = '"' .. whisperbin .. '" "'
		.. sourcefilename .. '"'
		.. ' --model ' .. model
		.. ' --output_format ' .. output_format
		.. ' --output_dir "' .. source_path .. "srt" .. '"'
	if language and language ~= "None" then
		command = command .. ' --language ' .. language
	end
	if word_timestamps == "True" then
		command = command .. ' --word_timestamps True'
	end
	if highlight_words == "True" then
		command = command .. ' --highlight_words True'
	end
	if max_line_width and max_line_width ~= "None" then
		command = command .. ' --max_line_width ' .. max_line_width
	end
	if max_line_count and max_line_count ~= "None" then
		command = command .. ' --max_line_count ' .. max_line_count
	end
	if max_words_per_line and max_words_per_line ~= "None" then
		command = command .. ' --max_words_per_line ' .. max_words_per_line
	end
	if prepend_punctuations and prepend_punctuations ~= "" then
		command = command .. ' --prepend_punctuations ' .. prepend_punctuations
	end
	if append_punctuations and append_punctuations ~= "" then
		command = command .. ' --append_punctuations ' .. append_punctuations
	end
	if generate then
		if showdebug then 
			print_debug("_______________ running command _______________")
			print_debug(command)
		end
		error = false
		timestart = reaper.time_precise()
		if reaper.file_exists(whisperbin) then 
			local response = reaper.ExecProcess(command, -2) -- run external command
		else
			reaper.MB("Cannot find the whisper executable. Check path in the settings file.", "Error", 0)
			error = true
			DeleteItem(transcription_track, itemtranscribing)
		end
		if showdebug then 
			print_debug("_____________ wait for srt file... _____________")
		end
		if not error then 
			loop() -- enter a loop to check if srt file is generated
		end
	else
		-- already generated and not wanting to regenerate? then insert the srt
		InsertSRT(srtfile, offset)
	end
end


function InsertSRT(srtfile, offset)
	-- insert the srt file into the track
	if reaper.file_exists(srtfile) and output_format=="srt" then
		reaper.SetOnlyTrackSelected(transcription_track)
		DeleteItem(transcription_track, itemtranscribing)
		reaper.SetEditCurPos(itemstart - offset, true, false)
		ImportSRT(itemtotranscribe)
	end
end


function loop()
	sourcefilename, source_path, srtfile, offset = Path_FromItem(itemtotranscribe)
	if srtfile and output_format == "srt" then
		if reaper.file_exists(srtfile) then
			-- the file is generated, insert it as item notes.
			InsertSRT(srtfile, offset)
			local timeseconds = reaper.time_precise() - timestart
			print_debug("done in " .. string.format("%.2f", timeseconds) .. " seconds.")
		else
			-- wait for srt file to be generated.
			-- TODO: fix performance
			reaper.runloop(loop)
		end
	end
end


function init()
	numselecteditems = reaper.CountSelectedMediaItems(0)
	if numselecteditems == 1 then -- only one item for now
		local f = 0
		-- get item to transcribe and time
		itemtotranscribe = reaper.GetSelectedMediaItem(0, f)
		itemstart = reaper.GetMediaItemInfo_Value(itemtotranscribe, "D_POSITION")
		itemlength = reaper.GetMediaItemInfo_Value(itemtotranscribe, "D_LENGTH")
		itemend = itemstart + itemlength
		
		-- get track of the item and next track as the transcriptions track
		local mediatrack = reaper.GetMediaItem_Track(itemtotranscribe)
		local trackid = reaper.CSurf_TrackToID(mediatrack, false)
		transcription_track = reaper.GetTrack(0, trackid)
		if not transcription_track then 
			-- no next track? create one
			reaper.SetOnlyTrackSelected(mediatrack)
			reaper.Main_OnCommand(40001, 0) -- insert track
			transcription_track = reaper.GetTrack(0, trackid)
		end
		-- get the media info
		if transcription_track then
			local take = reaper.GetActiveTake(itemtotranscribe)
			if take then
				local offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
				reaper.SetOnlyTrackSelected(transcription_track)
				itemtranscribing = CreateTextItem(itemstart - offset, itemend, "Transcribing...")
				reaper.SetMediaItemSelected(itemtotranscribe, true)
				whisper(itemtotranscribe)
			end
		else
			reaper.MB("Can't find the track to insert the text into", "Problem", 0)	
		end
	else
		reaper.MB("Select one item containing the audio file", "Info", 0)
	end
end

-- run only if it is not  the first time use, which only opens the settings file
if first_time==false then 
	-- run!
	init()
end
