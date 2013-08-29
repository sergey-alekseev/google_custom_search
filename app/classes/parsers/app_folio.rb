project_root = File.join(File.dirname(File.absolute_path(__FILE__)), '/../../../')
require File.join(project_root, 'app/classes/parsers/base.rb')

class Parsers::AppFolio < Parsers::Base
  SUBDOMAIN_REGEX = /(https?:\/\/)?(.*appfolio\.com\/listings)/i
  CONTACT_LINK_REGEX = SUBDOMAIN_REGEX

  class << self
    def question_for(keyword)
      "site:appfolio.com/listings+#{keyword}"
    end

    def contact_info(link)
      response = open(link) rescue nil
      return nil if response.nil?
      unit_urls = Nokogiri.HTML(response).css('.unit_info_container h2 a').map do |a|
        "#{link}#{a['href'].gsub('listings/','')}"
      end.take(12)
      return nil if unit_urls.blank?
      first_unit_url = unit_urls.first
      info = scrape_contact_info_from_unit(first_unit_url)
      (unit_urls - [first_unit_url]).each do |unit_url|
        break if info[:email].present?
        info[:email] = scrape_email_on_url(unit_url)
      end
      info
    rescue => e
      LOGGER.error e
      LOGGER.error "With info by link: #{link}."
      nil
    end

    private
      def scrape_contact_info_from_unit(unit_url)
        unit_html               = Nokogiri.HTML(open(unit_url))
        subdomain               = unit_url.match(SUBDOMAIN_REGEX)[2]
        contact_info_paragraphs = unit_html.css('#contact_info p')
        company_name            = contact_info_paragraphs.css('strong')[0].try(:text)
        phones                  = contact_info_paragraphs.reject { |p| p.inner_html.match(/<strong|<a/) }[0].try(:text)
        links_in_contact_info   = contact_info_paragraphs.css('a').map { |a| a[:href] }
        company_site_url        = links_in_contact_info.detect { |link| link.match(self::URL_REGEX) }
        email                   = scrape_email_address_from_contact_info(contact_info_paragraphs) ||
                                  scrape_email_address_from_description(unit_html)                ||
                                  scrape_email_from_company_site(company_site_url)
        {
          subdomain: subdomain,
          company_name: company_name,
          phone: phones,
          email: email,
          company_url: company_site_url,
          provider: 'AppFolio'
        }
      end

      def scrape_email_address_from_contact_info(contact_info_paragraphs)
        scrape_email_from_string(contact_info_paragraphs.inner_html)
      end

      def scrape_email_address_from_description(unit_html)
        scrape_email_from_string(unit_html.css('.content .info p.align_left').text)
      end

      def scrape_email_from_company_site(company_site_url)
        return nil if company_site_url.blank?
        email_from_main_page = scrape_email_on_url(company_site_url)
        return email_from_main_page if email_from_main_page
        get_contact_links_on_page(company_site_url).each do |contact_link|
          contact_url = if contact_link.match(self::URL_REGEX)
                          contact_link
                        else
                          [company_site_url, contact_link].join('/')
                        end
          email_from_contact_page = scrape_email_on_url(contact_url)
          return email_from_contact_page if email_from_contact_page
        end
        nil
      rescue => e
        LOGGER.error e
        LOGGER.error "Probably company site unavailable. Check it on #{company_site_url}."
        nil
      end

      def get_contact_links_on_page(url)
        links = Nokogiri.HTML(open(url)).css('a')
        links.select { |a| a.inner_html.match(/contact/i) }.map { |a| a['href'] }
      end

      def scrape_email_from_string(string)
        string.match(self::EMAIL_REGEX).try(:[], 0)
      end

      def get_html_page(url)
        open(url) { |f| f.read }
      rescue OpenURI::HTTPError
        Proxy.get(url)
      end

      def scrape_email_on_url(url)
        scrape_email_from_string get_html_page(url)
      end
  end
end
