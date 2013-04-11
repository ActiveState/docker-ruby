# This module provides a ruby client API for docker. The docker API is
# not complete; see https://github.com/dotcloud/docker/issues/21

# Copyright (c) 2013 ActiveState Software Inc.


require 'socket'

# FIXME: use eventmachine for non-blocking IO.
class DockerTCPClient
  def initialize(host = nil)
    @host = host || "localhost"
    @port = 4242
  end

  def conn
    c = TCPSocket.open @host, @port
    r = yield c
    c.close
    r
  end

  # Run a docker command on the remote node using the rcli protocol.
  def cmd_with_stdin(stdin, *args)
    conn do |s|
      puts "DOCKER CALL: #{args}"

      # Set arguments array as JSON, followed by a newline.
      s.puts args.to_json
      s.puts

      begin
        # Ignore the first line (pty control)
        s.gets 
      rescue Errno::ECONNRESET => e  # happens for 'docker wait'
        return ''
      end
      
      if not stdin.nil?
        s.puts stdin
        s.close_write
      end
      
      # The reset of the response from the server denotes the STDOUT
      # of the command being run. Read them until the server closes
      # (ECONNRESET) the connection.
      stdout = ''
      while true
        begin
          line = s.gets
        rescue Errno::ECONNRESET => e
          break
        end
        break if line.nil?
        stdout += line
      end
      
      puts "DOCKER FINISH: #{args}"
      puts stdout
      
      stdout
    end
  end

  def cmd(*args)
    cmd_with_stdin nil, *args
  end

  def wait(container_id)
    cmd "wait", container_id
  end

  def kill(container_id)
    cmd "kill", container_id
  end

  def rmi(image)
    cmd "rmi", image
  end

  # Return all running containers
  def ps_running
    cmd("ps", "-q").lines.map(&:strip)
  end

  def run(run_args, image, *command)
    args = ["run", "-d"] + run_args + [image] + command
    cmd(*args).strip
  end

  # Run with stdin content.
  def run_stdin(run_args, image, stdin, *command)
    args = ["run", "-i", "-a", "stdin"] + run_args + [image] + command
    cmd_with_stdin(stdin, *args).strip
  end

  def inspect(container_id)
    JSON.parse cmd("inspect", container_id)
  end

  def commit(container_id, new_image, comment)
    cmd("commit", "-m", comment, container_id, new_image).strip
  end

  # Composite methods below.

  # Extend an image by adding a single file, creating a new image.
  def extend_image_with_file(base_image, new_image, file_path, file_contents)
    container_id = run_stdin [], base_image, file_contents, "/bin/sh", "-c", "cat > #{file_path}; cat #{file_path}"
    wait container_id
    commit container_id, new_image, "Added #{file_path}"
  end

end
