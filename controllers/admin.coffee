# 基本类库
fs = require 'fs'
path = require 'path'
crypto = require 'crypto'
helper = require '../lib/helper'


# 扩展类库
EventProxy = require 'eventproxy'
config = require('../config').config

# 数据库
User = require("../model/mongo").User
Lots = require("../model/mongo").Lots
Dealer = require("../model/mongo").Dealer

str="qwertyuiopasdfghjklmnbvcxz1234567890"


exports.first = (req,res,next)->
	if req.cookies.login? and req.cookies.login is "in" and req.cookies.user?
		res.redirect "/admin/index"
	else
		res.redirect "/admin/in"
exports.before = (req,res,next)->
	# check login.
	if req.cookies.login isnt "in"
		return res.redirect "/dealer"
	next()
exports.in = (req,res,next)->
	defaultDealer()
	if req.cookies.login? and req.cookies.login is "in" and req.cookies.user?
		return res.redirect "/admin/index"
	console.log req.cookies.user
	res.render "admin/in",{name:req.cookies.user}
exports.index = (req,res,next)->

	res.render "admin/index"
exports.inpost = (req,res,next)->
	# 登录
	re = new helper.recode()
	type = req.body.usertype
	username = req.body.username
	password = req.body.password
	console.log type,username,password
	switch type
		when "1"
			console.log "经销商"
			re.recode = 201
			console.log username.toUpperCase()
			Dealer.login username.toUpperCase(),password,(err,resutls)->
				# console.log err,resutls
				if resutls?
					re.recode = 200
					res.cookie "login","in"
					res.cookie 'user',resutls.dealer_id
					res.cookie "dealer",resutls.dealer
					res.cookie 'usertype',type
				else
					re.recode = 203
					re.reason = "用户名或密码错误"
				res.send re

		when "2"
			console.log "客服"
			if username isnt "9999999"
				re.recode = 203
				re.reason = "用户名或密码错误"
		when "3"
			console.log "管理员"
			if username isnt "admin" and password isnt "admin888"
				re.recode = 203
				re.reason = "用户名或密码错误"

	if re.recode is 200
		res.cookie 'user',username
		res.cookie 'usertype',type
	if type isnt "1"
		res.send re
exports.out = (req,res,next)->
	console.log "out"
	res.cookie "login","out"
	res.render "admin/out"

exports.next = (req,res,next)->
	# 分发登录
	console.log req.cookies.usertype
	if req.cookies.usertype is "1"
		res.redirect "/admin/index"
	if req.cookies.usertype is "2"
		res.redirect "/admin/serv"
	if req.cookies.usertype is "3"
		res.redirect "/admin/homepage"

exports.dealer = (req,res,next)->
	if req.cookies.user?
		startime = req.query.startime
		endtime = req.query.endtime
		type = req.query.type
		console.log startime,endtime,type
		# if startime
		if startime? and endtime? and type?
			User.GetUserByTime req.cookies.user,startime,endtime,type,(err,resutls)->
				# console.log err,resutls
				res.render "admin/dealer",{list:resutls}
		else
			User.getUserByDealer req.cookies.user,(err,resutls)->
				# console.log resutls
				res.render "admin/dealer",{list:resutls}
	else
		res.redirect "/admin/in"
exports.dealerreser = (req,res,next)->
	console.log req.params.user_id,req.body.timer
	re = new helper.recode()

	if not req.body.timer? or req.body.timer is ""
		res.send re
	else
		User.getUserById req.params.user_id,(err,user)->
			reser_at = new Date req.body.timer
			if user.create_at.getTime() > reser_at.getTime()
				re.recode = 201
				re.reason = "预约时间不能小于注册时间."
				return res.send re
			user.reser_at = reser_at
			user.save()
			res.send re

exports.dealeractive = (req,res,next)->

	res.render "admin/active"

exports.nine = (req,res,next)->

	res.render "admin/nine",{dealer:req.cookies.dealer,dealer_id:req.cookies.user}
exports.ninepost = (req,res,next)->
	re = new helper.recode()

	othername = req.body.othername
	othermobile = req.body.othermobile
	thir = req.body.thir 
	cartype = req.body.cartype

	vin = req.body.vin
	mileage = req.body.mileage
	customer = req.body.customer

	dealer = req.cookies.user
	code = "9999999"


	if not customer? or customer is ""
		re.recode = 201
		re.reason = "客户代表必须填写"
	if not vin? or vin is "" or vin.length isnt 6
		re.recode = 201
		re.reason = "VIN码格式不正确"
	if not othermobile? or othermobile is "" or othermobile.length isnt 11
		re.recode = 201
		re.reason = "手机号码格式不正确"
	if not othername? or othername is ""
		re.recode = 201
		re.reason = "用户名不能为空"
	if re.recode isnt 200
		res.send re
		return false
	User.getUserByCarType cartype,vin,(err,uvin)->
		console.log "vin",uvin
		if uvin?
			re.recode = 201
			re.reason = "此VIN码在此车型下已经存在"
			res.send re
		else
			User.otherUser othermobile,(err,ouser)->
				if ouser?
					re.recode = 201
					re.reason = "此手机号已经实施过."
					res.send re
				else
					User.newUserNice code,dealer,thir,cartype,othername,othermobile,vin,mileage,customer,(err,user)->
						console.log err,user
						re.reason = user._id
						res.send re
exports.nineid = (req,res,next)->
	id = req.params.id

	User.getUserById id,(err,user)->
		if user?
			res.render "admin/nine",{user:user,dealer:req.cookies.dealer,dealer_id:req.cookies.user}


exports.dealerinfo = (req,res,next)->
	console.log req.query.code

	if req.query.code is "9999999"
		return res.redirect "/admin/dealer/nine"



	User.getUserByCode req.query.code,req.cookies.user,(err,user)->
		# console.log resutls
		if user?
			Lots.getById user.lot,(err,lot)->
				res.render "admin/info",{user:user,code:req.query.code,lot:lot,dealer_id:req.cookies.user,dealer:req.cookies.dealer}
		else
			res.render "admin/info",{user:null}


exports.dealerinfopost = (req,res,next)->
	re = new helper.recode()

	othername = req.body.othername
	othermobile = req.body.othermobile
	vin = req.body.vin
	mileage = req.body.mileage
	customer = req.body.customer

	dealer = req.body.dealer
	code = req.body.code

	# console.log othername,othermobile,vin,mileage,customer
	
	
	
	if not customer? or customer is ""
		re.recode = 201
		re.reason = "客户代表必须填写"
	if not vin? or vin is "" or vin.length isnt 6
		re.recode = 201
		re.reason = "VIN码格式不正确"
	if not othermobile? or othermobile is "" or othermobile.length isnt 11
		re.recode = 201
		re.reason = "手机号码格式不正确"
	if not othername? or othername is ""
		re.recode = 201
		re.reason = "用户名不能为空"
	console.log re
	if re.recode is 200
		ep = new EventProxy.create "user","uvin","ouser",(user,uvin,ouser)->
			# console.log "goto save."
			usedby = false
			if ouser?
				usedby = true
				console.log "已经实施过的用户."
			if uvin?
				re.recode = 201
				re.reason = "此VIN码在此车型下已经存在,请确认."
				res.send re
			else
				User.updateInfo code,req.cookies.user,othername,othermobile,vin,mileage,customer,usedby,(err,resutls)->
					if resutls?
						console.log resutls
					else
						re.recode = 201
						re.reason = "随机码非本经销商所有."
					res.send re
		User.otherUser othermobile,(err,ouser)->
			ep.emit "ouser",ouser
		User.getUserByCode code,req.cookies.user,(err,user)->
			cartype = user.cartype
			ep.emit "user",user
			console.log "user",user
			User.getUserByCarType cartype,vin,(err,uvin)->
				ep.emit "uvin",uvin
				console.log "vin",uvin
		
	else
		res.send re


exports.changepassword = (req,res,next)->
	res.render "admin/changepassword"
exports.pocp = (req,res,next)->
	re = new helper.recode()

	username = req.cookies.user
	password = req.body.password
	newpass = req.body.newpass

	if newpass.length < 6 || newpass.length > 18
		re.recode = 201
		re.reason = "新密码长度为6到18位"
		res.send re
		return false

	Dealer.login username.toUpperCase(),password,(err,resutls)->
		if resutls?
			resutls.password = newpass
			resutls.save()
			res.send re
		else
			re.recode = 201
			re.reason = "现用密码错误,无法修改."
			res.send re

exports.download = (req,res,next)->
	result = 'a,b,c'
	res.setHeader('Content-Type', 'application/vnd.openxmlformats');
	res.setHeader("Content-Disposition", "attachment; filename=Report.xls");
	res.end(result, 'binary');




