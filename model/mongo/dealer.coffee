models = require './base'
Dealer = models.Dealer


exports.login = (dealer,password,callback)->
  Dealer.findOne {dealer_id:dealer,password:password},callback

exports.new = (province,city,id,password,name,adr,callback)->
	d = new Dealer()
	d.province = province
	d.city = city
	d.dealer_id = id
	d.password = password
	d.dealer = name
	d.adr = adr
	d.save callback