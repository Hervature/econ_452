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

@session.visit "http://www.oddsportal.com/hockey/usa/nhl-2014-2015/results/#/page/4/"

@html_doc = Nokogiri::HTML(@session.html)

@html_doc.css('tr.deactivate').each do |tr|
  @date = tr.css('td')[0].attr('class').scan(/[t][0-9]+[-]/)[0][1..-2]
  @date = Time.at(@date.to_i + 5*60*60).to_datetime

  @home_team, @away_team = tr.css('td')[1].text.split(" - ")
  @home_team = @home_team.gsub(/[^A-z ]/i, '')
  @away_team = @away_team.gsub(/[^A-z ]/i, '')

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

  puts @home_team + " vs. " + @away_team + " played on " + @date.strftime('%m/%d/%Y') + " score was " + @home_goals.to_s + ":" + @away_goals.to_s + " home, tie, aways odds were: " + @home_odds.to_s + ", " + @tie_odds.to_s + ", " + @away_odds.to_s + "."
end