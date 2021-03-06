#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pony'
require 'sqlite3'

#для того чтобы добавлялись уникальные парикмахеры в базу
def is_barber_exists? db, name
  db.execute('select * from Barbers where name=?',[name]).length > 0
end

def seed_db db, barbers
  barbers.each do |barber|
    if !is_barber_exists? db, barber
      db.execute 'insert into Barbers (name) values (?)',[barber]
    end
  end
end

 def get_db
    db = SQLite3::Database.new 'barbershop.db'
    db.results_as_hash = true
    return db
  end

before do
  #достаем список парикмахров
  @hairdressers = get_db.execute 'select * from Barbers'
end

configure do 
  get_db.execute 'CREATE TABLE IF NOT EXISTS 
                "Users" 
                (
                  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
                  "username" TEXT NOT NULL,
                  "phone" TEXT,
                  "datestamp" TEXT,
                  "barber" TEXT,
                  "color" TEXT
                )'

  get_db.execute 'CREATE TABLE IF NOT EXISTS 
                "Barbers" 
                (
                  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
                  "name" TEXT NOT NULL
                )'
  seed_db get_db, ['Jessie Pinkman', 'Walter White', 'Gus Fring', 'Mike Erhman']
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
	erb "Hello Ruby!"			
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

# запись в файл
#	f = File.open './public/users.txt', 'a'
#	f.write "Hairdresser:#{@Hairdresser}, User: #{@name}, phone: #{@phone}, Date and time: #{@datetime}! Color: #{@color}\n\n"
#	f.close

# запись в базу
get_db.execute 'insert into Users (username,phone,datestamp,barber,color)
                  values (?, ?, ?, ?, ?)',
                  [@name, @phone, @datetime, @Hairdresser, @color]

	erb "<h2>Thank you! Dear, #{@name} we'll be waiting for you at #{@datetime} Your Hairdresser:#{@Hairdresser}! Your color: #{@color}</h2>"
end

post '/contacts' do 
	@email = params[:email]
	@textarea = params[:textarea]
	
	f = File.open './public/contacts.txt', 'a'
	f.write "User: #{@email}, message: #{@textarea}! \n\n"
	f.close

#	erb "Thank you! We'll be write anwser on your e-mail: #{@email}!"

# отправка на почту сообщения
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

#вывод из базы данных плохой вариант
# db = get_db

# db.execute 'select * from Users' do |row|
#   print row[1]
#   print "\t-\t"
#   puts row[3]
#   puts '========='
# end

#вывод из базы данных хороший вариант
# get_db.execute 'select * from Users order by id desc' do |row|
#   print row['username']
#   print "\t-\t"
#   puts row['datestamp']
#   puts '========='
# end

#вывод из базы данных в представление
get '/showusers' do
  @results = get_db.execute 'select * from Users order by id desc'
  erb :showusers
end

