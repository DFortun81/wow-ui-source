local REWARDS_SECTION_OFFSET = 5;		-- vertical distance between sections

function QuestInfoTimerFrame_OnUpdate(self, elapsed)
	if ( self.timeLeft ) then
		self.timeLeft = max(self.timeLeft - elapsed, 0);
		QuestInfoTimerText:SetText(TIME_REMAINING.." "..SecondsToTime(self.timeLeft));
	end
end

function QuestInfoItem_OnClick(self)
	if ( self.type == "choice" ) then
		QuestInfoItemHighlight:SetPoint("TOPLEFT", self, "TOPLEFT", -8, 7);
		QuestInfoItemHighlight:Show();
		QuestInfoFrame.itemChoice = self:GetID();
	end
end

function QuestInfo_Display(template, parentFrame, acceptButton, material, mapView)
	local lastFrame, shownFrame, bottomShownFrame;	
	local elementsTable = template.elements;
	local bottomShownFrame;
	
	QuestInfoFrame.questLog = template.questLog;
	QuestInfoFrame.chooseItems = template.chooseItems;
	QuestInfoFrame.acceptButton = acceptButton;
	
	if ( QuestInfoFrame.mapView ~= mapView ) then
		QuestInfoFrame.mapView = mapView;	
		if ( mapView ) then
			QuestInfoFrame.rewardsFrame = MapQuestInfoRewardsFrame;
			QuestInfoRewardsFrame:Hide();
		else
			QuestInfoFrame.rewardsFrame = QuestInfoRewardsFrame;
			MapQuestInfoRewardsFrame:Hide();	
		end
	end	
	if ( QuestInfoFrame.material ~= material ) then
		QuestInfoFrame.material = material;
		local textColor, titleTextColor = GetMaterialTextColors(material);
		-- headers
		QuestInfoTitleHeader:SetTextColor(titleTextColor[1], titleTextColor[2], titleTextColor[3]);
		QuestInfoDescriptionHeader:SetTextColor(titleTextColor[1], titleTextColor[2], titleTextColor[3]);
		QuestInfoObjectivesHeader:SetTextColor(titleTextColor[1], titleTextColor[2], titleTextColor[3]);
		QuestInfoRewardsFrame.Header:SetTextColor(titleTextColor[1], titleTextColor[2], titleTextColor[3]);
		-- other text
		QuestInfoDescriptionText:SetTextColor(textColor[1], textColor[2], textColor[3]);
		QuestInfoObjectivesText:SetTextColor(textColor[1], textColor[2], textColor[3]);
		QuestInfoGroupSize:SetTextColor(textColor[1], textColor[2], textColor[3]);
		QuestInfoRewardText:SetTextColor(textColor[1], textColor[2], textColor[3]);
		-- reward frame text
		QuestInfoRewardsFrame.ItemChooseText:SetTextColor(textColor[1], textColor[2], textColor[3]);
		QuestInfoRewardsFrame.ItemReceiveText:SetTextColor(textColor[1], textColor[2], textColor[3]);
		QuestInfoRewardsFrame.SpellLearnText:SetTextColor(textColor[1], textColor[2], textColor[3]);
		QuestInfoRewardsFrame.PlayerTitleText:SetTextColor(textColor[1], textColor[2], textColor[3]);
		QuestInfoRewardsFrame.XPFrame.ReceiveText:SetTextColor(textColor[1], textColor[2], textColor[3]);
	end
	
	for i = 1, #elementsTable, 3 do
		shownFrame, bottomShownFrame = elementsTable[i](template.contentWidth);
		if ( shownFrame ) then
			shownFrame:SetParent(parentFrame);
			if ( lastFrame ) then
				shownFrame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", elementsTable[i+1], elementsTable[i+2]);
			else
				shownFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", elementsTable[i+1], elementsTable[i+2]);			
			end
			lastFrame = bottomShownFrame or shownFrame;
		end
	end
end

