class Application
  ROOT = File.expand_path('..', __dir__)
  private_constant :ROOT

  class << self
    def root
      ROOT
    end

    def from_root(*paths)
      File.join(ROOT, *paths)
    end

    def from_src(*paths)
      from_root('dev', 'src', *paths)
    end
  end
end
