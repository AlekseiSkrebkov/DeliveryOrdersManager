class Load < ActiveRecord::Base
  belongs_to :user

  MORNING_LOAD = "M"
  AFTERNOON_LOAD = "N"
  EVENING_LOAD = "E"

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

  def self.create_loads_for_date(date)
    if date.nil?
      return
    end
    loads= {MORNING_LOAD => Load.create(delivery_date: date, delivery_shift: MORNING_LOAD, name: ("8am - 12am"), user: User.find(define_driver(date, MORNING_LOAD))),
            AFTERNOON_LOAD => Load.create(delivery_date: date, delivery_shift: AFTERNOON_LOAD, name: ("12am - 6pm"), user: User.find(define_driver(date, AFTERNOON_LOAD)) ),
            EVENING_LOAD => Load.create(delivery_date: date, delivery_shift: EVENING_LOAD, name: ("6pm - 10pm"), user: User.find(define_driver(date, EVENING_LOAD)) )
    }
  end

  def self.exist_for_date? (date)
    !Load.find_by(delivery_date: date).nil?
  end

  def self.get_by_date_and_load(date, shift)
    load = Load.find_by(delivery_date: date, delivery_shift: shift)
    if load.nil?
      load = Load.create(delivery_date: date, delivery_shift: shift, name: date + ' ' + shift)
    end
    return load
  end

  def self.get_loads_for_date(date)
    loads= {MORNING_LOAD => Load.find_by(delivery_date: date, delivery_shift: MORNING_LOAD),
            AFTERNOON_LOAD => Load.find_by(delivery_date: date, delivery_shift: AFTERNOON_LOAD),
            EVENING_LOAD => Load.find_by(delivery_date: date, delivery_shift: EVENING_LOAD)
    }
  end

  def enough_volume?(required_volume)
    required_volume < available_volume
  end

  def available_volume
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
    result = Order.joins(:address).select("address_id").where(load: self).group("address_id, order_type")
    return result.as_json.size
  end

  def orders_sorted_by_type
    Order.where(load: self).order("order_type")
  end

private
  def self.define_driver(date, shift)
    if date.nil?
      return
    end
    delta = date - INITIAL_DATE

    logger.debug "delta between dates=" + delta.to_s

    if delta % 2 == 1
      return ODD_DAYS_SCHEDULE[shift]
    else
      return EVEN_DAYS_SCHEDULE[shift]
    end
  end

end
