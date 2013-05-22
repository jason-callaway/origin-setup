#!/usr/bin/env ruby
#
# Set up an OpenShift Origin service on AWS EC2
#
require 'rubygems'
require 'thor'

module OpenShift

  module  Puppet

    class Cert < Thor
      namespace "puppet:cert"

      class_option :verbose, :type => :boolean, :default => false
      class_option :debug, :type => :boolean, :default => false
      class_option :quiet, :type => :boolean, :default => false

      desc "sign MASTER HOSTNAME", "sign an agent certificate"
      def sign(master, hostname)
        puts "task puppet:cert:sign #{master} #{hostname}" unless options[:quiet]

        username = options[:username] || Remote.ssh_username
        key_file = options[:ssh_key_file] || Remote.ssh_key_file

        cmd = "sudo puppet cert sign #{hostname}"

        exit_code, exit_signal, stdout, stderr = Remote.remote_command(
        master, username, key_file, cmd, options[:verbose])

      end


      desc "generate MASTER HOSTNAME", "sign an agent certificate"
      def generate(master, hostname)
        puts "task puppet:cert:generate #{master} #{hostname}" unless options[:quiet]

        username = options[:username] || Remote.ssh_username
        key_file = options[:ssh_key_file] || Remote.ssh_key_file

        cmd = "sudo puppet cert sign #{hostname}"

        exit_code, exit_signal, stdout, stderr = Remote.remote_command(
        master, username, key_file, cmd, options[:verbose])

      end

      desc "list MASTER", "list the outstanding unsigned (or all) certs"
      method_option :all, :type => :boolean, :default => false
      def list(master, hostname=nil)
        puts "task puppet:cert:list #{master}" unless options[:quiet]

        username = options[:username] || Remote.ssh_username
        key_file = options[:ssh_key_file] || Remote.ssh_key_file

        cmd = "sudo puppet cert list #{hostname}"
        cmd << " --all" if options[:all]

        exit_code, exit_signal, stdout, stderr = Remote.remote_command(
        master, username, key_file, cmd, options[:verbose])

        # check exit_code

        if hostname
          # check stdout: 
          # [+-] "<hostname>"\s+ (<fingerprint)[ (alt names: [names])]
          # or
          # err: Could not call list: could not find a certificate for <hostname>
        else
          
        end

        # parse the cert lines for 
        certlist = stdout.select {|line|
          # only pick lines that 
          line.match /^(\+|-)\s/
        }.map {|line|
          state, name, fingerprint, attrlist = line.split(' ', 4)
          # strip the leading and trailing quotes and parens
          [state, name[1..-2], fingerprint[1..-2]]
        }
        
        certlist.each { |state, name, fingerprint|
          puts "#{state} #{name} #{fingerprint}"
        }
        certlist
      end
      
    end

    class Master < Thor

      namespace "puppet:master"

      desc "set_moduledir HOSTNAME MODULEDIR", "set the moduledir for the master configuration"
      def set_moduledir(hostname, moduledir)
        puts "task: puppet:module:set_moduledir #{hostname} #{moduledir}" unless options[:quiet]


      end

    end

    class Agent < Thor

      namespace "puppet:agent"

      class_option :verbose, :type => :boolean, :default => false
      class_option :debug, :type => :boolean, :default => false
      class_option :quiet, :type => :boolean, :default => false

      desc "set_server HOSTNAME MASTER", "set the master hostname on an agent"
      def set_server(hostname, master)

        puts "task puppet:agent:set_server #{hostname} #{master}" unless options[:quiet]

        username = options[:username] || Remote.ssh_username
        key_file = options[:ssh_key_file] || Remote.ssh_key_file

        Remote::File.copy(hostname, username, key_file,
          '/etc/puppet/puppet.conf', 'puppet.conf', 
          false, false, false, options[:verbose])

        cmd = "sed -i -e  '/\\[main\\]/a\\    server = #{master}' puppet.conf"
        exit_code, exit_signal, stdout, stderr = Remote.remote_command(
          hostname, username, key_file, cmd, options[:verbose])

        Remote::File.copy(hostname, username, key_file,
          'puppet.conf', '/etc/puppet/puppet.conf',
          true, false, false, options[:verbose])
      end

    end

    class Module < Thor
      namespace "puppet:module"

      class_option :verbose, :type => :boolean, :default => false
      class_option :debug, :type => :boolean, :default => false
      class_option :quiet, :type => :boolean, :default => false

      desc "install HOSTNAME MODULE [MODULE]...", "install a puppet module on a remote host"
      def install(hostname, *modules)
        
        puts "task: puppet:module:install #{hostname} #{modules.join(' ')}" if not options[:quiet]

        username = options[:username] || Remote.ssh_username
        key_file = options[:ssh_key_file] || Remote.ssh_key_file

        cmd = "sudo puppet module install --mode master #{modules.join(' ')}"
        exit_code, exit_signal, stdout, stderr = Remote.remote_command(
          hostname, username, key_file, cmd, options[:verbose]
          )

      end


    end

  end

end

