class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.date :desired_date
      t.string :desired_shift, :limit => 1
      t.string :order_type
      t.string :purchase_order_number
      t.references :client, index: true
      t.references :address, index: true
      t.string :mode, :null => false, :default => 'TRUCKLOA'
      t.float :volume, :null => false
      t.integer :unit_quantity
      t.string :unit_type
      t.references :load, index: true
      t.timestamps
    end
  end
end
