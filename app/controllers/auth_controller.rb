class AuthController < ApplicationController

  def signin
    @errors = session[:errors]
    session[:errors] = nil
    if @errors.nil?
      @errors = []
    end


    if !session[:user].nil?
      user = User.find(session[:user])
    else
      if params["commit"].nil?
        return
      end

      login = params[:login]
      if login.nil? || login.empty?
        @errors.push('Login is empty')
      end

      password = params[:password]
      if  password.nil? || password.empty?
        @errors.push('Password is empty')
      end

      user = User.find_by(login: login, password: User.encrypt_password(password))
    end

    if user.nil?
      @errors.push("User with specified login and passoword haven't been found")
      return
    end

    session[:user] = user.id

    if user.dispatcher?
      redirect_to orders_path
    else
      redirect_to loads_path
    end
  end

  def signout
    session[:user] = nil
    redirect_to root_path
  end
end
