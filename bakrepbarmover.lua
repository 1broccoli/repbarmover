-- ReputationBarMover.lua

-- Create a table to store frame references and other addon data
ReputationBarMover = {}

-- Function to apply saved sizes and text offsets
local function ApplySavedSettings()
    if not ReputationBarMoverDB then return end  -- Ensure the saved variable exists

    -- Apply bar sizes
    ReputationBarMover.reputationBar:SetSize(ReputationBarMoverDB.width, ReputationBarMoverDB.height)
    ReputationBarMover.backgroundBar:SetSize(ReputationBarMoverDB.width, ReputationBarMoverDB.height)
    ReputationBarMover.frame:SetSize(ReputationBarMoverDB.width, ReputationBarMoverDB.height)  -- Set frame size to match the bars

    -- Apply text offsets
    ReputationBarMover.ApplyNameTextOffset()
    ReputationBarMover.ApplyPercentageTextOffset()
    ReputationBarMover.ApplyStandingTextOffset()
    ReputationBarMover.ApplyRemainingTextOffset()
    ReputationBarMover.ApplyCurrentTotalTextOffset()

    if ReputationBarMoverDB.debug then
        print("Applied Saved Settings - Width:", ReputationBarMoverDB.width, "Height:", ReputationBarMoverDB.height)
        print("Name Text Offset - X:", ReputationBarMoverDB.nameXOffset, "Y:", ReputationBarMoverDB.nameYOffset)
        print("Percentage Text Offset - X:", ReputationBarMoverDB.percentageXOffset, "Y:", ReputationBarMoverDB.percentageYOffset)
        print("Standing Text Offset - X:", ReputationBarMoverDB.standingXOffset, "Y:", ReputationBarMoverDB.standingYOffset)
        print("Remaining Text Offset - X:", ReputationBarMoverDB.remainingXOffset, "Y:", ReputationBarMoverDB.remainingYOffset)
        print("Current/Total Text Offset - X:", ReputationBarMoverDB.currentTotalXOffset, "Y:", ReputationBarMoverDB.currentTotalYOffset)
    end
end

-- Function to apply name text offsets
function ReputationBarMover.ApplyNameTextOffset()
    if not ReputationBarMoverDB then return end
    ReputationBarMover.reputationNameText:ClearAllPoints()
    -- Set default offsets if not set
    local xOffset = ReputationBarMoverDB.nameXOffset or -5
    local yOffset = ReputationBarMoverDB.nameYOffset or 5
    ReputationBarMover.reputationNameText:SetPoint("BOTTOMRIGHT", ReputationBarMover.reputationBar, "TOPLEFT", xOffset, yOffset)
    if ReputationBarMoverDB.debug then
        print("Applied Name Text Offsets - X Offset:", xOffset, "Y Offset:", yOffset)
    end
end

-- Function to apply percentage text offsets
function ReputationBarMover.ApplyPercentageTextOffset()
    if not ReputationBarMoverDB then return end
    ReputationBarMover.reputationPercentageText:ClearAllPoints()
    -- Set default offsets if not set
    local xOffset = ReputationBarMoverDB.percentageXOffset or 5
    local yOffset = ReputationBarMoverDB.percentageYOffset or 5
    ReputationBarMover.reputationPercentageText:SetPoint("BOTTOMLEFT", ReputationBarMover.reputationBar, "TOPRIGHT", xOffset, yOffset)
    if ReputationBarMoverDB.debug then
        print("Applied Percentage Text Offsets - X Offset:", xOffset, "Y Offset:", yOffset)
    end
end

-- Function to apply standing text offsets
function ReputationBarMover.ApplyStandingTextOffset()
    if not ReputationBarMoverDB then return end
    ReputationBarMover.reputationStandingText:ClearAllPoints()
    -- Set default offsets if not set
    local xOffset = ReputationBarMoverDB.standingXOffset or 0
    local yOffset = ReputationBarMoverDB.standingYOffset or 10
    ReputationBarMover.reputationStandingText:SetPoint("BOTTOM", ReputationBarMover.reputationBar, "TOP", xOffset, yOffset)
    if ReputationBarMoverDB.debug then
        print("Applied Standing Text Offsets - X Offset:", xOffset, "Y Offset:", yOffset)
    end
end

-- Function to apply remaining text offsets
function ReputationBarMover.ApplyRemainingTextOffset()
    if not ReputationBarMoverDB then return end
    ReputationBarMover.reputationRemainingText:ClearAllPoints()
    -- Set default offsets if not set
    local xOffset = ReputationBarMoverDB.remainingXOffset or 0
    local yOffset = ReputationBarMoverDB.remainingYOffset or -15
    ReputationBarMover.reputationRemainingText:SetPoint("TOP", ReputationBarMover.reputationBar, "BOTTOM", xOffset, yOffset)
    if ReputationBarMoverDB.debug then
        print("Applied Remaining Text Offsets - X Offset:", xOffset, "Y Offset:", yOffset)
    end
