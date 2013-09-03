project_root = File.join(File.dirname(File.absolute_path(__FILE__)), '/../../../')
Dir.glob(File.join(project_root, "app/*/*.rb")).each { |f| require f }
require File.join(project_root, 'core_ext/object/blank')
require 'nokogiri'
require 'open-uri'
require 'httparty'
require 'parallel'
require 'csv'
require 'active_record'

module Parsers
  class Base
    # TODO: remove LOGGER instantiating in several files somehow
    LOGGER = LogFactory.logger('GCS')
    URL_REGEX = /https?:\/\/[\S]+/i
    EMAIL_REGEX = /[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}/i
    PHONE_REGEX = /^((\([\d]+\).*)|(.*\([\d.]{5,}\))|([\d.\- \(\)\/]+\((fax|office)\))?|([\d.\- \(\)\/]{10,}.*)|([\d\-]{8,}.*)|(Joey Gonzalez Cell \(fax\)))$/

    class << self
      def contact_infos_for(keyword)
        LOGGER.info "Start scraping contact infos for #{keyword}"
        contact_links = links_for(keyword)
        infos = Parallel.map(contact_links, in_processes: 4, in_threads: 20) do |cl|
          ret = 2
          begin
            contact_info(cl)
          rescue => e
            LOGGER.error "#{e} for #{cl}"
            if (ret = ret - 1) > 0
              LOGGER.info "retrying for #{cl}"
              retry
            end
          end
        end.compact
        ContactInfo.write(infos)
        contact_links.size / 10 + 1
      rescue => e
        LOGGER.error e
      end

      def links_for(keyword, start = 11)
        question = question_for(keyword)
        links, total_results = GoogleCustomSearch.response_links_with_total_results(question, 1)
        LOGGER.info "#{total_results} total results for #{keyword}"
        while start <= 91 && start <= total_results
          ret = 2
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
        links.flatten.map { |link| link.match(self::CONTACT_LINK_REGEX)[0] }.uniq
      rescue => e
        LOGGER.error "It seems that 100 queries limit is over. See details below:"
        LOGGER.error e
      end

      protected
        def question_for(keyword) ; raise 'Not implemented!' ; end
        def contact_info(link) ; raise 'Not implemented!' ; end
    end
  end
end
