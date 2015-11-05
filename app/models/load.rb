class Load < ActiveRecord::Base
  belongs_to :user

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

  def self.create_morning_load(date)
    Load.create(delivery_date: date, delivery_shift: MORNING_LOAD, name: ("8am - 12am"))
  end

  def self.create_afternoon_load(date)
    Load.create(delivery_date: date, delivery_shift: AFTERNOON_LOAD, name: ("12am - 6pm"))
  end

  def self.create_evening_load(date)
    Load.create(delivery_date: date, delivery_shift: EVENING_LOAD, name: ("6pm - 10pm"))
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

  def available_volume()
    sum = Order.where("load_id = ? and order_type = 'Delivery'", id).sum("volume")
    available_volume = (TOTAL_VOLUME - sum).round(2)

    return available_volume
  end

  def get_orders
    Order.where(load: self).order(:stop_num)
  end

  def self.get_morning_load_for_date(date)
    Load.find_by(delivery_date: date, delivery_shift: MORNING_LOAD)
  end

  def self.get_afternoon_load_for_date(date)
    Load.find_by(delivery_date: date, delivery_shift: AFTERNOON_LOAD)
  end

  def self.get_evening_load_for_date(date)
    Load.find_by(delivery_date: date, delivery_shift: EVENING_LOAD)
  end

end
