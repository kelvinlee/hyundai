mongoose = require('mongoose')
config = require('../../../config').config
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

mongoose.connect config.mdb, (err)->
  if err
    console.error('Connect to %s error: %s', config.mdb, err.message) 
    process.exit(1)



require "./user"
require "./serv"
require "./lots"
require "./dealer"


exports.User = mongoose.model('User')
exports.Serv = mongoose.model('Serv')
exports.Dealer = mongoose.model('Dealer')
exports.Lots = mongoose.model('Lots')
