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
  app.post "/regs",home.post
  

  # 管理后台
  app.get '/admin/*',admin.before
  app.get '/admin/in',admin.in
  app.get '/admin/next',admin.next
  app.get '/admin/dealer',admin.dealer
  app.post '/admin/dealer/reser/:user_id',admin.dealerreser
  app.get '/admin/dealer/active',admin.dealeractive
  app.get '/admin/dealer/info',admin.dealerinfo
  app.post '/admin/dealer/infopost',admin.dealerinfopost

  app.post '/admin/in',admin.inpost
  # app.get '/admin/dealer',dealer.homepage
  # app.get '/admin/dealer',dealer.homepage
  # app.get '/admin/home',dealer.homepage


  # app.get '*', note.notfind

console.log "routes loaded."