function QuestInfo_ShowTitle(contentWidth)
	local questTitle;
	if ( QuestInfoFrame.questLog ) then
		questTitle = GetQuestLogTitle(GetQuestLogSelection());
		if ( not questTitle ) then
			questTitle = "";
		end
		if ( IsCurrentQuestFailed() ) then
			questTitle = questTitle.." - ("..FAILED..")";
		end
	else
		questTitle = GetTitleText();
	end
	QuestInfoTitleHeader:SetText(questTitle);
	QuestInfoTitleHeader:SetWidth(contentWidth);
	return QuestInfoTitleHeader;
end

function QuestInfo_ShowDescriptionText(contentWidth)
	local questDescription;
	if ( QuestInfoFrame.questLog ) then
		questDescription = GetQuestLogQuestText();
	else
		questDescription = GetQuestText();
	end	
	QuestInfoDescriptionText:SetText(questDescription);
	QuestInfoDescriptionText:SetWidth(contentWidth);
	return QuestInfoDescriptionText;
end

function QuestInfo_ShowObjectives(contentWidth)
	local numObjectives = GetNumQuestLeaderBoards();
	local objective;
	local text, type, finished;
	local objectivesTable = QuestInfoObjectivesFrame.Objectives;
	local numVisibleObjectives = 0;
	for i = 1, numObjectives do
		text, type, finished = GetQuestLogLeaderBoard(i);
		if (type ~= "spell" and type ~= "log" and numVisibleObjectives < MAX_OBJECTIVES) then
			numVisibleObjectives = numVisibleObjectives+1;
			objective = objectivesTable[numVisibleObjectives];
			if ( not objective ) then
				objective = QuestInfoObjectivesFrame:CreateFontString("QuestInfoObjective"..numVisibleObjectives, "BACKGROUND", "QuestFontNormalSmall");
				objective:SetPoint("TOPLEFT", objectivesTable[numVisibleObjectives - 1], "BOTTOMLEFT", 0, -2);
				objective:SetJustifyH("LEFT");
				objective:SetWidth(285);
				objectivesTable[numVisibleObjectives] = objective;
			end
			if ( not text or strlen(text) == 0 ) then
				text = type;
			end
			if ( finished ) then
				objective:SetTextColor(0.2, 0.2, 0.2);
				text = text.." ("..COMPLETE..")";
			else
				objective:SetTextColor(0, 0, 0);
			end
			objective:SetText(text);
			objective:SetWidth(contentWidth);
			objective:Show();
		end
	end
	for i = numVisibleObjectives + 1, #objectivesTable do
		objectivesTable[i]:Hide();
	end
	if ( objective ) then
		QuestInfoObjectivesFrame:Show();
		return QuestInfoObjectivesFrame, objective;
	else
		QuestInfoObjectivesFrame:Hide();
		return nil;
	end
end

