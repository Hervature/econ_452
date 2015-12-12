class AddHomeColumns < ActiveRecord::Migration
  def change
    change_table :games do |t|
      t.integer :home_days_since_last_travel
      t.integer :home_last_travel_length_km
      t.integer :home_timezone_change
      t.boolean :home_last_travel_direction
    end
  end
end