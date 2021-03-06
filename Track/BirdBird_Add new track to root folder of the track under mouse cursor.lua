--[[
 * ReaScript Name: Add new track to root folder of the track under mouse cursor.lua
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2019-12-19)
 	+ Initial Release
--]]

--=====UTILITY=====--
function hasParent(track)
    return reaper.GetParentTrack(track) ~= nil
end

function getFolderTrack(track)
    local folderTrack = track
    if not folderTrack then
      return
    end
    
    while (hasParent(folderTrack))
    do
      folderTrack = reaper.GetParentTrack(folderTrack)
    end    

    return folderTrack
end

function getChildTracks(track)
    local folderTrack = track
    local folderID = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    local count = reaper.CountTracks(0) - 1

    local children = {}
    for i=folderID, count do
        local childTrack = reaper.GetTrack(0, i)
        if getFolderTrack(childTrack) == track then
            table.insert(children, childTrack)
        else
            break
        end
    end

    return children
end

--=====MAIN=====--
local insertNewTrackCommandID = 40001
local selectTrackUnderMouseCommandID = 41110
local unselectAllTracksCommandID = 40297
local scriptTitle = 'Add new track to root folder of the track under mouse cursor'

function main()
    reaper.Undo_BeginBlock()
    
    --get last track in folder
    reaper.Main_OnCommand(unselectAllTracksCommandID, 0);
    reaper.Main_OnCommand(selectTrackUnderMouseCommandID, 0);
    local selectedTrack = reaper.GetSelectedTrack(0, 0)
    if not selectedTrack then
        --reaper.ShowMessageBox("Could not find a track under the mouse cursor.", "Error", 0) -- silently failing is less annoying to use
        return
    end

    --if no folder track has been found add track directly underneath
    if hasParent(selectedTrack) == false then
        reaper.Main_OnCommand(unselectAllTracksCommandID, 0);   
        reaper.Main_OnCommand(insertNewTrackCommandID, 0);
        return
    end     
    
    local folderTrack = getFolderTrack(selectedTrack)
    local children = getChildTracks(folderTrack)
    local lastTrack = children[#children]
    local folderDepth = reaper.GetMediaTrackInfo_Value(lastTrack, "I_FOLDERDEPTH")
    local depthCounter = math.abs(folderDepth) - 1
    
    --get last folder track
    local lastFolderTrack = lastTrack
    for i=0, depthCounter-1 do
        lastFolderTrack = reaper.GetParentTrack(lastFolderTrack)
    end
    
    --add a new track and move it above the last folder track
    reaper.Main_OnCommand(unselectAllTracksCommandID, 0);
    reaper.Main_OnCommand(insertNewTrackCommandID, 0);
    local track = reaper.GetSelectedTrack(0, 0)
    local lastFolderTrackID = reaper.GetMediaTrackInfo_Value(lastFolderTrack, "IP_TRACKNUMBER")
    reaper.ReorderSelectedTracks( lastFolderTrackID-1, 0 )

    --move the last folder track above the new track, hacky, but it works
    reaper.Main_OnCommand(unselectAllTracksCommandID, 0);
    local lastTrackID = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    reaper.SetTrackSelected(lastFolderTrack, true)
    reaper.ReorderSelectedTracks(lastTrackID-1, 0)  
    
    reaper.Main_OnCommand(unselectAllTracksCommandID, 0);
    reaper.SetTrackSelected(track, true)
    reaper.Undo_EndBlock(scriptTitle, -1)
end
--==========--
reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)