class Order < ActiveRecord::Base
  belongs_to :client
  belongs_to :address
  belongs_to :load

  validates :purchase_order_number, numericality: {only_integer: true, message: 'Purchase Order Number should be specified as integer number'}, presence: {message: "Purchase Order Number couldn't be blank"}
  validates :unit_quantity, numericality: {only_integer: true, message: 'Units Quantity should be specified as integer number'}, presence: {message: "Units quantity couldn't be blank"}
  validates :volume, numericality: {message: 'Volume should be presented as integer of float value'}, presence: {message: "Volume couldn't be blank"}
  validates :desired_date, presence: {message: "Desired Delivery Date couldn't be blank"}
  validates :unit_type, presence: {message: 'Unit type should be specified'}
  validates :client, presence: {message: "Client haven't been created for order"}
  validates :address, presence: {message: "Address haven't been created for order"}

  ORDER_TYPE_DELIVERY = "Delivery"
  ORDER_TYPE_RETURN = "Return"

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

    order.save
    return order
  end

  def self.orders_by_date(date)
    Order.where(desired_date: date)
  end

  def cargo_description
    ActionController::Base.helpers.pluralize(self.unit_quantity, self.unit_type)
  end

end
