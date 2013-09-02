require 'yaml'
def project_root ; File.join(File.dirname(File.absolute_path(__FILE__)), '/..') ; end
set :output, "#{project_root}/log/cron_log.log"

def scraping_command(config_filename)
  config = YAML.load(File.read(config_filename))
  "cd #{project_root} && GCS_KEY=#{config['GCS_KEY']} GCS_CX=#{config['GCS_CX']} ruby run.rb"
end

every 1.day, at: '12:00 pm' do
  command scraping_command('config/gcs.1.yml')
end

every 1.day, at: '1:00 pm' do
  command scraping_command('config/gcs.2.yml')
end

every 1.day, at: '2:00 pm' do
  command "cd #{project_root} && " \
    "sqlite3 #{project_root}/db/contact_infos.sqlite3 < #{project_root}/db/import_to_csv.sql"
end
