------------------------------------------------------------
------------------------------------------------------------
---- Author: Dylan 'Itokoyamato' Thuillier              ----
----                                                    ----
---- Email: itokoyamato@hotmail.fr                      ----
----                                                    ----
---- Resource: tokovoip_script                          ----
----                                                    ----
---- File: c_TokoVoip.lua                               ----\
------------------------------------------------------------
------------------------------------------------------------

--------------------------------------------------------------------------------
--	Client: TokoVoip functions
--------------------------------------------------------------------------------

TokoVoip = {};
TokoVoip.__index = TokoVoip;
local lastTalkState = false

function TokoVoip.init(self, config)
	local self = setmetatable(config, TokoVoip);
	self.config = json.decode(json.encode(config));
	self.lastNetworkUpdate = 0;
	self.lastPlayerListUpdate = self.playerListRefreshRate;
	self.playerList = {};
	return (self);
end

function TokoVoip.loop(self)
	Citizen.CreateThread(function()
		while (true) do
			Citizen.Wait(self.refreshRate);
			self:processFunction();
			self:sendDataToTS3();

			self.lastNetworkUpdate = self.lastNetworkUpdate + self.refreshRate;
			self.lastPlayerListUpdate = self.lastPlayerListUpdate + self.refreshRate;
			if (self.lastNetworkUpdate >= self.networkRefreshRate) then
				self.lastNetworkUpdate = 0;
				self:updateTokoVoipInfo();
			end
			if (self.lastPlayerListUpdate >= self.playerListRefreshRate) then
				self.playerList = GetActivePlayers();
				self.lastPlayerListUpdate = 0;
			end
		end
	end);
end

function TokoVoip.sendDataToTS3(self) -- Send usersdata to the Javascript Websocket
	self:updatePlugin("updateTokoVoip", self.plugin_data);
end

function TokoVoip.updateTokoVoipInfo(self, forceUpdate) -- Update the top-left info
	local info = "";
	if (self.mode == 1) then
		info = "Normal";
	elseif (self.mode == 2) then
		info = "Whispering";
	elseif (self.mode == 3) then
		info = "Shouting";
	end

	if (self.plugin_data.radioTalking) then
		if self.plugin_data.radioChannel < 1000 then
			info = info .. " on radio ";
		else
			info = info .. " on phone ";
		end
	end
	if (self.talking == 1 or self.plugin_data.radioTalking) then
		info = "<font class='talking'>" .. info .. "</font>";
	end
	if (self.plugin_data.radioChannel ~= -1 and self.myChannels[self.plugin_data.radioChannel]) then
		if self.plugin_data.radioChannel > 1000 then
			info = info  .. "<br> [Phone] Connected" .. ' 🎧🎤';
		else
			info = info  .. "<br> Radio: " .. self.myChannels[self.plugin_data.radioChannel].name .. ' 🎧🎤';
		end
	end
	if (info == self.screenInfo and not forceUpdate) then return end
	self.screenInfo = info;
	self:updatePlugin("updateTokovoipInfo", "" .. info);
end

function TokoVoip.updatePlugin(self, event, payload)
	exports.tokovoip_script:doSendNuiMessage(event, payload);
end

function TokoVoip.updateConfig(self)
	local data = self.config;
	data.plugin_data = self.plugin_data;
	data.pluginVersion = self.pluginVersion;
	data.pluginStatus = self.pluginStatus;
	data.pluginUUID = self.pluginUUID;
	self:updatePlugin("updateConfig", data);
end

function TokoVoip.initialize(self)
	self:updateConfig();
	self:updatePlugin("initializeSocket", nil);
	TriggerEvent('ym-hud:client:UpdateVoiceProximity', self.mode)
	Citizen.CreateThread(function()
		TriggerEvent("ym-hud:client:UpdateVoiceProximity", 2)
		while (true) do
			Citizen.Wait(5);

			if (IsDisabledControlJustPressed(0, self.keyProximity)) then -- Switch proximity modes (normal / whisper / shout)
				if (not self.mode) then
					self.mode = 1;
				end
				self.mode = self.mode + 1;
				if (self.mode > 3) then
					self.mode = 1;
				end
				setPlayerData(self.serverId, "voip:mode", self.mode, true);
				self:updateTokoVoipInfo();
				if self.mode == 1 then
					TriggerEvent("ym-hud:client:UpdateVoiceProximity", 2)
					TriggerEvent('notification', '[Tokovoip] Whispering', 1)

				elseif self.mode == 2 then
					TriggerEvent("ym-hud:client:UpdateVoiceProximity", 1)
					TriggerEvent('notification', '[Tokovoip] Normal', 1)
				else
					TriggerEvent("ym-hud:client:UpdateVoiceProximity", 3)
					TriggerEvent('notification', '[Tokovoip] Shouting', 1)
				end
			end

			if (IsControlPressed(0, self.radioKey) and self.plugin_data.radioChannel ~= -1 and self.config.radioEnabled) then -- Talk on radio
				TriggerEvent('ym-hud:client:UpdateVoiceProximity', self.mode)
				self.plugin_data.radioTalking = true;
				self.plugin_data.localRadioClicks = true;
				if (self.plugin_data.radioChannel > self.config.radioClickMaxChannel) then
					self.plugin_data.localRadioClicks = false;
				end
				if (not getPlayerData(self.serverId, "radio:talking")) then
					setPlayerData(self.serverId, "radio:talking", true, true);
				end
				self:updateTokoVoipInfo();
				if (lastTalkState == false and self.myChannels[self.plugin_data.radioChannel]) then
					if ( not IsPedSittingInAnyVehicle(PlayerPedId())) and self.plugin_data.radioChannel ~= self.listenBroadcast and self.plugin_data.radioChannel < 1000 then
						RequestAnimDict("random@arrests");
						while not HasAnimDictLoaded("random@arrests") do
							Wait(5);
						end
						TaskPlayAnim(PlayerPedId(),"random@arrests","generic_radio_chatter", 8.0, 0.0, -1, 49, 0, 0, 0, 0);
					end
					lastTalkState = true
				end
				else
				if self.talking ~= lastTalking or self.plugin_data.radioTalking == true then
					if self.plugin_data.radioTalking == true then
						self.plugin_data.radioTalking = false;
						if (getPlayerData(self.serverId, "radio:talking")) then
							setPlayerData(self.serverId, "radio:talking", false, true);
						end
					end
					if self.talking ~= lastTalking then
						lastTalking = self.talking
					end
					self:updateTokoVoipInfo();
				end
				
				if lastTalkState == true then
					lastTalkState = false
					StopAnimTask(PlayerPedId(), "random@arrests","generic_radio_chatter", -4.0);
				end
				end
				end
				end);
				end

function TokoVoip.disconnect(self)
	self:updatePlugin("disconnect");
end