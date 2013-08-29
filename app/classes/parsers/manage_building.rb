project_root = File.join(File.dirname(File.absolute_path(__FILE__)), '/../../../')
require File.join(project_root, 'app/classes/parsers/base.rb')

class Parsers::ManageBuilding < Parsers::Base
  SUBDOMAIN_REGEX = /(https?:\/\/)?(.*managebuilding\.com)/i
  CONTACT_LINK_REGEX = /https?:\/\/([\w-]+).managebuilding.com\/Resident\/PublicPages\/ContactUs.aspx/i

  class << self
    def question_for(keyword)
      "site:managebuilding.com/Resident/PublicPages/ContactUs.aspx+#{keyword}"
    end

    def contact_info(link)
      g = open(link) rescue nil # in case when 'contacts' page doesn't exist
      return nil if g.nil?
      info = Nokogiri.HTML(g).at_css('#_ctl0_contentPlaceHolderBody_ucSideBox_lblBody').inner_html.split('<br>')
      info.delete_at(1)
      info.unshift(link)
      link = info.shift
      company = info.shift
      email = info.grep(self::EMAIL_REGEX).select(&:present?).first
      info.delete(email) if email.present?
      phones = info.grep(self::PHONE_REGEX).select(&:present?)
      phones.each { |p| info.delete(p) }
      faxes = phones.select { |p| p.match('fax') }.join(',')
      phones = phones.select { |p| !p.match('fax') }.join(',')
      info.delete('')
      townzip = info.pop
      city, statezip = townzip.split(',') if townzip
      state, zip = statezip.split(' ') if statezip
      address = info.join(',')
      subdomain = link.match(SUBDOMAIN_REGEX)[2]
      {
        subdomain: subdomain,
        company_name: company,
        address: address,
        city: city || townzip,
        state: state,
        zip: zip,
        phone: phones,
        fax: faxes,
        email: email,
        total_properties: total_properties("https://#{subdomain}/Resident/PublicPages/ApartmentSearch.aspx"),
        provider: 'Buildium'
      }
    rescue => e
      LOGGER.error e
      LOGGER.error "With info: #{info}"
      nil
    end

    private
      def total_properties(link)
        g = open(link) rescue nil
        Nokogiri.HTML(g).search('table.listings td.description').count
      end
  end
end
