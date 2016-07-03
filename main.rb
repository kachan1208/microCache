load "server.rb"

settings = {
  'port'    => 11211,
  'memory'  => 65536, #64Mb
  'threads' => 1
}

ARGV.each { |arg|
  res = nil
  settings['port']    = res[1] if res = arg.match(/-port=(\d+)/)
  settings['memory']  = res[1] if res = arg.match(/-memory=(\d+)/)
  settings['threads'] = res[1] if res = arg.match(/-threads=(\d+)/)
}

# p settings
server = MicroCache.new(settings['port'], settings['memory'], settings['threads'])
server.listen

