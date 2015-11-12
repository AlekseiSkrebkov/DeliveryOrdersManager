class Client < ActiveRecord::Base
  validates_presence_of :name, :message => "Client Name couldn't be blank"
  validates_presence_of :phone,:message => "Client Phone coundn't be blank"

  def self.get_by_name_and_phone(name, phone)
    Client.find_or_create_by(name: name, phone: phone)
  end

end
