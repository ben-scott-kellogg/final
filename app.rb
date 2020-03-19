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

#Locations Table: restaurants, activities, bars
locations_table = DB.from(:locations)

#Rikis Table: reviews for locations (e.g. thumbs up/down, comment, symbol)
rikis_table = DB.from(:rikis)

#Areas Table: neighborhoods in Chicago
areas_table = DB.from(:areas)

#Users Table: users 
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

get "/" do
    puts "params: #{params}"
    @areas = areas_table.all.to_a
    view "home"
end

get "/areas/:id" do
    puts "params: #{params}"
    @area = areas_table.where(id: params[:id]).to_a[0]
    @locations = locations_table.where(areas_id: @area[:id])
    view "area"
end

get "/locations/:id" do
    puts "params: #{params}"
    @locations = locations_table.all.to_a
    @location = locations_table.where(id: params[:id]).to_a[0]
    @user = users_table.where(id: params[:id]).to_a[0]
    @rikis = rikis_table.where(locations_id: @location[:id])
    @users_table = users_table
    @average = rikis_table.where(locations_id: @location[:id]).avg(:rating)

    view "location"
end

get "/map/:id" do
  # lat: ± 90.0
  # long: ± 180.0
  puts "params: #{params}"
  @locations = locations_table.all.to_a
  @location = locations_table.where(id: params[:id]).to_a[0]
  view "map"
end

get "/users/new" do
    view "new_user"
end

post "/users/create" do
    puts params
    hashed_password = BCrypt::Password.create(params["password"])
    users_table.insert(name: params["name"], email: params["email"], password: hashed_password)
    view "create_user"
end

get "/logins/new" do
    view "new_login"
end

post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]

    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            redirect "/"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

get "/logout" do
    session["user_id"] = nil
    @current_user = nil
    view "logout"
end

# Riki Submission Page

post "/rikis/submit" do
    puts params
        rikis_table.insert(purpose: params["purpose"],
                        rating: params["rating"],
                        comments: params["comments"],
                        users_id: params["users_id"],
                        locations_id: params["locations_id"])
    view "submit_riki"
end

# Location Submission Page

post "/locations/submit" do
    puts params
    locations_table.insert(areas_id: params["areas_id"], 
                            name: params["name"],
                            address: params["address"],
                            description: params["description"])
    view "submit_location"
end