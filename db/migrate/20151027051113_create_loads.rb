class CreateLoads < ActiveRecord::Migration
  def change
    create_table :loads do |t|
      t.date :delivery_date
      t.string :delivery_shift
      t.string :name

      t.timestamps
    end
    add_index :loads, [:delivery_date, :delivery_shift]
  end
end
