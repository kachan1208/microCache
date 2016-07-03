require "socket"

class MicroCache 
  def initialize(port, mem, thr)
    @port         = port.to_i
    @memoryLimit  = mem.to_i
    @threadsLimit = thr.to_i
    @data         = {}
    @threads      = [] 
    @expire       = {}

    @server = TCPServer.new(@port)
    Thread.new {
      self.clear
    }
  end

  #Listen connections
  def listen
    loop do 
      socket = @server.accept
      if @threadsLimit > @threads.length
        @threads << Thread.new { 
          while !socket.closed?
            request = socket.gets("\n\r").chomp("\n\r")
            self.handle(socket, request)            
          end 

          @threads.delete(Thread.current)
          Thread.kill self
        }
      else
        socket.print("No free threads left", "\n\r")
        socket.close
      end
    end
  end

  #Mechanism of data expiring
  def clear
    loop do
      time = Time.now.to_i
      unless @expire[time].nil?
        p time
        keys = @expire[time] 
        keys.each { |key|
          @data.delete(key)
          p "Remove key " + key
        }

        @expire.delete(time)
        p 'Data'
        p @data
      end

      sleep(0.1)
    end 
  end

  #Handle commands
  def handle(socket, request)
    request = request.split
    case request[0]
    when 'get'
      self.getData(socket, request) 
    when 'set'
      self.setData(request) 
    when 'stats'
      self.stats(socket) 
    when 'end'
      socket.close
    end
  end

  #Set data to storage
  def setData(request)
    if request.length
      key = request[1]
      data = request[2]
      time = Time.now.to_i + request[3].to_i

      @data[key] = data
      @expire[time] = [] if @expire[time].nil?
      @expire[time] << key 
      # end
    end
  end

  #Return data by key to socket
  def getData(socket, request)
    unless request[1].nil? 
      key = request[1]
      
      result = ''
      result = @data[key] unless @data[key].nil?

      socket.print(result, "\n\r")
    end
  end

  #Return curr unix time, data, data expire time
  def stats(socket)
    stats = Time.now.to_i + "\n" + 
            @data.flatten + "\n" + 
            @expire.flatten + "\n"
    socket.print(stats, "\n\r")
  end
end

#TODO: write new algorithm for clear memcache data
#TODO: write memory limit mechanism
#TODO: write new add string end for socket.write
#TODO: write waiting mechanism for threads limit
#TODO: check is socket closed