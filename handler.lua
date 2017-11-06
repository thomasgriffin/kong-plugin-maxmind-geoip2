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

	-- Set geolocation headers.
	if config.headers then
		header("X-Visitor-Continent", ngx.var.geoip2_continent)
		header("X-Visitor-Country-Name", ngx.var.geoip2_country_name)
		header("X-Visitor-Country-Code", ngx.var.geoip2_country_code)
		header("X-Visitor-Registered-Country-Name", ngx.var.geoip2_registered_country_name)
		header("X-Visitor-Registered-Country-Code", ngx.var.geoip2_registered_country_code)
		header("X-Visitor-Subdivision-Name", ngx.var.geoip2_subdivision_name)
		header("X-Visitor-Subdivision-Code", ngx.var.geoip2_subdivision_code)
		header("X-Visitor-City-Name", ngx.var.geoip2_city_name)
		header("X-Visitor-Postal-Code", ngx.var.geoip2_postal_code)
		header("X-Visitor-Latitude", ngx.var.geoip2_latitude)
		header("X-Visitor-Longitude", ngx.var.geoip2_longitude)
	end

	-- Prepare to append geolocation data to the request JSON body.
	if config.body then
		-- Prepare body.
		local parameters = retrieve_parameters()
		local encode	 = cjson.encode(parameters)
		local data	 	 = cjson.decode(encode)

		ngx.say(encode)

		-- Set client IP.
		local client_ip = ngx.var.remote_addr
		if ngx.req.get_headers()['x-forwarded-for'] then
			client_ip = string.match(ngx.req.get_headers()['x-forwarded-for'], "[^,%s]+")
		end

	  	-- Append the data to the body.
	  	data["gct"] = ngx.var.geoip2_continent
	  	data["gcs"] = ngx.var.geoip2_country_name
	  	data["gcc"] = ngx.var.geoip2_country_code
	  	data["grn"] = ngx.var.geoip2_registered_country_name
	  	data["grc"] = ngx.var.geoip2_registered_country_code
	  	data["gsn"] = ngx.var.geoip2_subdivision_name
	  	data["gnc"] = ngx.var.geoip2_subdivision_code
	  	data["gcn"] = ngx.var.geoip2_city_name
	  	data["gpc"] = ngx.var.geoip2_postal_code
	  	data["glt"] = ngx.var.geoip2_latitude
	  	data["gln"] = ngx.var.geoip2_longitude
	  	data["ip"]  = client_ip

	  	-- Finally, save the new body data.
	  	local transformed_body = cjson.encode(data)
	  	ngx.say(transformed_body)
	  	ngx.exit(200)
	  	set_body(transformed_body)
	  	header("Content-Length", #transformed_body)
	end
end

-- Set a custom plugin priority.
plugin.PRIORITY = 799

-- Return the plugin.
return plugin