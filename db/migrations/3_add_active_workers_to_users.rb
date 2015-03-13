Sequel.migration do
  change do
    alter_table(:users) do
      add_column :active_workers, Integer, default: 0, null: false
    end
  end
end
