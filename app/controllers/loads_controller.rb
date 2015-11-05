class LoadsController < ApplicationController

  def index
    #ToDo Add filter by status and driver
    @load_dates = Load.select(:delivery_date).order(:delivery_date).distinct

    @date = params[:date]
    if (@date.nil? || @date.size ==0)
      @date = @load_dates[0].delivery_date.to_s
    end

    driver_id = params[:driver]
    @driver = nil
    if !driver_id.nil?
      @driver = User.find(driver_id)
    end

    loads_by_driver = Load.where(user: @driver, delivery_date: @date)

    @orders_by_load = Hash.new
    loads_by_driver.each do |load|
      @orders_by_load[load] = Order.where(load: load).order(:stop_num)
    end

    respond_to do |format|
      format.html
      format.csv {
        send_data to_csv(@orders_by_load), filename: "Routing list for " + @date + ".csv"
        #redirect_to load_path(@load)
      }
    end
  end

  def show
    @load = Load.find(params[:id])
    @orders = Order.where(load: @load)

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
  def to_csv(orders_by_load)
    require 'csv'
    CSV.generate do |csv|
      csv << ['Date/Time', 'Stop #', 'Address', 'Purchase Order#', 'Description','Client Name', 'Client Phone#']
      orders_by_load.each do |load, orders|
        orders.each do |order|
          csv << [load.delivery_date.to_s + ' ' + load.name, order.stop_num.to_s, order.address.full_address, order.purchase_order_number, order.cargo_description, order.client.name, order.client.phone]
        end
      end
    end

  end

end
