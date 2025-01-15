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
    -- Apply Bar textures
    ReputationBarMover.reputationBar:SetStatusBarTexture(ReputationBarMoverDB.texture)
    ReputationBarMover.backgroundBar:SetStatusBarTexture(ReputationBarMoverDB.texture)
    
    -- Apply text offsets
    ReputationBarMover.ApplyNameTextOffset()
    ReputationBarMover.ApplyPercentageTextOffset()
    ReputationBarMover.ApplyStandingTextOffset()
    ReputationBarMover.ApplyRemainingTextOffset()
    ReputationBarMover.ApplyCurrentTotalTextOffset()

    -- Apply last known reputation values
    ReputationBarMover.lastRepValue = ReputationBarMoverDB.lastRepValue or 0
end

-- Function to apply name text offsets
function ReputationBarMover.ApplyNameTextOffset()
    if not ReputationBarMoverDB then return end
    ReputationBarMover.reputationNameText:ClearAllPoints()
    -- Set default offsets if not set
    local xOffset = ReputationBarMoverDB.nameXOffset or -5
    local yOffset = ReputationBarMoverDB.nameYOffset or -15  -- Move to bottom
    ReputationBarMover.reputationNameText:SetPoint("BOTTOMLEFT", ReputationBarMover.reputationBar, "TOPLEFT", xOffset, yOffset)
end

-- Function to apply percentage text offsets
function ReputationBarMover.ApplyPercentageTextOffset()
    if not ReputationBarMoverDB then return end
    ReputationBarMover.reputationPercentageText:ClearAllPoints()
    -- Set default offsets if not set
    local xOffset = ReputationBarMoverDB.percentageXOffset or -5
    local yOffset = ReputationBarMoverDB.percentageYOffset or 0
    ReputationBarMover.reputationPercentageText:SetPoint("RIGHT", ReputationBarMover.reputationBar, "RIGHT", xOffset, yOffset)
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
    local xOffset = ReputationBarMoverDB.remainingXOffset or 5
    local yOffset = ReputationBarMoverDB.remainingYOffset or -15  -- Move to bottom
    ReputationBarMover.reputationRemainingText:SetPoint("BOTTOMRIGHT", ReputationBarMover.reputationBar, "TOPRIGHT", xOffset, yOffset)
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

-- Function to create oscillating text
local function CreateOscillatingText(parent, text)
    -- Hide any existing oscillating text frames
    if ReputationBarMover.oscillatingFrame then
        ReputationBarMover.oscillatingFrame:Hide()
    end

    local oscillatingFrame = CreateFrame("Frame", nil, parent)
    oscillatingFrame:SetSize(100, 20)  -- Adjust size as needed
    oscillatingFrame:SetPoint("LEFT", ReputationBarMover.reputationStandingText, "RIGHT", 10, -20)  -- Position to the right of the standing text

    local oscillatingText = oscillatingFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    oscillatingText:SetText(text)
    oscillatingText:SetTextColor(0, 0, 0.5)  -- Medium blue color
    oscillatingText:SetPoint("CENTER", oscillatingFrame, "CENTER")

    local totalTime = 0
    local duration = 2  -- Duration in seconds

    oscillatingFrame:SetScript("OnUpdate", function(self, elapsed)
        totalTime = totalTime + elapsed
        local alpha = math.abs(math.sin(totalTime * math.pi / duration))
        oscillatingText:SetAlpha(alpha)

        if totalTime >= duration then
            oscillatingFrame:Hide()
            self:SetScript("OnUpdate", nil)
        end
    end)

    -- Store the reference to the current oscillating frame
    ReputationBarMover.oscillatingFrame = oscillatingFrame

    return oscillatingText
end

local function ShowOscillatingText(standingText, repGained)
    local originalText = standingText:GetText()
    local originalColor = {standingText:GetTextColor()}
    standingText:SetText("+" .. repGained)
    standingText:SetTextColor(0, 0.44, 0.87)  -- Default blue color in WoW

    local oscillatingFrame = CreateFrame("Frame")
    local totalTime = 0
    local duration = 2  -- Duration in seconds

    oscillatingFrame:SetScript("OnUpdate", function(self, elapsed)
        totalTime = totalTime + elapsed
        local alpha = math.abs(math.sin(totalTime * math.pi / duration))
        standingText:SetAlpha(alpha)

        if totalTime >= duration then
            standingText:SetText(originalText)
            standingText:SetTextColor(unpack(originalColor))
            standingText:SetAlpha(1)
            self:SetScript("OnUpdate", nil)
            self:Hide()
        end
    end)
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

        -- Show oscillating text for reputation gained
        local repGained = value - (ReputationBarMover.lastRepValue or 0)
        if repGained > 0 then
            ShowOscillatingText(ReputationBarMover.reputationStandingText, repGained)
        end
        ReputationBarMover.lastRepValue = value
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

