class SessionsController < ApplicationController
  def new
  end
  
  def create
    user = User.find_by(:username => params[:session][:username].downcase)
    if user && user.authenticate(params[:session][:password])
      user_id = user.id
      log_in(user_id)
      #user.update(:last_login => Time.now)
      params[:session][:remember_me] == '1' ? remember(user) : forget(user)
      redirect_back_or user
    else
      flash.now[:danger] = 'Invalid email/username/password combination'
      render 'new'
    end
  end
  
  def destroy
    log_out if logged_in?
    redirect_to login_url
  end
end
