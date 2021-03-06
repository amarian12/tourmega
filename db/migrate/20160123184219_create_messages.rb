class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.integer :sender_id
      t.integer :receiver_id
      t.string :title
      t.text :content
      t.boolean :skip_email

      t.timestamps null: false
    end
  end
end
