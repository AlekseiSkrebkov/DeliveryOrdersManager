class User < ActiveRecord::Base
  USER_DISPATCHER = 'dispatcher'
  USER_DRIVER = 'driver'

  def driver?
    user_type == USER_DRIVER
  end

  def dispatcher?
    user_type == USER_DISPATCHER
  end
end
