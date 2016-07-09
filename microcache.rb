require "socket"

class MicroCacheClient 
  def initialize(host, port)
    @host = host
    @port = port
    self.open
  end

  def open
    @client = TCPSocket.open(@host, @port)
  end


  def set(key, data, time)
    return if key.nil? || data.nil? || time.nil?

    data = data.to_s.gsub(' ', "\0")
    request = 'set ' + key.to_s + ' ' + data  + ' ' + time.to_s + "\n\r"
    
    @client.write(request)
  end

  def get(key)
    request = 'get ' + key.to_s + "\n\r"
    
    @client.write(request)
    response = @client.gets("\n\r").chomp("\n\r")
    return response.gsub("\0", ' ')
  end

  def close
    @client.write('end')
    @client.close
  end
end

client = MicroCacheClient.new('localhost', 11211)
client.set('Test', 'Hello Wosdkfjhsdlf sdlfjk haldkjfhalkdjf alskdjfhrld', 10)
p client.get('Test')
p client.get('Test')
p client.get('est')
client.close