end

-- Function to apply current/total text offsets
function ReputationBarMover.ApplyCurrentTotalTextOffset()
    if not ReputationBarMoverDB then return end
    ReputationBarMover.reputationCurrentTotalText:ClearAllPoints()
    -- Set default offsets if not set
    local xOffset = ReputationBarMoverDB.currentTotalXOffset or 0
    local yOffset = ReputationBarMoverDB.currentTotalYOffset or 15
    ReputationBarMover.reputationCurrentTotalText:SetPoint("TOP", ReputationBarMover.reputationBar, "BOTTOM", xOffset, yOffset)
    if ReputationBarMoverDB.debug then
        print("Applied Current/Total Text Offsets - X Offset:", xOffset, "Y Offset:", yOffset)
    end
end


-- Helper function to get standing text based on standingID
local function GetTextForStanding(standingID)
    local standingTexts = {
        [1] = "Hated",
        [2] = "Hostile",
        [3] = "Unfriendly",
        [4] = "Neutral",
        [5] = "Friendly",
        [6] = "Honored",
        [7] = "Revered",
        [8] = "Exalted",
    }
    return standingTexts[standingID] or "Unknown"
end

-- Function to get max reputation required for the current standing and the next standing

local function GetReputationThresholds(standingID)
    local thresholds = {
        [1] = {0, 36000},   -- Hated to Hostile (36,000)
        [2] = {36000, 39000},    -- Hostile to Unfriendly (3,000)
        [3] = {39000, 42000},    -- Unfriendly to Friendly (3,000)
        [4] = {0, 3000},         -- Neutral to Friendly (3,000)
        [5] = {3000, 9000},      -- Friendly to Honored (6,000)
        [6] = {9000, 21000},     -- Honored to Revered (12,000)
        [7] = {21000, 42000},    -- Revered to Exalted (21,000)
        [8] = {42000, 42000},    -- Exalted (max at 42,000)
    }
    return thresholds[standingID] or {0, 0}
end


-- Function to update the reputation bar
local function UpdateReputationBar()
    local name, standingID, minRep, maxRep, value = GetWatchedFactionInfo()

    if name then
        local standingText = GetTextForStanding(standingID)

        ReputationBarMover.reputationStandingText:SetText(standingText)
        ReputationBarMover.reputationBar:SetMinMaxValues(minRep, maxRep)
        ReputationBarMover.reputationBar:SetValue(value)
        ReputationBarMover.backgroundBar:SetMinMaxValues(minRep, maxRep)
        ReputationBarMover.backgroundBar:SetValue(maxRep)

        -- Calculate percentage
        local repPercentage = ((value - minRep) / (maxRep - minRep)) * 100

        -- Calculate remaining reputation
        local remainingRep = maxRep - value
        local remainingRepFormatted = string.format("%.1fk", remainingRep / 1000)

		-- Calculate current and total based on standing thresholds
		local currentThresholds = GetReputationThresholds(standingID)

		-- Current reputation within the standing should be (value - minRep)
		local currentRepInStanding = value - minRep

		-- Format current reputation to absolute value and total required for that standing
		local currentTotalFormatted = string.format("%.0f/%.0f", currentRepInStanding, maxRep - minRep)
		
		
        -- Update text labels
        ReputationBarMover.reputationNameText:SetText(name)
        ReputationBarMover.reputationPercentageText:SetText(string.format("%.1f%%", repPercentage))
        ReputationBarMover.reputationRemainingText:SetText(remainingRepFormatted)
        ReputationBarMover.reputationCurrentTotalText:SetText(currentTotalFormatted)

        -- Update the bar color based on standingID
        local color = FACTION_BAR_COLORS[standingID]
        if color then
            ReputationBarMover.reputationBar:SetStatusBarColor(color.r, color.g, color.b)
        else
            ReputationBarMover.reputationBar:SetStatusBarColor(1, 1, 1)  -- Default to white
        end
    else
        -- No faction tracked
        ReputationBarMover.reputationNameText:SetText("No faction tracked")
        ReputationBarMover.reputationPercentageText:SetText("")
        ReputationBarMover.reputationStandingText:SetText("")
        ReputationBarMover.reputationRemainingText:SetText("")
        ReputationBarMover.reputationCurrentTotalText:SetText("")
        ReputationBarMover.reputationBar:SetValue(0)
        ReputationBarMover.backgroundBar:SetValue(1)  -- Reset background to full when no faction is tracked
        ReputationBarMover.reputationBar:SetStatusBarColor(0.5, 0.5, 0.5)  -- Default to gray
    end
