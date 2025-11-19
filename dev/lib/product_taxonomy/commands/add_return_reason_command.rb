# frozen_string_literal: true

module ProductTaxonomy
  class AddReturnReasonCommand < Command
    def initialize(options)
      super
      load_taxonomy
      @name = options[:name]
      @description = options[:description]
    end

    def execute
      create_return_reason!
      update_data_files!
    end

    private

    def create_return_reason!
      @return_reason = ReturnReason.create_validate_and_add!(
        id: ReturnReason.next_id,
        name: @name,
        description: @description,
        friendly_id:,
        handle:,
      )
      logger.info("Created return reason `#{@return_reason.name}` with friendly_id=`#{@return_reason.friendly_id}`")
    end

    def update_data_files!
      DumpReturnReasonsCommand.new({}).execute
      SyncEnLocalizationsCommand.new(targets: "return_reasons").execute
      GenerateDocsCommand.new({}).execute
    end

    def friendly_id
      @friendly_id ||= IdentifierFormatter.format_friendly_id(@name)
    end

    def handle
      @handle ||= IdentifierFormatter.format_handle(friendly_id)
    end
  end
end
