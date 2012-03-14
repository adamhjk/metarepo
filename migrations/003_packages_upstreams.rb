#
# Author: adam@opscode.com
#
# Copyright 2012, Opscode, Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
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

