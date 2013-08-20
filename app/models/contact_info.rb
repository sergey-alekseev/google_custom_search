require 'active_record'
require './app/classes/log_factory'
class ContactInfo < ActiveRecord::Base
  # TODO: remove LOGGER instantiating in several files somehow
  LOGGER = LogFactory.logger('GCS')

  def self.write(infos)
    infos.each do |i|
      email_valid = i[:email].nil? || ContactInfo.where(email: i[:email]).empty?
      subdomain_valid = i[:subdomain].nil? || ContactInfo.where(subdomain: i[:subdomain]).empty?
      if email_valid && subdomain_valid
        LOGGER.info "Write to DB: #{i.inspect}"
        ContactInfo.create!(i)
      end
    end
  end
end
