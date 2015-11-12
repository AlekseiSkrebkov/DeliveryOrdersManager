class Load < ActiveRecord::Base
  belongs_to :user

  MORNING_LOAD = "M"
  AFTERNOON_LOAD = "N"
  EVENING_LOAD = "E"

  DELIVERY_TYMES = {
      MORNING_LOAD => '8am - 12am',
      AFTERNOON_LOAD => '12am - 6pm',
      EVENING_LOAD => '6pm - 10pm'
  }

  INITIAL_DATE = Date.new(2014,1,1)
  DRIVER_1 = 2
  DRIVER_2 = 3
  ODD_DAYS_SCHEDULE = {
      MORNING_LOAD => DRIVER_1,
      AFTERNOON_LOAD => DRIVER_2,
      EVENING_LOAD => DRIVER_1
  }
  EVEN_DAYS_SCHEDULE = {
      MORNING_LOAD => DRIVER_2,
      AFTERNOON_LOAD => DRIVER_1,
      EVENING_LOAD => DRIVER_2
  }

  TOTAL_VOLUME = 1400

  def self.exist_for_date? (date)
    !Load.find_by(delivery_date: date).nil?
  end

  def self.get_by_date_and_load(date, shift)
    load = Load.find_by(delivery_date: date, delivery_shift: shift)
    if load.nil?
      load = Load.create(delivery_date: date, delivery_shift: shift, name: get_load_name(date, shift), user: define_driver(date, shift))
    end
    return load
  end

  def fake?
    id.nil?
  end

  def self.retrieve_by_date_and_shift(date, shift)
    load = Load.find_by(delivery_date: date, delivery_shift: shift)
    if load.nil?
      load = Load.new(delivery_date: date, delivery_shift: shift, name: get_load_name(date, shift))
    end
    return load
  end

  def self.get_load_name(date, shift)
    DELIVERY_TYMES[shift]
  end

  def enough_volume?(required_volume)
    required_volume < available_volume
  end

  def available_volume
    if fake?
      return TOTAL_VOLUME
    end
    sum = Order.where("load_id = ? and order_type = 'Delivery'", id).sum("volume")
    available_volume = (TOTAL_VOLUME - sum).round(2)

    return available_volume
  end

  def available_volume_by_stop(stop_number)
    Order.where("load_id = ? and stop_num < ? and order_type = 'Delivery'", id, stop_number).sum("volume") + available_volume
  end

  def address_to_stopnum_map
    stop_num_to_address_map = Hash.new
    results = Order.select('stop_num, address_id').where(load: id).distinct
    results.each do |result|
      if !result.stop_num.nil?
        stop_num_to_address_map[result.address.id.to_s] = result.stop_num.to_s
      end
    end
    return stop_num_to_address_map
  end

  def stops_set
    Order.joins(:address).select("address_id, sum(volume) as volume, order_type, stop_num").where(load: self).group("address_id, order_type").order("stop_num, state, city, raw_line")
  end

  def number_of_stops
    if fake?
      return 0
    end
    result = Order.joins(:address).select("address_id").where(load: self).group("address_id, order_type")
    return result.as_json.size
  end

  def orders_sorted_by_type
    Order.where(load: self).order("order_type")
  end

  def destroy_if_empty
    if !Order.exists?(load:self)
      self.destroy
    end
  end

private
  def self.define_driver(date, shift)
    if date.nil?
      return
    end
    target_date = Date.strptime(date, '%Y-%m-%d')
    delta = target_date - INITIAL_DATE

    logger.debug "delta between dates=" + delta.to_s

    if delta % 2 == 1
      return User.find(ODD_DAYS_SCHEDULE[shift])
    else
      return User.find(EVEN_DAYS_SCHEDULE[shift])
    end
  end

end
