# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

locations_table = DB.from(:locations)
rikis_table = DB.from(:rikis)
areas_table = DB.from(:areas)
users_table = DB.from(:users)

get "/" do
    puts "params: #{params}"
    view "home"
end

get "/locations" do
    puts "params: #{params}"

    @locations = locations_table.all.to_a
    view "locations"
end

get "/users/new" do
    view "new_user"
end

post "/users/create" do
    puts "params: #{params}"
    
    users_table.insert(
        name: params["name"],
        email: params["email"],
        password: params["password"],
    )
    view "create_user"
end

get "/logins/new" do
    view "new_login"
end

post "/logins/create" do
    puts "params: #{params}"
 # is there a user with the params ["email"]
    @user = users_table.where(email: params["email"]).to_a[0]
    if @user
        #step 2: if there is, does the password match?   
        if @user[:password] == params["password"]
            session["user_id"] = @user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else view "create_login_failed"
    end
end

