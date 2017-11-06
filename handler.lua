-- Load the base plugin and create a subclass.
local plugin    = require("kong.plugins.base_plugin"):extend()
local cjson     = require "cjson"
local multipart = require "multipart"
local utils 	= require "kong.tools.utils"
local body      = ngx.req.read_body
local set_body  = ngx.req.set_body_data
local get_body  = ngx.req.get_body_data
local header    = ngx.req.set_header

-- Function to grab the body params.
local function retrieve_parameters()
	body()
	local body_parameters, err
	local content_type = ngx.req.get_headers()["Content-Type"]
	if content_type and string.find(content_type:lower(), "multipart/form-data", nil, true) then
		body_parameters = multipart(get_body(), content_type):get_all()
	elseif content_type and string.find(content_type:lower(), "application/json", nil, true) then
		body_parameters, err = cjson.decode(get_body())
		if err then
			body_parameters = {}
		end
	else
		body_parameters = ngx.req.get_post_args()
	end

	return utils.table_merge(ngx.req.get_uri_args(), body_parameters)
end

-- Subclass constructor.
function plugin:new()
	plugin.super.new(self, "maxmind-geoip2")
end

-- Runs inside of the access_by_lua_block hook.
function plugin:access(config)
	-- Make sure the base plugin also runs the access function.
	plugin.super.access(self)


end

-- Set a custom plugin priority.
plugin.PRIORITY = 799

-- Return the plugin.
return plugin