function QuestInfo_ShowSpecialObjectives()
	-- Show objective spell
	local spellID, spellName, spellTexture, finished;
	if ( QuestInfoFrame.questLog) then
		spellID, spellName, spellTexture, finished = GetQuestLogCriteriaSpell();
	else
		spellID, spellName, spellTexture, finished = GetCriteriaSpell();
	end
	
	local lastFrame = nil;
	local totalHeight = 0;
	
	if (spellID) then
		QuestInfoSpellObjectiveFrame.Icon:SetTexture(spellTexture);
		QuestInfoSpellObjectiveFrame.Name:SetText(spellName);
		QuestInfoSpellObjectiveFrame.spellID = spellID;
		
		QuestInfoSpellObjectiveFrame:ClearAllPoints();
		if (lastFrame) then
			QuestInfoSpellObjectiveLearnLabel:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -4);
			totalHeight = totalHeight + 4;
		else
			QuestInfoSpellObjectiveLearnLabel:SetPoint("TOPLEFT", 0, 0);
		end
		
		QuestInfoSpellObjectiveFrame:SetPoint("TOPLEFT", QuestInfoSpellObjectiveLearnLabel, "BOTTOMLEFT", 0, -4);
		
		if (finished and QuestInfoFrame.questLog) then -- don't show as completed for the initial offer, as it won't update properly
			QuestInfoSpellObjectiveLearnLabel:SetText(LEARN_SPELL_OBJECTIVE.." ("..COMPLETE..")");
			QuestInfoSpellObjectiveLearnLabel:SetTextColor(0.2, 0.2, 0.2);
		else
			QuestInfoSpellObjectiveLearnLabel:SetText(LEARN_SPELL_OBJECTIVE);
			QuestInfoSpellObjectiveLearnLabel:SetTextColor(0, 0, 0);
		end
		
		QuestInfoSpellObjectiveLearnLabel:Show();
		QuestInfoSpellObjectiveFrame:Show();
		totalHeight = totalHeight + QuestInfoSpellObjectiveFrame:GetHeight() + QuestInfoSpellObjectiveLearnLabel:GetHeight();
		lastFrame = QuestInfoSpellObjectiveFrame;
	else
		QuestInfoSpellObjectiveFrame:Hide();
		QuestInfoSpellObjectiveLearnLabel:Hide();
	end
	
	if (lastFrame) then
		QuestInfoSpecialObjectivesFrame:SetHeight(totalHeight);
		QuestInfoSpecialObjectivesFrame:Show();
		return QuestInfoSpecialObjectivesFrame;
	else
		QuestInfoSpecialObjectivesFrame:Hide();
		return nil;
	end
end

function QuestInfo_ShowTimer(contentWidth)
	local timeLeft = GetQuestLogTimeLeft();
	QuestInfoTimerFrame.timeLeft = timeLeft;
	if ( timeLeft ) then
		QuestInfoTimerText:SetText(TIME_REMAINING.." "..SecondsToTime(timeLeft));
		QuestInfoTimerText:SetWidth(contentWidth);
		QuestInfoTimerFrame:SetHeight(QuestInfoTimerFrame:GetTop() - QuestInfoTimerText:GetTop() + QuestInfoTimerText:GetHeight());
		QuestInfoTimerFrame:Show();
		return QuestInfoTimerFrame;
	else
		QuestInfoTimerFrame:Hide();
		return nil;
	end
end

function QuestInfo_ShowRequiredMoney()
	local requiredMoney = GetQuestLogRequiredMoney();
	if ( requiredMoney > 0 ) then
		MoneyFrame_Update("QuestInfoRequiredMoneyDisplay", requiredMoney);
		if ( requiredMoney > GetMoney() ) then
			-- Not enough money
			QuestInfoRequiredMoneyText:SetTextColor(0, 0, 0);
			SetMoneyFrameColor("QuestInfoRequiredMoneyDisplay", "red");
		else
			QuestInfoRequiredMoneyText:SetTextColor(0.2, 0.2, 0.2);
			SetMoneyFrameColor("QuestInfoRequiredMoneyDisplay", "white");
		end
		QuestInfoRequiredMoneyFrame:Show();
		return QuestInfoRequiredMoneyFrame;
	else
		QuestInfoRequiredMoneyFrame:Hide();
		return nil;
	end
end

function QuestInfo_ShowGroupSize()
	local groupNum;
	if ( QuestInfoFrame.questLog ) then
		groupNum = GetQuestLogGroupNum();
	else
		groupNum = GetSuggestedGroupNum();
	end
	if ( groupNum > 0 ) then
		local suggestedGroupString = format(QUEST_SUGGESTED_GROUP_NUM, groupNum);
		QuestInfoGroupSize:SetText(suggestedGroupString);
		QuestInfoGroupSize:Show();
		return QuestInfoGroupSize;
	else
		QuestInfoGroupSize:Hide();
		return nil;
	end
end

function QuestInfo_ShowDescriptionHeader()
	return QuestInfoDescriptionHeader;
end

