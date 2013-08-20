class CreateContactInfos < ActiveRecord::Migration
  def change
    create_table :contact_infos do |t|
      t.string :subdomain
      t.string :company_name
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      t.string :phone
      t.string :fax
      t.string :email
      t.integer :total_properties

      t.timestamps
    end
    add_index :contact_infos, :subdomain, unique: true
    add_index :contact_infos, :email, unique: true
    add_index :contact_infos, :state
  end
end
