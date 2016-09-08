ActiveAdmin.register AdminUser do
  menu parent: 'User'

  permit_params :email, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :email
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end

  filter :email
  filter :created_at

  form do |f|
    semantic_errors
    f.inputs "Admin Details" do
      f.input :email, input_html: { autofocus: true }
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

end
