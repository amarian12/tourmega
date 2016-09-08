class AddVideoPresentationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :video_presentation, :string
  end
end
