# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151027051113) do

  create_table "addresses", force: true do |t|
    t.string   "raw_line",   null: false
    t.integer  "zipcode",    null: false
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "addresses", ["raw_line", "zipcode"], name: "index_addresses_on_raw_line_and_zipcode"

  create_table "clients", force: true do |t|
    t.string   "name",       null: false
    t.string   "phone",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "clients", ["name", "phone"], name: "index_clients_on_name_and_phone"

  create_table "loads", force: true do |t|
    t.date     "delivery_date"
    t.string   "delivery_shift"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "loads", ["delivery_date", "delivery_shift"], name: "index_loads_on_delivery_date_and_delivery_shift"

  create_table "orders", force: true do |t|
    t.date     "desired_date"
    t.string   "desired_shift",         limit: 1
    t.string   "order_type"
    t.string   "purchase_order_number"
    t.integer  "client_id"
    t.integer  "address_id"
    t.string   "mode",                            default: "TRUCKLOA", null: false
    t.float    "volume",                                               null: false
    t.integer  "unit_quantity"
    t.string   "unit_type"
    t.integer  "load_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "orders", ["address_id"], name: "index_orders_on_address_id"
  add_index "orders", ["client_id"], name: "index_orders_on_client_id"
  add_index "orders", ["load_id"], name: "index_orders_on_load_id"

end
