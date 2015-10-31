class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.string :raw_line, :null => false
      t.integer :zipcode, :null => false
      t.string :city
      t.string :state
      t.string :country

      t.timestamps
    end
    add_index :addresses, [:raw_line, :zipcode]
  end
end
