-- Lapis stuff. Not global so I don't have to re-include them in different files.
lapis       = require'lapis'              -- Web framework functions
validate    = require'lapis.validate'     -- Input validation
app_helpers = require'lapis.application'  -- Application stuff

-- Function 'aliases'
capture_errors = app_helpers.capture_errors

-- The aplication
app = lapis.Application()
app:enable("etlua") -- templates
app.layout=require'views.layout' 	-- The layout of the whole wiki.
									-- views/layout.etlua

function validate.validate_functions.is_email(email,value) -- Validate function: Check if input is an email
	if value==true then
		local err='%s must be an email.'
	else
		local err='%s must not be an email.'
	end
	return (email:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?")~=nil)==value,err -- email:match(...) - Pattern for an email, ~=nil: true if there is an email, false if not. ==value: if the user wants it to be an email or not
end

function create_static_page(title,template) -- Creates a route function for a static page with an etlua template.
	return function(self)
		self.page_title=title or error('No title given (template: '..template..')')
		return { render = template}
	end
end

---------- Static Routes
app:get("index","/",create_static_page("index","index"))
app:get("register","/register",create_static_page("register","register"))
app:get("login","/login",create_static_page("login","login"))
