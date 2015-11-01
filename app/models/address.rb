class Address < ActiveRecord::Base

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
