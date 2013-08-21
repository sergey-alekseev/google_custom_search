set :output, './log/cron_log.log'

every 1.day, at: '1:05 pm' do
  command 'ruby run.rb'
  command 'sqlite3 db/showmojo_managebuilding_contact_infos.sqlite3 < db/import_to_csv.sql'
end