-- Function to align text elements to default positions
local function AlignTextElements()
    ReputationBarMover.reputationNameText:ClearAllPoints()
    ReputationBarMover.reputationNameText:SetPoint("BOTTOMLEFT", ReputationBarMover.reputationBar, "TOPLEFT", 0, -15)  -- Move to bottom

    ReputationBarMover.reputationStandingText:ClearAllPoints()
    ReputationBarMover.reputationStandingText:SetPoint("BOTTOM", ReputationBarMover.reputationBar, "TOP", 0, 10)

    ReputationBarMover.reputationRemainingText:ClearAllPoints()
    ReputationBarMover.reputationRemainingText:SetPoint("BOTTOMRIGHT", ReputationBarMover.reputationBar, "TOPRIGHT", 0, -15)  -- Move to bottom

    ReputationBarMover.reputationPercentageText:ClearAllPoints()
    ReputationBarMover.reputationPercentageText:SetPoint("RIGHT", ReputationBarMover.reputationBar, "RIGHT", -5, 0)

    ReputationBarMover.reputationCurrentTotalText:ClearAllPoints()
    ReputationBarMover.reputationCurrentTotalText:SetPoint("TOP", ReputationBarMover.reputationBar, "BOTTOM", 0, -15)
end

-- Function to change the tracked faction upon new reputation gained
local function ChangeTrackedFaction()
    local numFactions = GetNumFactions()
    for i = 1, numFactions do
        local name, _, standingID, minRep, maxRep, value, _, _, isHeader, isCollapsed, hasRep, isWatched = GetFactionInfo(i)
        if not isHeader and hasRep and value > (ReputationBarMover.lastRepValue or 0) then
            SetWatchedFactionIndex(i)
            break
        end
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
            print(string.format("|cffff0000 Invalid Faction Name X Offset input. Please enter a value between %d and %d.|", MIN_OFFSET, MAX_OFFSET))
        end
    end

    if nameYOffset then
        if nameYOffset >= MIN_OFFSET and nameYOffset <= MAX_OFFSET then
            ReputationBarMoverDB.nameYOffset = nameYOffset
        else
            print(string.format("|cffff0000 Invalid Faction Name Y Offset input. Please enter a value between %d and %d.|r", MIN_OFFSET, MAX_OFFSET))
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
            print(string.format("|cffff0000 Invalid Percentage X Offset input. Please enter a value between %d and %d.|", MIN_OFFSET, MAX_OFFSET))
        end
    end

    if percentageYOffset then
        if percentageYOffset >= MIN_OFFSET and percentageYOffset <= MAX_OFFSET then
            ReputationBarMoverDB.percentageYOffset = percentageYOffset
        else
            print(string.format("|cffff0000 Invalid Percentage Y Offset input. Please enter a value between %d and %d.|", MIN_OFFSET, MAX_OFFSET))
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
            print(string.format("|cffff0000 Invalid Standing X Offset input. Please enter a value between %d and %d.|", MIN_OFFSET, MAX_OFFSET))
        end
    end

    if standingYOffset then
        if standingYOffset >= MIN_OFFSET and standingYOffset <= MAX_OFFSET then
            ReputationBarMoverDB.standingYOffset = standingYOffset
        else
            print(string.format("|cffff0000 InvalidInvalid Standing Y Offset input. Please enter a value between %d and %d.|", MIN_OFFSET, MAX_OFFSET))
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
            print(string.format("|cffff0000 InvalidInvalid Remaining X Offset input. Please enter a value between %d and %d.|", MIN_OFFSET, MAX_OFFSET))
        end
    end

    if remainingYOffset then
        if remainingYOffset >= MIN_OFFSET and remainingYOffset <= MAX_OFFSET then
            ReputationBarMoverDB.remainingYOffset = remainingYOffset
        else
            print(string.format("|cffff0000  Invalid Remaining Y Offset input. Please enter a value between %d and %d.|", MIN_OFFSET, MAX_OFFSET))
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
            print(string.format("|cffff0000 InvalidInvalid Current/Total X Offset input. Please enter a value between %d and %d.|", MIN_OFFSET, MAX_OFFSET))
        end
    end

    if currentTotalYOffset then
        if currentTotalYOffset >= MIN_OFFSET and currentTotalYOffset <= MAX_OFFSET then
            ReputationBarMoverDB.currentTotalYOffset = currentTotalYOffset
        else
            print(string.format("|cffff0000 Invalid Current/Total Y Offset input. Please enter a value between %d and %d.|", MIN_OFFSET, MAX_OFFSET))
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

    -- Print a message in chat when settings are saved
    print("|cff00ff00Reputation Bar settings saved.|r")
