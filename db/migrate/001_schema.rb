class Schema < ActiveRecord::Migration
  def change
    create_table :games, force: true do |t|
      t.string :home_team
      t.integer :home_id
      t.string :away_team
      t.integer :away_id
      t.integer :home_goals
      t.integer :away_goals
      t.boolean :home_win
      t.boolean :away_win
      t.date :date
      t.integer :season
      t.float :home_odds
      t.float :tie_odds
      t.float :away_odds
      t.integer :away_roadtrip_length_games
      t.integer :away_roadtrip_length_days
      t.integer :away_roadtrip_length_km
      t.integer :away_days_since_last_travel
      t.integer :away_last_travel_length_km
      t.integer :away_timezone_change
      t.boolean :away_last_travel_direction
    end
  end
end