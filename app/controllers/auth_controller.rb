class AuthController < ApplicationController
  def signin
  end

  def auth
    login = params[:login]
    password = params[:password]

    if login == 'Disp'
      redirect_to orders_path
    elsif login == "Driver"
      redirect_to loads_path
    end
  end
end
