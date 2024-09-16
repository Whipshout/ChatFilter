local frame = CreateFrame("Frame", "ChatFilterPanel", UIParent)
frame.name = "Chat Filter"

local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetSize(64, 64)
icon:SetPoint("CENTER", frame, "TOP", 0, -64)
icon:SetTexture("Interface\\AddOns\\ChatFilter\\Icons\\icon.tga")

local header = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
header:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -150)
header:SetText("Channels to filter:")

local bannedWords = {}
local filteredChannels = {}

local function FindChannelIndex(channel)
    for i, v in ipairs(filteredChannels) do
        if v == channel then
            return i
        end
    end

    return nil
end

local function UpdateFilteredChannels(channel, isChecked)
    if isChecked then
        if not FindChannelIndex(channel) then
            table.insert(filteredChannels, channel)
        end
    else
        local index = FindChannelIndex(channel)
        if index then
            table.remove(filteredChannels, index)
        end
    end

    ChatFilterDB.filteredChannels = filteredChannels
end

local checkboxGeneral = CreateFrame("CheckButton", "ChatFilterGeneralCheckbox", frame, "ChatConfigCheckButtonTemplate")
checkboxGeneral:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)
checkboxGeneral.Text:SetText("General")
checkboxGeneral:SetScript("OnClick", function(self)
    UpdateFilteredChannels("general", self:GetChecked())
end)

local checkboxTrade = CreateFrame("CheckButton", "ChatFilterTradeCheckbox", frame, "ChatConfigCheckButtonTemplate")
checkboxTrade:SetPoint("TOPLEFT", checkboxGeneral, "BOTTOMLEFT", 0, -8)
checkboxTrade.Text:SetText("Trade")
checkboxTrade:SetScript("OnClick", function(self)
    UpdateFilteredChannels("trade", self:GetChecked())
end)

local checkboxServices = CreateFrame("CheckButton", "ChatFilterServicesCheckbox", frame, "ChatConfigCheckButtonTemplate")
checkboxServices:SetPoint("TOPLEFT", checkboxTrade, "BOTTOMLEFT", 0, -8)
checkboxServices.Text:SetText("Services")
checkboxServices:SetScript("OnClick", function(self)
    UpdateFilteredChannels("services", self:GetChecked())
end)

local inputField = CreateFrame("EditBox", "ChatFilterInputField", frame, "InputBoxTemplate")
inputField:SetSize(150, 20)
inputField:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -50, -150)
inputField:SetAutoFocus(false)
inputField:SetMaxLetters(50)
inputField:SetText("")

local addButton = CreateFrame("Button", "ChatFilterAddButton", frame, "UIPanelButtonTemplate")
addButton:SetSize(100, 22)
addButton:SetPoint("LEFT", inputField, "LEFT", -120, 0)
addButton:SetText("Add Filter")

local removeButton = CreateFrame("Button", "ChatFilterRemoveButton", frame, "UIPanelButtonTemplate")
removeButton:SetSize(100, 22)
removeButton:SetPoint("LEFT", inputField, "LEFT", -120, -30)
removeButton:SetText("Remove Filter")

local wordLabels = {}

