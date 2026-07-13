# frozen_string_literal: true

module ProductTaxonomy
  class StageDistAssetsCommand < Command
    def initialize(options)
      super

      @input_path = options.fetch(:input_path)
      @output_path = options.fetch(:output_path)
    end

    def execute
      staged_files = DistAssetStager.new(input_path: @input_path, output_path: @output_path).stage
      logger.info("Staged #{staged_files.length} distribution assets in #{File.expand_path(@output_path)}")
      staged_files
    end
  end
end
