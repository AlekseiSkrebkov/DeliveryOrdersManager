class OrdersController < ApplicationController
  ORDER_TYPE_DELIVERY = "Delivery"
  ORDER_TYPE_RETURN = "Return"

  COMPANY_NAME = "Larkin LLC"

  def index
    @errors = session[:errors]
    session[:errors] = nil
    @order_dates = Order.select(:desired_date).distinct.order("desired_date ASC")

    @selected_date = params[:selected_date]
    if @selected_date.nil?
      if @order_dates.size > 0
        order = @order_dates[0]
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
    @address = Address.new(country: 'US', state: 'NC')
    @client = Client.new
  end

  def create
    @errors = []
    order_params = prepare_order_params_from_order_form
    @errors.concat(get_error_messages(order_params[:address]))
    @errors.concat(get_error_messages(order_params[:client]))

    @order = Order.create(order_params)
    @errors.concat(get_error_messages(@order))

    if @order.valid?
      if (!@order.desired_date.nil? && !Load.exist_for_date?(@order.desired_date))
        Load.create_loads_for_date(@order.desired_date)
      end
      redirect_to orders_path(selected_date: @order.desired_date)
    else
      @address = order_params[:address]
      @client = order_params[:client]
      render 'new'
    end
  end

  def edit
    @order = Order.find(params[:id])
    @address = Address.find(@order.address.id)
    @client = Client.find(@order.client.id)
  end

  def update
    @errors = []
    order_params = prepare_order_params_from_order_form
    @errors.concat(get_error_messages(order_params[:address]))
    @errors.concat(get_error_messages(order_params[:client]))

    @order = Order.find(params[:id])
    @order.update(order_params)
    @errors.concat(get_error_messages(@order))

    if @order.valid?
      redirect_to orders_path(selected_date: @order.desired_date)
    else
      @address = order_params[:address]
      @client = order_params[:client]
      render 'edit'
    end
  end

  def show
  end

  def destroy
    order = Order.find(params[:id])
    date = order.desired_date
    order.destroy

    redirect_to orders_path(selected_date: date)
  end

  def set_load
    errors = Array.new
    desired_shift_conflict_orders = Array.new
    date = params[:delivery_date]
    orders_by_date = Order.orders_by_date(date)

    orders_to_delivery_shift_map = Hash.new
    orders_by_date.each do |order|
      delivery_shift = params[order.id.to_s]
      if (delivery_shift.nil?)
        next
      end

      if orders_to_delivery_shift_map[delivery_shift].nil?
        orders_to_delivery_shift_map[delivery_shift] = Array.new
      end
      if !order.desired_shift.nil? && (order.desired_shift != delivery_shift)
        desired_shift_conflict_orders.push(order.id)
      elsif (order.load.nil?) || (!order.load.nil? && (order.load.delivery_shift != delivery_shift))
        orders_to_delivery_shift_map[delivery_shift].push(order.id)
      end
    end

    if (!desired_shift_conflict_orders.empty?)
      errors.push("Selected delivery time contradicts with the time desired by Client for the following orders: " + desired_shift_conflict_orders.to_s)
    end

    orders_to_delivery_shift_map.each do |delivery_shift, orders|
      if !orders.empty?
        load = Load.get_by_date_and_load(date, delivery_shift)
        i=0
        orders.each do |order_id|
          order = Order.find(order_id)
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
    start_time = Time.now
    uploaded_csv = params[:orders]
    file_path = Rails.root.join('uploads', uploaded_csv.original_filename)
    total_loaded = 0
    File.open(file_path, 'wb') do |file|
      file.write(uploaded_csv.read)

      @failed_rows = Hash.new

      require 'csv'
      CSV.foreach(file_path, :headers => true) do |row|
        total_loaded += 1
        order_errors = read_order(row)
        if !order_errors.empty?
          @failed_rows = @failed_rows.merge(order_errors)
        end
      end
    end
    end_time = Time.now

    @failed_orders_quantity = @failed_rows.keys.size
    @loaded_orders_quantity = total_loaded - @failed_orders_quantity

    if @failed_rows.size > 0
      render 'fallout_report'
    else
      redirect_to orders_path
    end
  end

  def read_order(data)
    validation_errors = []
    order = Order.new
    if data['origin_name'] = COMPANY_NAME
      order.order_type = ORDER_TYPE_DELIVERY
      address = Address.get_address(data['destination_country'],
                                    data['destination_state'],
                                    data['destination_city'],
                                    data['destination_zip'],
                                    data['destination_raw_line_1']
                                    )

      client_name = data['client name']
    else
      order.order_type = ORDER_TYPE_RETURN
      address = Address.get_address(data['origin_country'],
                                    data['origin_state'],
                                    data['origin_city'],
                                    data['origin_zip'],
                                    data['origin_raw_line_1']
                                    )
      client_name = data['origin_name']
    end

    validation_errors.concat(get_error_messages(address))
    order.address = address

    client = Client.get_by_name_and_phone(client_name, data['phone_number'])
    validation_errors.concat(get_error_messages(client))
    order.client = client

    order.purchase_order_number = data['purchase_order_number']
    order.desired_date = data['delivery_date'] != nil ? Date.strptime(data['delivery_date'], '%m/%d/%Y') : nil
    order.desired_shift= data['delivery_shift']
    order.mode = data['mode']
    order.volume = data['volume']
    order.unit_quantity = data['handling_unit_quantity']
    order.unit_type = data['handling_unit_type']

    order.save
    if (!order.desired_date.nil? && !Load.exist_for_date?(order.desired_date))
      Load.create_loads_for_date(order.desired_date)
    end
    if order.invalid?
      validation_errors.concat(get_error_messages(order))
    else

    end

    order_errors = Hash.new
    if !validation_errors.empty?
      order_errors[order] = validation_errors
    end
    return order_errors
  end

private

  def prepare_order_params_from_order_form
    order_params = Hash.new
    order_params[:desired_date] = params[:desired_date]
    order_params[:desired_shift] = params[:desired_shift].empty? ? nil : params[:desired_shift]
    order_params[:order_type] = params[:order_type]
    order_params[:purchase_order_number] = params[:purchase_order_number]
    order_params[:mode] = params[:mode]
    order_params[:volume] = params[:volume]
    order_params[:unit_quantity] = params[:unit_quantity]
    order_params[:unit_type] = params[:unit_type]

    address = Address.get_address(params[:country], params[:state], params[:city], params[:zipcode], params[:raw_line])

    order_params[:address] = address

    client = Client.get_by_name_and_phone(params[:client_name], params[:client_phone])
    order_params[:client] = client
    return order_params
  end

  def get_error_messages(entity)
    messages_array = []
    entity.errors.messages.values.each do |value|
      value.each do |message|
        messages_array.push(message)
      end
    end
    return messages_array
  end

end
