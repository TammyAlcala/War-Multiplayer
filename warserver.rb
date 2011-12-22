#encoding: utf-8

#yaml_obj = YAML::dump(env)
#File.open('on_message','w+') { |f| f.write (yaml_obj) }

require 'cgi'
#require 'yaml'
require 'json'

class WarServer < Rack::WebSocket::Application
  
  attr_reader :sid
  
  def initialize(opts = {}) #chamado quando servidor é estartado.
    super #super sempre deve ser chamado primeiro
    @@app ||= WarChat.new
    @sid = nil
    puts 'Rodando aplicacao: ' + @@app.to_s
  end
  
  def on_open(env) #chamado quando uma conexão é aberta
    @sid = env['rack.session.options'][:id]
    @@app.new_conn(self)
  end
  
  def on_close(env) #chamado quando uma conexão é fechada
    @@app.closed_conn(self)
  end
  
  def on_message(env,msg) #chamado quando recebe um mensagem
    msg = JSON.parse(msg)
    @@app.message_received(self,msg)      
  end
  
  def on_error(env, error) #chamado quando um erro acontece
    puts "<<ERRO>> " << error.message
  end
  
  def send_msg(msg,escape=true)
    msg.each { |k,v| msg[k] = CGI.escapeHTML(v) } if escape
    msg = msg.to_json
    puts 'Enviando: ' + msg
    send_data(msg);
  end
end



class WarChat

  def initialize
    @persons = []
    puts 'Aplicacao WarChat iniciada...'
  end
  
  def new_conn(conn)
    puts 'Nova conexao...'
  end
  
  def closed_conn(conn)
    person = person_by_conn(conn)
    @persons.delete(person)
  end
  
  def message_received(conn,msg)    
    add_person(conn,msg['nick']) if msg['type'] == 'init'
    txt_message(conn,msg) if msg['type'] == 'txt'
  end  
  
  private
  def add_person(conn,nick)
    p =  Person.new(conn,nick)
    @persons.push(p)
    conn.send_msg(Message.warn('Bem Vindo ' + p.to_s))
    conn.send_msg(Message.warn('Existem ' + @persons.size.to_s + ' pessoas online'))
    broadcast(Message.warn(p.to_s + ' acabou de entrar'),[p])
  end
  
  def txt_message(conn,msg)
    person = person_by_conn(conn)
    broadcast(Message.txt(person,msg['msg']))
  end
  
  def broadcast(msg,remove=[])
    @persons.each do |p|
      p.send_msg(msg) unless remove.include?(p) #envia mensagem a nao ser que p exista em remove
    end
  end
  
  def person_by_conn(conn)
    i = @persons.index { |p| p.conn == conn }
    @persons[i]
  end
  
end

class Person
  attr_reader :conn, :nick

  def initialize(conn=nil,nick=nil)
    @conn = conn
    @nick = nick
  end
  
  def to_s
    nick
  end
  
  def send_msg(msg)
    @conn.send_msg(msg)
  end
  
end

class Message
  
  def self.warn(msg)
    {'msg' => msg, 'type' => 'warn'}
  end
  
  def self.txt(author,msg)
    {'msg' => msg, 'type' => 'txt', 'author' => author.to_s}
  end
end

