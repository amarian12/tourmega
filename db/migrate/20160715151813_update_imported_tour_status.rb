class UpdateImportedTourStatus < ActiveRecord::Migration
  def up
     Rake::Task['fix_data:update_imported_tours'].invoke
  end

  def down
  end
end
