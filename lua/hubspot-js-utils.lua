local filetypes = require("hubspot-js-utils-filetypes").defaultConfig
local fileExtensions = require("hubspot-js-utils-filetypes").fileExtensions

local buffer_find_root_dir = require("bobrown101.plugin-utils").buffer_find_root_dir
local is_dir = require("bobrown101.plugin-utils").is_dir
local file_exists = require("bobrown101.plugin-utils").file_exists
local path_join = require("bobrown101.plugin-utils").path_join
local open_file = require("bobrown101.plugin-utils").open_file

local Job = require("plenary.job")
local log = require("plenary.log").new({
	plugin = "hubspot-js-utils",
	use_console = true,
})

local M = {}

function reverse(t)
	local reversedTable = {}
	local itemCount = #t
	for k, v in ipairs(t) do
		reversedTable[itemCount + 1 - k] = v
	end
	return reversedTable
end

function splitStr(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

local function get_full_file_path_of_current_buffer()
	return
vim.fn.expand("%:p")
end

local function get_file_extension_from_path(path)
	local lastdotpos = (path:reverse()):find("%.")
	return (path:sub(1 - lastdotpos))
end

local function verify_filetype_is_valid()
	local bufnr = vim.api.nvim_get_current_buf()
	local buf_filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

	-- Filter which files we are considering.
	if not filetypes[buf_filetype] then
		log.error('current filetype is not relevant "', buf_filetype, '"')
		return false
	end
	return true
end

local function verify_static_test_dir_exists()
	local bufnr = vim.api.nvim_get_current_buf()
	local static_root_dir = buffer_find_root_dir(bufnr, function(dir)
		return is_dir(path_join(dir, "js")) and is_dir(path_join(dir, "test"))
	end)

	-- We couldn't find a root directory, so ignore this file.
	if not static_root_dir then
		log.error("No test directory found, ending")
		return false
	end
	return true
end

local function get_dirname_of_filepath(filepath)
	local result = ""
	Job:new({
		command = "dirname",
		args = { filepath },
		on_exit = function(j, return_val)
			local path = j:result()[1]
			result = path .. result
		end,
	}):sync()
	return result
end

local function mkdirp(path)
	local result = nil
	Job:new({
		command = "mkdir",
		args = { "-p", path },
		on_exit = function(j, return_val)
			result = j:result()
		end,
	}):sync()
	return result
end

local function touchFile(filepath)
	local result = nil
	Job:new({
		command = "touch",
		args = { filepath },
		on_exit = function(j, return_val)
			result = j:result()
		end,
	}):sync()
	return result
end

local function writeLineToFile(filepath, line)
	local f = assert(io.open(filepath, "a"))
	f:write(line, "\n")
	f:close()
	return
end

local function get_substring_before_and_after_match(mainstring, substring)
	local indexBeforeSubstring, indexAfterSubstring = string.find(mainstring, substring)

	local before = mainstring:sub(0, indexBeforeSubstring - 1) -- sub means substring
	local after = mainstring:sub(indexAfterSubstring + 1) -- sub means substring

	return { before = before, after = after }
end

local function generate_possible_testfilepaths_from_currentfilepath(currentfilepath)
	local filepathBeforeAfterStaticJs = get_substring_before_and_after_match(currentfilepath, "/static/js/")

	local currentfilepathextension = get_file_extension_from_path(currentfilepath)

	local possibleExtenstionsFromCurrentExtensions = fileExtensions[currentfilepathextension]

  if possibleExtenstionsFromCurrentExtensions == {} then
    print("Filetype not supported, ending")
    return
  end
	-- TODO error out if not found
	local results = {}

	for i, possibleExtension in ipairs(possibleExtenstionsFromCurrentExtensions) do
		local relativePath = string.gsub(
			filepathBeforeAfterStaticJs.after,
			"." .. currentfilepathextension,
			"-test." .. possibleExtension
		)

		local result = path_join(filepathBeforeAfterStaticJs.before, "static", "test", "spec", relativePath)
		table.insert(results, result)
	end

	return results
end

local function touch_file_recursive(filepath)
	local filepathBeforeAfterStaticJs = get_substring_before_and_after_match(filepath, "/static/test/spec/")

	local moduleName = reverse(splitStr(filepathBeforeAfterStaticJs.before, "/"))[1]

	local filePathWithoutTest = string.gsub(filepathBeforeAfterStaticJs.after, "-test%.%a+", "")

	local dirname = get_dirname_of_filepath(filepath)

	mkdirp(dirname)
	touchFile(filepath)
	writeLineToFile(filepath, "//Auto generated from hubspot-js-utils.nvim")
	writeLineToFile(filepath, "")
	writeLineToFile(filepath, 'describe("' .. moduleName .. "/" .. filePathWithoutTest .. '", () => {')
	writeLineToFile(filepath, "//")
	writeLineToFile(filepath, "})")
end

function M.test_file()
	if verify_filetype_is_valid() == false then
		return
	end
	if verify_static_test_dir_exists() == false then
		return
	end

	local buff_file_path = get_full_file_path_of_current_buffer()

	local suggested_locations = generate_possible_testfilepaths_from_currentfilepath(buff_file_path)

	for i, suggested_location in ipairs(suggested_locations) do
		if file_exists(suggested_location) then
			open_file(suggested_location)
			return
		end
	end

	local new_file_location = vim.fn.input({
		prompt = "New test file: ",
		default = suggested_locations[1],
		cancelreturn = nil,
	})

	if new_file_location ~= "" then
		touch_file_recursive(new_file_location)
		open_file(new_file_location)
	else
		log.error("New test file location is invalid - not creating '", new_file_location, '"')
	end
end

function M.setup()
	-- no-op for now, but we might need it later on
end

return M
