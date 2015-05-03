-- Lapis stuff. Not global so I don't have to re-include them in different files.
lapis       = require'lapis'              -- Web framework functions
validate    = require'lapis.validate'     -- Input validation
app_helpers = require'lapis.application'  -- Application stuff
Model=require("lapis.db.model").Model

-- Used for password encryption
bcrypt=require'bcrypt'
function createUser(model,user,pass,email)
	return true,model:create({
		username=user,
		password=enc(user,pass),
		email=email,
		createdate=os.time()
	})
end
function verifyLogin(model,user,pass)
	local target=model:find({username=user})
	local digest=target.password
	if not verify(user,pass,digest)	then
		return false,"Username not found" -- prevent people from seeing if a user exists
										  -- to try to prevent bruteforce attempts
	elseif target.banned then
		return false,"User is currently banned."
	end	
	return true
end

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

---------- Dynamic Routes
---- User creation
app:match("/create-user",capture_errors({ -- Called from /register, handles POST request to create a user.
	function(self)
		self.page_title='register'
		validate.assert_valid(self.req.params_post,{
			{"username","Username not entered?",exists=true,max_length=64}, -- Max username length in the DB is 64.
			{"password","Password too short/too long",exists=true,min_length=6,max_length=128}, -- have you even seen a 128 char pass?
			{"email","Enter your email. We promise we won't spam you.",exists=true,is_email=true,min_length=3}
		})
		local Users=Model:extend("users",{primary_key="uid"})
		if Users:find({username=self.req.params_post.username}) then
			yield_error"Username already in use!"
		elseif Users:find({email=self.req.params_post.email}) then
			yield_error"Email already in use!"
		end
		createUser(Users,self.req.params_post.username,self.req.params_post.password,self.req.params_post.email)
		self.success=true
		return { render = 'register' }
	end,
	on_error = create_static_page("register","register")
}))

--  User login
app:match("/login-user",capture_errors({
	function(self)
		self.page_title='login'
		validate.assert_valid(self.req.params_post,{
			{"username","Please enter your username.",exists=true},
			{"password","Please enter your password.",exists=true},
		})
		local Users=Model:extend("users",{primary_key="uid"})
		local success,err=verifyLogin(Users,self.req.params_post.username,self.req.params_post.password)
		if success then
			self.session.username=self.req.params_post.username
			self.session.signed_in=true
			self.success=true
		else
			yield_error(err)
		end
		return {render = 'login'}
	end,
	on_error=create_static_page("login","login")
}))
