models = require './base'
Dealer = models.Dealer


exports.login = (dealer,password,callback)->
  Dealer.findOne {dealer_id:dealer,password:password},callback
exports.get = (next)->
	Dealer.find {},next
exports.getbyid = (id,next)->
	Dealer.findOne {dealer_id:id},next
exports.findAll = (next)->
	Deaker.find {},next
	
exports.new = (province,city,county,id,name,password)->
	d = new Dealer()
	d.province = province
	d.city = city
	d.dealer_id = id
	d.password = password
	d.dealer = name
	d.county = county
	d.save()