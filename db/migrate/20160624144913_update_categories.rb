class UpdateCategories < ActiveRecord::Migration
  def up
    Country.update_all(is_searching_active: false)
    Rake::Task['data:update_countries'].invoke
  end

  def down
  end
end
