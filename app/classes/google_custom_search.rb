require 'net/https'
require 'uri'
require 'json'
require 'yaml'
require './app/classes/log_factory'

class GoogleCustomSearch
  CONFIG = YAML.load(File.read('config/gcs.yml'))
  # TODO: remove LOGGER instantiating in several files somehow
  LOGGER = LogFactory.logger('GCS')

  def self.response(q, start = 1)
    uri = request_uri(q, start)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.request Net::HTTP::Get.new(uri.request_uri)
  rescue => e
    LOGGER.error '[GSC] something went wrong with API or service. See backtrace below:'
    LOGGER.error e
  end

  def self.response_hash(q, start = 1)
    response = response(q, start)
    response_hash = JSON.parse(response.body)
    if response.code == '200'
      LOGGER.debug '[GSC] json successfully fetched'
      response_hash
    else
      LOGGER.warn "[GSC] request returned with status code #{response.code}. See details below:"
      LOGGER.warn response_hash['error']['errors'].map do |e|
                    %w(domain reason message).map { |k| "#{k}: #{e[k]}" }
                  end.join('\n')
    end
  end

  def self.response_items(q, start = 1)
    response_hash(q, start)['items']
  end

  def self.response_links(q, start = 1)
    response_items(q, start).map { |i| i['link'] }
  end

  def self.response_links_with_total_results(q, start = 1)
    response_hash = response_hash(q, start)
    total_results = response_hash['searchInformation']['totalResults'].to_i
    links = total_results == 0 ? [] : response_hash['items'].map { |i| i['link'] }
    [links, total_results]
  end

  private
    def self.request_uri(q, start = 1)
      key, cx = CONFIG['GCS_KEY'], CONFIG['GCS_CX']
      URI.parse("https://www.googleapis.com/customsearch/v1?key=#{key}&cx=#{cx}&q=#{q}&start=#{start}")
    end
end
