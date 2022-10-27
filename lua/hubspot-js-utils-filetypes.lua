local M = {}

local jsJsx = "javascript.jsx"
local js = "javascript"
local ts = "typescript"
local tsJsx = "typescript.jsx"
local jsReact = "javascriptreact"
local tsReact = "typescriptreact"

M.defaultConfig = {
	[jsJsx] = true,
	[js] = true,
	[ts] = true,
	[tsJsx] = true,
	[jsReact] = true,
	[tsReact] = true,
}

local javascriptFileExtensions = {
	"js",
	"ts",
	"jsx",
	"tsx",
}

M.fileExtensions = {
	["js"] = javascriptFileExtensions,
	["ts"] = javascriptFileExtensions,
	["jsx"] = javascriptFileExtensions,
	["tsx"] = javascriptFileExtensions,
}

return M
