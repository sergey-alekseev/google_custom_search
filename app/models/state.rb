require 'active_record'
class State < ActiveRecord::Base
  def self.next_state
    State.where(searched_by: false).first || (
      State.find_each { |s| s.update_attributes(searched_by: false) }
      State.first)
  end
end
