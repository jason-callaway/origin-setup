#!/usr/bin/env ruby
#
# Set up an OpenShift Origin service on AWS EC2
#
require 'thor'
require 'openshift/aws'

# Initialize AWS credentials
::OpenShift::AWS.awscred

module OpenShift

  class Volume < Thor

    namespace "ec2:volume"

    class_option :verbose, :type => :boolean, :default => false

    desc "list", "list the available snapshots"
    def list

      handle = AWS::EC2.new      
      volumes = handle.volumes
      volumes.each { |volume|
        puts "#{volume.id} created #{volume.create_time} (#{volume.status}) (#{volume.size}GB)"
      }

    end

    desc "delete VOLUME", "delete the volume"
    def delete(volume_id)
      puts "task ec2:volume:delete #{volume_id}" unless options[:quiet]
      handle = AWS::EC2.new
      volumes = handle.volumes
      volumes.select { |volume|
        volume.id == volume_id
      }.each {|volume|
        volume.delete
      }
    end

  end
end
