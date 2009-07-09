class EditorController < ApplicationController

  

  def index
    @user = current_user
    @vacation = Vacation.find_or_create_by_user(@user)
    unless @vacation.set_up?
      redirect_to :action => :setup unless session[:help_shown]
      session[:help_shown] = true
    end
  end

  def save
    @user = current_user
    @vacation = Vacation.find_or_create_by_user(@user)
    @vacation.enabled = params[:vacation][:enabled].to_i > 0
    @vacation.subject = params[:vacation][:subject]
    @vacation.message = params[:vacation][:message]
    if @vacation.save

      flash[:notice] = @vacation.enabled ? t("vacation_saved") :
         t("vacation_removed")
      
    else
      flash[:error] = t("error_on_save")
    end
    index
    redirect_to :action => "index"
  end

  # just a method to display generic setup info
  def help
    @username = logged_in? ? current_user.login : "<username>"
  end

end
