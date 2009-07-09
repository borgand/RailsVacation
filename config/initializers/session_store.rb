# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_RailsVacation_session',
  :secret      => 'e9ad50f29febd4b53419913d74ac9febf483bb885911f0dbce630c875b599be3ac32d16f39fe50d0b846548ccac032f366138c95b0aadd20927c7ff0c4b98f83'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
