models = require './base'
Lots = models.Lots
User = models.User


exports.used = (callback)->
	User.aggregate
		$group:{_id:{lot:"$lot",cartype:"$cartype"},total:{$sum:1}}
	.exec callback
exports.count = (callback)->
	Lots.find {},callback
exports.getById = (id,callback)->
	Lots.findById id,callback


exports.new = (data,callback)->
	l = new Lots()
	l.lotname = data.lotname
	l.description = data.description
	l.cartype = data.cartype
	l.nums = data.nums
	l.save callback