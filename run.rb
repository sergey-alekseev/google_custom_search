require './app/classes/parsers/manage_building'
require './app/classes/parsers/app_folio'

# TODO: remove LOGGER instantiating in several files somehow
LOGGER = LogFactory.logger('GCS')

begin
  queries_count = 0
  while queries_count <= 100
    state = State.next_state
    queries_count += Parsers::ManageBuilding.contact_infos_for(state.code)
    queries_count += Parsers::AppFolio.contact_infos_for(state.code)
    LOGGER.info "#{queries_count} queries have been already performed. Last state: #{state.code}."
    state.update_attributes(searched_by: true)
  end
rescue
  LOGGER.error "It seems that's all for today. Thanks."
end

