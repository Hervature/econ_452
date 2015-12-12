#!/usr/bin/env ruby

require 'active_record'
require 'sqlite3'
require 'logger'
require 'csv'

ActiveRecord::Base.logger = Logger.new('debug.log')
configuration = YAML::load(IO.read('config/database.yml'))
ActiveRecord::Base.establish_connection(configuration['development'])

class Game < ActiveRecord::Base
end

CSV.open("./database.csv", "wb") do |csv|
  csv << Game.attribute_names
  Game.all.each do |game|
    csv << game.attributes.values
  end
end