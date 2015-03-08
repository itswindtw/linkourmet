Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :user_id, null: false, unique: true, index: true
      String :access_token, null: false
    end
  end
end
