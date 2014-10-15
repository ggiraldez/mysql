require 'chef/mixin/shell_out'
require 'shellwords'

module MysqlCookbook
  module Helpers
    module Debian
      include Chef::Mixin::ShellOut

      def debian_mysql_cmd
        "/usr/bin/mysql --defaults-file=/etc/#{mysql_name}/debian.cnf -e 'show databases;'"
      end

      def include_dir
        "/etc/#{mysql_name}/conf.d"
      end

      def mysql_name
        "mysql-#{new_resource.parsed_instance}"
      end

      def mysql_version
        new_resource.parsed_version
      end

      def mysql_w_network_stashed_pass
        "/usr/bin/mysql -u root -h 127.0.0.1 -P #{new_resource.parsed_port} -p#{Shellwords.escape(stashed_pass)}"
      end

      def mysql_w_network_stashed_pass_working?
        query = 'show databases;'
        cmd = "echo \"#{query}\""
        cmd << " | #{mysql_w_network_stashed_pass}"
        cmd << ' --skip-column-names'
        info = shell_out!(cmd, :returns => [0, 1])
        info.exitstatus == 0 ? true : false
      end

      def mysql_w_network_resource_pass
        "/usr/bin/mysql -u root -h 127.0.0.1 -P #{new_resource.parsed_port} -p#{Shellwords.escape(new_resource.parsed_root_password)}"
      end

      def mysql_w_network_resource_pass_working?
        query = 'show databases;'
        cmd = "echo \"#{query}\""
        cmd << " | #{mysql_w_network_resource_pass}"
        cmd << ' --skip-column-names'
        info = shell_out!(cmd, :returns => [0, 1])
        info.exitstatus == 0 ? true : false
      end

      def mysql_w_socket_stashed_pass
        "/usr/bin/mysql -S #{socket_file} -p#{Shellwords.escape(stashed_pass)}"
      end

      def mysql_w_socket_stashed_pass_working?
        query = 'show databases;'
        cmd = "echo \"#{query}\""
        cmd << " | #{mysql_w_socket_stashed_pass}"
        cmd << ' --skip-column-names'
        info = shell_out!(cmd, :returns => [0, 1])
        info.exitstatus == 0 ? true : false
      end

      def mysql_w_socket_resource_pass
        "/usr/bin/mysql -S #{socket_file} -p#{Shellwords.escape(new_resource.parsed_root_password)}"
      end

      def mysql_w_socket_resource_pass_working?
        query = 'show databases;'
        cmd = "echo \"#{query}\""
        cmd << " | #{mysql_w_socket_resource_pass}"
        cmd << ' --skip-column-names'
        info = shell_out!(cmd, :returns => [0, 1])
        info.exitstatus == 0 ? true : false
      end

      def mysql_w_socket
        "/usr/bin/mysql -S #{socket_file}"
      end

      def mysql_w_socket_working?
        query = 'show databases;'
        cmd = "echo \"#{query}\""
        cmd << " | #{mysql_w_socket}"
        cmd << ' --skip-column-names'
        info = shell_out!(cmd, :returns => [0, 1])
        info.exitstatus == 0 ? true : false
      end

      def platform_and_version
        case node['platform']
        when 'debian'
          "debian-#{node['platform_version'].to_i}"
        when 'ubuntu'
          "ubuntu-#{node['platform_version']}"
        end
      end

      def pid_file
        "#{run_dir}/#{mysql_name}.pid"
      end

      def repair_debian_password
        query = 'GRANT SELECT, INSERT, UPDATE, DELETE,'
        query << ' CREATE, DROP, RELOAD, SHUTDOWN, PROCESS,'
        query << ' FILE, REFERENCES, INDEX, ALTER, SHOW DATABASES,'
        query << ' SUPER, CREATE TEMPORARY TABLES, LOCK TABLES,'
        query << ' EXECUTE, REPLICATION SLAVE,'
        query << " REPLICATION CLIENT ON *.* TO 'debian-sys-maint'@'localhost'"
        query << " IDENTIFIED BY '#{new_resource.parsed_debian_password}'"
        query << ' WITH GRANT OPTION;'
        try_really_hard(query, 'mysql')
      end

      def run_dir
        "/var/run/#{mysql_name}"
      end

      def socket_file
        "#{run_dir}/#{mysql_name}.sock"
      end

      def stashed_pass
        return ::File.open("/etc/#{mysql_name}/.mysql_root").read.chomp if ::File.exist?("/etc/#{mysql_name}/.mysql_root")
        ''
      end

      def test_debian_password
        query = 'show databases;'
        info = shell_out("echo \"#{query}\" | #{debian_mysql_cmd}")
        info.exitstatus == 0 ? true : false
      end

      def test_root_password
        cmd = '/usr/bin/mysql'
        cmd << " --defaults-file=/etc/#{mysql_name}/my.cnf"
        cmd << ' -u root'
        cmd << " -e 'show databases;'"
        cmd << " -p#{Shellwords.escape(new_resource.parsed_root_password)}"
        info = shell_out(cmd)
        info.exitstatus == 0 ? true : false
      end
    end
  end
end
