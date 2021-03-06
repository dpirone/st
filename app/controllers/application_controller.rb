# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  filter_parameter_logging :password #prevent logging of password param
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'e3a2381ed3c0a1d9a991691d41eb753b'

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

#do not log routing errors, unknown actions
#this keeps the log file size from growing unnecessarily
#EXCEPTIONS_NOT_LOGGED = ['ActionController::UnknownAction',
#                         'ActionController::RoutingError']
#protected
#  def log_error(exc)
#    super unless EXCEPTIONS_NOT_LOGGED.include?(exc.class.name)
#  end

end
