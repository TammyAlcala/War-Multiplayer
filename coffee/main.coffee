$ ->
  app = new AppController("ws://192.168.1.102:3000/websocket") 
  
  #adiciona os controllers da aplicação
  app.add_controller new ChatController app
  app.add_controller new PlayerListController app
  app.add_controller new SetNickController app
  
  app.start()
