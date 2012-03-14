Sequel.migration do
  up do
    create_table(:upstreams) do
      primary_key :id
      String :name, :unique => true 
      String :path
      String :type
    end
  end

  down do
    drop_table(:upstreams)
  end
end

