models = require './base'
# Lots = models.Lots
Serv = models.Serv


exports.login = (callback)->
	Serv.findOne {}
