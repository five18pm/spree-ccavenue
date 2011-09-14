Order.class_eval do
  # NOTE: we won't lose any data by setting dependent to destroy as 
  # orders are NOT deleted from the db ever.
  has_many :ccavenue_infos, :dependent => :destroy

  def ccavenue_latest_txn
    self.ccavenue_infos.where(:state => 'new').last
  end

  def ccavenue_successful_txn
    self.ccavenue_infos.where(:state => 'success').first
  end

  def ccavenue_failed_txns
    self.ccavenue_infos.where(:state => 'failed')
  end

  def ccavenue_pending_txns
    self.ccavenue_infos.where(:state => 'new')
  end
end
