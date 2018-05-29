class SessionsController < ApplicationController
  def new
  end
  def create
    user = User.find_by(username: params[:session][:username])
    if user && user.authenticate(params[:session][:password])
      log_in user
      session[:current_user_id] = user.id
      session[:team] = user.team
      # redirect to appropriate page
      if user.team == 0
        # redirect generates unknown error?
        redirect_to :controller=>'game',:action=>'edit'
      else
        redirect_to :controller=>'game',:action=>'view'
      end
    else
      # use flash to confirm failed login & rerender login page (figure out later)
      flash.now[:notice] = 'Invalid login.'
      redirect_to :controller=>'sessions',:action=>'new'
    end
  end
  def destroy
    log_out
    redirect_to :controller=>'sessions',:action=>'new'
  end
end
