class DeploysController < ApplicationController
  authorize_actions_for Deploy

  protect_from_forgery :except => :create

  skip_before_filter :verify_authenticity_token, :only => :create

  def create
    @app = App.find_by! api_key: params[:api_key]
    @deploy = @app.deploys.create!(default_deploy || heroku_deploy)
    render :xml => @deploy
  end

  def index
    @app = resource_app
    @deploys = @app.deploys.by_created_at.page(params[:page]).per(10)
  end

  def show
    @app = resource_app
    @deploy = @app.deploys.find params[:id]
  end

  private
    def resource_app
      @resource_app ||= current_user_or_guest.available_apps.detect_by_param!(params[:app_id])
    end

    def default_deploy
      if params[:deploy]
        {
          :username     => params[:deploy][:local_username],
          :environment  => params[:deploy][:rails_env],
          :repository   => params[:deploy][:scm_repository],
          :revision     => params[:deploy][:scm_revision],
          :message      => params[:deploy][:message]
        }
      end
    end

    # handle Heroku's HTTP post deployhook format
    def heroku_deploy
      {
        :username     => params[:user],
        :environment  => params[:rack_env].try(:downcase) || params[:app],
        :repository   => "git@heroku.com:#{params[:app]}.git",
        :revision     => params[:head],
      }
    end

end

