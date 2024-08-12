# frozen_string_literal: true

class GenerateReleaseCommand < ApplicationCommand
  usage do
    no_command
  end

  option :version do
    desc "Release version"
    long "--version VERSION"
  end

  def execute
    setup_options
    frame("Generating release") do
      logger.headline("Version: #{params[:version]}")

      update_version_file if version_mismatch?
      generate_dist
      generate_docs
      prepare_git_tag
      update_readme
    end
  end

  private

  def setup_options
    @version_from_file = sys.read_file("VERSION").strip
    params[:version] ||= @version_from_file
  end

  def version_mismatch?
    params[:version] != @version_from_file
  end

  def update_version_file
    spinner("Updating VERSION file") do |sp|
      sys.write_file!("VERSION") do |file|
        file.write(params[:version])
        file.write("\n")
      end
      sp.update_title("Updated VERSION file to #{params[:version]}")
    end
  end

  def generate_dist
    spinner("Generating distribution files") do |sp|
      GenerateDistCommand.new(**params.to_h).execute
      sp.update_title("Generated distribution files")
    end
  end

  def generate_docs
    spinner("Generating documentation files") do |sp|
      GenerateDocsCommand.new(**params.to_h).execute
      sp.update_title("Generated documentation files")
    end
  end

  def prepare_git_tag
    git_tag = "v#{params[:version]}"
    spinner("Preparing git tag") do |sp|
      system("git", "tag", git_tag)
      sp.update_title("Prepared git tag: #{git_tag}")
    end
  end

  def update_readme
    spinner("Updating README.md") do |sp|
      content = sys.read_file("dist/README.md")
      sys.write_file!("dist/README.md") do |file|
        content.gsub!(%r{badge/version-v(?<version>.*?)-blue\.svg}) do |match|
          match.sub($LAST_MATCH_INFO[:version], params[:version])
        end
        file.write(content)
      end
      sp.update_title("Updated README.md")
    end
  end
end
