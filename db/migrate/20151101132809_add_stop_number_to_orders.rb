class AddStopNumberToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :stop_num, :integer
  end
end
