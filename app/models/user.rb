class User < ActiveRecord::Base
  USER_DISPATCHER = 'dispatcher'
  USER_DRIVER = 'driver'

  def driver?
    user_type == USER_DRIVER
  end

  def dispatcher?
    user_type == USER_DISPATCHER
  end

  def self.encrypt_password(password)
    Digest::SHA2.hexdigest(password)
  end
end
