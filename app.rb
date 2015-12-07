#!/usr/bin/env ruby

require 'active_record'
require 'sqlite3'
require 'logger'
require 'capybara'
require 'capybara/poltergeist'
require 'nokogiri'

# Configure Poltergeist to not blow up on websites with js errors aka every website with js
# See more options at https://github.com/teampoltergeist/poltergeist#customization
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, js_errors: false)
end

# Configure Capybara to use Poltergeist as the driver
Capybara.default_driver = :poltergeist

ActiveRecord::Base.logger = Logger.new('debug.log')
configuration = YAML::load(IO.read('config/database.yml'))
ActiveRecord::Base.establish_connection(configuration['development'])

class Game < ActiveRecord::Base
end

@session = Capybara::Session.new(:poltergeist)
@session.driver.headers = { 'User-Agent' => "Safari" }

@teams = [
  "Anaheim Ducks",
  "Arizona Coyotes",
  "Boston Bruins",
  "Buffalo Sabres",
  "Calgary Flames",
  "Carolina Hurricanes",
  "Chicago Blackhawks",
  "Colorado Avalanche",
  "Columbus Blue Jackets",
  "Dallas Stars",
  "Detroit Red Wings",
  "Edmonton Oilers",
  "Florida Panthers",
  "Los Angeles Kings",
  "Minnesota Wild",
  "Montreal Canadiens",
  "Nashville Predators",
  "New Jersey Devils",
  "New York Islanders",
  "New York Rangers",
  "Ottawa Senators",
  "Philadelphia Flyers",
  "Pittsburgh Penguins",
  "San Jose Sharks",
  "StLouis Blues",
  "Tampa Bay Lightning",
  "Toronto Maple Leafs",
  "Vancouver Canucks",
  "Washington Capitals",
  "Winnipeg Jets",
]

#[year, pages, preseason, playoffs]
@season_data = [
  [2015, 29, 6, 13],
  [2014, 29, 1, 15],
  [2013, 17, 1, 30],
  [2012, 29, 3, 9],
  [2011, 29, 5, 11],
  [2010, 29, 1, 13],
  [2009, 27, 3, 13],
  [2008, 27, 1, 8],
  [2007, 24, 3, 9],
  [2006, 25, 4, 19]
]

@season_data.each do |data|
  puts data[0]
  (1..data[1]).each do |page|
    puts page
    @session.visit "http://www.oddsportal.com/hockey/usa/nhl-#{data[0]-1}-#{data[0]}/results/#/page/#{page}/"
    sleep(20)
    @html_doc = Nokogiri::HTML(@session.html)

    @html_doc.css('tr.deactivate').each do |tr|
      @date = tr.css('td')[0].attr('class').scan(/[t][0-9]+[-]/)[0][1..-2]
      @date = Time.at(@date.to_i + 5*60*60).to_datetime

      @home_team, @away_team = tr.css('td')[1].text.split(" - ")
      @home_team = @home_team.gsub(/[^A-z ]/i, '')
      @away_team = @away_team.gsub(/[^A-z ]/i, '')

      # Skip cancelled game
      next if tr.css('td')[2].text.include?('canc')

      @home_goals, @away_goals = tr.css('td')[2].text.split(":")

      # Make OT and SO ties
      @home_goals = @home_goals.to_i
      if @away_goals.include?('pen') || @away_goals.include?('OT') then
        @away_goals = [@away_goals[0].to_i, @home_goals.to_i].min
        @home_goals = @away_goals
      else
        @away_goals = @away_goals.to_i
      end

      if @home_goals > @away_goals then
        @home_win = true
        @away_win = false
      elsif @home_goals < @away_goals then
        @home_win = false
        @away_win = true
      else
        @away_win = false
        @home_win = false
      end

      @home_odds = tr.css('td')[3].css('a').text.to_f
      @tie_odds = tr.css('td')[4].css('a').text.to_f
      @away_odds = tr.css('td')[5].css('a').text.to_f

      @playoff_game = false
      @preseason_game = false

      if @date.strftime('%Y').to_i >= 2009 && (@date.strftime('%m').to_i > 4 || (@date.strftime('%m').to_i == 4 && @date.strftime('%d').to_i > data[3])) then
        @playoff_game = true
      elsif @date.strftime('%Y').to_i >= 2008 && (@date.strftime('%m').to_i < 10 || (@date.strftime('%m').to_i == 10 && @date.strftime('%d').to_i < data[2])) then
        @preseason_game = true
      end

      # Skip if All Star game
      next if @teams.index(@home_team).nil? || @teams.index(@away_team).nil?

      # Save record
      @g = Game.new
      @g.home_team = @home_team
      @g.home_id = @teams.index(@home_team) + 1
      @g.away_team = @away_team
      @g.away_id = @teams.index(@away_team) + 1
      @g.home_goals = @home_goals
      @g.away_goals = @away_goals
      @g.home_win = @home_win
      @g.away_win = @away_win
      @g.date = @date
      @g.season = data[0]
      @g.home_odds = @home_odds
      @g.tie_odds = @tie_odds
      @g.away_odds = @away_odds
      @g.playoff_game = @playoff_game
      @g.preseason_game = @preseason_game

      @g.save
    end
  end
end