local scrollFrame = CreateFrame("ScrollFrame", "ChatFilterScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(150, 100)
scrollFrame:SetPoint("TOPRIGHT", inputField, "BOTTOMRIGHT", 0, -10)

local content = CreateFrame("Frame", "ChatFilterContentFrame", scrollFrame)
content:SetSize(150, 100)
scrollFrame:SetScrollChild(content)

local function UpdateBannedWords()
    for _, label in pairs(wordLabels) do
        label:Hide()
    end

    content:SetHeight(#bannedWords * 20)

    wordLabels = {}

    for i = 1, #bannedWords do
        local wordLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        wordLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -20 * (i - 1))
        wordLabel:SetText(bannedWords[i])
        wordLabels[i] = wordLabel
    end
end

addButton:SetScript("OnClick", function()
    local newWord = inputField:GetText()
    if newWord ~= "" then
        table.insert(bannedWords, newWord)
        inputField:SetText("")
        ChatFilterDB.bannedWords = bannedWords
        UpdateBannedWords()
    end
end)

removeButton:SetScript("OnClick", function()
    local wordToRemove = inputField:GetText()
    if wordToRemove ~= "" then
        for i = #bannedWords, 1, -1 do
            if bannedWords[i]:lower() == wordToRemove:lower() then
                table.remove(bannedWords, i)
                inputField:SetText("")
                ChatFilterDB.bannedWords = bannedWords
                UpdateBannedWords()
                break
            end
        end
    end
end)

local function InitializeSavedVariables()
    if not ChatFilterDB then
        ChatFilterDB = {}
    end

    ChatFilterDB.bannedWords = ChatFilterDB.bannedWords or {"Nerub", "Queen Ansurek"}  -- Palabras prohibidas por defecto
    ChatFilterDB.filteredChannels = ChatFilterDB.filteredChannels or {"general", "trade", "services"}  -- Canales filtrados por defecto

    bannedWords = ChatFilterDB.bannedWords
    filteredChannels = ChatFilterDB.filteredChannels
end

frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "ChatFilter" then
        InitializeSavedVariables()
        checkboxGeneral:SetChecked(FindChannelIndex("general") ~= nil)
        checkboxTrade:SetChecked(FindChannelIndex("trade") ~= nil)
        checkboxServices:SetChecked(FindChannelIndex("services") ~= nil)
        UpdateBannedWords()
    end
end)
frame:RegisterEvent("ADDON_LOADED")

UpdateBannedWords()

local category = Settings.RegisterCanvasLayoutCategory(frame, frame.name)
local ID = category:GetID()
Settings.RegisterAddOnCategory(category)

SLASH_CHATFILTER1 = "/cf"
SlashCmdList["CHATFILTER"] = function(msg)
    Settings.OpenToCategory(category:GetID())
end

local minimapButton = CreateFrame("Button", "ChatFilterMinimapButton", Minimap)
minimapButton:SetSize(25, 25)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local iconTexture = minimapButton:CreateTexture(nil, "BACKGROUND")
iconTexture:SetTexture("Interface\\AddOns\\ChatFilter\\Icons\\icon.tga")
iconTexture:SetSize(20, 20)
iconTexture:SetPoint("CENTER")

local angle = 198
local radius = 100

local function UpdateButtonPosition()
    local x = math.cos(math.rad(angle)) * radius
    local y = math.sin(math.rad(angle)) * radius
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

UpdateButtonPosition()

minimapButton:SetScript("OnDragStart", function(self)
    self:LockHighlight()
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        px, py = px / scale, py / scale
        angle = math.deg(math.atan2(py - my, px - mx))
        UpdateButtonPosition()
    end)
end)

minimapButton:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
end)

minimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        Settings.OpenToCategory(category:GetID())
    end
end)

minimapButton:RegisterForDrag("LeftButton")

local function formatMessage(msg)
    msg = msg:gsub("|c%x%x%x%x%x%x%x%x", "")
    msg = msg:gsub("|r", "")
    msg = msg:gsub("|H.-|h(.-)|h", "%1")
    msg = msg:gsub("[^%w%s%-]", " ")
    msg = msg:gsub("%s+", " ")

    return msg
end

local function hasBannedWord(msg)
    local formattedMessage = formatMessage(msg)

    for _, word in ipairs(bannedWords) do
        if string.find(string.lower(formattedMessage), string.lower(word)) then
            return true
        end
    end

    return false
end

local function filterMessage(self, event, msg, author, languageName, channelName, target, flags, zoneChannelID, channelNumber, channelNameFull, counter, guid, bnSenderID, ...)
    local channelNameLower = string.lower(channelName or "")

    for _, channelKeyword in ipairs(filteredChannels) do
        if (channelKeyword == "trade" and string.find(channelNameLower, "trade %- city")) or 
           (channelKeyword == "services" and string.find(channelNameLower, "trade %(services%) %- city")) or
           (channelKeyword == "general" and string.find(channelNameLower, "general")) then
            if hasBannedWord(msg) then
                return true
            end
        end
    end

    return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filterMessage)