end

-- Function to change the reputation bar texture
local function ChangeTexture(texture)
    -- Change the texture of the reputation bar
    ReputationBarMover.reputationBar:SetStatusBarTexture(texture)
    ReputationBarMover.backgroundBar:SetStatusBarTexture(texture)
    
    -- Update the reputation bar
    UpdateReputationBar()
    
    -- Save the selected texture to saved variables
    ReputationBarMoverDB.texture = texture
    
    if ReputationBarMoverDB.debug then
        print("Changed texture to:", texture)
    end
end

-- Function to handle size and offset input changes and save
local function SaveSettings()
    -- Save Width and Height
    local widthInputText = ReputationBarMover.settings.widthInput:GetText()
    local heightInputText = ReputationBarMover.settings.heightInput:GetText()
    
    local width = tonumber(widthInputText)
    local height = tonumber(heightInputText)

    local MIN_WIDTH, MAX_WIDTH = 100, 1000
    local MIN_HEIGHT, MAX_HEIGHT = 10, 100

    if width and width >= MIN_WIDTH and width <= MAX_WIDTH then
        ReputationBarMoverDB.width = width
    else
        print(string.format("Invalid width input. Please enter a value between %d and %d.", MIN_WIDTH, MAX_WIDTH))
    end

    if height and height >= MIN_HEIGHT and height <= MAX_HEIGHT then
        ReputationBarMoverDB.height = height
    else
        print(string.format("Invalid height input. Please enter a value between %d and %d.", MIN_HEIGHT, MAX_HEIGHT))
    end

    -- Save Name Text Offsets
    local nameXOffsetInputText = ReputationBarMover.settings.nameXOffsetInput:GetText()
    local nameYOffsetInputText = ReputationBarMover.settings.nameYOffsetInput:GetText()
    
    local nameXOffset = tonumber(nameXOffsetInputText)
    local nameYOffset = tonumber(nameYOffsetInputText)

    -- Define reasonable ranges for name offsets
    local MIN_OFFSET, MAX_OFFSET = -500, 500  -- Adjust as needed

    if nameXOffset then
        if nameXOffset >= MIN_OFFSET and nameXOffset <= MAX_OFFSET then
            ReputationBarMoverDB.nameXOffset = nameXOffset
        else
            print(string.format("Invalid Name X Offset input. Please enter a value between %d and %d.", MIN_OFFSET, MAX_OFFSET))
        end
    end

    if nameYOffset then
        if nameYOffset >= MIN_OFFSET and nameYOffset <= MAX_OFFSET then
            ReputationBarMoverDB.nameYOffset = nameYOffset
        else
            print(string.format("Invalid Name Y Offset input. Please enter a value between %d and %d.", MIN_OFFSET, MAX_OFFSET))
        end
    end

    -- Save Percentage Text Offsets
    local percentageXOffsetInputText = ReputationBarMover.settings.percentageXOffsetInput:GetText()
    local percentageYOffsetInputText = ReputationBarMover.settings.percentageYOffsetInput:GetText()
    
    local percentageXOffset = tonumber(percentageXOffsetInputText)
    local percentageYOffset = tonumber(percentageYOffsetInputText)

    -- Define reasonable ranges for percentage offsets
    if percentageXOffset then
        if percentageXOffset >= MIN_OFFSET and percentageXOffset <= MAX_OFFSET then
            ReputationBarMoverDB.percentageXOffset = percentageXOffset
        else
            print(string.format("Invalid Percentage X Offset input. Please enter a value between %d and %d.", MIN_OFFSET, MAX_OFFSET))
        end
    end

    if percentageYOffset then
        if percentageYOffset >= MIN_OFFSET and percentageYOffset <= MAX_OFFSET then
            ReputationBarMoverDB.percentageYOffset = percentageYOffset
        else
            print(string.format("Invalid Percentage Y Offset input. Please enter a value between %d and %d.", MIN_OFFSET, MAX_OFFSET))
        end
    end

    -- Save Standing Text Offsets
    local standingXOffsetInputText = ReputationBarMover.settings.standingXOffsetInput:GetText()
    local standingYOffsetInputText = ReputationBarMover.settings.standingYOffsetInput:GetText()
    
    local standingXOffset = tonumber(standingXOffsetInputText)
    local standingYOffset = tonumber(standingYOffsetInputText)

    -- Define reasonable ranges for standing offsets
    if standingXOffset then
        if standingXOffset >= MIN_OFFSET and standingXOffset <= MAX_OFFSET then
            ReputationBarMoverDB.standingXOffset = standingXOffset
        else
            print(string.format("Invalid Standing X Offset input. Please enter a value between %d and %d.", MIN_OFFSET, MAX_OFFSET))
        end
    end

    if standingYOffset then
        if standingYOffset >= MIN_OFFSET and standingYOffset <= MAX_OFFSET then
            ReputationBarMoverDB.standingYOffset = standingYOffset
        else
            print(string.format("Invalid Standing Y Offset input. Please enter a value between %d and %d.", MIN_OFFSET, MAX_OFFSET))
        end
    end

    -- Save Remaining Text Offsets
    local remainingXOffsetInputText = ReputationBarMover.settings.remainingXOffsetInput:GetText()
    local remainingYOffsetInputText = ReputationBarMover.settings.remainingYOffsetInput:GetText()
    
    local remainingXOffset = tonumber(remainingXOffsetInputText)
    local remainingYOffset = tonumber(remainingYOffsetInputText)

    -- Define reasonable ranges for remaining offsets
    if remainingXOffset then
        if remainingXOffset >= MIN_OFFSET and remainingXOffset <= MAX_OFFSET then
            ReputationBarMoverDB.remainingXOffset = remainingXOffset
        else
            print(string.format("Invalid Remaining X Offset input. Please enter a value between %d and %d.", MIN_OFFSET, MAX_OFFSET))
        end
    end

    if remainingYOffset then
        if remainingYOffset >= MIN_OFFSET and remainingYOffset <= MAX_OFFSET then
            ReputationBarMoverDB.remainingYOffset = remainingYOffset
        else
            print(string.format("Invalid Remaining Y Offset input. Please enter a value between %d and %d.", MIN_OFFSET, MAX_OFFSET))
        end
    end

    -- Save Current/Total Text Offsets
    local currentTotalXOffsetInputText = ReputationBarMover.settings.currentTotalXOffsetInput:GetText()
    local currentTotalYOffsetInputText = ReputationBarMover.settings.currentTotalYOffsetInput:GetText()
    
    local currentTotalXOffset = tonumber(currentTotalXOffsetInputText)
    local currentTotalYOffset = tonumber(currentTotalYOffsetInputText)

    -- Define reasonable ranges for current/total offsets
    if currentTotalXOffset then
        if currentTotalXOffset >= MIN_OFFSET and currentTotalXOffset <= MAX_OFFSET then
            ReputationBarMoverDB.currentTotalXOffset = currentTotalXOffset
        else
            print(string.format("Invalid Current/Total X Offset input. Please enter a value between %d and %d.", MIN_OFFSET, MAX_OFFSET))
        end
    end

    if currentTotalYOffset then
        if currentTotalYOffset >= MIN_OFFSET and currentTotalYOffset <= MAX_OFFSET then
            ReputationBarMoverDB.currentTotalYOffset = currentTotalYOffset
        else
            print(string.format("Invalid Current/Total Y Offset input. Please enter a value between %d and %d.", MIN_OFFSET, MAX_OFFSET))
        end
    end

    -- Apply saved sizes and offsets
    ApplySavedSettings()
    ReputationBarMover.ApplyNameTextOffset()
    ReputationBarMover.ApplyPercentageTextOffset()
    ReputationBarMover.ApplyStandingTextOffset()
    ReputationBarMover.ApplyRemainingTextOffset()
    ReputationBarMover.ApplyCurrentTotalTextOffset()

    if ReputationBarMoverDB.debug then
        print("Saved new settings - Width:", ReputationBarMoverDB.width, "Height:", ReputationBarMoverDB.height,
              "Name X Offset:", ReputationBarMoverDB.nameXOffset, "Name Y Offset:", ReputationBarMoverDB.nameYOffset,
              "% X Offset:", ReputationBarMoverDB.percentageXOffset, "% Y Offset:", ReputationBarMoverDB.percentageYOffset,
              "Standing X Offset:", ReputationBarMoverDB.standingXOffset, "Standing Y Offset:", ReputationBarMoverDB.standingYOffset,
              "Remaining X Offset:", ReputationBarMoverDB.remainingXOffset, "Remaining Y Offset:", ReputationBarMoverDB.remainingYOffset,
              "Current X Offset:", ReputationBarMoverDB.currentTotalXOffset, "Current Y Offset:", ReputationBarMoverDB.currentTotalYOffset)
    end