defaultDealer = ->
	Dealer.get (err,resutls)->
		if resutls.length>0
			return false
		Dealer.new "北京","北京市","丰台区","D0101","京汉新港","100000"
		Dealer.new "北京","北京市","海淀区","D0102","鹏奥","100001"
		Dealer.new "北京","北京市","丰台区","D0103","信发","100002"
		Dealer.new "北京","北京市","朝阳区","D0104","燕盛隆","100003"
		Dealer.new "北京","北京市","朝阳区","D0105","胜鸿都","100004"
		Dealer.new "北京","北京市","朝阳区","D0106","博伟恒业","100005"
		Dealer.new "北京","北京市","朝阳区","D0107","瑞通嘉业","100006"
		Dealer.new "北京","北京市","开发区","D0108","冀财奥","100007"
		Dealer.new "北京","北京市","朝阳区","D0110","通铭伟业","100008"
		Dealer.new "北京","北京市","朝阳区","D0111","波士山","100009"
		Dealer.new "北京","北京市","海淀区","D0112","京现荣华","100010"
		Dealer.new "北京","北京市","平谷区","D0114","欧之杰","100011"
		Dealer.new "北京","北京市","海淀区","D0115","东方金硕","100012"
		Dealer.new "北京","北京市","密云县","D0116","安瑞迪","100013"
		Dealer.new "北京","北京市","房山区","D0117","连振高超","100014"
		Dealer.new "北京","北京市","昌平区","D0118","天乐国裕","100015"
		Dealer.new "北京","北京市","大兴区","D0119","大兴大通佳信","100016"
		Dealer.new "北京","北京市","石景山区","D0120","北方程远","100017"
		Dealer.new "北京","北京市","朝阳区","D0121","庞大伟业","100018"
		Dealer.new "北京","北京市","顺义区","D0123","北京成禄翔","100019"
		Dealer.new "北京","北京市","怀柔区","D0124","北京华阳顺通","100020"
		Dealer.new "北京","北京市","朝阳区","D0125","鸿都智通","100021"
		Dealer.new "北京","北京市","朝阳区","D0126","东仁环宇","100022"
		Dealer.new "北京","北京市","通州区","D0127","北京京信永达","100023"
		Dealer.new "上海","上海市","浦东新区","D0201","上海东昌","100024"
		Dealer.new "上海","上海市","闵行区","D0202","上海北现","100025"
		Dealer.new "上海","上海市","普陀区","D0203","上海中创","100026"
		Dealer.new "上海","上海市","宝山区","D0205","上海现峰","100027"
		Dealer.new "上海","上海市","徐汇区","D0206","上海通现","100028"
		Dealer.new "上海","上海市","宝山区","D0210","上海百联","100029"
		Dealer.new "上海","上海市","淞江区","D0212","上海惠盈","100030"
		Dealer.new "上海","上海市","奉贤区","D0213","上海金现","100031"
		Dealer.new "上海","上海市","宝山区","D0215","上海宝银","100032"
		Dealer.new "上海","上海市","浦东新区","D0216","上海联诚","100033"
		Dealer.new "上海","上海市","金山区","D0217","上海轿辰","100034"
		Dealer.new "上海","上海市","宝山区","D0218","上海恒锐","100035"
		Dealer.new "上海","上海市","闵行区","D0219","上海强生","100036"
		Dealer.new "上海","上海市","闵行区","D0220","上海弘怡","100037"
		Dealer.new "上海","上海市","青浦区","D0221","上海联兴","100038"
		Dealer.new "重庆","重庆市","渝北区","D0301","重庆美源","100039"
		Dealer.new "重庆","重庆市","南岸区","D0302","重庆互邦正信","100040"
		Dealer.new "重庆","重庆市","渝北区","D0303","重庆当代","100041"
		Dealer.new "重庆","重庆市","涪陵区","D0304","涪陵驰御","100042"
		Dealer.new "重庆","重庆市","璧山区","D0305","重庆奥瑞","100043"
		Dealer.new "重庆","重庆市","巴南区","D0306","重庆沛鑫","100044"
		Dealer.new "重庆","重庆市","永川区","D0307","永川美源永现","100045"
		Dealer.new "重庆","重庆市","万州区","D0308","美源万现","100046"
		Dealer.new "重庆","重庆市","合川区","D0309","重庆通际","100047"
		Dealer.new "天津","天津市","河西区","D0401","天津捷安","100048"
		Dealer.new "天津","天津市","北辰区","D0402","天津中乒","100049"
		Dealer.new "天津","天津市","南开区","D0403","天津鸿通","100050"
		Dealer.new "天津","天津市","河西区","D0404","天津信盛","100051"
		Dealer.new "天津","天津市","开发区","D0405","天津瑞芝","100052"
		Dealer.new "天津","天津市","汽车园","D0406","天津森龙","100053"
		Dealer.new "天津","天津市","北辰区","D0407","天津庞大伟通","100054"
		Dealer.new "天津","天津市","西青区","D0408","天津森达","100055"
		Dealer.new "天津","天津市","静海县","D0409","天津捷世德","100056"
		Dealer.new "天津","天津市","西青区","D0410","天津博兴奇智","100057"
		Dealer.new "天津","天津市","蓟县","D0412","蓟县汇青源通","100058"
		Dealer.new "山东","青岛市","市北区","D1003","青岛裕泰","100059"
		Dealer.new "山东","青岛市","市北区","D1004","青岛福日","100060"
		Dealer.new "山东","淄博市","张店区","D1005","淄博泰通达","100061"
		Dealer.new "山东","临沂市","义堂镇","D1006","临沂鲁泰","100062"
		Dealer.new "山东","济宁市","高新区","D1007","济宁永泰","100063"
		Dealer.new "山东","烟台市","芝罘区","D1008","烟台博泰","100064"
		Dealer.new "山东","临沂市","兰山市区","D1009","临沂阳光","100065"
		Dealer.new "山东","烟台市","开发区","D1010","烟台金德","100066"
		Dealer.new "山东","潍坊市","坊子区","D1011","潍坊金龙","100067"
		Dealer.new "山东","潍坊市","开发区","D1012","潍坊晟星","100068"
		Dealer.new "山东","东营市","东营区","D1014","东营通泰","100069"
		Dealer.new "山东","聊城市","东昌府区","D1015","聊城恒泰","100070"
		Dealer.new "山东","日照市","东港区","D1016","日照美多","100071"
		Dealer.new "山东","泰安市","岱岳区","D1017","泰安北方","100072"
		Dealer.new "山东","东营市","垦利县","D1018","东营明达","100073"
		Dealer.new "山东","济南市","槐荫区","D1019","山东润寰","100074"
		Dealer.new "山东","莱芜市","开发区","D1020","莱芜泰达","100075"
		Dealer.new "山东","德州市","德城区","D1021","德州正豪","100076"
		Dealer.new "山东","淄博市","张店区","D1022","淄博金恒吉","100077"
		Dealer.new "山东","日照市","东港区","D1023","日照顺新","100078"
		Dealer.new "山东","枣庄市","市中区","D1024","枣庄凯顺","100079"
		Dealer.new "山东","菏泽市","牡丹区","D1025","菏泽昌信","100080"
		Dealer.new "山东","滨州市","滨城区","D1026","滨州远方","100081"
		Dealer.new "山东","临沂市","罗庄区","D1027","临沂翔宇","100082"
		Dealer.new "山东","威海市","环翠区","D1028","威海振洋","100083"
		Dealer.new "山东","青岛市","崂山区","D1029","青岛润洋","100084"
		Dealer.new "山东","淄博市","淄川区","D1031","淄博众智源","100085"
		Dealer.new "山东","济宁市","市中区","D1033","济宁鸿源","100086"
		Dealer.new "山东","潍坊市","寿光市","D1034","寿光元润","100087"
		Dealer.new "山东","潍坊市","诸城市","D1035","诸城佳恒","100088"
		Dealer.new "山东","济南市","历下区","D1036","山东华建","100089"
		Dealer.new "山东","烟台市","招远市","D1037","招远玲珑","100090"
		Dealer.new "山东","青岛市","胶南市","D1038","青岛宇海","100091"
		Dealer.new "山东","聊城市","东昌府区","D1039","聊城金友","100092"
		Dealer.new "山东","青岛市","平度市","D1040","青岛宝威","100093"
		Dealer.new "山东","烟台市","龙口市","D1041","烟台龙口","100094"
		Dealer.new "山东","德州市","德城区","D1042","德州正达","100095"
		Dealer.new "山东","泰安市","泰山区","D1043","泰安好运","100096"
		Dealer.new "山东","威海市","环翠区","D1044","威海悦洋","100097"
		Dealer.new "山东","滨州市","滨城区","D1045","滨州通悦","100098"
		Dealer.new "山东","菏泽市","开发区","D1046","菏泽通源","100099"
		Dealer.new "山东","枣庄市","滕州市","D1047","滕州永大","100100"
		Dealer.new "山东","潍坊市","高密市","D1048","高密鑫佳恒","100101"
		Dealer.new "山东","青岛市","即墨市","D1049","即墨宏峰合达","100102"
		Dealer.new "山东","济宁市","市中区","D1050","济宁永昌","100103"
		Dealer.new "山东","潍坊市","青州市","D1051","青州宝隆","100104"
		Dealer.new "山东","济南市","章丘市","D1052","章丘瑞和众达","100105"
		Dealer.new "山东","东营市","东营区","D1053","东营巨丰","100106"
		Dealer.new "山东","临沂市","河东区","D1054","临沂汇通","100107"
		Dealer.new "山东","青岛市","城阳区","D1055","青岛金阳光","100108"
		Dealer.new "山东","菏泽市","郓城县","D1056","郓城中汇","100109"
		Dealer.new "山东","青岛市","胶州市","D1057","青岛胶州双龙源","100110"
		Dealer.new "山东","青岛市","黄岛区","D1058","青岛庚辰润通","100111"
		Dealer.new "山东","烟台市","莱州市","D1059","莱州鸿昌达","100112"
		Dealer.new "山东","济宁市","曲阜市","D1060","曲阜新东源","100113"
		Dealer.new "山东","临沂市","兰山区","D1061","临沂悦晟","100114"
		Dealer.new "山东","济宁市","邹城市","D1062","邹城君之舆","100115"
		Dealer.new "山东","日照市","莒县","D1063","莒县和瑞","100116"
		Dealer.new "山东","东营市","广饶县","D1065","广饶石大乐安","100117"
		Dealer.new "山东","滨州市","邹平县","D1066","邹平顺捷","100118"
		Dealer.new "山东","烟台市","莱山区","D1067","莱山金泰莱","100119"
		Dealer.new "山东","烟台市","莱阳市","D1068","莱阳一弘","100120"
		Dealer.new "山东","青岛市","莱西市","D1069","莱西宝威恒盛","100121"
		Dealer.new "山东","菏泽市","开发区","D1070","单县华汇","100122"
		Dealer.new "山东","潍坊市","昌乐市","D1071","昌乐烨丰","100123"
		Dealer.new "山东","临沂市","沂水县","D1074","沂水乔丰","100124"
		Dealer.new "山东","烟台市","海阳市","D1075","海阳海嘉","100125"
		Dealer.new "山东","济宁市","梁山县","D1076","梁山聚源","100126"
		Dealer.new "山东","济南市","市中区","D1077","济南海源","100127"
		Dealer.new "山东","潍坊市","临朐县","D1078","临朐基泰","100128"
		Dealer.new "山东","威海市","乳山市","D1079","乳山振洋","100129"
		Dealer.new "江苏","南京市","秦淮区","D1101","江苏万帮","100130"
		Dealer.new "江苏","南京市","栖霞区","D1102","南京朗驰","100131"
		Dealer.new "江苏","苏州市","高新区","D1103","苏州新泰","100132"
		Dealer.new "江苏","无锡市","新区","D1104","无锡东方","100133"
		Dealer.new "江苏","常州市","新北区","D1106","常州金田","100134"
		Dealer.new "江苏","扬州市","邗江区","D1107","扬州玉峰","100135"
		Dealer.new "江苏","南通市","崇川区","D1108","南通文峰","100136"
		Dealer.new "江苏","苏州市","常熟市","D1109","苏州华现","100137"
		Dealer.new "江苏","苏州市","吴中区","D1110","苏州正旺","100138"
		Dealer.new "江苏","徐州市","云龙区","D1111","徐州润东","100139"
		Dealer.new "江苏","常州市","江阴市","D1112","江阴海鹏","100140"
		Dealer.new "江苏","苏州市","昆山市","D1113","昆山华腾","100141"
		Dealer.new "江苏","连云港市","海州开发区","D1114","连云港华驰","100142"
		Dealer.new "江苏","常州市","武进区","D1115","常州明盛","100143"
		Dealer.new "江苏","盐城市","开发区","D1116","盐城森风","100144"
		Dealer.new "江苏","镇江市","润州区","D1117","镇江京鹏","100145"
		Dealer.new "江苏","淮安市","淮阴区","D1118","淮安润东","100146"
		Dealer.new "江苏","南通市","港闸区","D1119","南通富嘉","100147"
		Dealer.new "江苏","苏州市","张家港市开发区","D1120","张家港宏伟","100148"
		Dealer.new "江苏","宿迁市","开发区","D1121","宿迁苏驰","100149"
		Dealer.new "江苏","泰州市","海陵区","D1122","泰州宝天","100150"
		Dealer.new "江苏","无锡市","宜兴市","D1123","宜兴恒信","100151"
		Dealer.new "江苏","苏州市","相城区","D1124","苏州东昌","100152"
		Dealer.new "江苏","无锡市","溧阳市","D1125","溧阳顺达","100153"
		Dealer.new "江苏","镇江市","丹阳市","D1127","丹阳京利","100154"
		Dealer.new "江苏","苏州市","太仓市","D1128","太仓华鳌","100155"
		Dealer.new "江苏","苏州市","吴江市","D1129","吴江韩帮","100156"
		Dealer.new "江苏","苏州市","吴江市","D1130","吴江嘉诚","100157"
		Dealer.new "江苏","扬州市","江都区","D1131","江都宏远","100158"
		Dealer.new "江苏","南通市","海门市","D1132","海门宝诚","100159"
		Dealer.new "江苏","南京市","江宁区","D1133","南京金现","100160"
		Dealer.new "江苏","徐州市","铜山新区","D1134","徐州苏企","100161"
		Dealer.new "江苏","无锡市","崇安区","D1135","无锡东方鑫现","100162"
		Dealer.new "江苏","苏州市","吴中区","D1136","苏州惠盈","100163"
		Dealer.new "江苏","无锡市","惠山区","D1137","无锡嘉现","100164"
		Dealer.new "江苏","泰州市","兴化市","D1138","兴化金鼎","100165"
		Dealer.new "江苏","盐城市","盐都新区","D1139","盐城宁泰","100166"
		Dealer.new "江苏","常州市","新北区","D1140","常州飞悦","100167"
		Dealer.new "江苏","宿迁市","沭阳县","D1141","沭阳弘翔","100168"
		Dealer.new "江苏","南京市","溧水市","D1142","溧水万帮","100169"
		Dealer.new "江苏","淮安市","清河新区","D1143","雨田鸿运","100170"
		Dealer.new "江苏","苏州市","张家港市金港镇","D1144","张家港金港","100171"
		Dealer.new "江苏","徐州市","邳州市","D1145","邳州开隆","100172"
		Dealer.new "江苏","南京市","浦口区","D1146","南京克洛博","100173"
		Dealer.new "江苏","南通市","启东市","D1147","启粱文邦","100174"
		Dealer.new "江苏","徐州市","新沂市","D1148","徐州达骏洲运","100175"
		Dealer.new "江苏","南京市","高淳市","D1149","高淳万帮","100176"
		Dealer.new "江苏","连云港市","开发区","D1150","连云港现宇","100177"
		Dealer.new "江苏","南通市","崇川区","D1151","南通新城世纪","100178"
		Dealer.new "江苏","无锡市","北塘区","D1152","无锡朗润","100179"
		Dealer.new "江苏","常州市","钟楼区","D1153","常州惠盈","100180"
		Dealer.new "江苏","苏州市","昆山市","D1154","昆山森美","100181"
		Dealer.new "江苏","南通市","如皋市","D1155","如皋弘瑞","100182"
		Dealer.new "江苏","淮安市","盱眙市","D1158","盱眙和盛","100183"
		Dealer.new "江苏","扬州市","广陵区","D1159","扬州瑞丰时代","100184"
		Dealer.new "江苏","南通市","开发区","D1160","南通文峰伟业","100185"
		Dealer.new "江苏","南通市","海安市","D1161","海安征程","100186"
		Dealer.new "江苏","镇江市","句容市","D1163","句容鼎现","100187"
		Dealer.new "江苏","泰州市","姜堰区","D1164","姜堰宝泰","100188"
		Dealer.new "江苏","南通市","如东市","D1165","如东嘉恒","100189"
		Dealer.new "江苏","宿迁市","泗洪市","D1166","泗洪苏驰恒祥","100190"
		Dealer.new "江苏","常州市","金坛市","D1167","金坛金驰","100191"
		Dealer.new "江苏","泰州市","泰兴市","D1168","泰兴宝运","100192"
		Dealer.new "江苏","常州市","江阴市","D1169","江阴星现","100193"
		Dealer.new "江苏","宿迁市","泗阳市","D1170","泗阳恒辰","100194"
		Dealer.new "江苏","泰州市","靖江市","D1171","靖江宝达","100195"
		Dealer.new "江苏","盐城市","东台市","D1173","东台恒达","100196"
		Dealer.new "浙江","杭州市","江干区","D1201","浙江韩通","100197"
		Dealer.new "浙江","宁波市","江北区","D1203","宁波海达","100198"
		Dealer.new "浙江","温州市","瓯海区","D1204","温州奥奔","100199"
		Dealer.new "浙江","金华市","婺城区","D1205","金华金京","100200"
		Dealer.new "浙江","嘉兴市","秀洲区","D1206","嘉兴金腾","100201"
		Dealer.new "浙江","金华市","义乌市","D1207","义乌和邦","100202"
		Dealer.new "浙江","杭州市","萧山区","D1208","浙江通达","100203"
		Dealer.new "浙江","宁波市","江东区","D1209","宁波天源","100204"
		Dealer.new "浙江","湖州市","吴兴区","D1211","湖州中北","100205"
		Dealer.new "浙江","台州市","黄岩区","D1212","台州万和","100206"
		Dealer.new "浙江","绍兴市","越城区","D1213","绍兴海潮","100207"
		Dealer.new "浙江","宁波市","慈溪市","D1214","慈溪京通","100208"
		Dealer.new "浙江","绍兴市","上虞区","D1215","绍兴瑞源","100209"
		Dealer.new "浙江","台州市","路桥区","D1216","台州泽宇","100210"
		Dealer.new "浙江","温州市","瑞安市","D1217","瑞安红日","100211"
		Dealer.new "浙江","绍兴市","袍江区","D1218","绍兴袍江韩通","100212"
		Dealer.new "浙江","衢州市","柯城区","D1219","浙江君悦","100213"
		Dealer.new "浙江","丽水市","莲都区","D1221","丽水伊翔","100214"
		Dealer.new "浙江","温州市","乐清市","D1222","乐清大江","100215"
		Dealer.new "浙江","嘉兴市","海宁市","D1223","海宁浩通","100216"
		Dealer.new "浙江","宁波市","北仑区","D1226","宁波联众","100217"
		Dealer.new "浙江","绍兴市","诸暨市","D1227","诸暨正大","100218"
		Dealer.new "浙江","金华市","东阳市","D1228","东阳京达","100219"
		Dealer.new "浙江","杭州市","萧山区","D1230","浙江金凯","100220"
		Dealer.new "浙江","台州市","临海市","D1232","临海台运","100221"
		Dealer.new "浙江","嘉兴市","桐乡市","D1233","桐乡兴田","100222"
		Dealer.new "浙江","金华市","永康市","D1234","永康韩龙","100223"
		Dealer.new "浙江","杭州市","拱墅区","D1235","浙江全通","100224"
		Dealer.new "浙江","温州市","龙湾区","D1236","温州红盈","100225"
		Dealer.new "浙江","宁波市","余姚市","D1237","余姚舜驰","100226"
		Dealer.new "浙江","杭州市","西湖区","D1238","杭州合诚","100227"
		Dealer.new "浙江","台州市","温岭市","D1239","温岭泽行","100228"
		Dealer.new "浙江","绍兴市","嵊州市","D1240","嵊州广成八达","100229"
		Dealer.new "浙江","舟山市","定海区","D1241","舟山霁锃","100230"
		Dealer.new "浙江","温州市","苍南县","D1242","苍南冠隆","100231"
		Dealer.new "浙江","温州市","永嘉县","D1243","永嘉现盛","100232"
		Dealer.new "浙江","宁波市","宁海市","D1244","宁海翔源","100233"
		Dealer.new "浙江","台州市","椒江区","D1246","台州元现","100234"
		Dealer.new "浙江","湖州市","长兴县","D1247","长兴中现","100235"
		Dealer.new "浙江","湖州市","安吉县","D1248","安吉中建","100236"
		Dealer.new "浙江","温州市","龙湾区","D1249","温州金昌","100237"
		Dealer.new "浙江","温州市","平阳县","D1250","平阳骏达","100238"
		Dealer.new "浙江","金华市","义乌市","D1251","义乌京皓","100239"
		Dealer.new "浙江","杭州市","余杭区","D1252","余杭宝盈","100240"
		Dealer.new "浙江","金华市","浦江县","D1253","浦江金瑞","100241"
		Dealer.new "浙江","杭州市","临安市","D1254","临安元信","100242"
		Dealer.new "浙江","杭州市","余杭区","D1255","余杭中轿禾现","100243"
		Dealer.new "浙江","丽水市","莲都区","D1256","丽水红旭","100244"
		Dealer.new "浙江","嘉兴市","南湖区","D1257","嘉兴嘉现","100245"
		Dealer.new "浙江","衢州市","江山市","D1258","江山恒大","100246"
		Dealer.new "浙江","宁波市","象山市","D1259","象山海达顺通","100247"
		Dealer.new "浙江","杭州市","桐庐市","D1260","桐庐海昌","100248"
		Dealer.new "浙江","金华市","婺城区","D1261","金华金唯","100249"
		Dealer.new "浙江","杭州市","富阳市","D1262","富阳和诚富现","100250"
		Dealer.new "浙江","宁波市","慈溪市","D1263","慈溪嘉顺","100251"
		Dealer.new "浙江","湖州市","德清县","D1264","德清嘉和","100252"
		Dealer.new "浙江","杭州市","滨江区","D1265","杭州昌鸿","100253"
		Dealer.new "浙江","宁波市","奉化市","D1268","宁波鑫远达","100254"
		Dealer.new "安徽","合肥市","新站区","D1301","合肥伟光","100255"
		Dealer.new "安徽","芜湖市","鸠江区","D1302","芜湖亚夏","100256"
		Dealer.new "安徽","合肥市","包河区","D1303","合肥稳达","100257"
		Dealer.new "安徽","蚌埠市","高新区","D1304","蚌埠润通","100258"
		Dealer.new "安徽","安庆市","开发区","D1305","安庆宜通","100259"
		Dealer.new "安徽","阜阳市","开发区","D1307","阜阳飞达","100260"
		Dealer.new "安徽","巢湖市","居巢区","D1308","巢湖南峰","100261"
		Dealer.new "安徽","宣城市","宣州区","D1309","宣城亚绅","100262"
		Dealer.new "安徽","六安市","裕安区","D1310","六安万通","100263"
		Dealer.new "安徽","亳州市","蒙城县","D1311","亳州瑞和","100264"
		Dealer.new "安徽","马鞍山市","当涂市","D1312","马鞍山伟厚","100265"
		Dealer.new "安徽","淮北市","相山区","D1313","淮北北润","100266"
		Dealer.new "安徽","黄山市","屯溪区","D1314","黄山亚翔","100267"
		Dealer.new "安徽","合肥市","包河区","D1315","合肥伟合","100268"
		Dealer.new "安徽","宿州市","开发区","D1316","宿州万上","100269"
		Dealer.new "安徽","淮南市","大通区","D1317","淮南恒美","100270"
		Dealer.new "安徽","铜陵市","狮子山区","D1318","铜陵金丰鑫海","100271"
		Dealer.new "安徽","滁州市","琅琊区","D1319","滁州宁宝","100272"
		Dealer.new "安徽","池州市","站前区","D1320","池州盛奇","100273"
		Dealer.new "安徽","合肥市","高新区","D1321","合肥亚越","100274"
		Dealer.new "安徽","亳州市","谯城区","D1322","亳州英豪","100275"
		Dealer.new "安徽","阜阳市","颍州区","D1323","阜阳伟田","100276"
		Dealer.new "安徽","芜湖市","鸠江区","D1324","芜湖伟胜","100277"
		Dealer.new "安徽","安庆市","宜秀区","D1325","安庆永通","100278"
		Dealer.new "安徽","六安市","金安区","D1326","六安汇添","100279"
		Dealer.new "安徽","合肥市","庐阳区","D1327","合肥恒信华通","100280"
		Dealer.new "河南","郑州市","惠济区","D1401","河南裕华金阳光","100281"
		Dealer.new "河南","郑州市","管城区","D1402","河南万佳捷泰","100282"
		Dealer.new "河南","郑州市","管城区","D1403","河南长江","100283"
		Dealer.new "河南","洛阳市","西工区","D1404","洛阳德众","100284"
		Dealer.new "河南","漯河市","郾城区","D1406","漯河润中","100285"
		Dealer.new "河南","许昌市","魏都区","D1407","许昌亿阳","100286"
		Dealer.new "河南","安阳市","文峰区","D1408","安阳福尔福","100287"
		Dealer.new "河南","焦作市","解放区","D1409","焦作博大伟业","100288"
		Dealer.new "河南","平顶山市","卫东区","D1410","平顶山得普","100289"
		Dealer.new "河南","濮阳市","华龙区","D1411","濮阳华瑞璞光","100290"
		Dealer.new "河南","新乡市","卫滨区","D1412","新乡兆阳","100291"
		Dealer.new "河南","信阳市","羊山新区","D1414","信阳全程","100292"
		Dealer.new "河南","鹤壁市","淇滨区","D1415","鹤壁鹤海","100293"
		Dealer.new "河南","商丘市","梁园区","D1416","商丘宝志","100294"
		Dealer.new "河南","济源市","济源市","D1417","济源浩轩","100295"
		Dealer.new "河南","郑州市","金水区","D1418","郑州北环","100296"
		Dealer.new "河南","三门峡市","湖滨区","D1419","三门峡时尚博长","100297"
		Dealer.new "河南","开封市","金明区","D1420","开封天翔","100298"
		Dealer.new "河南","郑州市","中原区","D1421","河南天行健","100299"
		Dealer.new "河南","驻马店市","开发区","D1422","驻马店腾麟","100300"
		Dealer.new "河南","南阳市","卧龙区","D1423","南阳中澳","100301"
		Dealer.new "河南","南阳市","宛城区","D1424","南阳威佳","100302"
		Dealer.new "河南","洛阳市","涧西区","D1425","洛阳德众胜达","100303"
		Dealer.new "河南","许昌市","禹州市","D1426","许昌双亿","100304"
		Dealer.new "河南","周口市","川汇区","D1427","周口长达","100305"
		Dealer.new "河南","新乡市","卫滨区","D1428","新乡锦程","100306"
		Dealer.new "河南","商丘市","梁园区","D1429","商丘天泽","100307"
		Dealer.new "河南","安阳市","龙安区","D1430","安阳万源","100308"
		Dealer.new "河南","三门峡市","灵宝市","D1431","灵宝长来","100309"
		Dealer.new "河南","永城市","侯岭镇","D1432","永城金祥","100310"
		Dealer.new "河南","新乡市","长垣县","D1433","长垣大广","100311"
		Dealer.new "河南","郑州市","金水区","D1434","郑州恒业","100312"
		Dealer.new "河南","平顶山市","新华区","D1435","平顶山瑞格","100313"
		Dealer.new "河南","驻马店市","驿城区","D1436","驻马店腾威","100314"
		Dealer.new "河南","焦作市","解放区","D1437","焦作博大兴业","100315"
		Dealer.new "河南","信阳市","工业新区","D1438","信阳和润","100316"
		Dealer.new "河南","濮阳市","高新区","D1439","濮阳璞润机电","100317"
		Dealer.new "河南","洛阳市","瀍河区","D1441","洛阳众腾","100318"
		Dealer.new "河南","新乡市","红旗区","D1442","东安远达（新乡）","100319"
		Dealer.new "河南","郑州市","二七区","D1443","郑州汇翔","100320"
		Dealer.new "河南","郑州市","新郑市","D1444","新郑天河","100321"
		Dealer.new "河南","许昌市","长葛市","D1445","长葛兆通","100322"
		Dealer.new "湖北","武汉市","汉阳区","D1501","武汉华星鸿泰","100323"
		Dealer.new "湖北","武汉市","江汉区","D1502","湖北欣瑞","100324"
		Dealer.new "湖北","襄阳市","襄州区","D1503","襄樊神星","100325"
		Dealer.new "湖北","宜昌市","东山开发区","D1504","宜昌腾龙","100326"
		Dealer.new "湖北","武汉市","洪山区","D1505","湖北港田","100327"
		Dealer.new "湖北","荆州市","荆州区","D1506","荆州恒信德龙","100328"
		Dealer.new "湖北","十堰市","茅箭区","D1507","十堰泽泰","100329"
		Dealer.new "湖北","黄石市","下陆区","D1508","黄石新兴","100330"
		Dealer.new "湖北","恩施市","开发区","D1509","恩施恒星","100331"
		Dealer.new "湖北","荆门市","东宝区","D1510","荆门华通","100332"
		Dealer.new "湖北","随州市","开发区","D1511","随州华神","100333"
		Dealer.new "湖北","咸宁市","咸安区","D1512","咸宁恒信","100334"
		Dealer.new "湖北","孝感市","孝南区","D1513","孝感贤良","100335"
		Dealer.new "湖北","武汉市","洪山区","D1514","华星天佑","100336"
		Dealer.new "湖北","黄冈市","黄州区","D1515","黄冈广源","100337"
		Dealer.new "湖北","武汉市","洪山区","D1516","武汉广恒","100338"
		Dealer.new "湖北","武汉市","江岸区","D1517","武汉三环泽通","100339"
		Dealer.new "湖北","宜昌市","夷陵区","D1518","宜昌恒信华通","100340"
		Dealer.new "湖北","襄阳市","襄州区","D1519","襄阳永奥","100341"
		Dealer.new "湖北","十堰市","张湾区","D1520","十堰瑞实","100342"
		Dealer.new "湖北","武汉市","江夏区","D1521","武汉泽泰融通","100343"
		Dealer.new "湖北","仙桃市","干河区","D1522","仙桃仙旺","100344"
		Dealer.new "湖北","武汉市","洪山区","D1523","武汉恒信华通","100345"
		Dealer.new "湖北","黄石市","开发区","D1524","黄石新兴振宇","100346"
		Dealer.new "贵州","贵阳市","花溪区","D1601","贵州乾通","100347"
		Dealer.new "贵州","遵义市","红花岗区","D1603","遵义千乘","100348"
		Dealer.new "贵州","贵阳市","小河区","D1604","贵阳宏健东","100349"
		Dealer.new "贵州","贵阳市","乌当区","D1605","贵阳安泰和","100350"
		Dealer.new "贵州","铜仁市","万山区","D1606","铜仁恒信华通","100351"
		Dealer.new "贵州","六盘水市","红桥新区","D1607","六盘水远现","100352"
		Dealer.new "贵州","安顺市","西秀区","D1608","安顺恒信德龙","100353"
		Dealer.new "贵州","兴义市","木贾物流园","D1609","兴义林兴","100354"
		Dealer.new "贵州","凯里市","鸭塘镇","D1610","凯里恒信德龙","100355"
		Dealer.new "贵州","都匀市","甘糖园区","D1611","都匀恒信华通","100356"
		Dealer.new "贵州","毕节市","七星关区","D1613","毕节佰润京汉","100357"
		Dealer.new "四川","成都市","成华区","D1701","四川华星卓越","100358"
		Dealer.new "四川","成都市","金牛区","D1702","四川明嘉","100359"
		Dealer.new "四川","成都市","武侯区","D1703","四川港宏","100360"
		Dealer.new "四川","绵阳市","高新区","D1704","绵阳新川萨","100361"
		Dealer.new "四川","德阳市","旌阳区","D1706","德阳名帝马","100362"
		Dealer.new "四川","眉山市","东坡区","D1708","眉山天威","100363"
		Dealer.new "四川","成都市","武侯区","D1709","成都万吉","100364"
		Dealer.new "四川","自贡市","贡井区","D1710","自贡新成","100365"
		Dealer.new "四川","成都市","青羊区","D1711","成都鑫蓝","100366"
		Dealer.new "四川","凉山州","西昌市","D1713","西昌鸿源","100367"
		Dealer.new "四川","南充市","顺庆区","D1714","南充天成","100368"
		Dealer.new "四川","泸州市","龙马潭区","D1715","泸州都慧","100369"
		Dealer.new "四川","乐山市","市中区","D1716","乐山天威","100370"
		Dealer.new "四川","成都市","温江区","D1717","成都先锋","100371"
		Dealer.new "四川","成都市","武侯区","D1718","成都申蓉","100372"
		Dealer.new "四川","达州市","达川区","D1719","达州禾林","100373"
		Dealer.new "四川","宜宾市","翠屏区","D1720","宜宾尚远","100374"
		Dealer.new "四川","广安市","广安区","D1721","广安天骄","100375"
		Dealer.new "四川","成都市","金堂区","D1722","成都金驿","100376"
		Dealer.new "四川","德阳市","广汉市","D1723","广汉恩丽","100377"
		Dealer.new "四川","南充市","高坪区","D1724","南充弘博天成","100378"
		Dealer.new "四川","资阳市","雁江区","D1725","资阳港宏泰瑞","100379"
		Dealer.new "四川","遂宁市","船山区","D1726","遂宁瑞现","100380"
		Dealer.new "四川","成都市","都江堰市","D1727","都江堰明嘉","100381"
		Dealer.new "四川","攀枝花市","市仁和区","D1728","攀枝花明嘉皓升","100382"
		Dealer.new "四川","绵阳市","涪城区","D1729","绵阳汇平","100383"
		Dealer.new "四川","雅安市","雨城区","D1730","雅安乾康","100384"
		Dealer.new "四川","内江市","市中区","D1731","内江利恒孚","100385"
		Dealer.new "四川","成都市","崇州市","D1732","崇州中鑫店","100386"
		Dealer.new "四川","成都市","双流区","D1734","双流泽通车业","100387"
		Dealer.new "四川","广元市","元坝区","D1735","广元宇风","100388"
		Dealer.new "云南","昆明市","盘龙区","D1801","云南鑫源","100389"
		Dealer.new "云南","昆明市","五华区","D1802","云南宝龙","100390"
		Dealer.new "云南","玉溪市","红塔区","D1803","玉溪诚远","100391"
		Dealer.new "云南","大理市","下关开发区","D1804","大理博源","100392"
		Dealer.new "云南","芒市","芒市","D1806","瑞丽景泰","100393"
		Dealer.new "云南","昭通市","昭阳区","D1807","昭通和熠","100394"
		Dealer.new "云南","开远市","东联村","D1808","开远裕隆","100395"
		Dealer.new "云南","昆明市","官渡区","D1809","云南庞大兴业","100396"
		Dealer.new "云南","楚雄市","开发区","D1810","楚雄艺龙","100397"
		Dealer.new "云南","保山市","隆阳区","D1811","保山天马源","100398"
		Dealer.new "云南","昆明市","呈贡新区","D1812","云南星瑞达毅","100399"
		Dealer.new "云南","普洱市","思茅区","D1814","普洱普龙","100400"
		Dealer.new "云南","曲靖市","麒麟区","D1816","曲靖鹏龙瑞桓","100401"
		Dealer.new "青海","西宁市","开发区","D1902","西宁金岛","100402"
		Dealer.new "青海","西宁市","开发区","D1903","西宁金鳞宝","100403"
		Dealer.new "青海","格尔木市","开发区","D1904","格尔木","100404"
		Dealer.new "福建","泉州市","鲤城区","D2001","泉州中达","100405"
		Dealer.new "福建","福州市","仓山区","D2002","福州中诺","100406"
		Dealer.new "福建","厦门市","湖里区","D2003","厦门国戎","100407"
		Dealer.new "福建","泉州市","晋江市","D2004","晋江远通","100408"
		Dealer.new "福建","漳州市","龙文区","D2005","漳州捷诚","100409"
		Dealer.new "福建","福州市","晋安区","D2006","福建中源","100410"
		Dealer.new "福建","莆田市","荔城区","D2007","莆田奇奇","100411"
		Dealer.new "福建","龙岩市","新罗区","D2008","龙岩通顺","100412"
		Dealer.new "福建","三明市","梅列区","D2009","三明兴闽","100413"
		Dealer.new "福建","南平市","延平区","D2010","南平龙鑫","100414"
		Dealer.new "福建","宁德市","蕉城区","D2012","宁德联丰","100415"
		Dealer.new "福建","福州市","福清市","D2013","福清吉诺","100416"
		Dealer.new "福建","厦门市","湖里区","D2014","厦门国贸启润","100417"
		Dealer.new "福建","泉州市","丰泽区","D2015","泉州华友","100418"
		Dealer.new "福建","福州市","闽侯县","D2018","福建新锐","100419"
		Dealer.new "福建","龙岩市","新罗区","D2019","龙岩中天","100420"
		Dealer.new "福建","厦门市","海沧区","D2020","厦门国贸宝润","100421"
		Dealer.new "福建","漳州市","漳浦县","D2022","漳浦安泰","100422"
		Dealer.new "福建","莆田市","仙游县","D2023","仙游阿强","100423"
		Dealer.new "广东","广州市","天河区","D2101","广州南现","100424"
		Dealer.new "广东","深圳市","福田区","D2102","深圳大胜","100425"
		Dealer.new "广东","广州市","白云区","D2103","广东羊城","100426"
		Dealer.new "广东","佛山市","禅城区","D2104","佛山泰鑫","100427"
		Dealer.new "广东","佛山市","顺德区","D2105","顺德合现","100428"
		Dealer.new "广东","广州市","番禺区","D2106","广州宏现","100429"
		Dealer.new "广东","东莞市","南城区","D2107","东莞永怡","100430"
		Dealer.new "广东","深圳市","南山区","D2108","深圳顺和盈","100431"
		Dealer.new "广东","东莞市","寮步镇","D2110","东莞冠丰","100432"
		Dealer.new "广东","深圳市","福田区","D2111","深圳鹏峰","100433"
		Dealer.new "广东","中山市","西区","D2112","中山创现","100434"
		Dealer.new "广东","汕头市","龙湖区","D2114","汕头合民","100435"
		Dealer.new "广东","广州市","天河区","D2115","广东中现","100436"
		Dealer.new "广东","惠州市","惠城区","D2116","惠州展现","100437"
		Dealer.new "广东","珠海市","香洲区","D2117","珠海华德","100438"
		Dealer.new "广东","佛山市","南海区","D2118","南海禅昌","100439"
		Dealer.new "广东","广州市","花都区","D2119","广州龙腾花现","100440"
		Dealer.new "广东","揭阳市","榕城区","D2120","揭阳群记","100441"
		Dealer.new "广东","佛山市","顺德区","D2126","佛山乐现","100442"
		Dealer.new "广东","肇庆市","端州区","D2127","肇庆美现","100443"
		Dealer.new "广东","茂名市","茂南区","D2128","茂名卓粤","100444"
		Dealer.new "广东","湛江市","赤坎区","D2129","湛江中富","100445"
		Dealer.new "广东","东莞市","大朗镇","D2131","东莞大朗世达","100446"
		Dealer.new "广东","深圳市","龙岗区","D2133","深圳新力达","100447"
		Dealer.new "广东","东莞市","虎门镇","D2134","东莞广泰","100448"
		Dealer.new "广东","广州市","增城区","D2135","增城伟加","100449"
		Dealer.new "广东","江门市","江海区","D2136","江门瑞华宏现","100450"
		Dealer.new "广东","惠州市","惠城区","D2137","惠州三惠","100451"
		Dealer.new "广东","韶关市","浈江区","D2138","韶关联现","100452"
		Dealer.new "广东","广州市","荔湾区","D2139","广州东奇","100453"
		Dealer.new "广东","河源市","紫金县","D2140","河源冠丰行","100454"
		Dealer.new "广东","中山市","南区","D2141","中山创世纪城南","100455"
		Dealer.new "广东","梅州市","梅县","D2142","梅州宏达","100456"
		Dealer.new "广东","清远市","清城区","D2143","清远泰翔","100457"
		Dealer.new "广东","潮州市","潮安县","D2144","潮州南熙","100458"
		Dealer.new "广东","东莞市","长安镇","D2145","东莞东胜","100459"
		Dealer.new "广东","阳江市","江城区","D2146","阳江京泰","100460"
		Dealer.new "广东","中山市","西区","D2147","中山中启","100461"
		Dealer.new "广东","云浮市","云城区","D2148","云浮美轮运现","100462"
		Dealer.new "广东","东莞市","常平镇","D2149","东莞金世达","100463"
		Dealer.new "广东","江门市","蓬江区","D2150","江门精文","100464"
		Dealer.new "广东","深圳市","宝安区","D2151","深圳昊天林","100465"
		Dealer.new "广东","深圳市","宝安区","D2152","深圳威博","100466"
		Dealer.new "广东","东莞市","塘厦镇","D2153","塘厦新世达","100467"
		Dealer.new "广东","东莞市","石龙镇","D2155","石龙永信","100468"
		Dealer.new "广东","佛山市","南海区","D2157","佛山南海时利和","100469"
		Dealer.new "江西","南昌市","东湖区","D2201","江西国力","100470"
		Dealer.new "江西","萍乡市","安源区","D2205","萍乡国力赣源","100471"
		Dealer.new "江西","九江市","庐山区","D2206","九江金穗","100472"
		Dealer.new "江西","上饶市","上饶县","D2207","上饶宏旭","100473"
		Dealer.new "江西","宜春市","袁州区","D2208","宜春和丰","100474"
		Dealer.new "江西","南昌市","青云谱区","D2209","南昌华美","100475"
		Dealer.new "江西","赣州市","章贡区","D2210","赣州国力","100476"
		Dealer.new "江西","吉安市","吉州区","D2211","吉安上峰","100477"
		Dealer.new "江西","抚州市","临川区","D2212","抚州华宏金鑫","100478"
		Dealer.new "江西","新余市","渝水区","D2213","新余和元","100479"
		Dealer.new "江西","景德镇市","昌江区","D2214","景德镇璟瞳","100480"
		Dealer.new "江西","赣州市","赣县","D2215","赣州华宏","100481"
		Dealer.new "江西","南昌市","红谷滩区","D2216","南昌金汇","100482"
		Dealer.new "江西","宜春市","高安市","D2217","高安和福","100483"
		Dealer.new "江西","九江市","浔阳区","D2218","九江浔瑞","100484"
		Dealer.new "江西","上饶市","鄱阳县","D2219","鄱阳加西亚现泰","100485"
		Dealer.new "江西","南昌市","青山湖区","D2220","南昌汇银","100486"
		Dealer.new "江西","鹰潭市","月湖区","D2221","鹰潭弘鹰","100487"
		Dealer.new "江西","上饶市","信州区","D2222","上饶华宏名现","100488"
		Dealer.new "湖南","长沙市","开福区","D2301","湖南华运达","100489"
		Dealer.new "湖南","长沙市","雨花区","D2302","湖南瑞特","100490"
		Dealer.new "湖南","衡阳市","蒸湘区","D2304","衡阳华利","100491"
		Dealer.new "湖南","常德市","武陵区","D2305","常德星都","100492"
		Dealer.new "湖南","湘潭市","岳塘区","D2306","湘潭九城","100493"
		Dealer.new "湖南","郴州市","苏仙区","D2307","郴州京湘","100494"
		Dealer.new "湖南","株洲市","荷塘区","D2308","株洲蓝代","100495"
		Dealer.new "湖南","岳阳市","岳阳楼区","D2309","岳阳梦达","100496"
		Dealer.new "湖南","娄底市","娄星区","D2310","娄底和轩","100497"
		Dealer.new "湖南","邵阳市","双清区","D2311","邵阳宝京","100498"
		Dealer.new "湖南","益阳市","赫山区","D2312","益阳蓝马","100499"
		Dealer.new "湖南","长沙市","雨花区","D2313","长沙世代","100500"
		Dealer.new "湖南","永州市","零陵区","D2314","永州永通华悦","100501"
		Dealer.new "湖南","湘潭市","雨湖区","D2315","湘潭九现","100502"
		Dealer.new "湖南","株洲市","芦淞区","D2316","株洲蓝现","100503"
		Dealer.new "湖南","长沙市","高新区","D2317","长沙中拓瑞达","100504"
		Dealer.new "湖南","长沙市","岳麓区","D2318","长沙韩顺","100505"
		Dealer.new "湖南","长沙市","天心区","D2319","长沙永通华盛","100506"
		Dealer.new "湖南","衡阳市","石鼓区","D2320","衡阳铭星","100507"
		Dealer.new "湖南","长沙市","浏阳市","D2321","浏阳中拓瑞晟","100508"
		Dealer.new "湖南","怀化市","鹤城区","D2322","怀化永通华峰","100509"
		Dealer.new "湖南","常德市","开发区","D2323","常德双星星润","100510"
		Dealer.new "湖南","岳阳市","岳阳楼区","D2326","岳阳华阳凯达","100511"
		Dealer.new "海南","海口市","美兰区","D2401","海南京诚","100512"
		Dealer.new "海南","三亚市","河东区","D2402","三亚骏诚","100513"
		Dealer.new "海南","海口市","琼山区","D2403","海口华诚","100514"
		Dealer.new "黑龙江","哈尔滨市","道里区","D2501","哈尔滨百丰","100515"
		Dealer.new "黑龙江","哈尔滨市","道外区","D2502","哈尔滨亿发鸿运","100516"
		Dealer.new "黑龙江","大庆市","高新区","D2503","大庆润达新亚","100517"
		Dealer.new "黑龙江","佳木斯市","佳木斯市","D2505","佳木斯中天驭风","100518"
		Dealer.new "黑龙江","齐齐哈尔市","南苑开发区","D2506","齐齐哈尔瑞宝宏通","100519"
		Dealer.new "黑龙江","牡丹江市","阳明区","D2507","牡丹江百强丰源","100520"
		Dealer.new "黑龙江","七台河市","桃山区","D2508","七台河隆达","100521"
		Dealer.new "黑龙江","黑河市","北安市","D2509","北安成功万邦","100522"
		Dealer.new "黑龙江","大庆市","让胡路区","D2510","大庆业勤鸿润","100523"
		Dealer.new "黑龙江","齐齐哈尔市","龙沙区","D2511","齐齐哈尔骏发","100524"
		Dealer.new "黑龙江","绥化市","开发区","D2512","绥化圣亚","100525"
		Dealer.new "黑龙江","双鸭山市","尖山区","D2513","双鸭山顺雷","100526"
		Dealer.new "黑龙江","哈尔滨市","香坊区","D2514","哈尔滨利泰","100527"
		Dealer.new "黑龙江","哈尔滨市","道里区","D2515","哈尔滨汇华","100528"
		Dealer.new "黑龙江","鸡西市","鸡冠区","D2516","鸡西隆达鑫煜","100529"
		Dealer.new "吉林","长春市","开发区","D2601","长春华众","100530"
		Dealer.new "吉林","吉林市","丰满区","D2602","吉林宏利源","100531"
		Dealer.new "吉林","延吉市","开发区","D2603","延吉中诚","100532"
		Dealer.new "吉林","四平市","开发区","D2604","四平鑫韩亚","100533"
		Dealer.new "吉林","通化市","东昌区","D2605","通化华阳","100534"
		Dealer.new "吉林","松原市","前郭县","D2606","松原子余","100535"
		Dealer.new "吉林","长春市","汽车开发区","D2607","长春韩亚","100536"
		Dealer.new "吉林","吉林市","船营区","D2608","吉林荣阳","100537"
		Dealer.new "吉林","梅河口市","梅河口区","D2609","梅河口广通","100538"
		Dealer.new "吉林","长春市","宽城区","D2610","长春金达洲瑞威","100539"
		Dealer.new "吉林","辽源市","西安区","D2611","辽源洪鑫","100540"
		Dealer.new "吉林","长春市","高新区","D2612","长春成铭","100541"
		Dealer.new "吉林","延吉市","龙井区","D2613","延吉天鸿","100542"
		Dealer.new "吉林","白城市","洮北区","D2614","白城致诚","100543"
		Dealer.new "吉林","白山市","浑江区","D2615","白山益信","100544"
		Dealer.new "辽宁","沈阳市","铁西区","D2702","沈阳汇众","100545"
		Dealer.new "辽宁","沈阳市","沈河区","D2703","辽宁路鑫","100546"
		Dealer.new "辽宁","营口市","站前区","D2705","营口金富佳","100547"
		Dealer.new "辽宁","盘锦市","兴隆台区","D2706","盘锦永盛","100548"
		Dealer.new "辽宁","锦州市","太和区","D2707","锦州鑫汇众","100549"
		Dealer.new "辽宁","葫芦岛市","高新区","D2708","葫芦岛路赛得","100550"
		Dealer.new "辽宁","辽阳市","宏伟区","D2709","辽阳天合","100551"
		Dealer.new "辽宁","抚顺市","望花区","D2710","抚顺金博众","100552"
		Dealer.new "辽宁","鞍山市","铁西区","D2711","鞍山鑫路鑫","100553"
		Dealer.new "辽宁","朝阳市","双塔区","D2712","朝阳吉安","100554"
		Dealer.new "辽宁","沈阳市","大东区","D2713","通孚兴邦","100555"
		Dealer.new "辽宁","铁岭市","辽海园区","D2714","铁岭北方","100556"
		Dealer.new "辽宁","丹东市","振兴区","D2715","丹东东盛","100557"
		Dealer.new "辽宁","大连市","甘井子区","D2716","大连鑫昱佳","100558"
		Dealer.new "辽宁","沈阳市","于洪区","D2717","辽宁汇鑫","100559"
		Dealer.new "辽宁","沈阳市","皇姑区","D2718","京源鸿业","100560"
		Dealer.new "辽宁","大连市","保税区","D2719","大连汇航","100561"
		Dealer.new "辽宁","沈阳市","浑南新区","D2720","沈阳庞大华明","100562"
		Dealer.new "辽宁","本溪市","明山区","D2721","本溪汇丰","100563"
		Dealer.new "辽宁","阜新市","开发区","D2722","阜新汇龙","100564"
		Dealer.new "辽宁","鞍山市","铁西区","D2723","鞍山汇阳","100565"
		Dealer.new "辽宁","大连市","中山区","D2724","大连汇明","100566"
		Dealer.new "辽宁","瓦房店市","吴店村","D2725","恒岳伟业","100567"
		Dealer.new "辽宁","大连市","西岗区","D2726","大连金汇航","100568"
		Dealer.new "辽宁","抚顺市","望花区","D2727","抚顺鑫博众","100569"
		Dealer.new "河北","石家庄市","裕华区","D2801","河北骏通","100570"
		Dealer.new "河北","秦皇岛市","开发区","D2802","秦皇岛瑞通佰盛","100571"
		Dealer.new "河北","保定市","开发区","D2803","保定轩宇","100572"
		Dealer.new "河北","石家庄市","长安区","D2804","河北盛文","100573"
		Dealer.new "河北","邯郸市","高新区","D2805","邯郸嘉华","100574"
		Dealer.new "河北","唐山市","开平区","D2806","唐山海洋","100575"
		Dealer.new "河北","邢台市","桥东区","D2807","邢台京鹏","100576"
		Dealer.new "河北","唐山市","路南区","D2808","唐山冀东","100577"
		Dealer.new "河北","衡水市","高新区","D2810","衡水德昌","100578"
		Dealer.new "河北","张家口市","桥东区","D2811","张家口美华","100579"
		Dealer.new "河北","廊坊市","广阳区","D2812","廊坊瑞龙","100580"
		Dealer.new "河北","石家庄市","桥西区","D2813","石家庄广德行","100581"
		Dealer.new "河北","承德市","双桥区","D2814","承德冀东乐业","100582"
		Dealer.new "河北","保定市","南市区","D2815","保定天华","100583"
		Dealer.new "河北","保定市","涿州市","D2817","涿州朝阳世纪","100584"
		Dealer.new "河北","沧州市","新华区","D2819","沧州恒源","100585"
		Dealer.new "河北","廊坊市","霸州市","D2820","霸州亿龙","100586"
		Dealer.new "河北","沧州市","运河区","D2822","沧州安捷","100587"
		Dealer.new "河北","唐山市","高新区","D2823","唐山庞大广盛","100588"
		Dealer.new "河北","张家口市","桥东区","D2824","张家口泰成达","100589"
		Dealer.new "河北","石家庄市","新华区","D2825","天徽致远","100590"
		Dealer.new "河北","邯郸市","邯山区","D2826","邯郸华宝","100591"
		Dealer.new "河北","衡水市","开发区","D2827","衡水衡冲","100592"
		Dealer.new "河北","沧州市","运河区","D2828","沧州蓝池泰龙","100593"
		Dealer.new "河北","邢台市","任县","D2829","邢台德翔","100594"
		Dealer.new "河北","秦皇岛市","海港区","D2830","秦皇岛庞大广盈","100595"
		Dealer.new "河北","唐山市","迁安市","D2831","迁安庞大广发","100596"
		Dealer.new "河北","保定市","北市区","D2832","保定骊致","100597"
		Dealer.new "河北","邯郸市","复兴区","D2833","邯郸远洋","100598"
		Dealer.new "河北","沧州市","任丘市","D2834","任丘宏丰","100599"
		Dealer.new "河北","邢台市","清河县","D2835","清河德瑞达","100600"
		Dealer.new "河北","石家庄市","裕华区","D2836","国和众现达","100601"
		Dealer.new "河北","保定市","南市区","D2837","保定嘉通","100602"
		Dealer.new "河北","唐山市","遵化市","D2838","遵化广鸿","100603"
		Dealer.new "河北","廊坊市","开发区","D2839","廊坊万运","100604"
		Dealer.new "河北","邯郸市","武安市","D2840","邯郸悦华","100605"
		Dealer.new "河北","邯郸市","复兴区","D2841","邯郸恒信","100606"
		Dealer.new "河北","石家庄市","正定县","D2842","河北正博","100607"
		Dealer.new "河北","保定市","高碑店市","D2843","高碑店盛世金鼎","100608"
		Dealer.new "河北","保定市","定州市","D2844","保定轩宇瑞浩","100609"
		Dealer.new "河北","邢台市","桥西区","D2846","邢台蓝池洋龙","100610"
		Dealer.new "河北","承德市","双桥区","D2847","承德万森","100611"
		Dealer.new "河北","廊坊市","三河市","D2848","三河和鑫","100612"
		Dealer.new "山西","太原市","小店区","D2901","山西茂元","100613"
		Dealer.new "山西","太原市","小店区","D2902","山西黄河","100614"
		Dealer.new "山西","临汾市","尧都区","D2903","临汾嘉信","100615"
		Dealer.new "山西","运城市","盐湖区","D2904","运城泽龙","100616"
		Dealer.new "山西","太原市","万柏林区","D2906","山西恒润","100617"
		Dealer.new "山西","大同市","大同市","D2907","大同国贸","100618"
		Dealer.new "山西","晋城市","晋城市","D2908","晋城澜港","100619"
		Dealer.new "山西","长治市","长治市","D2909","长治霄云","100620"
		Dealer.new "山西","晋中市","介休市","D2910","介休通鑫","100621"
		Dealer.new "山西","吕梁市","离石市","D2911","吕梁金谷泓龙","100622"
		Dealer.new "山西","阳泉市","阳泉市","D2915","阳泉鼎晟","100623"
		Dealer.new "山西","运城市","河津市","D2916","河津晋诚","100624"
		Dealer.new "山西","临汾市","尧都区","D2917","临汾天健","100625"
		Dealer.new "山西","朔州市","朔州市","D2918","朔州鹏远","100626"
		Dealer.new "山西","忻州市","开发区","D2919","忻州唯众","100627"
		Dealer.new "山西","长治市","长治市","D2920","长治云烨","100628"
		Dealer.new "山西","晋中市","榆次区","D2921","晋中香山","100629"
		Dealer.new "山西","晋城市","泽州县","D2922","晋城瀚港","100630"
		Dealer.new "山西","大同市","大同市","D2923","大同庞大明悦","100631"
		Dealer.new "山西","阳泉市","阳泉市","D2924","阳泉海东","100632"
		Dealer.new "山西","晋城市","高平市","D2925","高平丹枫","100633"
		Dealer.new "山西","运城市","盐湖区","D2926","运城彩虹","100634"
		Dealer.new "山西","运城市","盐湖区","D2927","运城鑫田","100635"
		Dealer.new "山西","太原市","万柏林区","D2928","太原汇发","100636"
		Dealer.new "山西","太原市","小店区","D2929","太原传奇","100637"
		Dealer.new "陕西","西安市","未央区","D3001","陕西福达","100638"
		Dealer.new "陕西","西安市","高新区","D3002","西安华中","100639"
		Dealer.new "陕西","西安市","新城区","D3003","陕西彤立江","100640"
		Dealer.new "陕西","榆林市","开发区","D3005","榆林志成","100641"
		Dealer.new "陕西","延安市","宝塔区","D3006","延安鸿业","100642"
		Dealer.new "陕西","宝鸡市","渭滨区","D3008","宝鸡蓝天","100643"
		Dealer.new "陕西","汉中市","开发区","D3009","汉中冀祥","100644"
		Dealer.new "陕西","西安市","沣渭新区","D3010","陕西安利达","100645"
		Dealer.new "陕西","榆林市","横山县","D3011","榆林华明","100646"
		Dealer.new "陕西","西安市","灞桥区","D3012","西安庞大明祥","100647"
		Dealer.new "陕西","安康市","高新区","D3013","安康众诚","100648"
		Dealer.new "陕西","榆林市","神木县","D3014","神木天河","100649"
		Dealer.new "陕西","商洛市","商州区","D3015","商洛泽泰源瑞","100650"
		Dealer.new "陕西","咸阳市","秦都区","D3016","咸阳荣华","100651"
		Dealer.new "陕西","西安市","雁塔区","D3018","西安泽泰瑞钢","100652"
		Dealer.new "陕西","铜川市","王益区","D3019","铜川泽泰盛世","100653"
		Dealer.new "陕西","渭南市","临渭区","D3020","渭南新盛","100654"
		Dealer.new "陕西","咸阳市","秦都区","D3021","咸阳鹏龙鸿秦","100655"
		Dealer.new "甘肃","兰州市","七里河区","D3102","兰州永丰","100656"
		Dealer.new "甘肃","兰州市","城关区","D3103","甘肃通汇","100657"
		Dealer.new "甘肃","嘉峪关市","镜铁区","D3104","嘉峪关飞瑞","100658"
		Dealer.new "甘肃","兰州市","安宁区","D3105","兰州金岛兴合","100659"
		Dealer.new "甘肃","天水市","麦积区","D3106","天水永林","100660"
		Dealer.new "甘肃","平凉市","崆峒区","D3108","平凉恒信华通","100661"
		Dealer.new "甘肃","白银市","白银区","D3109","白银恒信华通","100662"
		Dealer.new "甘肃","张掖市","甘州区","D3110","张掖银通","100663"
		Dealer.new "甘肃","定西市","安定区","D3111","定西恒信华通","100664"
		Dealer.new "甘肃","庆阳市","西峰区","D3112","庆阳天驰嘉盛","100665"
		Dealer.new "新疆","乌鲁木齐市","新市区","D4001","新疆捷康","100666"
		Dealer.new "新疆","乌鲁木齐市","水磨沟区","D4002","新疆博望","100667"
		Dealer.new "新疆","库尔勒市","库尔勒市","D4003","库尔勒永达","100668"
		Dealer.new "新疆","克拉玛依市","克拉玛依市","D4004","克拉玛依天捷","100669"
		Dealer.new "新疆","昌吉市","昌吉市","D4005","昌吉庞大全汇","100670"
		Dealer.new "新疆","阿克苏市","阿克苏市","D4006","阿克苏银丰","100671"
		Dealer.new "新疆","乌鲁木齐市","米东区","D4007","新疆天汇华嘉","100672"
		Dealer.new "新疆","哈密市","哈密市","D4008","天汇华鹏","100673"
		Dealer.new "新疆","伊宁市","伊犁市","D4009","伊犁宏威","100674"
		Dealer.new "新疆","喀什市","喀什市","D4010","喀什华力","100675"
		Dealer.new "新疆","乌鲁木齐市","新市区","D4011","新疆鸿盛丰","100676"
		Dealer.new "新疆","奎屯市","奎屯市","D4012","奎屯嘉丰","100677"
		Dealer.new "西藏","拉萨市","城关区","D4102","拉萨康达","100678"
		Dealer.new "广西","桂林市","灵川县","D4201","桂林顺景","100679"
		Dealer.new "广西","南宁市","江南区","D4202","广西通源","100680"
		Dealer.new "广西","南宁市","西乡塘区","D4203","广西鑫广达","100681"
		Dealer.new "广西","柳州市","柳南区","D4204","柳州中冠","100682"
		Dealer.new "广西","玉林市","玉州区","D4207","玉林得利","100683"
		Dealer.new "广西","柳州市","柳北区","D4208","柳州恒翔","100684"
		Dealer.new "广西","贵港市","港北区","D4209","贵港中博","100685"
		Dealer.new "广西","钦州市","钦南区","D4210","钦州恒骋","100686"
		Dealer.new "广西","梧州市","万秀区","D4211","梧州金欣","100687"
		Dealer.new "广西","南宁市","兴宁区","D4212","南宁全越","100688"
		Dealer.new "广西","河池市","金城江区","D4213","河池明远","100689"
		Dealer.new "广西","桂林市","临桂区","D4214","桂林万亚","100690"
		Dealer.new "广西","百色市","右江区","D4215","百色联泰","100691"
		Dealer.new "内蒙","包头市","青山区","D4302","包头蒙驰","100692"
		Dealer.new "内蒙","呼和浩特市","新城区","D4303","内蒙古鹏顺","100693"
		Dealer.new "内蒙","鄂尔多斯市","东胜区","D4304","鄂尔多斯蒙天","100694"
		Dealer.new "内蒙","赤峰市","红山区","D4305","赤峰蒙恒","100695"
		Dealer.new "内蒙","呼伦贝尔市","海拉尔区","D4306","呼伦贝尔友邦","100696"
		Dealer.new "内蒙","锡林郭勒盟","锡林浩特市","D4307","锡林浩特威力斯","100697"
		Dealer.new "内蒙","乌海市","海勃湾区","D4308","乌海蒙达","100698"
		Dealer.new "内蒙","呼和浩特市","回民区","D4309","内蒙古明祥","100699"
		Dealer.new "内蒙","通辽市","开发区","D4310","通辽万鑫","100700"
		Dealer.new "内蒙","鄂尔多斯市","东胜区","D4311","鄂尔多斯华明","100701"
		Dealer.new "内蒙","巴彦淖尔市","临河区","D4312","巴彦淖尔丰圣","100702"
		Dealer.new "内蒙","包头市","九原区","D4313","包头庆祥","100703"
		Dealer.new "内蒙","兴安盟","乌兰浩特市","D4314","兴安盟泰信","100704"
		Dealer.new "内蒙","乌兰察布市","集宁区","D4315","乌兰察布广鹤","100705"
		Dealer.new "内蒙","包头市","高新区","D4316","包头金冠","100706"
		Dealer.new "内蒙","呼和浩特市","新城区","D4318","呼市丰胜","100707"
		Dealer.new "内蒙","包头市","九原区","D4319","包头蒙兴","100708"
		Dealer.new "内蒙","赤峰市","红山区","D4320","赤峰泰恒","100709"
		Dealer.new "内蒙","鄂尔多斯市","东胜区","D4322","鄂尔多斯天孚","100710"
		Dealer.new "内蒙","巴彦淖尔市","开发区","D4323","巴彦淖尔利丰泰昕","100711"
		Dealer.new "宁夏","银川市","贺兰县","D4402","银川德联","100712"
		Dealer.new "宁夏","银川市","金凤区","D4403","银川好世界","100713"
		Dealer.new "宁夏","银川市","金凤区","D4404","宁夏天创","100714"
		Dealer.new "宁夏","吴忠市","利通区","D4405","吴忠恒信华通","100715"
		Dealer.new "宁夏","固原市","原州区","D4406","固原磊腾","100716"
		Dealer.new "宁夏","石嘴山市","大武口区","D4407","石嘴山京石","100717"
