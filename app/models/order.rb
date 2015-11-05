class Order < ActiveRecord::Base
  belongs_to :originator
  belongs_to :client
  belongs_to :address
  belongs_to :load

  def self.create_order_with_loads(desired_date, desired_shift, order_type, purchase_order_number, client, address, mode, volume, unit_quantity, unit_type)
    order = Order.new
    order.desired_date = desired_date
    order.desired_shift= desired_shift
    order.order_type= order_type
    order.purchase_order_number = purchase_order_number
    order.client = client
    order.address = address
    order.mode = mode
    order.volume = volume
    order.unit_quantity = unit_quantity
    order.unit_type = unit_type

    if Load.find_by(delivery_date: desired_date).nil?
      loads = Load.create_loads_for_date(desired_date)
    else
      loads = Load.get_loads_for_date(desired_date)
    end

    order.save
  end

  def cargo_description
    ActionController::Base.helpers.pluralize(self.unit_quantity, self.unit_type)
  end

end
