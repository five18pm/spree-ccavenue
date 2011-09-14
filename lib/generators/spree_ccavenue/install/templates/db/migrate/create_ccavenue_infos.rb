class CreateCcavenueInfos < ActiveRecord::Migration
  def self.up
    create_table "ccavenue_infos", :force => true do |t|
      t.string   "order_number"
      t.decimal  "amount",                :precision => 8, :scale => 2
      t.string   "amount_str"
      t.string   "auth_desc"
      t.string   "checksum"
      t.string   "gateway_order_no"
      t.integer  "order_id"
      t.string   "card_category"
      t.string   "state"
      t.string   "ccavenue_order_number"
      t.timestamps
    end
  end

  def self.down
    drop_table :ccavenue_infos
  end
end
