class AddIndexesForLocations < ActiveRecord::Migration
  def change
    add_index :locations, :country
    add_index :locations, :country_id
    add_index :locations, :city_id
    add_index :locations, :name
  end
end
