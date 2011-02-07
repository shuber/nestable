module Nestable # :nodoc:
  # Stores information about this gem's version
  module Version
    MAJOR = 0
    MINOR = 0
    PATCH = 0

    # Returns a version string like 1.0.2 from "#{Version::MAJOR}.#{Version::MINOR}.#{Version::PATCH}"
    def self.string
      [MAJOR, MINOR, PATCH].join('.')
    end
  end
end