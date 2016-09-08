namespace :mark_some_tours_as_featured do
  task perform: :environment do
    Tour.update_all(featured: false)
    # TODO: @Quynh
    Tour.where(id: []).update_all(featured: true)
  end
end
