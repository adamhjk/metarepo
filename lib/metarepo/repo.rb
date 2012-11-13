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
require 'metarepo/package'

class Metarepo
  class Repo < Sequel::Model
    plugin :validation_helpers

    many_to_many :packages

    attr_accessor :repo_dir

    def validate
      super
      validates_unique :name
      validates_presence [ :type ]
      errors.add(:type, "must be yum, apt or dir") unless [ "yum", "apt", "dir" ].include?(type)
    end

    def list_packages
      case type
      when "yum"
        Dir[File.join(path, "*.rpm")]
      when "apt"
        Dir[File.join(path, "*.deb")]
      when "dir"
        [
         Dir[File.join(path, "*.rpm")],
         Dir[File.join(path, "*.deb")]
        ].flatten
      end
    end

    def repo_path
      rpath = @repo_dir.nil? ? Metarepo::Config.repo_path : @repo_dir
      File.expand_path(File.join(rpath, name))
    end

    def repo_file_for(package)
      case type
      when "apt"
        Metarepo.create_directory(File.join(repo_path, "pool"))
        File.expand_path(File.join(repo_path, "pool", package.filename))
      else
        File.expand_path(File.join(repo_path, package.filename))
      end
    end

    def link_package(package, pool=nil)
      Metarepo::Log.info("Linking #{package.name} to repo #{name}")
      pool ||= Metarepo::Pool.new(Metarepo::Config.pool_path)
      Metarepo.create_directory(repo_path)
      unless File.exists?(repo_file_for(package))
        Metarepo::Log.info("Building hard link for missing package #{package.name} in repo")
        File.link(pool.pool_file_for(package), repo_file_for(package))
      end
      add_package(package) unless packages.detect { |o| o.shasum == package.shasum }
    end

    def unlink_package(package, pool=nil)
      Metarepo::Log.info("Unlinking #{package.name} from repo #{name}")
      File.unlink(repo_file_for(package)) if File.exists?(repo_file_for(package))
      remove_package(package)
    end

    def sync_packages(upstream_packages, pool=nil)
      pool ||= Metarepo::Pool.new(Metarepo::Config.pool_path)
      upstream_packages.each do |upstream_package|
        link_package(upstream_package, pool) unless packages.detect { |o| o.shasum == upstream_package.shasum }
      end
      packages_dataset.all do |repo_package|
        unlink_package(repo_package, pool) unless upstream_packages.detect { |o| o.shasum == repo_package.shasum }
      end
      self.save
    end

    def sync_to_upstream(name, pool=nil)
      pool ||= Metarepo::Pool.new(Metarepo::Config.pool_path)
      upstream_packages = Metarepo::Upstream[:name => name].packages_dataset.all
      sync_packages(upstream_packages, pool)
    end

    def sync_to_repo(name, pool=nil)
      pool ||= Metarepo::Pool.new(Metarepo::Config.pool_path)
      upstream_packages = Metarepo::Repo[:name => name].packages_dataset.all
      sync_packages(upstream_packages, pool)
    end

    def update_index_yum
      Metarepo.command("createrepo #{repo_path}")
    end

    def update_index_apt
      archs = [ "amd64", "i386" ]
      files_to_include_in_release = []
      package_files = []
      archs.each do |arch|
        arch_dist_path = File.join(repo_path, "dists", "main", "binary-#{arch}")
        Metarepo.create_directory(arch_dist_path)
        files_to_include_in_release << File.join(arch_dist_path, "Release")
        files_to_include_in_release << File.join(arch_dist_path, "Packages")
        files_to_include_in_release << File.join(arch_dist_path, "Packages.gz")

        File.open(File.join(arch_dist_path, "Release"), "w") do |file|
          file.print <<-EOH
Archive: #{name}
Component: main
Origin: metarepo
Label: metarepo
Architecture: #{arch}
          EOH
        end
        package_files << File.open(File.join(arch_dist_path, "Packages"), "w")
      end
      Dir[File.join(repo_path, "pool", "*.deb")].each do |deb_file|
        Dir.mktmpdir("debian") do |tmpdir|
          Metarepo.command("dpkg-deb -e #{deb_file} #{tmpdir}")
          package_data = ""
          package_arch = nil
          File.open(File.join(tmpdir, "control")) do |control|
            control.each_line do |line|
              case line
              when /^(Essential|Filename|MD5Sum|SHA1|SHA256|Size)/
                next
              when /^Architecture: (.+)$/
                package_arch = $1
              end
              package_data << line
            end
          end
          deb_file =~ /\/(pool\/.+)$/
          pool_filename = $1
          package_data << "Filename: #{pool_filename}\n"
          package_data << "MD5Sum: #{Metarepo::Package.get_md5sum(deb_file)}\n"
          package_data << "SHA1: #{Metarepo::Package.get_shasum1(deb_file)}\n"
          package_data << "SHA256: #{Metarepo::Package.get_shasum(deb_file)}\n"
          package_data << "Size: #{File.stat(deb_file).size}\n"
          package_files.each do |pfile|
            Metarepo::Log.info("Writing #{deb_file} to #{pfile.path}")
            if pfile.path =~ /binary-#{package_arch}/ || package_arch == "all"
              pfile.puts package_data
              pfile.print "\n"
            end
          end
        end
      end
      package_files.each do |pf|
        pf.close
        Metarepo.command("bash -c 'cat #{pf.path} | gzip > #{pf.path}.gz'")
      end
      File.open(File.join(repo_path, "dists", "main", "Release"), "w") do |release_file|
        release_file.puts <<-EOH
Origin: metarepo
Label: metarepo
Codename: main
Components: main
Architectures: #{archs.join(" ")}
EOH
        md5string = "MD5Sum:\n"
        sha1string = "SHA1:\n"
        sha256string = "SHA256:\n"
        files_to_include_in_release.each do |file|
          file =~ /(binary-.+)$/
          filename = $1
          size = File.stat(file).size
          md5sum = Metarepo::Package.get_md5sum(file)
          sha1sum = Metarepo::Package.get_shasum1(file)
          sha256sum = Metarepo::Package.get_shasum(file)
          md5string << "  #{md5sum} #{size} ./#{filename}\n"
          sha1string << "  #{sha1sum} #{size} ./#{filename}\n"
          sha256string << "  #{sha256sum} #{size} ./#{filename}\n"
        end
        release_file.puts md5string
        release_file.puts sha1string
        release_file.puts sha256string
      end
      File.unlink(File.join(repo_path, "dists", "main", "Release.gpg")) if File.exists?(File.join(repo_path, "dists", "main", "Release.gpg"))
      Metarepo.command("gpg -abs --no-tty --use-agent -u'#{Metarepo::Config['gpg_key']}' -o'#{File.join(repo_path, "dists", "main", "Release.gpg")}' #{File.join(repo_path, "dists", "main", "Release")}")
      Dir.mktmpdir("gpg") do |tmpdir|
        Metarepo.command("chmod 0700 #{tmpdir}")
        Metarepo.command("bash -c 'gpg -q --export -a \'#{Metarepo::Config['gpg_key']}\' > #{File.join(repo_path, "pubkey.gpg")}'")
        Metarepo.command("bash -c 'cat #{File.join(repo_path, "pubkey.gpg")} | gpg -q --homedir #{tmpdir} --import'")
        Metarepo.command("mv #{File.join(tmpdir, "pubring.gpg")} #{File.join(repo_path, "keyring.gpg")}")
      end
    end

    def update_index
      Metarepo::Log.info("Creating package index")
      case type
      when "yum"
        update_index_yum
      when "apt"
        update_index_apt
      end
    end

  end
end
