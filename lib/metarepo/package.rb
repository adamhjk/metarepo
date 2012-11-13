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
require 'digest/sha2'

class Metarepo
  class Package < Sequel::Model
    plugin :validation_helpers

    many_to_many :upstreams

    def self.from_file(file)
      Metarepo::Log.info("Loading package from file #{file}")
      if file =~ /rpm$/
        Metarepo::Package.from_rpm(file)
      elsif file =~ /deb$/
        Metarepo::Package.from_deb(file)
      end
    end

    # Creates an Metarepo::Package from an RPM
    #
    # @param [String] the rpm file to create the object from
    # @return [Metarepo::Package]
    def self.from_rpm(file)
      Metarepo::Log.debug("#{file} is an rpm")
      shasum = self.get_shasum(file)
      p = Metarepo::Package[:shasum => shasum]
      return p if !p.nil?
      p = Metarepo::Package.new
      p.shasum = shasum
      p.type = "rpm"
      p.path = file
      p.filename = File.basename(file)
      Metarepo::Log.debug("Extracting package data from #{file}")
      Metarepo.command_per_line('rpm -qp --queryformat \'name: %{NAME}\nversion: %{VERSION}\niteration: %{RELEASE}\narch: %{ARCH}\nmaintainer: %{PACKAGER}\ndescription: %{SUMMARY}\nurl: %{URL}\n\' ' + file) do |item|
        item =~ /^(.+?): (.+)$/
        p.send("#{$1}=".to_sym, $2)
      end
      p
    end

    # Creates an Metarepo::Package from a dpkg
    #
    # @param [String] the deb file to create the object from
    # @return [Metarepo::Package]
    def self.from_deb(file)
      Metarepo::Log.debug("#{file} is an deb")
      shasum = self.get_shasum(file)
      p = Metarepo::Package[:shasum => shasum]
      return p if !p.nil?
      p = Metarepo::Package.new
      p.shasum = shasum
      p.type = "deb"
      p.path = file
      p.filename = File.basename(file)
      Metarepo::Log.debug("Extracting package data from #{file}")
      Metarepo.command_per_line('dpkg-deb --show --showformat \'name: ${Package}\nversion: ${Version}\narch: ${Architecture}\nmaintainer: ${Maintainer}\ndescription: ${Description}\nurl: ${Homepage}\n\' ' + file) do |item|
        next if item =~ /^ / # Skip extraneous lines from dpkg
        case item
        when /^(.+?): (.+)$/
          accessor = $1
          value = $2
        when /^(.+?):/
          accessor = $1
          value = "nil"
        end
        Metarepo::Log.debug("#{accessor} #{value}")

        if accessor == 'version'
          if value =~ /^(.+)-(.+)$/
            version = $1
            iteration = $2
          else
            version = value
            iteration = 0
          end
          p.send("version=".to_sym, version)
          p.send("iteration=".to_sym, iteration)
        elsif accessor != "" && !accessor.nil?
          p.send("#{accessor}=".to_sym, value)
        else
          Metarepo::Log.debug("Blank accessor!")
        end
      end
      p
    end

    def self.get_shasum(file)
      Metarepo::Log.debug("Generating shasum for #{file}")
      hashfunc = Digest::SHA256.new
      File.open(file, "rb") do |io|
        while (!io.eof)
          hashfunc.update(io.readpartial(1024))
        end
      end
      Metarepo::Log.debug("#{file} shasum #{hashfunc.hexdigest}")
      hashfunc.hexdigest
    end

    def self.get_shasum1(file)
      Metarepo::Log.debug("Generating shasum for #{file}")
      hashfunc = Digest::SHA1.new
      File.open(file, "rb") do |io|
        while (!io.eof)
          hashfunc.update(io.readpartial(1024))
        end
      end
      Metarepo::Log.debug("#{file} shasum #{hashfunc.hexdigest}")
      hashfunc.hexdigest
    end

    def self.get_md5sum(file)
      Metarepo::Log.debug("Generating shasum for #{file}")
      hashfunc = Digest::MD5.new
      File.open(file, "rb") do |io|
        while (!io.eof)
          hashfunc.update(io.readpartial(1024))
        end
      end
      Metarepo::Log.debug("#{file} shasum #{hashfunc.hexdigest}")
      hashfunc.hexdigest
    end

    def validate
      super
      validates_unique :shasum
      validates_presence [ :name, :version, :iteration, :arch, :maintainer, :url, :description, :path, :type, :filename ]
      errors.add(:type, "must be deb or rpm") unless [ "deb", "rpm" ].include?(type)
    end

  end
end
