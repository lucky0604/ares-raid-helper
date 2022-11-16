local GlobalAddonName, ARH = ...

ARH.VERSION = 1000
ARH.T = "R"

ARH.Slash = {}
ARH.OnAddonMessage = {}
ARH.MiniMapMenu = {}
ARH.Modules = {}
ARH.ModulesLoaded = {}
ARH.ModulesOptions = {}
ARH.Classic = {}
ARH.Debug = {}
ARH.RaidVersions = {}
ARH.Temp = {}

ARH.A = {}

ARH.msg_prefix = {
	["EXRTADD"] = true,
}

ARH.L = {}
ARH.locale = GetLocale()

do
	local version, buildVersion, buildDate, uiVersion = GetBuildInfo()
	ARH.clientUIinterface = uiVersion
	local expansion, majorPatch, minorPatch = (version or "5.0.0"):match("^(%d+)%.(%d+)%.(%d+)")
	ARH.clientVersion = (expansion or 0) * 10000 + (majorPatch or 0) * 100 + (minorPatch or 0)
end

-- version
if ARH.clientVersion < 20000 then
	ARH.isClassic = true
	ARH.T = "Classic"
elseif ARH.clientVersion < 30000 then
	ARH.isClassic = true
	ARH.isBC = true
	ARH.T = "BC"
elseif ARH.clientVersion < 40000 then
	ARH.isClassic = true
	ARH.isBC = true
	ARH.isLK = true
	ARH.T = "WotLK"
elseif ARH.clientVersion < 50000 then
	ARH.isClassic = true
	ARH.isBC = true
	ARH.isLK = true
	ARH.isCata = true
	ARH.T = "Cataclysm"
elseif ARH.clientVersion >= 100000 then
	ARH.is10 = true
end

ARH.SDB = {}

do
	local realmKey = GetRealmName() or ""
	local charName = UnitName'player' or ""
	realmKey = realmKey:gsub(" ", "")
	ARH.SDB.realmKey = realmKey
	ARH.SDB.charKey = charName .. "-" .. realmKey
	ARH.SDB.charName = charName
	ARH.SDB.charLevel = UnitLevel'player'
end

-- global table
ARH.GDB = {}

local pcall, unpack, pairs, coroutine, assert, next = pcall, unpack, pairs, coroutine, assert, next
local GetTime, IsEncounterInProgress, CombatLogGetCurrentEventInfo = GetTime, IsEncounterInProgress, CombatLogGetCurrentEventInfo
local SendAddonMessage, strsplit = C_ChatInfo.SendAddonMessage, strsplit
local C_Timer_NewTicker, debugprofilestop = C_Timer.NewTicker, debugprofilestop

if ARH.T == "D" then
	ARH.isDev = true
	pcall = function(func, ...)
		func(...)
		return true
	end
end

ARH.NULL = {}
ARH.NULLfunc = function() end

ARH.mod = {}

do
	local function mod_LoadOptions(this)
		this:SetScript("OnShow", nil)
		if this.Load then
			this:Load()
		end
		this.Load = nil
		ARH.F.dprint(this.moduleName.."'s options loaded")
		this.isLoaded = true
	end
	local function mod_Options_CreateTitle(self)
		self.title = ARH.lib:Text(self, self.name, 20):Point(15, 6):Top()
	end
	function ARH:New(moduleName, localizatedName, disableOptions)
		if ARH.A[moduleName] then
			return false
		end
		local self = {}
		for k, v in pairs(ARH.mod) do self[k] = v end
		if not disableOptions then
			self.options = ARH.Options:Add(moduleName, localizatedName)
			self.options:Hide()
			self.options.moduleName = moduleName
			self.options.name = localizatedName or moduleName
			self.options.SetScript("OnShow", mod_LoadOptions)
			self.options.CreateTitle = mod_Options_CreateTitle
			ARH.ModulesOptions[#ARH.ModulesOptions + 1] = self.options
		end
		self.main = CreateFrame("Frame", nil)
		self.main.events = {}
		self.main:SetScript("OnEvent", ARH.mod.Event)
		self.main.ADDON_LOADED = ARH.NULLfunc

		if ARH.T == "D" or ARH.T == "DU" then
			self.main.eventsCounter = {}
			self.main:HookScript("OnEvent", ARH.mod.HookEvent)
			self.main.name = moduleName
		end
		self.db = {}
		self.name = moduleName
		table.insert(ARH.Modules, self)
		ARH.A[moduleName] = self
		ARH.F.dprint("New Module: "..moduleName)
		return self
	end
end

function ARH.mod:Event(event, ...)
	return self[event](self, ...)
end

if ARH.T == "DU" then
	local ARHDebug = ARH.Debug
	function ARH.mod:Event(event, ...)
		local dt = debugprofilestop()
		self[event](self, ...)
		ARHDebug[#ARHDebug + 1] = {debugprofilestop() - dt, self.name, event}
	end
end

function ARH.mod:HookEvent(event)
	self.eventsCounter[event] = self.eventsCounter[event] and self.eventsCounter[event] + 1 or 1
end

