require 'sinatra'
require 'haml'
require_relative 'helpers/init'

class Main < Sinatra::Base
  helpers Sinatra::Partials
  helpers ContentFor

  before do
    @current_username = ""
  end

  get '/' do
    @overall_stats = connection.get_results_for_overall
    @user_stats = connection.get_results_for_user(@current_username)
    haml :home
  end

  post '/fordrink' do
    @current_username = params[:username]
    redirect "/#{params[:username]}"
  end

  get '/item/:item' do
    top_users =  connection.top_users_per_drink(params[:item])

    @item_stats = case
      when top_users.to_a.empty?
        nil
      else
        {:top_users => top_users }
      end
      haml :item
    end

  get '/machine/:machine' do
    "MACHINE"
    haml :machine
  end

  get '/:username' do
    @user_stats = connection.get_results_for_user(params[:username])
    haml :user
  end

  not_found do
    "NOT FOUND DUDE"
  end

  helpers do
    include DrinkStats::Helpers
    def connection
      DrinkStats::Database.new
    end
  end
end