end


-- Function to create the settings window
local function CreateSettingsWindow()
    if ReputationBarMover.settingsWindow then return ReputationBarMover.settingsWindow end

    local settings = CreateFrame("Frame", "ReputationBarSettingsWindow", UIParent, "BasicFrameTemplateWithInset")
    settings:SetSize(500, 550)  -- Increased width and height to accommodate new inputs
    settings:SetPoint("CENTER", UIParent, "CENTER")
    settings:Hide()

    settings.title = settings:CreateFontString(nil, "OVERLAY")
    settings.title:SetFontObject("GameFontHighlight")
    settings.title:SetPoint("LEFT", settings.TitleBg, "LEFT", 5, 0)
    settings.title:SetText("Reputation Bar Settings")

    -- Enable Reputation Bar Checkbox
    local enableCheckbox = CreateFrame("CheckButton", nil, settings, "InterfaceOptionsCheckButtonTemplate")
    enableCheckbox:SetPoint("TOPLEFT", settings, "TOPLEFT", 20, -40)
    enableCheckbox.Text:SetText("Enable Reputation Bar")
    enableCheckbox:SetChecked(ReputationBarMover.frame:IsShown())
    
    enableCheckbox:SetScript("OnClick", function(self)
        if self:GetChecked() then
            ReputationBarMover.frame:Show()
        else
            ReputationBarMover.frame:Hide()
        end
    end)

    -- Create texture buttons
    local textures = {
        "Interface\\AddOns\\ReputationBarMover\\Aluminium.tga",
        "Interface\\AddOns\\ReputationBarMover\\glaze.tga",
        "Interface\\AddOns\\ReputationBarMover\\Minimalist.tga",
        "Interface\\AddOns\\ReputationBarMover\\smooth.tga"
    }
    local textureNames = {"Aluminium", "Glaze", "Minimalist", "Smooth"}

    for i, texture in ipairs(textures) do
        local button = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
        button:SetSize(100, 25)
        button:SetPoint("TOPLEFT", settings, "TOPLEFT", 20 + (i-1)*110, -80)  -- Arrange buttons horizontally
        button:SetText(textureNames[i])
        
        button:SetScript("OnClick", function()
            ChangeTexture(texture)
        end)
    end

    -- Create input boxes for width and height
    local widthInput = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    widthInput:SetPoint("TOPLEFT", settings, "TOPLEFT", 20, -150)
    widthInput:SetSize(100, 30)
    widthInput:SetNumeric(true)
    settings.widthInput = widthInput

    local heightInput = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    heightInput:SetPoint("TOPLEFT", settings, "TOPLEFT", 140, -150)
    heightInput:SetSize(100, 30)
    heightInput:SetNumeric(true)
    settings.heightInput = heightInput

    -- Create input boxes for Name Text Offsets
    local nameXOffsetInput = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    nameXOffsetInput:SetPoint("TOPLEFT", settings, "TOPLEFT", 20, -200)
    nameXOffsetInput:SetSize(100, 30)
    
    settings.nameXOffsetInput = nameXOffsetInput

    local nameYOffsetInput = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    nameYOffsetInput:SetPoint("TOPLEFT", settings, "TOPLEFT", 140, -200)
    nameYOffsetInput:SetSize(100, 30)
    
    settings.nameYOffsetInput = nameYOffsetInput

    -- Create input boxes for Percentage Text Offsets
    local percentageXOffsetInput = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    percentageXOffsetInput:SetPoint("TOPLEFT", settings, "TOPLEFT", 20, -250)
    percentageXOffsetInput:SetSize(100, 30)
   
    settings.percentageXOffsetInput = percentageXOffsetInput

    local percentageYOffsetInput = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    percentageYOffsetInput:SetPoint("TOPLEFT", settings, "TOPLEFT", 140, -250)
    percentageYOffsetInput:SetSize(100, 30)
    
    settings.percentageYOffsetInput = percentageYOffsetInput

    -- Create input boxes for Standing Text Offsets
    local standingXOffsetInput = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    standingXOffsetInput:SetPoint("TOPLEFT", settings, "TOPLEFT", 20, -300)
    standingXOffsetInput:SetSize(100, 30)
    
    settings.standingXOffsetInput = standingXOffsetInput

    local standingYOffsetInput = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    standingYOffsetInput:SetPoint("TOPLEFT", settings, "TOPLEFT", 140, -300)
    standingYOffsetInput:SetSize(100, 30)
    
    settings.standingYOffsetInput = standingYOffsetInput

    -- Create input boxes for Remaining Text Offsets
    local remainingXOffsetInput = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    remainingXOffsetInput:SetPoint("TOPLEFT", settings, "TOPLEFT", 20, -350)
    remainingXOffsetInput:SetSize(100, 30)
    
    settings.remainingXOffsetInput = remainingXOffsetInput

    local remainingYOffsetInput = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    remainingYOffsetInput:SetPoint("TOPLEFT", settings, "TOPLEFT", 140, -350)
    remainingYOffsetInput:SetSize(100, 30)
    
    settings.remainingYOffsetInput = remainingYOffsetInput

    -- Create input boxes for Current/Total Text Offsets
    local currentTotalXOffsetInput = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    currentTotalXOffsetInput:SetPoint("TOPLEFT", settings, "TOPLEFT", 20, -400)
    currentTotalXOffsetInput:SetSize(100, 30)
    
    settings.currentTotalXOffsetInput = currentTotalXOffsetInput

    local currentTotalYOffsetInput = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    currentTotalYOffsetInput:SetPoint("TOPLEFT", settings, "TOPLEFT", 140, -400)
    currentTotalYOffsetInput:SetSize(100, 30)
    
    settings.currentTotalYOffsetInput = currentTotalYOffsetInput

    -- Create a save button
    local saveButton = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
    saveButton:SetSize(80, 30)
    saveButton:SetPoint("TOPLEFT", settings, "TOPLEFT", 20, -450)
    saveButton:SetText("Save")
    
    saveButton:SetScript("OnClick", SaveSettings)

    -- Populate input boxes with current values when opening settings window
    settings:SetScript("OnShow", function()
        settings.widthInput:SetText(tostring(ReputationBarMoverDB.width))  -- Set current width
        settings.heightInput:SetText(tostring(ReputationBarMoverDB.height))  -- Set current height
        settings.nameXOffsetInput:SetText(tostring(ReputationBarMoverDB.nameXOffset or -5))  -- Set current Name X offset
        settings.nameYOffsetInput:SetText(tostring(ReputationBarMoverDB.nameYOffset or 5))   -- Set current Name Y offset
        settings.percentageXOffsetInput:SetText(tostring(ReputationBarMoverDB.percentageXOffset or 5))  -- Set current Percentage X offset
        settings.percentageYOffsetInput:SetText(tostring(ReputationBarMoverDB.percentageYOffset or 5))  -- Set current Percentage Y offset
        settings.standingXOffsetInput:SetText(tostring(ReputationBarMoverDB.standingXOffset or 0))  -- Set current Standing X offset
        settings.standingYOffsetInput:SetText(tostring(ReputationBarMoverDB.standingYOffset or 10))  -- Set current Standing Y offset
        settings.remainingXOffsetInput:SetText(tostring(ReputationBarMoverDB.remainingXOffset or 0))  -- Set current Remaining X offset
        settings.remainingYOffsetInput:SetText(tostring(ReputationBarMoverDB.remainingYOffset or -15))  -- Set current Remaining Y offset
        settings.currentTotalXOffsetInput:SetText(tostring(ReputationBarMoverDB.currentTotalXOffset or 0))  -- Set current Current/Total X offset
        settings.currentTotalYOffsetInput:SetText(tostring(ReputationBarMoverDB.currentTotalYOffset or 15))  -- Set current Current/Total Y offset
    end)

    -- Labels for the input boxes
    -- Width and Height Labels
    local widthLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    widthLabel:SetPoint("BOTTOMLEFT", widthInput, "TOPLEFT", 0, 5)
    widthLabel:SetText("Bar Width:")

    local heightLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    heightLabel:SetPoint("BOTTOMLEFT", heightInput, "TOPLEFT", 0, 5)
    heightLabel:SetText("Bar Height:")

    -- Name Text Offset Labels
    local nameXOffsetLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameXOffsetLabel:SetPoint("BOTTOMLEFT", nameXOffsetInput, "TOPLEFT", 0, 5)
    nameXOffsetLabel:SetText("Faction X Offset:")

    local nameYOffsetLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameYOffsetLabel:SetPoint("BOTTOMLEFT", nameYOffsetInput, "TOPLEFT", 0, 5)
    nameYOffsetLabel:SetText("Faction Y Offset:")

    -- Percentage Text Offset Labels
    local percentageXOffsetLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    percentageXOffsetLabel:SetPoint("BOTTOMLEFT", percentageXOffsetInput, "TOPLEFT", 0, 5)
    percentageXOffsetLabel:SetText("% X Offset:")

    local percentageYOffsetLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    percentageYOffsetLabel:SetPoint("BOTTOMLEFT", percentageYOffsetInput, "TOPLEFT", 0, 5)
    percentageYOffsetLabel:SetText("% Y Offset:")

    -- Standing Text Offset Labels
    local standingXOffsetLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    standingXOffsetLabel:SetPoint("BOTTOMLEFT", standingXOffsetInput, "TOPLEFT", 0, 5)
    standingXOffsetLabel:SetText("Standing X Offset:")

    local standingYOffsetLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    standingYOffsetLabel:SetPoint("BOTTOMLEFT", standingYOffsetInput, "TOPLEFT", 0, 5)
    standingYOffsetLabel:SetText("Standing Y Offset:")

    -- Remaining Text Offset Labels
    local remainingXOffsetLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    remainingXOffsetLabel:SetPoint("BOTTOMLEFT", remainingXOffsetInput, "TOPLEFT", 0, 5)
    remainingXOffsetLabel:SetText("Remaining X Offset:")

    local remainingYOffsetLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    remainingYOffsetLabel:SetPoint("BOTTOMLEFT", remainingYOffsetInput, "TOPLEFT", 0, 5)
    remainingYOffsetLabel:SetText("Remaining Y Offset:")

    -- Current/Total Text Offset Labels
    local currentTotalXOffsetLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    currentTotalXOffsetLabel:SetPoint("BOTTOMLEFT", currentTotalXOffsetInput, "TOPLEFT", 0, 5)
    currentTotalXOffsetLabel:SetText("Current X Offset:")

    local currentTotalYOffsetLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    currentTotalYOffsetLabel:SetPoint("BOTTOMLEFT", currentTotalYOffsetInput, "TOPLEFT", 0, 5)
    currentTotalYOffsetLabel:SetText("Current Y Offset:")

    -- Create Debug Mode Toggle
    local debugCheckbox = CreateFrame("CheckButton", nil, settings, "InterfaceOptionsCheckButtonTemplate")
    debugCheckbox:SetPoint("TOPLEFT", settings, "TOPLEFT", 20, -20)
    debugCheckbox.Text:SetText("Debug Mode")
    debugCheckbox:SetChecked(ReputationBarMoverDB.debug)
    
    debugCheckbox:SetScript("OnClick", function(self)
        ReputationBarMoverDB.debug = self:GetChecked()
        if ReputationBarMoverDB.debug then
            print("Debug Mode Enabled")
        else
            print("Debug Mode Disabled")
        end
    end)

    -- Keyboard navigation
    widthInput:SetScript("OnTabPressed", function(self)
        ReputationBarMover.settings.heightInput:SetFocus()
    end)

    heightInput:SetScript("OnTabPressed", function(self)
        ReputationBarMover.settings.nameXOffsetInput:SetFocus()
    end)

    nameXOffsetInput:SetScript("OnTabPressed", function(self)
        ReputationBarMover.settings.nameYOffsetInput:SetFocus()
    end)

    nameYOffsetInput:SetScript("OnTabPressed", function(self)
        ReputationBarMover.settings.percentageXOffsetInput:SetFocus()
    end)

    percentageXOffsetInput:SetScript("OnTabPressed", function(self)
        ReputationBarMover.settings.percentageYOffsetInput:SetFocus()
    end)

    percentageYOffsetInput:SetScript("OnTabPressed", function(self)
        ReputationBarMover.settings.standingXOffsetInput:SetFocus()
    end)

    standingXOffsetInput:SetScript("OnTabPressed", function(self)
        ReputationBarMover.settings.standingYOffsetInput:SetFocus()
    end)

    standingYOffsetInput:SetScript("OnTabPressed", function(self)
        ReputationBarMover.settings.remainingXOffsetInput:SetFocus()
    end)

    remainingXOffsetInput:SetScript("OnTabPressed", function(self)
        ReputationBarMover.settings.remainingYOffsetInput:SetFocus()
    end)

    remainingYOffsetInput:SetScript("OnTabPressed", function(self)
        ReputationBarMover.settings.currentTotalXOffsetInput:SetFocus()
    end)

    currentTotalXOffsetInput:SetScript("OnTabPressed", function(self)
        ReputationBarMover.settings.currentTotalYOffsetInput:SetFocus()
    end)

    currentTotalYOffsetInput:SetScript("OnTabPressed", function(self)
        ReputationBarMover.settings.widthInput:SetFocus()
    end)

    ReputationBarMover.settingsWindow = settings

    return settings
