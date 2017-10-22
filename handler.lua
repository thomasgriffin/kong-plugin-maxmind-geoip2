-- Load the base plugin and create a subclass.
local plugin = require("kong.plugins.base_plugin"):extend()
local header = ngx.req.set_header

-- Subclass constructor.
function plugin:new()
	plugin.super.new(self, "maxmind-geoip2")
end

-- Runs inside of the access_by_lua_block hook.
function plugin:access(config)
	-- Make sure the base plugin also runs the access function.
	plugin.super.access(self)

	-- Set geolocation headers.
	header("X-Visitor-Content", ngx.var.geoip2_continent)
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

-- Set a custom plugin priority.
plugin.PRIORITY = 2

-- Return the plugin.
return plugin