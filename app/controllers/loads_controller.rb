class LoadsController < ApplicationController

  def index
    @load_dates = Load.select(:delivery_date).order(:delivery_date).distinct

    @date = params[:date]
    if @date.nil? && !@load_dates.empty?
      @date = @load_dates[0].delivery_date.to_s
    end

    driver_id = session[:user]
    @driver = User.find(driver_id)

    loads_by_driver = Load.where(user: @driver, delivery_date: @date)

    @orders_by_load = Hash.new
    loads_by_driver.each do |load|
      @orders_by_load[load] = Order.where(load: load).order(:stop_num)
    end
  end

  def show
    load = Load.find(params[:id])
    @orders_by_load = Hash.new
    @orders_by_load[load] = Order.where(load: load).order(:stop_num)
    respond_to do |format|
      format.html
      format.csv {
        send_data to_csv(@orders_by_load), filename: 'Routing_List_' + load.delivery_date.to_s + '_' + load.name + '.csv'
        #redirect_to load_path(@load)
      }
    end
  end

  def routing
    @errors = session[:errors]
    session[:errors] = nil
    @load = Load.find(params[:id])
    @date = @load.delivery_date
    @stops = @load.stops_set
  end

  def set_route
    load = Load.find(params[:id])
    orders_in_load = load.orders_sorted_by_type

    errors = []
    address_to_stopnum_map = load.address_to_stopnum_map
    duplications = Set.new

    orders_in_load.each do |order|
      order_stop_num = order.stop_num.to_s
      address_id = order.address.id
      order_type = order.order_type
      params_key= address_id.to_s + order_type

      specified_stop_num = params[params_key]

      if (order_stop_num == specified_stop_num)
        next
      end

      if !specified_stop_num.empty?
        #Check truck's available capacity for return orders
        if order.order_type == Order::ORDER_TYPE_RETURN
          required_volume = order.volume
          volume_before_return = load.available_volume_by_stop(specified_stop_num)
          if required_volume > volume_before_return
            errors.push("There will not enough room in truck to get cargo from " + order.address.raw_line + ", " + order.address.city + " at stop #" + specified_stop_num + ". Available volume at this stop is " + load.available_volume.to_s )
            next
          end
        end
       #Checking for duplications
        if address_to_stopnum_map.has_value?(specified_stop_num) && (address_to_stopnum_map.key(specified_stop_num) != address_id)
          duplications.add(specified_stop_num)
          #stop_nums.push(order_stop_num)
          address_to_stopnum_map[specified_stop_num] = address_id
          next
        end

        #stop_nums.push(specified_stop_num)
        address_to_stopnum_map[specified_stop_num] = address_id
        order.update(stop_num: specified_stop_num)
      end
    end

    if !duplications.empty?
      errors.push("The following Stop numbers are duplicated: " + duplications.to_a.to_s)
    end

    session[:errors] = errors
    redirect_to load_routing_path
  end

private
  def to_csv(orders_by_load)
    logger.debug "order_b_load:" + orders_by_load.to_s

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
