Sequel.migration do
  up do
    create_table(:packages_upstreams) do
      foreign_key :package_id, :packages
      foreign_key :upstream_id, :upstreams
      index [:package_id, :upstream_id], :unique => true
    end
  end

  down do
    drop_table(:packages_upstreams)
  end
end

