# frozen_string_literal: true

require_relative "../test_helper"

class DistributionMatchesDataTest < ActiveSupport::TestCase
  include Minitest::Hooks
  parallelize(workers: 1) # disable parallelization

  def setup
    @sys = System.new
  end

  test "dist/ files match the system" do
    dist_files_before = @sys.glob("dist/en/**/*.{json,txt}").map { [_1, @sys.read_file(_1)] }.to_h

    SeedLocalCommand.new(interactive: false).execute
    GenerateDistCommand.new(interactive: false).execute

    dist_files_after = @sys.glob("dist/en/**/*.{json,txt}").map { [_1, @sys.read_file(_1)] }.to_h

    files_added = dist_files_after.keys - dist_files_before.keys
    files_removed = dist_files_before.keys - dist_files_after.keys
    files_changed = dist_files_after.select { |k, v| dist_files_before[k] != v }.keys

    assert_empty(files_added, <<~MSG)
      Expected, but did not find, these files: #{files_added.join("\n")}.

      If run locally, this test itself has fixed the issue.
    MSG
    assert_empty(files_removed, <<~MSG)
      Found, but did not expect, these files:
      #{files_removed.join("\n")}

      If run locally, this test itself has fixed the issue
    MSG
    assert_empty(files_changed, <<~MSG)
      Expected changes to these files:
      #{files_changed.join("\n")}

      If run locally, this test itself has fixed the issue
    MSG
  end
end
