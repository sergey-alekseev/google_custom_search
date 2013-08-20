require File.join(File.dirname(__FILE__), '../../app/models/state.rb')

class AddSearchedByToStates < ActiveRecord::Migration
  def change
    add_column :states, :searched_by, :boolean, default: false
  end
end