function QuestInfo_ShowObjectivesHeader()
	return QuestInfoObjectivesHeader;
end

function QuestInfo_ShowObjectivesText(contentWidth)
	local questObjectives, _;
	if ( QuestInfoFrame.questLog ) then
		_, questObjectives = GetQuestLogQuestText();
	else
		questObjectives = GetObjectiveText();
	end
	QuestInfoObjectivesText:SetText(questObjectives);
	QuestInfoObjectivesText:SetWidth(contentWidth);
	return QuestInfoObjectivesText;
end

function QuestInfo_ShowSpacer()
	return QuestInfoSpacerFrame;
end

function QuestInfo_ShowAnchor()
	return QuestInfoAnchor;
end

function QuestInfo_ShowRewardText()
	QuestInfoRewardText:SetText(GetRewardText());
	return QuestInfoRewardText;
end

function QuestInfo_GetRewardButton(rewardsFrame, index)
	local rewardButtons = rewardsFrame.RewardButtons;
	if ( not rewardButtons[index] ) then
		button = CreateFrame("BUTTON", "$parentQuestInfoItem"..index, rewardsFrame, rewardsFrame.buttonTemplate);
		rewardButtons[index] = button;
	end
	return rewardButtons[index];
end

function QuestInfo_ShowRewards()
	local numQuestRewards;
	local numQuestChoices;
	local numQuestCurrencies;
	local numQuestSpellRewards = 0;
	local money;
	local skillName;
	local skillPoints;
	local skillIcon;
	local xp;
	local playerTitle;
	local totalHeight = 0;
	local rewardsFrame = QuestInfoFrame.rewardsFrame;
	
	if ( QuestInfoFrame.questLog ) then
		numQuestRewards = GetNumQuestLogRewards();
		numQuestChoices = GetNumQuestLogChoices();
		numQuestCurrencies = GetNumQuestLogRewardCurrencies();
		if ( GetQuestLogRewardSpell() ) then
			if (select(6, GetQuestLogRewardSpell()) and (not IsCharacterNewlyBoosted())) then
				numQuestSpellRewards = 0;
			else
				numQuestSpellRewards = 1;
			end
		end
		money = GetQuestLogRewardMoney();
		skillName, skillIcon, skillPoints = GetQuestLogRewardSkillPoints();
		xp = GetQuestLogRewardXP();
		playerTitle = GetQuestLogRewardTitle();
		ProcessQuestLogRewardFactions();
	else
		numQuestRewards = GetNumQuestRewards();
		numQuestChoices = GetNumQuestChoices();
		numQuestCurrencies = GetNumRewardCurrencies();
		if ( GetRewardSpell() ) then
			if (select(6, GetRewardSpell()) and (not IsCharacterNewlyBoosted())) then
				numQuestSpellRewards = 0;
			else
				numQuestSpellRewards = 1;
			end
		end
		money = GetRewardMoney();
		skillName, skillIcon, skillPoints = GetRewardSkillPoints();
		xp = GetRewardXP();
		playerTitle = GetRewardTitle();
	end

	local totalRewards = numQuestRewards + numQuestChoices + numQuestCurrencies;
	if ( totalRewards == 0 and money == 0 and xp == 0 and not playerTitle and numQuestSpellRewards == 0 ) then
		rewardsFrame:Hide();
		return nil;
	end
		
	-- Hide unused rewards
	local rewardButtons = rewardsFrame.RewardButtons;
	for i = totalRewards + 1, #rewardButtons do
		rewardButtons[i]:Hide();
	end
	
	local questItem, name, texture, isTradeskillSpell, isSpellLearned, quality, isUsable, numItems;
	local rewardsCount = 0;
	local lastFrame = rewardsFrame.Header;
	
	local totalHeight = rewardsFrame.Header:GetHeight();
	local buttonHeight = rewardsFrame.RewardButtons[1]:GetHeight();
	-- Setup choosable rewards
	if ( numQuestChoices > 0 ) then
		rewardsFrame.ItemChooseText:Show();
		
		local index;
		local baseIndex = rewardsCount;
		for i = 1, numQuestChoices, 1 do	
			index = i + baseIndex;
			questItem = QuestInfo_GetRewardButton(rewardsFrame, index);
			questItem.type = "choice";
			questItem.objectType = "item";
			numItems = 1;
			if ( QuestInfoFrame.questLog ) then
				name, texture, numItems, quality, isUsable = GetQuestLogChoiceInfo(i);
			else
				name, texture, numItems, quality, isUsable = GetQuestItemInfo(questItem.type, i);
			end
			questItem:SetID(i)
			questItem:Show();
			-- For the tooltip
			questItem.Name:SetText(name);
			SetItemButtonCount(questItem, numItems);
			SetItemButtonTexture(questItem, texture);
			if ( isUsable ) then
				SetItemButtonTextureVertexColor(questItem, 1.0, 1.0, 1.0);
				SetItemButtonNameFrameVertexColor(questItem, 1.0, 1.0, 1.0);
			else
				SetItemButtonTextureVertexColor(questItem, 0.9, 0, 0);
				SetItemButtonNameFrameVertexColor(questItem, 0.9, 0, 0);
			end
			if ( i > 1 ) then
				if ( mod(i,2) == 1 ) then
					questItem:SetPoint("TOPLEFT", rewardButtons[index - 2], "BOTTOMLEFT", 0, -2);
					lastFrame = questItem;
					totalHeight = totalHeight + buttonHeight + 2;
				else
					questItem:SetPoint("TOPLEFT", rewardButtons[index - 1], "TOPRIGHT", 1, 0);
				end
			else
				questItem:SetPoint("TOPLEFT", rewardsFrame.ItemChooseText, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
				lastFrame = questItem;
				totalHeight = totalHeight + buttonHeight + REWARDS_SECTION_OFFSET;
			end
			rewardsCount = rewardsCount + 1;
		end
		if ( numQuestChoices == 1 ) then
			QuestInfoFrame.chooseItems = nil
			rewardsFrame.ItemChooseText:SetText(REWARD_ITEMS_ONLY);
		elseif ( QuestInfoFrame.chooseItems ) then
			rewardsFrame.ItemChooseText:SetText(REWARD_CHOOSE);
		else
			rewardsFrame.ItemChooseText:SetText(REWARD_CHOICES);
		end
		totalHeight = totalHeight + rewardsFrame.ItemChooseText:GetHeight() + REWARDS_SECTION_OFFSET;
	else
		rewardsFrame.ItemChooseText:Hide();
	end
	
	-- Setup spell rewards
	if ( numQuestSpellRewards > 0 ) then
		rewardsFrame.SpellLearnText:Show();
		rewardsFrame.SpellLearnText:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);

		if ( QuestInfoFrame.questLog ) then
			texture, name, isTradeskillSpell, isSpellLearned, hideSpellLearnText = GetQuestLogRewardSpell();
		else
			texture, name, isTradeskillSpell, isSpellLearned, hideSpellLearnText = GetRewardSpell();
		end
		
		if ( not hideSpellLearnText ) then
			if ( isTradeskillSpell ) then
				rewardsFrame.SpellLearnText:SetText(REWARD_TRADESKILL_SPELL);
			elseif ( not isSpellLearned ) then
				rewardsFrame.SpellLearnText:SetText(REWARD_AURA);
			else
				rewardsFrame.SpellLearnText:SetText(REWARD_SPELL);
			end
		end
		totalHeight = totalHeight + rewardsFrame.SpellLearnText:GetHeight() + REWARDS_SECTION_OFFSET;

		questItem = rewardsFrame.SpellFrame;
		questItem:Show();
		-- For the tooltip
		questItem.Icon:SetTexture(texture);
		questItem.Name:SetText(name);
		questItem:SetPoint("TOPLEFT", rewardsFrame.SpellLearnText, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
		lastFrame = questItem;
		totalHeight = totalHeight + questItem:GetHeight() + REWARDS_SECTION_OFFSET;
	else
		rewardsFrame.SpellFrame:Hide();
		rewardsFrame.SpellLearnText:Hide();
	end

	-- Title reward
	if ( playerTitle ) then
		rewardsFrame.PlayerTitleText:Show();
		rewardsFrame.PlayerTitleText:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
		totalHeight = totalHeight +  rewardsFrame.PlayerTitleText:GetHeight() + REWARDS_SECTION_OFFSET;
		rewardsFrame.TitleFrame:SetPoint("TOPLEFT", rewardsFrame.PlayerTitleText, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
		rewardsFrame.TitleFrame.Name:SetText(playerTitle);
		rewardsFrame.TitleFrame:Show();
		lastFrame = rewardsFrame.TitleFrame;
		totalHeight = totalHeight +  rewardsFrame.TitleFrame:GetHeight() + REWARDS_SECTION_OFFSET;
	else
		rewardsFrame.PlayerTitleText:Hide();
		rewardsFrame.TitleFrame:Hide();
	end

	-- Setup mandatory rewards
	if ( numQuestRewards > 0 or numQuestCurrencies > 0 or money > 0 or xp > 0 ) then
		-- receive text, will either say "You will receive" or "You will also receive"
		local questItemReceiveText = rewardsFrame.ItemReceiveText;
		if ( numQuestChoices > 0 or numQuestSpellRewards > 0 or playerTitle ) then
			questItemReceiveText:SetText(REWARD_ITEMS);
		else
			questItemReceiveText:SetText(REWARD_ITEMS_ONLY);
		end
		questItemReceiveText:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
		questItemReceiveText:Show();
		totalHeight = totalHeight + questItemReceiveText:GetHeight() + REWARDS_SECTION_OFFSET;
		lastFrame = questItemReceiveText;

		-- Money and XP
		if ( QuestInfoFrame.mapView ) then
			if ( xp > 0 ) then
				rewardsFrame.XPFrame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
				rewardsFrame.XPFrame.Name:SetText(BreakUpLargeNumbers(xp));
				rewardsFrame.XPFrame:Show();
				lastFrame = rewardsFrame.XPFrame;				
				totalHeight = totalHeight + buttonHeight + REWARDS_SECTION_OFFSET;
			else
				rewardsFrame.XPFrame:Hide();
			end
			if ( money > 0 ) then
				if ( xp > 0 ) then
					rewardsFrame.MoneyFrame:SetPoint("TOPLEFT", rewardsFrame.XPFrame, "TOPRIGHT", 2, 0);
				else
					rewardsFrame.MoneyFrame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
					lastFrame = rewardsFrame.MoneyFrame;					
					totalHeight = totalHeight + buttonHeight + REWARDS_SECTION_OFFSET;
				end
				rewardsFrame.MoneyFrame.Name:SetText(GetMoneyString(money));
				rewardsFrame.MoneyFrame:Show();
			else
				rewardsFrame.MoneyFrame:Hide();
			end
		else
			-- Money rewards
			if ( money > 0 ) then
				MoneyFrame_Update(rewardsFrame.MoneyFrame, money);
				rewardsFrame.MoneyFrame:Show();
			else
				rewardsFrame.MoneyFrame:Hide();
			end
			-- XP rewards
			if ( QuestInfo_ToggleRewardElement(rewardsFrame.XPFrame, BreakUpLargeNumbers(xp), lastFrame) ) then
				lastFrame = rewardsFrame.XPFrame;
				totalHeight = totalHeight + rewardsFrame.XPFrame:GetHeight() + REWARDS_SECTION_OFFSET;
			end
		end
		-- Skill Point rewards
		if ( QuestInfo_ToggleRewardElement(rewardsFrame.SkillPointFrame, skillPoints, lastFrame) ) then
			lastFrame = rewardsFrame.SkillPointFrame;
			rewardsFrame.SkillPointFrame.Icon:SetTexture(skillIcon);
			if (skillName) then
				rewardsFrame.SkillPointFrame.Name:SetFormattedText(BONUS_SKILLPOINTS, skillName);
				rewardsFrame.SkillPointFrame.tooltip = format(BONUS_SKILLPOINTS_TOOLTIP, skillPoints, skillName);
			else
				rewardsFrame.SkillPointFrame.tooltip = nil;
				rewardsFrame.SkillPointFrame.Name:SetText("");
			end
			totalHeight = totalHeight + buttonHeight + REWARDS_SECTION_OFFSET;
		end
		-- Item rewards
		local index;
		local baseIndex = rewardsCount;
		local buttonIndex = 0;
		for i = 1, numQuestRewards, 1 do
			buttonIndex = buttonIndex + 1;
			index = i + baseIndex;
			questItem = QuestInfo_GetRewardButton(rewardsFrame, index);
			questItem.type = "reward";
			questItem.objectType = "item";
			if ( QuestInfoFrame.questLog ) then
				name, texture, numItems, quality, isUsable = GetQuestLogRewardInfo(i);
			else
				name, texture, numItems, quality, isUsable = GetQuestItemInfo(questItem.type, i);
			end
			questItem:SetID(i)
			questItem:Show();
			-- For the tooltip
			questItem.Name:SetText(name);
			SetItemButtonCount(questItem, numItems);
			SetItemButtonTexture(questItem, texture);
			if ( isUsable ) then
				SetItemButtonTextureVertexColor(questItem, 1.0, 1.0, 1.0);
				SetItemButtonNameFrameVertexColor(questItem, 1.0, 1.0, 1.0);
			else
				SetItemButtonTextureVertexColor(questItem, 0.9, 0, 0);
				SetItemButtonNameFrameVertexColor(questItem, 0.9, 0, 0);
			end
			
			if ( buttonIndex > 1 ) then
				if ( mod(buttonIndex,2) == 1 ) then
					questItem:SetPoint("TOPLEFT", rewardButtons[index - 2], "BOTTOMLEFT", 0, -2);
					lastFrame = questItem;
					totalHeight = totalHeight + buttonHeight + 2;
				else
					questItem:SetPoint("TOPLEFT", rewardButtons[index - 1], "TOPRIGHT", 1, 0);
				end
			else
				questItem:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
				lastFrame = questItem;
				totalHeight = totalHeight + buttonHeight + REWARDS_SECTION_OFFSET;				
			end
			rewardsCount = rewardsCount + 1;
		end
		
		-- currency
		baseIndex = rewardsCount;
		for i = 1, numQuestCurrencies, 1 do
			buttonIndex = buttonIndex + 1;
			index = i + baseIndex;
			questItem = QuestInfo_GetRewardButton(rewardsFrame, index);
			questItem.type = "reward";
			questItem.objectType = "currency";
			if ( QuestInfoFrame.questLog ) then
				name, texture, numItems = GetQuestLogRewardCurrencyInfo(i);
			else
				name, texture, numItems = GetQuestCurrencyInfo(questItem.type, i);
			end
			questItem:SetID(i)
			questItem:Show();
			-- For the tooltip
			questItem.Name:SetText(name);
			SetItemButtonCount(questItem, numItems);
			SetItemButtonTexture(questItem, texture);
			SetItemButtonTextureVertexColor(questItem, 1.0, 1.0, 1.0);
			SetItemButtonNameFrameVertexColor(questItem, 1.0, 1.0, 1.0);
			
			if ( buttonIndex > 1 ) then
				if ( mod(buttonIndex,2) == 1 ) then
					questItem:SetPoint("TOPLEFT", rewardButtons[index - 2], "BOTTOMLEFT", 0, -2);
					lastFrame = questItem;
					totalHeight = totalHeight + buttonHeight + 2;
				else
					questItem:SetPoint("TOPLEFT", rewardButtons[index - 1], "TOPRIGHT", 1, 0);
				end
			else
				questItem:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
				lastFrame = questItem;
				totalHeight = totalHeight + buttonHeight + REWARDS_SECTION_OFFSET;
			end
			rewardsCount = rewardsCount + 1;
		end
	else	
		rewardsFrame.ItemReceiveText:Hide();
		rewardsFrame.MoneyFrame:Hide();
		rewardsFrame.XPFrame:Hide();		
		rewardsFrame.SkillPointFrame:Hide();
	end

	-- deselect item
	QuestInfoFrame.itemChoice = 0;
	if ( rewardsFrame.ItemHighlight ) then
		rewardsFrame.ItemHighlight:Hide();
	end
	rewardsFrame:Show();
	rewardsFrame:SetHeight(totalHeight);
	return rewardsFrame, lastFrame;
end

function QuestInfo_ToggleRewardElement(frame, value, anchor)
	if ( value and value ~= 0 ) then
		frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
		frame.ValueText:SetText(value);
		frame:Show();
		return true;
	else
		frame:Hide();
	end
end

QUEST_TEMPLATE_DETAIL = { questLog = nil, chooseItems = nil, contentWidth = 285,
	elements = {
		QuestInfo_ShowTitle, 10, -10,
		QuestInfo_ShowDescriptionText, 0, -5,
		QuestInfo_ShowObjectivesHeader, 0, -15,	
		QuestInfo_ShowObjectivesText, 0, -5,
		QuestInfo_ShowSpecialObjectives, 0, -10,
		QuestInfo_ShowGroupSize, 0, -10,
		QuestInfo_ShowRewards, 0, -15,
		QuestInfo_ShowSpacer, 0, -15,
	}
}

QUEST_TEMPLATE_LOG = { questLog = true, chooseItems = nil, contentWidth = 285,
	elements = {
		QuestInfo_ShowTitle, 5, -5,
		QuestInfo_ShowObjectivesText, 0, -5,
		QuestInfo_ShowTimer, 0, -10,
		QuestInfo_ShowObjectives, 0, -10,
		QuestInfo_ShowSpecialObjectives, 0, -10,
		QuestInfo_ShowRequiredMoney, 0, 0,
		QuestInfo_ShowGroupSize, 0, -10,
		QuestInfo_ShowDescriptionHeader, 0, -10,
		QuestInfo_ShowDescriptionText, 0, -5,
		QuestInfo_ShowRewards, 0, -10,
		QuestInfo_ShowSpacer, 0, -10
	}
}

QUEST_TEMPLATE_REWARD = { questLog = nil, chooseItems = true, contentWidth = 285,
	elements = {
		QuestInfo_ShowTitle, 5, -10,
		QuestInfo_ShowRewardText, 0, -5,
		QuestInfo_ShowRewards, 0, -10,
		QuestInfo_ShowSpacer, 0, -10
	}
}

QUEST_TEMPLATE_MAP_DETAILS = { questLog = true, chooseItems = nil, contentWidth = 244,
	elements = {
		QuestInfo_ShowTitle, 5, -5,
		QuestInfo_ShowObjectivesText, 0, -5,
		QuestInfo_ShowTimer, 0, -10,
		QuestInfo_ShowObjectives, 0, -10,
		QuestInfo_ShowSpecialObjectives, 0, -10,
		QuestInfo_ShowRequiredMoney, 0, 0,
		QuestInfo_ShowGroupSize, 0, -10,
		QuestInfo_ShowDescriptionHeader, 0, -10,
		QuestInfo_ShowDescriptionText, 0, -5,
		QuestInfo_ShowSpacer, 0, 0,
	}
}

QUEST_TEMPLATE_MAP_REWARDS = { questLog = true, chooseItems = nil, contentWidth = 244,
	elements = {
		QuestInfo_ShowRewards, 8, -42,
	}
}