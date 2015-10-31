class Client < ActiveRecord::Base

  def Client.get_by_name_and_phone(name, phone)
    Client.find_or_create_by(name: name, phone: phone)
  end

end
