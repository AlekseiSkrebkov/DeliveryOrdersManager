class OrdersController < ApplicationController
  ORDER_TYPE_DELIVERY = "Delivery"
  ORDER_TYPE_RETURN = "Return"

  COMPANY_NAME = "Larkin LLC"
  COMPANY_STREET = "1505 S BLOUNT ST"
  COMPANY_ZIPCODE = "27603"

  def index
    @errors = session[:errors]
    session[:errors] = nil
    @order_dates = Order.select(:desired_date).distinct.order("desired_date ASC")
    @selected_date = params[:selected_date]
    #Retrieving Orders
    #if date was not selected by User then orders for the nearest date are displayed
    if @selected_date.nil?
      if @order_dates.size > 0
        order = @order_dates[1]
        @selected_date = order.desired_date.to_s
      end
    end

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

  def new
    @order = Order.new
    @order.desired_date = params[:date]
    @addresses = Address.all.order(:raw_line)
    @clients = Client.all.order(:name)
  end

  def create
    order = Order.new
    desired_date = params[:desired_date]
    desired_shift = params[:desired_shift]
    order_type = params[:order_type]
    purchase_order_number = params[:purchase_order_number]
    client = params[:client]
    address = params[:address]
    mode = params[:mode]
    volume = params[:volume]
    unit_quantity = params[:unit_quantity]
    unit_type = params[:unit_type]
    Order.create_order_with_loads(desired_date, desired_shift, order_type, purchase_order_number, Client.find(client), Address.find(address), mode, volume, unit_quantity, unit_type)
    redirect_to orders_path(selected_date: desired_date)
  end

  def edit
    @order = Order.find(params[:id])
    @addresses = Address.all.order(:raw_line)
    @clients = Client.all.order(:name)
  end

  def update
    order = Order.find(params[:id])
    client = Client.find(params[:client])
    address = Address.find(params[:address])
    parameters = params.permit(:desired_date, :desired_shift, :order_type, :purchase_order_number, :mode, :volume, :unit_quantity, :unit_type)
    parameters[:client] = client
    parameters[:address] = address
    order.update(parameters)
    redirect_to orders_path(selected_date:order.desired_date)
  end

  def set_load
    errors = Array.new
    desired_shift_conflict_orders = Array.new
    date = params[:delivery_date]
    orders_by_date = Order.where("desired_date = ?", date)

    orders_by_delivery_shift = Hash.new
    orders_by_date.each do |order|
      delivery_shift = params[order.id.to_s]
      if (delivery_shift.nil?)
        next
      end

      if orders_by_delivery_shift[delivery_shift].nil?
        orders_by_delivery_shift[delivery_shift] = Array.new
      end
      logger.debug "ALSK id=" + order.id.to_s + " load is nil?=" + order.load.nil?.to_s + " load is changed?=" + (!order.load.nil? && (order.load.delivery_shift != delivery_shift)).to_s
      if !order.desired_shift.nil? && (order.desired_shift != delivery_shift)
        desired_shift_conflict_orders.push(order.id)
      elsif (order.load.nil?) || (!order.load.nil? && (order.load.delivery_shift != delivery_shift))
        orders_by_delivery_shift[delivery_shift].push(order.id)
      end
    end

    if (!desired_shift_conflict_orders.empty?)
      errors.push("Selected delivery time contradicts with the time desired by Client for the following orders: " + desired_shift_conflict_orders.to_s)
    end
    logger.debug "ALSK " + orders_by_delivery_shift.to_s

    orders_by_delivery_shift.each do |delivery_shift, orders|
      if !orders.empty?
        load = Load.get_by_date_and_load(date, delivery_shift)
        i=0
        orders.each do |order_id|
          order = Order.find(order_id)
          #logger.debug "ALSK available_volume=" + load.available_volume.to_s + " need volume=" + required_volume.to_s
          if load.enough_volume?(order.volume)
            order.update(load: load)
            i += 1
          else
            error_message = "Available volume is not enough to put following orders into load for " + load.name + ": "
            failed_orders = Array.new
            while i < orders.size do
              failed_orders.push(orders[i])
              i += 1
            end
            error_message += failed_orders.to_s
            errors.push(error_message)
            break
          end
        end
      end
    end

    session[:errors] = errors
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

end
