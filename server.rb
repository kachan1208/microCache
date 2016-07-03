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
          loop do
            request = socket.gets
            self.handle(socket, request)
          end 
        }
      else
        socket.print "No free threads left"
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
    self.getData(socket, request) if request[0] == 'get'
    self.setData(request) if request[0] == 'set'
    self.stats(socket) if request[0] == 'stats'
  end

  #Set data to storage
  def setData(request)
    p 'Set data'
    if request.length
      key = request[1]
      data = request[2]
      time = Time.now.to_i + request[3].to_i

      # sizeOfStorage = ObjectSpace.memsize_of(@data)
      # sizeOfData = ObjectSpace.memsize_of(data)

      # if sizeOfStorage + sizeOfData < @memoryLimit
      p 'Set key = data'
      @data[key] = data
      p 'Set Time'
      @expire[time] = [] if @expire[time].nil?
      @expire[time] << key 
      # end


      p 'Data been set'
      p @data
      p @expire
    end
  end

  #Return data by key to socket
  def getData(socket, request)
    unless request[1].nil? 
      key = request[1]
    
      result = ''
      result = @data[key] unless @data[key].nil?

      socket.print result
    end
  end

  #Return curr unix time, data, data expire time
  def stats(socket)
    stats = Time.now.to_i + '\n\r\0' + 
            @data.flatten + '\n\r\0' + 
            @expire.flatten + '\n\r\0'
    socket.print stats
  end
end

#TODO: write new algorithm for clear memcache data
#TODO: write memory limit mechanism
#TODO: write new add string end for socket.write
#TODO: write waiting mechanism for threads limit