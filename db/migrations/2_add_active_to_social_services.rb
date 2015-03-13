Sequel.migration do
  change do
    alter_table(:social_services) do
      add_column :active, TrueClass, default: true, null: false
    end
  end
end
