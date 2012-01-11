# encoding: utf-8

require 'oauth'
require 'twitter'

ENV['RACK_ENV'] ||= "development"

module WikiHelpers
  def link_to(page)
    '<a href="/' + page + '">' + page.gsub('_', ' ').capitalize + '</a>'
  end

  def signed_in?
    !session[:oauth][:access_token].nil?
  end

  def current_user
    session[:oauth] ? session[:oauth][:user] : nil
  end

  def authorize!
    return if ENV['RACK_ENV'] == 'test'
    redirect '/login' unless signed_in?
  end

  def oauth_consumer
    OAuth::Consumer.new(SimpleWiki::TW_KEY, SimpleWiki::TW_SECRET, :site => "http://twitter.com")
  end

  def setup_client(access_token)
    return nil unless access_token
    Twitter.configure do |config|
      config.consumer_key = SimpleWiki::TW_KEY
      config.consumer_secret = SimpleWiki::TW_SECRET
      config.oauth_token = access_token.token
      config.oauth_token_secret = access_token.secret
    end
    @client = Twitter::Client.new
    return nil unless @client
    session[:oauth][:user] = @client.current_user.screen_name
    @client
  end

  def get_request_token
    request_token = session[:oauth][:request_token]   
    request_token_secret = session[:oauth][:request_token_secret]
    if request_token.nil? or request_token_secret.nil?
      @request_token = oauth_consumer.get_request_token(:oauth_callback => "#{SimpleWiki::BASE_URL}/auth")
      session[:oauth][:request_token] = @request_token.token
      session[:oauth][:request_token_secret] = @request_token.secret
    else
      # we made this user's request token before, so recreate the object
      @request_token = OAuth::RequestToken.new(oauth_consumer, request_token, request_token_secret)
    end
    @request_token
  end

  def get_access_token
    access_token = session[:oauth][:access_token]
    access_token_secret = session[:oauth][:access_token_secret]
    unless access_token.nil? or access_token_secret.nil?
      # the ultimate goal is to get here
      @access_token = OAuth::AccessToken.new(oauth_consumer, access_token, access_token_secret)
    end
    return @access_token
  end
end
