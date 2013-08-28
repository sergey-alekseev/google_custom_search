class AddCompanyUrlAndProviderToContactInfos < ActiveRecord::Migration
  def change
    add_column :contact_infos, :company_url, :string
    add_column :contact_infos, :provider, :string
  end
end
