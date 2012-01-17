class UpgradeCcavenueTables < ActiveRecord::Migration
  def up
    change_table :ccavenue_infos do |t|
      t.remove :order_number
      t.rename :ccavenue_order_number, :transaction_number
      t.integer :payment_method_id
      t.rename :amount_str, :ccavenue_amount
      t.change :auth_desc, :string, :length => 1
      t.rename :gateway_order_no, :ccavenue_order_number
    end

    rename_table :ccavenue_infos, :spree_ccavenue_transactions

    Spree::Ccavenue::Transaction.reset_column_information
    Spree::Ccavenue::Transaction.update_all "state = 'failed'", "state = 'new' or state is null"
    Spree::Ccavenue::Transaction.update_all "state = 'authorized'", "state = 'success'"
  end

  def down
    raise ActiveRecord::IrreversibleMigration.new("ccavenue_table upgrade cannot be migrated down")
  end
end
