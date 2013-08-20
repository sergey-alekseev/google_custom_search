require 'active_record'
class State < ActiveRecord::Base
  def self.next_state
    State.where(searched_by: false).first
  end
end
