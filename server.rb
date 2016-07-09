require "socket"

class MicroCache 
  def initialize(port, mem, thr, autoclear = false)
    @port         = port.to_i
    @memoryLimit  = mem.to_i
    @threadsLimit = thr.to_i
    @data         = {}
    @threads      = [] 
    @expire       = {}

    @server = TCPServer.new(@port)
    if autoclear
      Thread.new {
        self.clear
      }
    end
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
      @data.each { |key, val|
        if val['time'] <= Time.now.to_i
          @data.delete(key) 
          p 'Remove: ' + key
        end
      }

      sleep(5) 
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

      @data[key] = {'data' => data, 'time' => time}
    end
  end

  #Return data by key to socket
  def getData(socket, request)
    unless request[1].nil? 
      key = request[1]
      result = ''

      #lazy expire
      unless @data[key].nil?
        if @data[key]['time'] > Time.now.to_i
          result = @data[key]['data']  
        else
          @data.delete(key)
        end
      end

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

#TODO: write memory limit mechanism
  #TODO: write new add string end for socket.write
#TODO: write waiting mechanism for threads limit
#TODO: check is socket closed