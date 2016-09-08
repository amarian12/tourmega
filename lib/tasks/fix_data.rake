namespace :fix_data do
  task update_imported_tours: :environment do
    Tour.joins(:tour_import).update_all(status: :approved)
  end
end
