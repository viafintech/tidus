# encoding: utf-8

module Tidus
  class Settings
    def self.access_roles=(roles)
      @roles = roles
    end

    def self.access_roles
      @roles || []
    end
  end
end