end

-- Function to create the settings window
local function CreateSettingsWindow()
    if ReputationBarMover.settingsWindow then return ReputationBarMover.settingsWindow end

    local settings = CreateFrame("Frame", "ReputationBarSettingsWindow", UIParent, "BackdropTemplate")
    settings:SetSize(300, 200)  -- Adjusted height to accommodate texture options
    settings:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    settings:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    settings:SetBackdropColor(0, 0, 0, 0.8)  -- Background color (black with transparency)
    settings:SetBackdropBorderColor(0, 0, 0)  -- Border color
    settings:Hide()

    -- Make the settings window movable
    settings:SetMovable(true)
    settings:EnableMouse(true)
    settings:RegisterForDrag("LeftButton")
    settings:SetScript("OnDragStart", settings.StartMoving)
    settings:SetScript("OnDragStop", settings.StopMovingOrSizing)

    -- Title for the settings window
    local title = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", settings, "TOP", 0, -10)
    title:SetText("Reputation Bar Settings")
    settings.title = title

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


    -- Add an alignment texture to the settings frame
    local settingsAlignTexture = settings:CreateTexture(nil, "ARTWORK")
    settingsAlignTexture:SetSize(24, 24)
    settingsAlignTexture:SetPoint("RIGHT", settingsCloseTexture, "LEFT", -5, 0)  -- Adjusted position to the left of the close.png
    settingsAlignTexture:SetTexture("Interface\\AddOns\\ReputationBarMover\\align.png")  -- Corrected texture path
    settingsAlignTexture:SetTexCoord(0, 1, 0, 1)

    -- Add highlighting and clicking features to the settings align texture
    settingsAlignTexture:SetScript("OnEnter", function(self)
        self:SetVertexColor(0, 1, 1)
    end)
    settingsAlignTexture:SetScript("OnLeave", function(self)
        self:SetVertexColor(1, 1, 1)
    end)
    settingsAlignTexture:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            AlignTextElements()
            ApplySavedSettings()
        end
    end)

    -- Add a close texture to the settings frame
    local settingsCloseTexture = settings:CreateTexture(nil, "ARTWORK")
    settingsCloseTexture:SetSize(24, 24)
    settingsCloseTexture:SetPoint("TOPRIGHT", settings, "TOPRIGHT", -5, -5)
    settingsCloseTexture:SetTexture("Interface\\AddOns\\ReputationBarMover\\close.png")
    settingsCloseTexture:SetTexCoord(0, 1, 0, 1)

    -- Add an alignment texture to the settings frame
    local settingsAlignTexture = settings:CreateTexture(nil, "ARTWORK")
    settingsAlignTexture:SetSize(24, 24)
    settingsAlignTexture:SetPoint("RIGHT", settingsCloseTexture, "LEFT", -5, 0)  -- Adjusted position to the left of the close.png
    settingsAlignTexture:SetTexture("Interface\\AddOns\\ReputationBarMover\\align.png")  -- Corrected texture path
    settingsAlignTexture:SetTexCoord(0, 1, 0, 1)

    -- Add highlighting and clicking features to the settings close texture
    settingsCloseTexture:SetScript("OnEnter", function(self)
        self:SetVertexColor(1, 0, 0)
    end)
    settingsCloseTexture:SetScript("OnLeave", function(self)
        self:SetVertexColor(1, 1, 1)
    end)
    settingsCloseTexture:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            settings:Hide()
        end
    end)

    -- Dropdown menu for texture selection
    local textureDropdown = CreateFrame("Frame", "ReputationBarTextureDropdown", settings, "UIDropDownMenuTemplate")
    textureDropdown:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", -15, -20)
    UIDropDownMenu_SetWidth(textureDropdown, 150)
    UIDropDownMenu_SetText(textureDropdown, "Select Texture")

    local textures = {
        { text = "Aluminium", value = "Interface\\AddOns\\ReputationBarMover\\Aluminium.tga" },
        { text = "Glaze", value = "Interface\\AddOns\\ReputationBarMover\\glaze.tga" },
        { text = "Minimalist", value = "Interface\\AddOns\\ReputationBarMover\\Minimalist.tga" },
        { text = "Smooth", value = "Interface\\AddOns\\ReputationBarMover\\smooth.tga" }
    }

    UIDropDownMenu_Initialize(textureDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        for _, texture in ipairs(textures) do
            info.text = texture.text
            info.value = texture.value
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(textureDropdown, self.value)
                ChangeTexture(self.value)
                UIDropDownMenu_SetText(textureDropdown, self:GetText())
            end
            info.checked = (texture.value == ReputationBarMoverDB.texture)
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- Set the current texture as selected in the dropdown
    UIDropDownMenu_SetSelectedValue(textureDropdown, ReputationBarMoverDB.texture)
    UIDropDownMenu_SetText(textureDropdown, textures[1].text)

    -- Add a test oscillating button
    local testOscillatingButton = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
    testOscillatingButton:SetSize(120, 25)
    testOscillatingButton:SetPoint("TOPLEFT", textureDropdown, "BOTTOMLEFT", 0, -20)
    testOscillatingButton:SetText("Test Oscillating")
    testOscillatingButton:SetScript("OnClick", function()
        local oscillatingText = CreateOscillatingText(ReputationBarMover.frame, "Demo Text")
        -- Randomize color
        local r = math.random()
        local g = math.random()
        local b = math.random()
        oscillatingText:SetTextColor(r, g, b)
        oscillatingText:Show()
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
eventFrame:RegisterEvent("PLAYER_LOGOUT")

-- Event handler function
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ReputationBarMover" then
        -- Initialize saved variables
        ReputationBarMoverDB = ReputationBarMoverDB or { 
            width = 300, 
            height = 15, 
            debug = false, 
            texture = "Interface\\AddOns\\ReputationBarMover\\smooth.tga",  -- Default texture
            nameXOffset = -5, 
            nameYOffset = 5,
            percentageXOffset = 5,
            percentageYOffset = 5,
            standingXOffset = 0,
            standingYOffset = 5,
            remainingXOffset = 0,
            remainingYOffset = 5,
            currentTotalXOffset = 0,
            currentTotalYOffset = 15
        }
        print("ReputationBarMoverDB Loaded. Width:", ReputationBarMoverDB.width, "Height:", ReputationBarMoverDB.height,
              "Texture:", ReputationBarMoverDB.texture,
              "Name X:", ReputationBarMoverDB.nameXOffset, "Name Y:", ReputationBarMoverDB.nameYOffset,
              "% X:", ReputationBarMoverDB.percentageXOffset, "Percentage Y:", ReputationBarMoverDB.percentageYOffset,
              "Standing X", ReputationBarMoverDB.standingXOffset, "Standing Y:", ReputationBarMoverDB.standingYOffset,
              "Remaining X :", ReputationBarMoverDB.remainingXOffset, "Remaining Y:", ReputationBarMoverDB.remainingYOffset,
              "Current/Total X:", ReputationBarMoverDB.currentTotalXOffset, "Current/Total Y:", ReputationBarMoverDB.currentTotalYOffset)
        
        -- Initialize the reputation bar
        InitializeReputationBar()
    elseif event == "UPDATE_FACTION" or event == "PLAYER_ENTERING_WORLD" then
        if ReputationBarMover.reputationBar then
            ChangeTrackedFaction()
            UpdateReputationBar()
        end
    elseif event == "PLAYER_LOGOUT" then
        -- Save the position of the frame on logout
        local point, relativeTo, relativePoint, xOfs, yOfs = ReputationBarMover.frame:GetPoint()
        ReputationBarMoverDB.position = { point = point, relativeTo = relativeTo, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs }
        -- Save the last known reputation values
        ReputationBarMoverDB.lastRepValue = ReputationBarMover.lastRepValue
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
