class LoaderController < ApplicationController

  def upload_orders

  end

  def upload
    uploaded_csv = params[:orders]
    file_path = Rails.root.join('uploads', uploaded_csv.original_filename)
    File.open(file_path, 'wb') do |file|
      file.write(uploaded_csv.read)
      read_csv(file_path)
    end
    redirect_to orders_path
  end

private
  def read_csv(file_path)
    require 'csv'
    @duplications = Array.new

    CSV.foreach(file_path, :headers => true) do |row|
      @data_array = row
      #logger.info @data_array
      read_order
    end

    logger.info @duplications

  end

  def read_order
    order_number = @data_array['purchase_order_number']

    if Order.where(id: order_number).exists?
      @duplications.append(order_number)
    else
      Order.create(id: @data_array['purchase_order_number'],
                   originator: read_originator,
                   client: read_client,
                   address: read_destination_address,
                   delivery_date: @data_array['delivery_date'] != nil ? Date.strptime(@data_array['delivery_date'], '%m/%d/%Y') : nil,
                   delivery_shift: @data_array['delivery_shift'],
                   mode: @data_array['mode'],
                   volume: @data_array['volume'],
                   unit_quantity: @data_array['handling_unit_quantity'].to_i,
                   unit_type: @data_array['handling_unit_type'])
    end
  end

  def read_client
    Client.find_or_create_by(:name => @data_array['client name'], :phone => @data_array['phone_number'])
  end

  def read_originator
    originatorName = @data_array['origin_name']

    if Originator.where(name: originatorName).exists?
      Originator.find_by(name: originatorName)
    else
      Originator.create(name: originatorName, address: read_originator_address)
    end
  end

  def read_originator_address
    country = read_country(@data_array['origin_country'])
    state = read_state(@data_array['origin_state'], country)
    city = read_city(@data_array['origin_city'], state)
    read_address(@data_array['origin_raw_line_1'],
                @data_array['origin_zip'],
                city)
  end

  def read_destination_address
    country = read_country(@data_array['destination_country'])
    state = read_state(@data_array['destination_state'], country)
    city = read_city(@data_array['destination_city'], state)
    read_address(@data_array['destination_raw_line_1'],
                @data_array['destination_zip'],
                city)
  end

  def read_country(country_str)
    Country.find_or_create_by(name: country_str)
  end

  def read_state(state_str, country)
    State.find_or_create_by(name: state_str, country: country)
  end

  def read_city(city_str, state)
    City.find_or_create_by(name: city_str, state: state)
  end

  def read_address(raw_line_str, zip_str, city)
    address = Address.find_or_create_by(raw_line: raw_line_str, zipcode: zip_str, city: city)
  end

end
