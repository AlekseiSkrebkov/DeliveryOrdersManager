class Address < ActiveRecord::Base
  validates :zipcode, numericality: {only_integer: true, message: 'ZIP Code should contains numbers only'}, presence: {message: "ZIP Code couldn't be blank"}
  validates :raw_line, presence: {message: "Raw line couldn't be blank"}
  validates :city, presence: {message: "City couldn't be blank"}
  validates :state, presence: {message: "State couldn't be blank"}
  validates :country, presence: {message: "Country couldn't be blank"}

  def Address.get_address(country_name, state_name, city_name, zipcode, raw_line)
    address = Address.find_by(zipcode: zipcode, raw_line: raw_line)
    if address.nil?
      address = Address.create(zipcode: zipcode, raw_line: raw_line, city: city_name, state: state_name, country: country_name)
    end
    return address
  end

  def full_address
    raw_line + ', ' + city + ', ' + state + ', ' + zipcode.to_s + ', ' + country
  end
end