end

-- Function to initialize the reputation bar and related frames
local function InitializeReputationBar()
    -- Create the main frame for the reputation bar
    local f = CreateFrame("Frame", "ReputationBarMoverFrame", UIParent)
    f:SetPoint("CENTER", UIParent, "CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    -- Create the reputation bar
    local reputationBar = CreateFrame("StatusBar", nil, f)
    reputationBar:SetStatusBarTexture("Interface\\AddOns\\ReputationBarMover\\smooth.tga")
    reputationBar:SetMinMaxValues(0, 1)  -- Default values
    reputationBar:SetValue(0)  -- Placeholder for actual reputation progress
    reputationBar:SetSize(ReputationBarMoverDB.width, ReputationBarMoverDB.height)  -- Set size from saved variables
    reputationBar:SetPoint("CENTER", f, "CENTER")  -- Center within the frame
    
    -- Create the background bar
    local backgroundBar = CreateFrame("StatusBar", nil, f)
    backgroundBar:SetStatusBarTexture("Interface\\AddOns\\ReputationBarMover\\smooth.tga")
    backgroundBar:SetAllPoints(reputationBar)
    backgroundBar:SetStatusBarColor(0.5, 0.5, 0.5)  -- Gray color for uncompleted progression
    backgroundBar:SetMinMaxValues(0, 1)
    backgroundBar:SetValue(1)  -- Fill the background bar to show complete
    
    -- Create text for the faction name
    local reputationNameText = reputationBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    reputationNameText:ClearAllPoints()  -- Clear existing points
    reputationNameText:SetText("Faction")  -- Placeholder text
    
    -- Create text for the reputation percentage
    local reputationPercentageText = reputationBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    reputationPercentageText:ClearAllPoints()  -- Clear existing points
    reputationPercentageText:SetText("0.0%")  -- Placeholder text
    
    -- Create text for the faction standing
    local reputationStandingText = reputationBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    reputationStandingText:ClearAllPoints()  -- Clear existing points
    reputationStandingText:SetText("Standing")  -- Placeholder text

    -- Create text for the remaining total
    local reputationRemainingText = reputationBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    reputationRemainingText:ClearAllPoints()  -- Clear existing points
    reputationRemainingText:SetText("+0.00k")  -- Placeholder text

    -- Create text for the current/total
    local reputationCurrentTotalText = reputationBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    reputationCurrentTotalText:ClearAllPoints()  -- Clear existing points
    reputationCurrentTotalText:SetText("0k/0k")  -- Placeholder text

    -- Store references in the table
    ReputationBarMover.frame = f
    ReputationBarMover.reputationBar = reputationBar
    ReputationBarMover.backgroundBar = backgroundBar
    ReputationBarMover.reputationNameText = reputationNameText
    ReputationBarMover.reputationPercentageText = reputationPercentageText
    ReputationBarMover.reputationStandingText = reputationStandingText
    ReputationBarMover.reputationRemainingText = reputationRemainingText
    ReputationBarMover.reputationCurrentTotalText = reputationCurrentTotalText
	

    -- Apply saved sizes and offsets
    ApplySavedSettings()
    
    -- Create settings window
    ReputationBarMover.settings = CreateSettingsWindow()
    
    -- Show the reputation bar by default
    f:Show()
    
    -- Event handlers for mouse interactions
    f:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            local settingsWindow = CreateSettingsWindow()
            if settingsWindow:IsShown() then
                settingsWindow:Hide()  -- Close the window if it's already open
            else
                settingsWindow:Show()  -- Show the window if it's not open
            end
        end
    end)
    
    -- Add tooltip
    f:SetScript("OnEnter", function()
        GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
        GameTooltip:SetText("Right-click to open Reputation Bar settings.")
        GameTooltip:Show()
    end)
    
    f:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Initial update
    UpdateReputationBar()
