class Load < ActiveRecord::Base

  MORNING_LOAD = "M"
  AFTERNOON_LOAD = "N"
  EVENING_LOAD = "E"
  TOTAL_VOLUME = 1400

  def self.create_loads_for_date(date)
    loads= {MORNING_LOAD => Load.create(delivery_date: date, delivery_shift: MORNING_LOAD, name: ("8am - 12am")),
            AFTERNOON_LOAD => Load.create(delivery_date: date, delivery_shift: AFTERNOON_LOAD, name: ("12am - 6pm")),
            EVENING_LOAD => Load.create(delivery_date: date, delivery_shift: EVENING_LOAD, name: ("6pm - 10pm"))
    }
  end

  def self.get_loads_for_date(date)
    loads= {MORNING_LOAD => Load.find_by(delivery_date: date, delivery_shift: MORNING_LOAD),
            AFTERNOON_LOAD => Load.find_by(delivery_date: date, delivery_shift: AFTERNOON_LOAD),
            EVENING_LOAD => Load.find_by(delivery_date: date, delivery_shift: EVENING_LOAD)
    }
  end

  def get_available_volume()
    sum = Order.where("load_id = ? and order_type = 'Delivery'", id).sum("volume")
    logger.debug "ALSK " + sum.to_s
    available_volume = (TOTAL_VOLUME - sum).round(2)

    return available_volume
  end

end
