class LoadsController < ApplicationController

  def index
    @selected_date = params[:selected_date]
    if @selected_date.nil?
      @selected_date = Load.find_by(delivery_date: @selected_date).delivery_date
    end
    @other_dates = Load.select(:delivery_date).where("delivery_date <> ?", @selected_date).distinct

    @morning_load = Load.get_morning_load_for_date(@selected_date)
    @afternoon_load = Load.get_afternoon_load_for_date(@selected_date)
    @evening_load = Load.get_evening_load_for_date(@selected_date)

    @morning_orders = @morning_load.get_orders
    @afternoon_orders = @afternoon_load.get_orders
    @evening_orders = @evening_load.get_orders

  end

  def show
    @load = Load.find(params[:id])
    @orders = Order.where(load: @load)
    respond_to do |format|
      format.html
      format.csv {
        send_data self.to_csv(@load, @orders)
        #redirect_to load_path(@load)
      }
    end
  end

  def edit
    @load = Load.find(params[:id])
    @date = @load.delivery_date

    @orders = Order.joins(:address).select("address_id, sum(volume) as volume, order_type, stop_num").where(load: @load).group("client_id, order_type").order("state, city, raw_line")

  end

  def set_route
    @load = Load.find(params[:id])
    orders_in_load = Order.where(load: @load)

    logger.debug "order in loads quantity: " + orders_in_load.count.to_s

    orders_in_load.each do |order|
      address_id = order.address.id

      logger.debug "processing address_id = " + address_id.to_s

      specified_stop_num = params[address_id.to_s]


      if !specified_stop_num.nil?
        logger.debug "specified stop num = " + specified_stop_num
        order.update(stop_num: specified_stop_num)
      end
    end


    redirect_to @load
  end

private
  def to_csv(load, orders)
    require 'csv'
    CSV.generate do |csv|
      csv << ['Date and shift', 'Stop #', 'Address', 'Purchase Order#', 'Description','Contact Phone#']
      orders.each do |order|
        csv << [load.name, order.stop_num.to_s, order.address.full_address, order.purchase_order_number, order.unit_quantity.to_s + order.unit_type, order.client.phone]
      end
    end
  end

end
