class OrdersController < ApplicationController
  ORDER_TYPE_DELIVERY = "Delivery"
  ORDER_TYPE_RETURN = "Return"

  COMPANY_NAME = "Larkin LLC"
  COMPANY_STREET = "1505 S BLOUNT ST"
  COMPANY_ZIPCODE = "27603"

  def index
    #Retrieving  dates
    @order_dates = Order.select(:desired_date).distinct.order("desired_date ASC")
    @selected_date = params[:selected_date]
    @orders_count = Order.count
    #Retrieving Orders
    #if date was not selected by User then orders for the nearest date are displayed
    if @selected_date.nil?
      if @order_dates.size > 0
        temp = @order_dates[0]
        @selected_date = temp.desired_date
      end
    end

   # @orders = Array.new

    if !@selected_date.nil?
      #Retrieving Loads
      @loads = Load.get_loads_for_date(@selected_date)
      @morning_load = @loads[Load::MORNING_LOAD]
      @afternoon_load = @loads[Load::AFTERNOON_LOAD]
      @evening_load = @loads[Load::EVENING_LOAD]

      #Retrieve Orders by Load

      @unassigned_orders = Order.joins(:address).where("desired_date = ? and load_id is null", @selected_date).order("addresses.state, addresses.city")
      @morning_orders = Order.joins(:address).where(orders: {desired_date: @selected_date, load_id: @morning_load}).order("addresses.state, addresses.city")
      @afternoon_orders = Order.joins(:address).where(orders: {desired_date: @selected_date, load_id: @afternoon_load}).order("addresses.state, addresses.city")
      @evening_orders = Order.joins(:address).where(orders: {desired_date: @selected_date, load_id: @evening_load}).order("addresses.state, addresses.city")
    end

  end

  def set_load
    date = params[:delivery_date]
    logger.debug "Date="+date.to_s
    orders_without_desired_shift = Order.where("desired_date = ? and desired_shift is null", date)
    logger.debug "Orders count=" + orders_without_desired_shift.count.to_s
    loads = Load.get_loads_for_date(date)
    logger.debug loads.count.to_s + " loads selected"
    orders_without_desired_shift.each do |order|
      id = order.id.to_s
      selected_load = params[id].to_s
      logger.debug "selected load for id=" + id + " is "+ selected_load + selected_load.nil?.to_s

      #ToDo: refactor
      if !selected_load.nil? && selected_load.length > 0
        if order.load.nil?
          logger.debug "set load="+loads[selected_load].delivery_shift
          order.update(load: loads[selected_load])
        else
          if order.load.delivery_shift != selected_load
            logger.debug "override load="+loads[selected_load].delivery_shift
            order.update(load: loads[selected_load])
          end
        end
      end


    end
    redirect_to orders_path("selected_date" => date )
  end

  def upload_orders
    uploaded_csv = params[:orders]
    file_path = Rails.root.join('uploads', uploaded_csv.original_filename)
    File.open(file_path, 'wb') do |file|
      file.write(uploaded_csv.read)

      require 'csv'
      CSV.foreach(file_path, :headers => true) do |row|
        @failed_rows = Hash.new
        read_order(row)
      end
    end
    if @failed_rows.size > 0
      render 'fallout_report'
    else
      redirect_to orders_path
    end
  end

  def set_sequence_of_stops

  end

  def fallout_report

  end

  def read_order(data)
    if data['origin_name'] = COMPANY_NAME && data['origin_raw_line_1'] == COMPANY_STREET and data['origin_zip'] == COMPANY_ZIPCODE
      order_type = ORDER_TYPE_DELIVERY
      address = Address.get_address(data['destination_country'],
                                    data['destination_state'],
                                    data['destination_city'],
                                    data['destination_zip'],
                                    data['destination_raw_line_1']
                                    )
      client_name = data['client name']
    else
      order_type = ORDER_TYPE_RETURN
      address = Address.get_address(data['origin_country'],
                                    data['origin_state'],
                                    data['origin_city'],
                                    data['origin_zip'],
                                    data['origin_raw_line_1']
                                    )
      client_name = data['origin_name']
    end
    purchase_order_number = data['purchase_order_number']
    client = Client.get_by_name_and_phone(client_name, data['phone_number'])
    desired_date = data['delivery_date'] != nil ? Date.strptime(data['delivery_date'], '%m/%d/%Y') : nil
    desired_shift= data['delivery_shift']
    mode = data['mode']
    volume = data['volume']
    unit_quantity = data['handling_unit_quantity']
    unit_type = data['handling_unit_type']

    Order.create_order_with_loads(desired_date, desired_shift, order_type, purchase_order_number, client, address, mode, volume, unit_quantity, unit_type)

    #ToDo: need additional implementation for failed_rows

    #if result == false
    #  @failed_rows[data] = result
    #end
  end

private
  def default_assignment_to_load(load_label, load)
    orders = Order.where("delivery_shift = ? and load_id is null", load_label)
    orders.each do |order|
      order.update(load: load)
    end
  end


end
