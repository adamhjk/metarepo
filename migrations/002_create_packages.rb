Sequel.migration do
  up do
    create_table(:packages) do
      primary_key :id
      String :shasum, :unique => true
      String :name
      String :version
      String :iteration
      String :arch
      String :maintainer
      String :url
      String :description
      String :type
      String :filename
      String :path
    end
  end

  down do
    drop_table(:packages)
  end
end