end

-- Create a frame to handle events
local eventFrame = CreateFrame("Frame")

-- Register necessary events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("UPDATE_FACTION")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Event handler function
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ReputationBarMover" then
        -- Initialize saved variables
        ReputationBarMoverDB = ReputationBarMoverDB or { 
            width = 300, 
            height = 15, 
            debug = false, 
            nameXOffset = -5, 
            nameYOffset = 5,
            percentageXOffset = 5,
            percentageYOffset = 5,
            standingXOffset = 0,
            standingYOffset = 10,
            remainingXOffset = 0,
            remainingYOffset = -15,
            currentTotalXOffset = 0,
            currentTotalYOffset = 15
        }
        print("ReputationBarMoverDB Loaded. Width:", ReputationBarMoverDB.width, "Height:", ReputationBarMoverDB.height,
              "Name X:", ReputationBarMoverDB.nameXOffset, "Name Y:", ReputationBarMoverDB.nameYOffset,
              "% X:", ReputationBarMoverDB.percentageXOffset, "Percentage Y:", ReputationBarMoverDB.percentageYOffset,
              "Standing X", ReputationBarMoverDB.standingXOffset, "Standing Y:", ReputationBarMoverDB.standingYOffset,
              "Remaining X :", ReputationBarMoverDB.remainingXOffset, "Remaining Y:", ReputationBarMoverDB.remainingYOffset,
              "Current/Total X:", ReputationBarMoverDB.currentTotalXOffset, "Current/Total Y:", ReputationBarMoverDB.currentTotalYOffset)
        
        -- Initialize the reputation bar
        InitializeReputationBar()
    elseif event == "UPDATE_FACTION" or event == "PLAYER_ENTERING_WORLD" then
        if ReputationBarMover.reputationBar then
            UpdateReputationBar()
        end
    end
end)

-- Slash command to toggle visibility
SLASH_REPBARMOVER1 = "/repmover"
SlashCmdList["REPBARMOVER"] = function()
    if ReputationBarMover.frame and ReputationBarMover.frame:IsShown() then
        ReputationBarMover.frame:Hide()
    elseif ReputationBarMover.frame then
        ReputationBarMover.frame:Show()
    end
end
