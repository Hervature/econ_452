class AddColumns < ActiveRecord::Migration
  def change
    change_table :games do |t|
      t.boolean :playoff_game
      t.boolean :preseason_game
    end
  end
end