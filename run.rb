require './app/classes/parsers/manage_building'
require './app/classes/parsers/app_folio'

# TODO: remove LOGGER instantiating in several files somehow
LOGGER = LogFactory.logger('GCS')

begin
  queries_count = 0
  while queries_count <= 100
    state = State.next_state
    keyword = state.code
    queries_count += Parsers::ManageBuilding.contact_infos_for(keyword)
    queries_count += Parsers::AppFolio.contact_infos_for(keyword)
    LOGGER.info "#{queries_count} queries have been already performed. Last keyword: #{keyword}."
    state.update_attributes(searched_by: true)
  end
rescue
  LOGGER.error "It seems that's all for today. Thanks."
end

