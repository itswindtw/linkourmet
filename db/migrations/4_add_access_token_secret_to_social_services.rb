Sequel.migration do
  change do
    alter_table(:social_services) do
      add_column :access_token_secret, String, text: true
    end
  end
end
