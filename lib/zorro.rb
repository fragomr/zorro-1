require 'bundler/setup'
require 'httparty'

require_relative "zorro/version"

module Zorro
  module Messages
    GEM_NOT_FOUND = 'Gem not found'
  end

  module Request
    include HTTParty

    base_uri 'https://rubygems.org/api/v1'
  end

  class Base
    def self.say(message)
      puts message
    end
  end

  class Gem < Base
    class NotFound < StandardError; end

    attr_accessor :name, :version, :valid
    alias_method :valid?, :valid

    def initialize(response)
      @name     = response['name']
      @version  = response['version']
      @valid    = response[:valid]
    end

    def self.info(gem_name)
      url = "/gems/%s.json" % CGI.escape(gem_name)
      response = Request.get(url)

      case response.code
      when 200 then Gem.new(response.merge!(valid: true))
      when 404 then raise NotFound
      end
    rescue NotFound
      Gem.new(valid: false)
    end

    def self.run(gem_name, *args)
      info = Gem.info(gem_name)

      if info.valid?
        say 'Searching info for %s...' % info.name
        say info.to_gemfile
      else
        say Messages::GEM_NOT_FOUND
      end
    end

    def to_gemfile
      "gem \'#{name}\', \'~> #{version}\'" if valid?
    end
  end
end
