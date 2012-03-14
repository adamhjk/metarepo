require 'mixlib/config'

class Metarepo
  class Config
    extend Mixlib::Config

    db_connect 'postgres://localhost/metarepo'
    pool_path '/var/opt/metarepo/pool'
    repo_path '/var/opt/metarepo/repos'

  end
end

