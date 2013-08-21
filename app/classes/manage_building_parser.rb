project_root = File.join(File.dirname(File.absolute_path(__FILE__)), '/../../')
Dir.glob(File.join(project_root, "app/**/*.rb")).each { |f| require f }
require File.join(project_root, 'core_ext/object/blank')
require 'nokogiri'
require 'open-uri'
require 'httparty'
require 'parallel'
require 'csv'
require 'active_record'

class ManageBuildingParser
  # TODO: remove LOGGER instantiating in several files somehow
  LOGGER = LogFactory.logger('GCS')
  CONTACT_LINK_REGEX = /https?:\/\/([\w-]+).managebuilding.com\/Resident\/PublicPages\/ContactUs.aspx/i
  SUBDOMAIN_REGEX = /(https?:\/\/)?(.*managebuilding\.com)/
  EMAIL_REGEX =  /^(|(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6})$/i
  PHONE_REGEX = /^((\([\d]+\).*)|(.*\([\d.]{5,}\))|([\d.\- \(\)\/]+\((fax|office)\))?|([\d.\- \(\)\/]{10,}.*)|([\d\-]{8,}.*)|(Joey Gonzalez Cell \(fax\)))$/

  SEMAPHORE = Mutex.new

  def self.parse
    proxy_ip_rotator = Thread.new do
      loop {
        SEMAPHORE.synchronize { Proxy.rotate_ip }
        sleep(60)
      }
    end
    sleep 10
    yield
  rescue => e
    LOGGER.error e
  ensure
    proxy_ip_rotator.kill
  end

  def self.links_for(keyword, start = 11)
    question = "site:managebuilding.com/Resident/PublicPages/ContactUs.aspx+#{keyword}"
    links, total_results = GoogleCustomSearch.response_links_with_total_results(question, 1)
    LOGGER.info "#{total_results} total results for #{keyword}"
    while start <= 91 && start <= total_results
      ret = 5
      begin
        links << GoogleCustomSearch.response_links(question, start)
      rescue => e
        LOGGER.info e
        if (ret -= 1) > 0
          LOGGER.info "retrying for #{links.inspect}"
          retry
        end
      end
      start += 10
    end
    links.flatten.map { |link| link.match(CONTACT_LINK_REGEX)[0] }.uniq
  rescue => e
    LOGGER.error "It seems that 100 queries limit is over. See details below:"
    LOGGER.error e
  end

  def self.contact_info(link)
    g = HTTParty.get(link, no_follow: true) rescue nil # in case when 'contacts' page doesn't exist
    return nil if g.nil?
    info = Nokogiri.HTML(g).at_css('#_ctl0_contentPlaceHolderBody_ucSideBox_lblBody').inner_html.split('<br>')
    info.delete_at(1)
    info.unshift(link)
    info
  end

  def self.total_properties(link)
    g = HTTParty.get(link, no_follow: true) rescue nil
    Nokogiri.HTML(g).search('table.listings td.description').count
  end

  def self.contact_infos_for(keyword)
    parse do
      LOGGER.info "Start scraping contact infos for #{keyword}"
      contact_links = links_for(keyword)
      infos = Parallel.map(contact_links, in_processes: 4, in_threads: 20) do |cl|
        ret = 5
        begin
          contact_info(cl)
        rescue => e
          LOGGER.info "error: #{e} for #{cl}"
          if (ret = ret - 1) > 0
            LOGGER.info "retrying for #{cl}"
            retry
          end
        end
      end.compact
      infos = infos.map { |i| sanitize_info(i) }.compact
      infos = infos_with_total_properties_count(infos)
      ContactInfo.write(infos)
      contact_links.size / 10 + 1
    end
  end

  private
    def self.sanitize_info(info)
      info = info.clone
      link = info.shift
      company = info.shift
      email = info.grep(EMAIL_REGEX).select(&:present?).first
      info.delete(email) if email.present?
      phones = info.grep(PHONE_REGEX).select(&:present?)
      phones.each { |p| info.delete(p) }
      faxes = phones.select { |p| p.match('fax') }.join(',')
      phones = phones.select { |p| !p.match('fax') }.join(',')
      info.delete('')
      townzip = info.pop
      city, statezip = townzip.split(',') if townzip
      state, zip = statezip.split(' ') if statezip
      address = info.join(',')
      {
        subdomain: link.match(SUBDOMAIN_REGEX)[2],
        company_name: company,
        address: address,
        city: city || townzip,
        state: state,
        zip: zip,
        phone: phones,
        fax: faxes,
        email: email
      }
      # [link.match(SUBDOMAIN_REGEX)[2], company, address, city||townzip, state, zip, phones, faxes, email]
    rescue => e
      LOGGER.error e
      LOGGER.error "With info: #{info}"
      nil
    end

    def self.infos_with_total_properties_count(infos)
      infos.map do |i|
        link = "https://#{i[:subdomain]}/Resident/PublicPages/ApartmentSearch.aspx"
        i[:total_properties] = total_properties(link)
        i
      end
    end
end
