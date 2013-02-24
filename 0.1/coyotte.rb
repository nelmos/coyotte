#!/usr/bin/ruby

require 'socket'

################
#  COYOTTE 0.1 #
################

################################
##### Fonction collection  #####
################################

def check_active ( hash )
  @hash_config = hash
  @tab_error = Array.new
  if !@hash_config.has_key? "host"
    @tab_error.push('host (-h=)')
  end
  if !@hash_config.has_key? "cmd"
    @tab_error.push('cmd (-c=)')
  end
  if !@hash_config.has_key? "args"
    @tab_error.push('args (-a=)')
  end
  return @tab_error
end

def check_passive ( hash )
  @hash_config = hash
  @tab_error = Array.new
  @ntype_state = '0'  
  if !@hash_config.has_key? "notified_type"
    @tab_error.push ('notified_type (ntype=)')
    @ntype_state = '1'
  end
  
  if @ntype_state == '0'

    if !@hash_config.has_key? "host"
      @tab_error.push('host (-h)')
    end

    if !@hash_config.has_key? "timestamp"
      @tab_error.push('timestamp (-tsp)')
    end
    if !@hash_config.has_key? "notified_host"
      @tab_error.push('notified_host (-nhost)')
    end
    if !@hash_config.has_key? "return_code"
      @tab_error.push('return_code (-rc)')
    end
    if !@hash_config.has_key? "message"
      @tab_error.push('message (-msg)')
    end

    ### IF NOTIFIED_TYPE = S, CHECK NOTIFIED_SERVICE KEY
    if @hash_config["notified_type"] == 's'
      if !@hash_config.has_key? "notified_service"
        @tab_error.push('notified_service (-nsrv)')
      end
    end

  end
  return @tab_error
end

def create_active ( hash )
  @hash_config = hash
  if @hash_config["mode"] == "w"
  #appel de la fonction wrapper
  # 
  else
    @request = "-rt=#{@hash_config["rt"]}|-chk=#{@hash_config["cmd"]}|-args=#{@hash_config["args"]}|-tmo=#{@hash_config["timeout"]}"
    return @request
  end
end

def create_passive ( hash )
  @hash_config = hash
  @type = @hash_config["notified_type"]
  case @type
  when "s"
    @request = "-rt=#{@hash_config["rt"]}|-tsp=#{@hash_config["timestamp"]}|-ntype=#{@hash_config["notified_type"]}|-nhost=#{@hash_config["notified_host"]}|-nserv=#{@hash_config["notified_service"]}|-rc=#{@hash_config["return_code"]}|-msg=#{@hash_config["message"]}"
  when "h"
    @request = "-rt=#{@hash_config["rt"]}|-tsp=#{@hash_config["timestamp"]}|-ntype=#{@hash_config["notified_type"]}|-nhost=#{@hash_config["notified_host"]}||-rc=#{@hash_config["return_code"]}|-msg=#{@hash_config["message"]}" 
  end
  return @request  
end

def wrapper_search()
end

def request_push ( request, host, port )
  @request = request
  @host = host
  @port = port
  socket = TCPSocket.open(@host, @port)
  socket.puts "#{@request}"
  while line = socket.gets
    puts line
  end
  socket.close
end

##########################
######### BEGIN ##########
##########################


# Instanciation des objets necessaire au demarrage
hash_config = Hash.new

# 1°- Peuplement de hash_config avec les valeurs par defaut
hash_config["rt"] = "a"
hash_config["mode"] = "s"
hash_config["timeout"] = "30"
hash_config["port"] = "5666"

# Recherche d'eventuels arguments de configuration passé en parametre et override des key si necessaire
ARGV.each do|element|
  value_arg = element.gsub(/^-[a-z_]+=/, "")
  case element
  when /-rt=/
    hash_config["rt"]= value_arg
  when /-m=/
    hash_config["mode"] = value_arg
  when /-t=/
    hash_config["timeout"] = value_arg
  when /-p=/
    hash_config["port"] = value_arg
  when /-h=/
    hash_config["host"]= value_arg
  when /-c=/
    hash_config["cmd"] = value_arg
  when /-a=/
    hash_config["args"] = value_arg
  when /-tsp=/
    hash_config["timestamp"] = value_arg
  when /-nsrv=/
    hash_config["notified_service"] = value_arg
  when /-nhost=/
    hash_config["notified_host"] = value_arg
  when /-ntype=/
    hash_config["notified_type"]= value_arg
  when /-rc=/
    hash_config["return_code"] = value_arg
  when /-msg=/
    hash_config["message"] = value_arg
  end
end


# Search request_type and lunch processing required
if hash_config["rt"] == "a"
  verifActive = check_active ( hash_config )
  if verifActive.length != 0
    verifActive.each do |element|
      puts "\"#{element}\" not defined"
    end
    exit 1
  end
  request = create_active ( hash_config )
  request_push request, hash_config["host"], hash_config["port"]
elsif hash_config["rt"] == "p"
    verifPassive = check_passive ( hash_config )
  if verifPassive.length != 0
    puts "Request passive error :"
    verifPassive.each do |element|
      puts "\"#{element}\" not defined"
    end
    exit 1
  end
  request = create_passive ( hash_config )
  puts "coyotte push : #{request}"
  request_push request, hash_config["host"], hash_config["port"]
else 
  puts "RT not Reconized"
  exit 1
end
