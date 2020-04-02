local function round(number, precision)
    local fmtStr = string.format('%%0.%sf', precision)
    number = string.format(fmtStr, number)
    return number
end

local function pruneData(minutes)
    local newXPTrackerData = {}
    for i = 0, minutes, 1 do
        local index = date('%Y-%m-%dT%H:%M', time() - (i * 60))
        if not (TrackedXP[index] == nil) then
            newXPTrackerData[index] = {}
            newXPTrackerData[index]['X'] = TrackedXP[index]['X']
            newXPTrackerData[index]['L'] = TrackedXP[index]['L']
            newXPTrackerData[index]['T'] = TrackedXP[index]['T']
        end
    end
    TrackedXP = newXPTrackerData
end

local function getPercentXPInLevel()
    local unitXP, unitXPMax = UnitXP('player'), UnitXPMax('player')
    local percentXP = round((unitXP / unitXPMax) * 100, 2)
    return percentXP
end

local function storeCurrentXP()
    local now = date('%Y-%m-%dT%H:%M')
    TrackedXP[now] = {}
    TrackedXP[now]['X'] = getPercentXPInLevel()
    TrackedXP[now]['L'] = UnitLevel('player')
    TrackedXP[now]['T'] = time()
end

local frame = CreateFrame('FRAME');
frame:RegisterEvent('PLAYER_XP_UPDATE')
frame:RegisterEvent('ADDON_LOADED')

function frame:OnEvent(event, arg1)
    if event == 'ADDON_LOADED' and arg1 == 'EXT' then
        if TrackedXP == nil then TrackedXP = {} end
        pruneData(43200)
    end
    storeCurrentXP()
end
frame:SetScript('OnEvent', frame.OnEvent)

SLASH_EXT1, SLASH_EXT2, SLASH_EXT3 = '/xptrack', '/ext', '/xp';
local function handler(msg, editBox)
    local minutesToRetreive
    
    if msg == '' then
        minutesToRetreive = 60
    elseif msg == 'reset' then
        TrackedXP = {}
		return
    else
        minutesToRetreive = tonumber(msg)
    end

    local now = date('%Y-%m-%dT%H:%M')
    local targetTimeFormatted = date('%H:%M', time() - (minutesToRetreive * 60))
    local earliest = {}

    storeCurrentXP()

    for i = 0, minutesToRetreive, 1 do
        local index = date('%Y-%m-%dT%H:%M', time() - (i * 60))
        if not (TrackedXP[index] == nil) then
            if not (TrackedXP[index]['X'] == 'nan()') then
                earliest['XP'] = TrackedXP[index]['X']
                earliest['Level'] = TrackedXP[index]['L']
                earliest['Time'] = TrackedXP[index]['T']
            end 
        end
    end

    local gainedLevelDiff = (UnitLevel('player') - earliest['Level']) 

    local gainedXPDiff = getPercentXPInLevel() - earliest['XP']

    local gainedXP = 0
    if gainedXPDiff < 0 then
        gainedXP = 100 + gainedXPDiff
        gainedLevelDiff = gainedLevelDiff -1
        if gainedLevelDiff <= 0 then gainedLevelDiff = 0 end
    else
        gainedXP = gainedXPDiff
    end

    gainedXP = gainedXP + (gainedLevelDiff * 100)

    local gainedMessage = round(gainedXP, 2) .. '% XP gained'
    print(gainedMessage .. ' since ' ..
              targetTimeFormatted .. ' (' ..
              minutesToRetreive .. 'm ago)')
end
SlashCmdList['EXT'] = handler
