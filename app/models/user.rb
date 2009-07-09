require 'digest/sha1'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message


  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation


  def self.table_name
    Conf.users_table
  end

  def self.primary_key
    Conf.users_table_key
  end

  alias_attribute :name, Conf.full_name unless Conf.full_name.blank?
  alias_attribute :first_name, Conf.first_name unless Conf.first_name.blank?
  alias_attribute :last_name, Conf.last_name unless Conf.last_name.blank?
  alias_attribute :crypted_password, Conf.password_field.to_sym unless Conf.password_field.blank?
  alias_attribute :salt, Conf.salt_field.to_sym unless Conf.salt_field.blank?

  def dotted.name
    unless Conf.first_name.blank?
      return [first_name.split,last_name.split].flatten!.join(".")
    else
      return name.split.join(".")
    end
  end


  # disable cookie token
  def remember_token?
    false
  end
  def self.find_by_remember_token(*args)
    nil
  end
  attr_accessor :remember_token_expires_at, :remember_token

  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login.downcase) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Add old crypt() password support
  alias sha1_encrypt encrypt
  def encrypt(password)
    Conf.old_crypt_password ? password.crypt(crypted_password) : sha1_encrypt(password)
  end

  protected
    


end
