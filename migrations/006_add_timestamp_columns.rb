Sequel.migration do
  change do
    alter_table(:upstreams) do
      add_column :created_at, :timestamp
      add_column :updated_at, :timestamp
    end
    alter_table(:packages) do
      add_column :created_at, :timestamp
      add_column :updated_at, :timestamp
    end
    alter_table(:repos) do
      add_column :created_at, :timestamp
      add_column :updated_at, :timestamp
    end
  end
end
