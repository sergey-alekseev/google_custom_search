project_root = File.join(File.dirname(File.absolute_path(__FILE__)), '/..')
set :output, "#{project_root}/log/cron_log.log"

every 1.day, at: '1:50 pm' do
  command "cd #{project_root} && ruby run.rb"
end

every 1.day, at: '2:10 pm' do
  command "cd #{project_root} && " \
    "sqlite3 #{project_root}/db/contact_infos.sqlite3 < #{project_root}/db/import_to_csv.sql"
end
