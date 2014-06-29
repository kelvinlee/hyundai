# art = require './controllers/art'
home = require './controllers/home'
admin = require './controllers/admin'
# sign = require './controllers/sign'
# git = require './controllers/git'
# admin = require './controllers/admin'


# note = require './controllers/note'

module.exports = (app)->
  app.get '/', home.index
  app.get '/success', home.success
  app.get '/backcode', home.backcode
  app.post "/regs",home.post
  

  # 管理后台
  app.get '/admin/*',admin.before
  app.get '/admin/index',admin.index
  app.get '/admin/in',admin.in
  app.get '/admin/next',admin.next
  app.get '/admin/dealer',admin.dealer
  app.get '/admin/password',admin.changepassword
  app.get '/admin/out',admin.out
  app.post '/admin/password',admin.pocp

  app.post '/admin/dealer/reser/:user_id',admin.dealerreser
  app.get '/admin/dealer/active',admin.dealeractive
  app.get '/admin/dealer/info',admin.dealerinfo
  app.get '/admin/dealer/nine',admin.nine
  app.get '/admin/dealer/nine/:id',admin.nineid
  app.post '/admin/dealer/nine',admin.ninepost
  app.post '/admin/dealer/infopost',admin.dealerinfopost

  app.post '/admin/in',admin.inpost


  app.get '/admin/download',admin.download
  
  # app.get '/admin/dealer',dealer.homepage
  # app.get '/admin/dealer',dealer.homepage
  # app.get '/admin/home',dealer.homepage


  # app.get '*', note.notfind

console.log "routes loaded."