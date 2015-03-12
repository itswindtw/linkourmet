Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :username, null: false, unique: true, index: true
      String :password_salt, null: false
      String :password_hash, null: false
    end

    create_table(:associations) do
      primary_key :id
      foreign_key :user_id, :users
      String :provider, null: false
      String :access_token, text: true
      String :cursor, text: true
    end
  end
end
