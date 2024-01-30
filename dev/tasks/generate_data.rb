# typed: false
# frozen_string_literal: true

module Dev
  module Tasks
    class GenerateData < Task
      class ForPages < Dev::Dep
        def met_failure_description(ctx)
          "Data not found in /docs/_data/sibling_groups.yml"
        end

        def title
          "Generating Pages Data"
        end

        def met?(ctx)
          File.exist?("/docs/_data/sibling_groups.yml")
        end

        def meet(ctx)
          ctx.execute("bin generate_data")
        end
      end

      class << self
        def title
          "Generate Data for Pages"
        end

        def description
          <<~EOM
            Generates Data for Github Pages
          EOM
        end

        def example_usage
          <<~EOM
            ```yaml
            - generate_data
            ```
          EOM
        end
      end

      def initialize(args, dir:, name:)
        super

        on(:up, run: ForPages.new)
      end
    end
  end
end
