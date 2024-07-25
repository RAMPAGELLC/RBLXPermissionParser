-- Copyright (c) 2024 RAMPAGE Interactive
-- Written by vq9o

-- License: MIT
-- GitHub: https://github.com/RAMPAGELLC/RBLXPermissionParser

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Divisions = require(ReplicatedStorage.Knight.Database.Divisions)
local Qualifications = require(ReplicatedStorage.Knight.Database.Qualifications)
local RolesAPI = require(ReplicatedStorage.Packages.RolesAPI)

local Parser = {}

export type PermissionTypeString = string
export type ParsedPermissions = { string }

local function split(str, delimiter)
	local result = {}

	for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end

	return result
end

local function parsePermissions(permissions)
	local parsedPermissions = {}

	for _, permission in ipairs(permissions) do
		table.insert(parsedPermissions, split(permission, ":"))
	end

	return parsedPermissions
end

local function HasDiscordRole(Player: Player, RoleId: string): boolean
	return table.find(_G.PlayerData[Player.Name] ~= nil and _G.PlayerData[Player.Name].DiscordRoles or {}, RoleId)
end

function Parser:Parse(Player: Player, Permissions: { PermissionTypeString }, RequireAll: boolean | nil): boolean
	if RequireAll == nil then
		RequireAll = false
	end

	local PermissionsPassed: number = 0
	local ParsedPermissions: ParsedPermissions = parsePermissions(Permissions);

	for _, perm in ipairs(ParsedPermissions) do
		if PermissionsPassed > 0 and not RequireAll then
			break
		end

		if perm[1] == "Role" and RolesAPI:HasRole(Player, perm[2]) then
			PermissionsPassed += 1
		end

		if perm[1] == "Group" and Player:GetRankInGroup(tonumber(perm[2])) >= (perm[3] ~= nil and tonumber(perm[3]) or 1) then
			PermissionsPassed += 1
		end

		if perm[1] == "Username" and Player.Name == tostring(perm[2]) then
			PermissionsPassed += 1
		end

		if perm[1] == "UserId" and Player.UserId == tonumber(perm[2]) then
			PermissionsPassed += 1
		end

		if perm[1] == "Team" and Player.Team ~= nil and Player.Team.Name == perm[2] then
			PermissionsPassed += 1
		end

		if perm[1] == "Qualification" and Qualifications[perm[2]] ~= nil and HasDiscordRole(Player, Qualifications[perm[2]].DiscordRole) then
			PermissionsPassed += 1
		end

		if perm[1] == "Division" and Divisions[perm[2]] ~= nil and HasDiscordRole(Player, Divisions[perm[2]].roleId) then
			PermissionsPassed += 1
		end
	end

	return RequireAll and (PermissionsPassed >= ParsedPermissions) or PermissionsPassed >= 1
end

return function(...): boolean
	if RunService:IsServer() then
		return Parser:Parse(...)
	end

	return Parser:Parse(Players.LocalPlayer, ...)
end
