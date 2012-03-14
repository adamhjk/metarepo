Sequel.migration do
  up do
    create_table(:packages_repos) do
      foreign_key :package_id, :packages
      foreign_key :repo_id, :repos
      index [:package_id, :repo_id], :unique => true
    end
  end

  down do
    drop_table(:packages_repos)
  end
end


