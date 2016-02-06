#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pony'
require 'sqlite3'

configure do 
  @db = SQLite3::Database.new 'barbershop.db'
  @db.execute 'CREATE TABLE IF NOT EXISTS 
                "Users" 
                (
                  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
                  "username" TEXT NOT NULL,
                  "phone" TEXT,
                  "datestamp" TEXT,
                  "barber" TEXT,
                  "color" TEXT
                )'
end

#sinatra_origin user_login
configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/secure/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
  @username = params['username']
  @password = params['password']
    if @username == 'admin' && @password == 'secret'
      session[:identity] = params['username']
      where_user_came_from = session[:previous_url] || '/'
      redirect to where_user_came_from
    else
      erb :login_form
    end
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb 'This is a secret place that only <%=session[:identity]%> has access to!'
end
#sinatra_origin


get '/' do
	erb "Hello! <a href=\"https://github.com/bootstrap-ruby/sinatra-bootstrap\">Original</a> pattern has been modified for <a href=\"http://rubyschool.us/\">Ruby School</a>"			
end

get '/about' do
	erb :about 
end

get '/contacts' do  
    erb :contacts
end

get '/visit' do
	erb :visit 
end

post '/visit' do 
	@name = params[:name]
	@phone = params[:phone]
	@datetime = params[:datetime]
	@Hairdresser = params[:hairdresser]
  @color = params[:color]


  hh = {  :name => 'Введите имя',
          :phone => 'Введите номер телефона',
          :datetime => 'Введите дату' }
  
  @error = hh.select {|key,_| params[key] == ""}.values.join(", ")

  if @error != ''
    return erb :visit
  end



	f = File.open './public/users.txt', 'a'
	f.write "Hairdresser:#{@Hairdresser}, User: #{@name}, phone: #{@phone}, Date and time: #{@datetime}! Color: #{@color}\n\n"
	f.close

	erb "Thank you! Dear, #{@name} we'll be waiting for you at #{@datetime} Your Hairdresser:#{@Hairdresser}! Your color: #{@color}"
end

post '/contacts' do 
	@email = params[:email]
	@textarea = params[:textarea]
	
	f = File.open './public/contacts.txt', 'a'
	f.write "User: #{@email}, message: #{@textarea}! \n\n"
	f.close

#	erb "Thank you! We'll be write anwser on your e-mail: #{@email}!"


Pony.mail(
  :to => 'komyotpravlyaem@mail.ru',
  :from => params[:email],
  :subject => 'hi',
  :body => params[:email] +" сообщение: "+ params[:textarea],
  :via => :smtp,
  :via_options => { 
    :address              => 'smtp.gmail.com', 
    :port                 => '587', 
    :enable_starttls_auto => true, 
    :user_name            => 'olivka1025', 
    :password             => 'qwerty111111', 
    :authentication       => :plain, 
    :domain               => 'localhost.localdomain'
  })
#redirect '/success' 
  erb "Thank you! We'll be write anwser on your e-mail: #{@email}!"
end