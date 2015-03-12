Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :email, null: false, unique: true, index: true
      String :password, null: false
    end

    create_table(:social_services) do
      primary_key :id
      foreign_key :user_id, :users, null: false, on_delete: :cascade
      String :provider, null: false
      String :access_token, text: true
      String :cursor, text: true
    end
  end
end
