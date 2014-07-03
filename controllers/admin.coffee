# 基本类库
fs = require 'fs'
path = require 'path'
crypto = require 'crypto'
helper = require '../lib/helper'


# 扩展类库
EventProxy = require 'eventproxy'
config = require('../config').config
nodeExcel = require('excel-export')


# 数据库
User = require("../model/mongo").User
Lots = require("../model/mongo").Lots
Dealer = require("../model/mongo").Dealer

str="qwertyuiopasdfghjklmnbvcxz1234567890"

unique = (data)->
	data = data or []
	a = {}
	for i in [0...data.length]
		v = data[i].mobile
		if not a[v]?
			a[v] = data[i]
	data.length = 0
	for i of a
		data[data.length] = a[i]

	return data

exports.first = (req,res,next)->
	# if req.cookies.login? and req.cookies.login is "in" and req.cookies.user?
		# res.redirect "/admin/index"
	# else
	res.redirect "/admin/in"
exports.before = (req,res,next)->
	# check login.
	if req.cookies.login isnt "in"
		return res.redirect "/dealer"
	next()
exports.in = (req,res,next)->
	defaultDealer()
	# if req.cookies.login? and req.cookies.login is "in" and req.cookies.user?
	# 	return res.redirect "/admin/index"
	# console.log req.cookies.user
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
				res.render "admin/dealer",{list:unique(resutls),selectype:type}
		else
			User.getUserByDealer req.cookies.user,(err,resutls)->
				console.log resutls.length,unique(resutls)
				res.render "admin/dealer",{list:unique(resutls)}
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
	if parseInt(mileage) > 10000000
		re.recode = 201
		re.reason = "行驶里程过长"
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
			Dealer.getbyid user.dealer,(err,dealer)->
				Lots.getById user.lot,(err,lot)->
					res.render "admin/info",{user:user,code:req.query.code,lot:lot,dealer_id:req.cookies.user,dealer:req.cookies.dealer,dl:dealer}
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

# exports.download = (req,res,next)->
# 	result = 'a,b,c'
# 	res.setHeader('Content-Type', 'application/vnd.openxmlformats');
# 	res.setHeader("Content-Disposition", "attachment; filename=Report.xls");
# 	res.end(result, 'binary');


resetCode = (code)->

	# code = parseInt(code).toString(32);
	# var reg = /(\w{1})(\w{6})/;code = code.replace(reg,"d"); return new Date(parseInt(code,32)*100);

exports.downloadxml = (req,res,next)->
	# 
	_lots = []
	_dealers = []
	# 
	conf ={}
	conf.stylesXmlFile = path.join(__dirname, 'styles.xml')
	conf.cols = [
		{
			caption:'注册时间',
			type:'string',
			beforeCellWrite: (row,cellData,eOpt)->
				if cellData?
					date = new Date(cellData)
					return date.getFullYear()+"-"+(date.getMonth()+1)+"-"+date.getDate()+" "+date.getHours()+":"+date.getMinutes()+":"+date.getSeconds()
				else
					return cellData
			width:20
		}
		{
			caption:"预约日期",
			type:'string',
			width:20
			beforeCellWrite: (row,cellData,eOpt)->
				if cellData?
					date = new Date(cellData)
					return date.getFullYear()+"-"+(date.getMonth()+1)+"-"+date.getDate()
				else
					return ""
		}
		{
			caption:"验证码",
			type:"string"
		}
		{
			caption:"姓名",
			type:"string"
		}
		{
			caption:"手机",
			type:"string",
			width:28
		}
		{
			caption:"车型",
			type:"string",
			beforeCellWrite: (row,cellData,eOpt)->
				type = [{name:"悦动",type:"1"},{name:"伊兰特",type:"2"},{name:"雅绅特",type:"3"},{name:"瑞纳",type:"4"},{name:"i30",type:"5"},{name:"途胜",type:"6"}]
				return type[parseInt(cellData)-1].name
		}
		{
			caption:"32项",
			type:"string"
		}
		{
			caption:"汽车用品",
			type:"string",
			beforeCellWrite: (row,cellData,eOpt)->
				for i in [0..._lots.length]
					if cellData+"" is _lots[i]._id+""
						return _lots[i].lotname
				return ""
		}
		{
			caption:"保养配件",
			type:"string",
			beforeCellWrite: (row,cellData,eOpt)->
				if cellData
					return "是"
				else
					return "否"
		}
		{
			caption:"是否置换"
			type:"string"
			beforeCellWrite: (row,cellData,eOpt)->
				if cellData
					return "是"
				else
					return "否"
		}
		{
			caption:"省/市"
			type:"string"
		}
		{
			caption:"城市"
			type:"string"
		}
		# {
		# 	caption:"区县"
		# 	type:"string"
		# 	beforeCellWrite: (row,cellData,eOpt)->
		# 		for i in [0..._dealers.length]
		# 			if cellData is _dealers[i].dealer_id
		# 				return _dealers[i].county
		# }
		# {
		# 	caption:"店名"
		# 	type:"string"
		# 	beforeCellWrite: (row,cellData,eOpt)->
		# 		for i in [0..._dealers.length]
		# 			if cellData is _dealers[i].dealer_id
		# 				return _dealers[i].dealer
		# }
		{
			caption:"店号"
			type:"string"
		}
	]
	conf.rows = []
	# conf.rows = [
	# 	["a","2014-07-01 13:12:32"],
	# 	["b","2014-07-01 13:12:32"]
	# ]
	

	st = new Date().getTime()-(1000*60*60*4)
	et = new Date().getTime()+(1000*60*60*4)
	type = ""
	if req.query.startime? and req.query.endtime?
		st = req.query.startime
		et = req.query.endtime
		type = req.query.type
		

	ep = new EventProxy.create "users","lots","dealers","tenoff","used",(users,lots,dealers,tenoff,used)->
		_lots = lots
		_dealers = dealers
		list = getList lots,used
		
		for i in [0...users.length]
			conf.rows.push [ users[i].create_at , users[i].reser_at, users[i].code, users[i].username, users[i].mobile, users[i].cartype, users[i].thir.length, users[i].lot, users[i].tenoff, users[i].changed, users[i].province, users[i].city, users[i].dealer] 

		result = nodeExcel.execute(conf);
		res.setHeader('Content-Type', 'application/vnd.openxmlformats');
		res.setHeader("Content-Disposition", "attachment; filename=" + "hyundai.xlsx");
		res.end(result, 'binary');

		# res.render "admin/super",{selectype:req.query.type,users:users,dealers:dealers,lots:lots,list:list,used:used,tenoff:tenoff}

	User.findAll st,et,type,(err,users)->
		# console.log users
		ep.emit "users",users
	Dealer.findAll (err,dealers)->
		ep.emit "dealers",dealers
	Lots.count (err,count)->
		ep.emit "lots",count

	Lots.used (err,used)->
		ep.emit "used",used

	User.getTenoff (err,results)->
		console.log err,results
		ep.emit "tenoff",results



exports.superlogin = (req,res,next)->
	res.render "admin/superlogin"
exports.superloginpost = (req,res,next)->
	re = new helper.recode()
	if req.body.username is "admin" and req.body.password is "759432"
		res.send re
	else
		re.recode = 201
		re.reason = "用户名或密码错误"
		res.send re
exports.super = (req,res,next)->

	st = new Date().getTime()-(1000*60*60*4)
	et = new Date().getTime()+(1000*60*60*4)
	type = ""
	if req.query.startime? and req.query.endtime?
		st = req.query.startime
		et = req.query.endtime
		type = req.query.type
		

	ep = new EventProxy.create "users","lots","dealers","tenoff","used","userscount",(users,lots,dealers,tenoff,used,userscount)->
		
		list = getList lots,used
		
		res.render "admin/super",{st:st,et:et,selectype:req.query.type,users:users,dealers:dealers,lots:lots,list:list,used:used,tenoff:tenoff}

	User.findAll st,et,type,(err,users)->
		# console.log users
		ep.emit "users",users

	User.usercount st,et,type,(err,results)->
		ep.emit "userscount",results

	Dealer.findAll (err,dealers)->
		ep.emit "dealers",dealers
	Lots.count (err,count)->
		ep.emit "lots",count

	Lots.used (err,used)->
		ep.emit "used",used

	User.getTenoff (err,results)->
		console.log err,results
		ep.emit "tenoff",results


# 
getList = (count,used)->
	list = []
	for d in count
		list.push {lot:d._id,used:0,count:d.nums[0]} if not d.cartype

	for a in used
		for b in count
			# console.log a._id.lot,b._id
			if a._id.lot+"" is b._id+""
				if b.cartype
					if a.total >= b.nums[ parseInt(a._id.cartype)-1 ]
						a.can = false
						list.push {lot:a._id.lot,cartype:a._id.cartype,used:a.total,count:b.nums[ parseInt(a._id.cartype)-1 ],can:false}
					else
						a.can = true
						list.push {lot:a._id.lot,cartype:a._id.cartype,used:a.total,count:b.nums[ parseInt(a._id.cartype)-1 ],can:true}

	for a in used
		continue if a.can?
		for b in list
			if b.lot+"" is a._id.lot+""
				b.used += a.total
	for a in list
		if a.used >= a.count
			a.can = false 
		else
			a.can = true
	return list


defaultDealer = ->
	Dealer.get (err,resutls)->
		if resutls.length>0
			return false
		# "北京","北京市","丰台区","D0101","京汉新港","100000"
		Dealer.new "北京","北京市","丰台区","D0101","京汉新港","159658"
		Dealer.new "北京","北京市","海淀区","D0102","鹏奥","434653"
		Dealer.new "北京","北京市","丰台区","D0103","信发","458317"
		Dealer.new "北京","北京市","朝阳区","D0104","燕盛隆","907133"
		Dealer.new "北京","北京市","朝阳区","D0105","胜鸿都","482755"
		Dealer.new "北京","北京市","朝阳区","D0106","博伟恒业","414682"
		Dealer.new "北京","北京市","朝阳区","D0107","瑞通嘉业","179516"
		Dealer.new "北京","北京市","开发区","D0108","冀财奥","287909"
		Dealer.new "北京","北京市","朝阳区","D0110","通铭伟业","903338"
		Dealer.new "北京","北京市","朝阳区","D0111","波士山","224463"
		Dealer.new "北京","北京市","海淀区","D0112","京现荣华","955571"
		Dealer.new "北京","北京市","平谷区","D0114","欧之杰","788121"
		Dealer.new "北京","北京市","海淀区","D0115","东方金硕","111720"
		Dealer.new "北京","北京市","密云县","D0116","安瑞迪","794017"
		Dealer.new "北京","北京市","房山区","D0117","连振高超","430324"
		Dealer.new "北京","北京市","昌平区","D0118","天乐国裕","537685"
		Dealer.new "北京","北京市","大兴区","D0119","大兴大通佳信","296675"
		Dealer.new "北京","北京市","石景山区","D0120","北方程远","903866"
		Dealer.new "北京","北京市","朝阳区","D0121","庞大伟业","762697"
		Dealer.new "北京","北京市","顺义区","D0123","北京成禄翔","653716"
		Dealer.new "北京","北京市","怀柔区","D0124","北京华阳顺通","842872"
		Dealer.new "北京","北京市","朝阳区","D0125","鸿都智通","380255"
		Dealer.new "北京","北京市","朝阳区","D0126","东仁环宇","667785"
		Dealer.new "北京","北京市","通州区","D0127","北京京信永达","551232"
		Dealer.new "上海","上海市","浦东新区","D0201","上海东昌","291176"
		Dealer.new "上海","上海市","闵行区","D0202","上海北现","180116"
		Dealer.new "上海","上海市","普陀区","D0203","上海中创","243974"
		Dealer.new "上海","上海市","宝山区","D0205","上海现峰","439877"
		Dealer.new "上海","上海市","徐汇区","D0206","上海通现","188649"
		Dealer.new "上海","上海市","宝山区","D0210","上海百联","420076"
		Dealer.new "上海","上海市","淞江区","D0212","上海惠盈","115640"
		Dealer.new "上海","上海市","奉贤区","D0213","上海金现","858779"
		Dealer.new "上海","上海市","宝山区","D0215","上海宝银","120453"
		Dealer.new "上海","上海市","浦东新区","D0216","上海联诚","610618"
		Dealer.new "上海","上海市","金山区","D0217","上海轿辰","458540"
		Dealer.new "上海","上海市","宝山区","D0218","上海恒锐","869397"
		Dealer.new "上海","上海市","闵行区","D0219","上海强生","693812"
		Dealer.new "上海","上海市","闵行区","D0220","上海弘怡","770775"
		Dealer.new "上海","上海市","青浦区","D0221","上海联兴","297798"
		Dealer.new "重庆","重庆市","渝北区","D0301","重庆美源","344193"
		Dealer.new "重庆","重庆市","南岸区","D0302","重庆互邦正信","992590"
		Dealer.new "重庆","重庆市","渝北区","D0303","重庆当代","706893"
		Dealer.new "重庆","重庆市","涪陵区","D0304","涪陵驰御","301403"
		Dealer.new "重庆","重庆市","璧山区","D0305","重庆奥瑞","373046"
		Dealer.new "重庆","重庆市","巴南区","D0306","重庆沛鑫","821622"
		Dealer.new "重庆","重庆市","永川区","D0307","永川美源永现","393676"
		Dealer.new "重庆","重庆市","万州区","D0308","美源万现","780750"
		Dealer.new "重庆","重庆市","合川区","D0309","重庆通际","597627"
		Dealer.new "天津","天津市","河西区","D0401","天津捷安","601087"
		Dealer.new "天津","天津市","北辰区","D0402","天津中乒","787274"
		Dealer.new "天津","天津市","南开区","D0403","天津鸿通","152651"
		Dealer.new "天津","天津市","河西区","D0404","天津信盛","197492"
		Dealer.new "天津","天津市","开发区","D0405","天津瑞芝","344431"
		Dealer.new "天津","天津市","汽车园","D0406","天津森龙","730637"
		Dealer.new "天津","天津市","北辰区","D0407","天津庞大伟通","847545"
		Dealer.new "天津","天津市","西青区","D0408","天津森达","619935"
		Dealer.new "天津","天津市","静海县","D0409","天津捷世德","448653"
		Dealer.new "天津","天津市","西青区","D0410","天津博兴奇智","843222"
		Dealer.new "天津","天津市","蓟县","D0412","蓟县汇青源通","694753"
		Dealer.new "山东","青岛市","市北区","D1003","青岛裕泰","476573"
		Dealer.new "山东","青岛市","市北区","D1004","青岛福日","477142"
		Dealer.new "山东","淄博市","张店区","D1005","淄博泰通达","155857"
		Dealer.new "山东","临沂市","义堂镇","D1006","临沂鲁泰","729443"
		Dealer.new "山东","济宁市","高新区","D1007","济宁永泰","563056"
		Dealer.new "山东","烟台市","芝罘区","D1008","烟台博泰","516181"
		Dealer.new "山东","临沂市","兰山市区","D1009","临沂阳光","555622"
		Dealer.new "山东","烟台市","开发区","D1010","烟台金德","346438"
		Dealer.new "山东","潍坊市","坊子区","D1011","潍坊金龙","317015"
		Dealer.new "山东","潍坊市","开发区","D1012","潍坊晟星","691124"
		Dealer.new "山东","东营市","东营区","D1014","东营通泰","430363"
		Dealer.new "山东","聊城市","东昌府区","D1015","聊城恒泰","258108"
		Dealer.new "山东","日照市","东港区","D1016","日照美多","575629"
		Dealer.new "山东","泰安市","岱岳区","D1017","泰安北方","496208"
		Dealer.new "山东","东营市","垦利县","D1018","东营明达","839299"
		Dealer.new "山东","济南市","槐荫区","D1019","山东润寰","687824"
		Dealer.new "山东","莱芜市","开发区","D1020","莱芜泰达","399109"
		Dealer.new "山东","德州市","德城区","D1021","德州正豪","363467"
		Dealer.new "山东","淄博市","张店区","D1022","淄博金恒吉","689852"
		Dealer.new "山东","日照市","东港区","D1023","日照顺新","505771"
		Dealer.new "山东","枣庄市","市中区","D1024","枣庄凯顺","926412"
		Dealer.new "山东","菏泽市","牡丹区","D1025","菏泽昌信","312220"
		Dealer.new "山东","滨州市","滨城区","D1026","滨州远方","323326"
		Dealer.new "山东","临沂市","罗庄区","D1027","临沂翔宇","663724"
		Dealer.new "山东","威海市","环翠区","D1028","威海振洋","852969"
		Dealer.new "山东","青岛市","崂山区","D1029","青岛润洋","221301"
		Dealer.new "山东","淄博市","临淄区","D1031","淄博众智源","219400"
		Dealer.new "山东","济宁市","市中区","D1033","济宁鸿源","513361"
		Dealer.new "山东","潍坊市","寿光市","D1034","寿光元润","714932"
		Dealer.new "山东","潍坊市","诸城市","D1035","诸城佳恒","415747"
		Dealer.new "山东","济南市","历下区","D1036","山东华建","961142"
		Dealer.new "山东","烟台市","招远市","D1037","招远玲珑","418093"
		Dealer.new "山东","青岛市","胶南市","D1038","青岛宇海","740789"
		Dealer.new "山东","聊城市","东昌府区","D1039","聊城金友","411971"
		Dealer.new "山东","青岛市","平度市","D1040","青岛宝威","359458"
		Dealer.new "山东","烟台市","龙口市","D1041","烟台龙口","967609"
		Dealer.new "山东","德州市","德城区","D1042","德州正达","444891"
		Dealer.new "山东","泰安市","泰山区","D1043","泰安好运","729398"
		Dealer.new "山东","威海市","环翠区","D1044","威海悦洋","938028"
		Dealer.new "山东","滨州市","滨城区","D1045","滨州通悦","920121"
		Dealer.new "山东","菏泽市","开发区","D1046","菏泽通源","450630"
		Dealer.new "山东","枣庄市","滕州市","D1047","滕州永大","958755"
		Dealer.new "山东","潍坊市","高密市","D1048","高密鑫佳恒","613075"
		Dealer.new "山东","青岛市","即墨市","D1049","即墨宏峰合达","256148"
		Dealer.new "山东","济宁市","市中区","D1050","济宁永昌","240087"
		Dealer.new "山东","潍坊市","青州市","D1051","青州宝隆","189993"
		Dealer.new "山东","济南市","章丘市","D1052","章丘瑞和众达","951042"
		Dealer.new "山东","东营市","东营区","D1053","东营巨丰","811292"
		Dealer.new "山东","临沂市","河东区","D1054","临沂汇通","743131"
		Dealer.new "山东","青岛市","城阳区","D1055","青岛金阳光","630723"
		Dealer.new "山东","菏泽市","郓城县","D1056","郓城中汇","455816"
		Dealer.new "山东","青岛市","胶州市","D1057","青岛胶州双龙源","983011"
		Dealer.new "山东","青岛市","黄岛区","D1058","青岛庚辰润通","726220"
		Dealer.new "山东","烟台市","莱州市","D1059","莱州鸿昌达","218721"
		Dealer.new "山东","济宁市","曲阜市","D1060","曲阜新东源","205209"
		Dealer.new "山东","临沂市","兰山区","D1061","临沂悦晟","637294"
		Dealer.new "山东","济宁市","邹城市","D1062","邹城君之舆","555843"
		Dealer.new "山东","日照市","莒县","D1063","莒县和瑞","942487"
		Dealer.new "山东","东营市","广饶县","D1065","广饶石大乐安","925836"
		Dealer.new "山东","滨州市","邹平县","D1066","邹平顺捷","192582"
		Dealer.new "山东","烟台市","莱山区","D1067","莱山金泰莱","619255"
		Dealer.new "山东","烟台市","莱阳市","D1068","莱阳一弘","215252"
		Dealer.new "山东","青岛市","莱西市","D1069","莱西宝威恒盛","587187"
		Dealer.new "山东","菏泽市","开发区","D1070","单县华汇","173240"
		Dealer.new "山东","潍坊市","昌乐市","D1071","昌乐烨丰","648304"
		Dealer.new "山东","临沂市","沂水县","D1074","沂水乔丰","851059"
		Dealer.new "山东","烟台市","海阳市","D1075","海阳海嘉","583331"
		Dealer.new "山东","济宁市","梁山县","D1076","梁山聚源","935969"
		Dealer.new "山东","济南市","市中区","D1077","济南海源","536323"
		Dealer.new "山东","潍坊市","临朐县","D1078","临朐基泰","336065"
		Dealer.new "山东","威海市","乳山市","D1079","乳山振洋","396159"
		Dealer.new "江苏","南京市","秦淮区","D1101","江苏万帮","460187"
		Dealer.new "江苏","南京市","栖霞区","D1102","南京朗驰","366057"
		Dealer.new "江苏","苏州市","高新区","D1103","苏州新泰","331094"
		Dealer.new "江苏","无锡市","新区","D1104","无锡东方","407876"
		Dealer.new "江苏","常州市","新北区","D1106","常州金田","311869"
		Dealer.new "江苏","扬州市","邗江区","D1107","扬州玉峰","101483"
		Dealer.new "江苏","南通市","崇川区","D1108","南通文峰","451440"
		Dealer.new "江苏","苏州市","常熟市","D1109","苏州华现","634189"
		Dealer.new "江苏","苏州市","吴中区","D1110","苏州正旺","109867"
		Dealer.new "江苏","徐州市","云龙区","D1111","徐州润东","615606"
		Dealer.new "江苏","常州市","江阴市","D1112","江阴海鹏","690822"
		Dealer.new "江苏","苏州市","昆山市","D1113","昆山华腾","938247"
		Dealer.new "江苏","连云港市","海州开发区","D1114","连云港华驰","571635"
		Dealer.new "江苏","常州市","武进区","D1115","常州明盛","207231"
		Dealer.new "江苏","盐城市","开发区","D1116","盐城森风","222238"
		Dealer.new "江苏","镇江市","润州区","D1117","镇江京鹏","799650"
		Dealer.new "江苏","淮安市","淮阴区","D1118","淮安润东","288756"
		Dealer.new "江苏","南通市","港闸区","D1119","南通富嘉","625293"
		Dealer.new "江苏","苏州市","张家港市开发区","D1120","张家港宏伟","354453"
		Dealer.new "江苏","宿迁市","开发区","D1121","宿迁苏驰","229725"
		Dealer.new "江苏","泰州市","海陵区","D1122","泰州宝天","803809"
		Dealer.new "江苏","无锡市","宜兴市","D1123","宜兴恒信","475183"
		Dealer.new "江苏","苏州市","相城区","D1124","苏州东昌","405929"
		Dealer.new "江苏","无锡市","溧阳市","D1125","溧阳顺达","467438"
		Dealer.new "江苏","镇江市","丹阳市","D1127","丹阳京利","964010"
		Dealer.new "江苏","苏州市","太仓市","D1128","太仓华鳌","324617"
		Dealer.new "江苏","苏州市","吴江市","D1129","吴江韩帮","428372"
		Dealer.new "江苏","苏州市","吴江市","D1130","吴江嘉诚","712871"
		Dealer.new "江苏","扬州市","江都区","D1131","江都宏远","196171"
		Dealer.new "江苏","南通市","海门市","D1132","海门宝诚","502806"
		Dealer.new "江苏","南京市","江宁区","D1133","南京金现","879809"
		Dealer.new "江苏","徐州市","铜山新区","D1134","徐州苏企","561406"
		Dealer.new "江苏","无锡市","崇安区","D1135","无锡东方鑫现","837673"
		Dealer.new "江苏","苏州市","吴中区","D1136","苏州惠盈","838379"
		Dealer.new "江苏","无锡市","惠山区","D1137","无锡嘉现","464362"
		Dealer.new "江苏","泰州市","兴化市","D1138","兴化金鼎","673716"
		Dealer.new "江苏","盐城市","盐都新区","D1139","盐城宁泰","921148"
		Dealer.new "江苏","常州市","新北区","D1140","常州飞悦","842883"
		Dealer.new "江苏","宿迁市","沭阳县","D1141","沭阳弘翔","645507"
		Dealer.new "江苏","南京市","溧水市","D1142","溧水万帮","392924"
		Dealer.new "江苏","淮安市","清河新区","D1143","雨田鸿运","871488"
		Dealer.new "江苏","苏州市","张家港市金港镇","D1144","张家港金港","309308"
		Dealer.new "江苏","徐州市","邳州市","D1145","邳州开隆","251903"
		Dealer.new "江苏","南京市","浦口区","D1146","南京克洛博","559817"
		Dealer.new "江苏","南通市","启东市","D1147","启粱文邦","353394"
		Dealer.new "江苏","徐州市","新沂市","D1148","徐州达骏洲运","187118"
		Dealer.new "江苏","南京市","高淳市","D1149","高淳万帮","130269"
		Dealer.new "江苏","连云港市","开发区","D1150","连云港现宇","937183"
		Dealer.new "江苏","南通市","崇川区","D1151","南通新城世纪","789109"
		Dealer.new "江苏","无锡市","北塘区","D1152","无锡朗润","763194"
		Dealer.new "江苏","常州市","钟楼区","D1153","常州惠盈","595371"
		Dealer.new "江苏","苏州市","昆山市","D1154","昆山森美","132480"
		Dealer.new "江苏","南通市","如皋市","D1155","如皋弘瑞","701643"
		Dealer.new "江苏","淮安市","盱眙市","D1158","盱眙和盛","692632"
		Dealer.new "江苏","扬州市","广陵区","D1159","扬州瑞丰时代","682777"
		Dealer.new "江苏","南通市","开发区","D1160","南通文峰伟业","755241"
		Dealer.new "江苏","南通市","海安市","D1161","海安征程","819675"
		Dealer.new "江苏","镇江市","句容市","D1163","句容鼎现","157241"
		Dealer.new "江苏","泰州市","姜堰区","D1164","姜堰宝泰","511655"
		Dealer.new "江苏","南通市","如东市","D1165","如东嘉恒","224336"
		Dealer.new "江苏","宿迁市","泗洪市","D1166","泗洪苏驰恒祥","725783"
		Dealer.new "江苏","常州市","金坛市","D1167","金坛金驰","622408"
		Dealer.new "江苏","泰州市","泰兴市","D1168","泰兴宝运","774849"
		Dealer.new "江苏","常州市","江阴市","D1169","江阴星现","947253"
		Dealer.new "江苏","宿迁市","泗阳市","D1170","泗阳恒辰","408938"
		Dealer.new "江苏","泰州市","靖江市","D1171","靖江宝达","802450"
		Dealer.new "江苏","盐城市","东台市","D1173","东台恒达","129155"
		Dealer.new "浙江","杭州市","江干区","D1201","浙江韩通","980617"
		Dealer.new "浙江","宁波市","江北区","D1203","宁波海达","465739"
		Dealer.new "浙江","温州市","瓯海区","D1204","温州奥奔","754713"
		Dealer.new "浙江","金华市","婺城区","D1205","金华金京","872445"
		Dealer.new "浙江","嘉兴市","秀洲区","D1206","嘉兴金腾","374226"
		Dealer.new "浙江","金华市","义乌市","D1207","义乌和邦","650620"
		Dealer.new "浙江","杭州市","萧山区","D1208","浙江通达","410609"
		Dealer.new "浙江","宁波市","江东区","D1209","宁波天源","483666"
		Dealer.new "浙江","湖州市","吴兴区","D1211","湖州中北","474409"
		Dealer.new "浙江","台州市","黄岩区","D1212","台州万和","560228"
		Dealer.new "浙江","绍兴市","越城区","D1213","绍兴海潮","890871"
		Dealer.new "浙江","宁波市","慈溪市","D1214","慈溪京通","232505"
		Dealer.new "浙江","绍兴市","上虞区","D1215","绍兴瑞源","239830"
		Dealer.new "浙江","台州市","路桥区","D1216","台州泽宇","608058"
		Dealer.new "浙江","温州市","瑞安市","D1217","瑞安红日","954601"
		Dealer.new "浙江","绍兴市","袍江区","D1218","绍兴袍江韩通","914257"
		Dealer.new "浙江","衢州市","柯城区","D1219","浙江君悦","844851"
		Dealer.new "浙江","丽水市","莲都区","D1221","丽水伊翔","675419"
		Dealer.new "浙江","温州市","乐清市","D1222","乐清大江","791187"
		Dealer.new "浙江","嘉兴市","海宁市","D1223","海宁浩通","280519"
		Dealer.new "浙江","宁波市","北仑区","D1226","宁波联众","903406"
		Dealer.new "浙江","绍兴市","诸暨市","D1227","诸暨正大","413149"
		Dealer.new "浙江","金华市","东阳市","D1228","东阳京达","576444"
		Dealer.new "浙江","杭州市","萧山区","D1230","浙江金凯","884730"
		Dealer.new "浙江","台州市","临海市","D1232","临海台运","315254"
		Dealer.new "浙江","嘉兴市","桐乡市","D1233","桐乡兴田","160460"
		Dealer.new "浙江","金华市","永康市","D1234","永康韩龙","989469"
		Dealer.new "浙江","杭州市","拱墅区","D1235","浙江全通","478904"
		Dealer.new "浙江","温州市","龙湾区","D1236","温州红盈","608183"
		Dealer.new "浙江","宁波市","余姚市","D1237","余姚舜驰","328810"
		Dealer.new "浙江","杭州市","西湖区","D1238","杭州合诚","911636"
		Dealer.new "浙江","台州市","温岭市","D1239","温岭泽行","440546"
		Dealer.new "浙江","绍兴市","嵊州市","D1240","嵊州广成八达","806972"
		Dealer.new "浙江","舟山市","定海区","D1241","舟山霁锃","295846"
		Dealer.new "浙江","温州市","苍南县","D1242","苍南冠隆","807557"
		Dealer.new "浙江","温州市","永嘉县","D1243","永嘉现盛","895042"
		Dealer.new "浙江","宁波市","宁海市","D1244","宁海翔源","485801"
		Dealer.new "浙江","台州市","椒江区","D1246","台州元现","554482"
		Dealer.new "浙江","湖州市","长兴县","D1247","长兴中现","798652"
		Dealer.new "浙江","湖州市","安吉县","D1248","安吉中建","357092"
		Dealer.new "浙江","温州市","龙湾区","D1249","温州金昌","153246"
		Dealer.new "浙江","温州市","平阳县","D1250","平阳骏达","154989"
		Dealer.new "浙江","金华市","义乌市","D1251","义乌京皓","467711"
		Dealer.new "浙江","杭州市","余杭区","D1252","余杭宝盈","807287"
		Dealer.new "浙江","金华市","浦江县","D1253","浦江金瑞","424134"
		Dealer.new "浙江","杭州市","临安市","D1254","临安元信","351891"
		Dealer.new "浙江","杭州市","余杭区","D1255","余杭中轿禾现","342002"
		Dealer.new "浙江","丽水市","莲都区","D1256","丽水红旭","543996"
		Dealer.new "浙江","嘉兴市","南湖区","D1257","嘉兴嘉现","739289"
		Dealer.new "浙江","衢州市","江山市","D1258","江山恒大","683274"
		Dealer.new "浙江","宁波市","象山市","D1259","象山海达顺通","447481"
		Dealer.new "浙江","杭州市","桐庐市","D1260","桐庐海昌","966864"
		Dealer.new "浙江","金华市","婺城区","D1261","金华金唯","358353"
		Dealer.new "浙江","杭州市","富阳市","D1262","富阳和诚富现","535827"
		Dealer.new "浙江","宁波市","慈溪市","D1263","慈溪嘉顺","582732"
		Dealer.new "浙江","湖州市","德清县","D1264","德清嘉和","148273"
		Dealer.new "浙江","杭州市","滨江区","D1265","杭州昌鸿","926162"
		Dealer.new "浙江","宁波市","奉化市","D1268","宁波鑫远达","533476"
		Dealer.new "安徽","合肥市","新站区","D1301","合肥伟光","130068"
		Dealer.new "安徽","芜湖市","鸠江区","D1302","芜湖亚夏","264048"
		Dealer.new "安徽","合肥市","包河区","D1303","合肥稳达","336514"
		Dealer.new "安徽","蚌埠市","高新区","D1304","蚌埠润通","691982"
		Dealer.new "安徽","安庆市","开发区","D1305","安庆宜通","132073"
		Dealer.new "安徽","阜阳市","开发区","D1307","阜阳飞达","945689"
		Dealer.new "安徽","巢湖市","居巢区","D1308","巢湖南峰","967740"
		Dealer.new "安徽","宣城市","宣州区","D1309","宣城亚绅","755638"
		Dealer.new "安徽","六安市","裕安区","D1310","六安万通","621776"
		Dealer.new "安徽","亳州市","蒙城县","D1311","亳州瑞和","585226"
		Dealer.new "安徽","马鞍山市","当涂市","D1312","马鞍山伟厚","341714"
		Dealer.new "安徽","淮北市","相山区","D1313","淮北北润","237427"
		Dealer.new "安徽","黄山市","屯溪区","D1314","黄山亚翔","720023"
		Dealer.new "安徽","合肥市","包河区","D1315","合肥伟合","175979"
		Dealer.new "安徽","宿州市","开发区","D1316","宿州万上","413384"
		Dealer.new "安徽","淮南市","大通区","D1317","淮南恒美","286832"
		Dealer.new "安徽","铜陵市","狮子山区","D1318","铜陵金丰鑫海","927404"
		Dealer.new "安徽","滁州市","琅琊区","D1319","滁州宁宝","656856"
		Dealer.new "安徽","池州市","站前区","D1320","池州盛奇","737622"
		Dealer.new "安徽","合肥市","高新区","D1321","合肥亚越","448958"
		Dealer.new "安徽","亳州市","谯城区","D1322","亳州英豪","581840"
		Dealer.new "安徽","阜阳市","颍州区","D1323","阜阳伟田","410996"
		Dealer.new "安徽","芜湖市","鸠江区","D1324","芜湖伟胜","585245"
		Dealer.new "安徽","安庆市","宜秀区","D1325","安庆永通","533889"
		Dealer.new "安徽","六安市","金安区","D1326","六安汇添","761391"
		Dealer.new "安徽","合肥市","庐阳区","D1327","合肥恒信华通","743410"
		Dealer.new "河南","郑州市","惠济区","D1401","河南裕华金阳光","824470"
		Dealer.new "河南","郑州市","管城区","D1402","河南万佳捷泰","475993"
		Dealer.new "河南","郑州市","管城区","D1403","河南长江","358864"
		Dealer.new "河南","洛阳市","西工区","D1404","洛阳德众","181932"
		Dealer.new "河南","漯河市","郾城区","D1406","漯河润中","719416"
		Dealer.new "河南","许昌市","魏都区","D1407","许昌亿阳","317216"
		Dealer.new "河南","安阳市","文峰区","D1408","安阳福尔福","544339"
		Dealer.new "河南","焦作市","解放区","D1409","焦作博大伟业","602180"
		Dealer.new "河南","平顶山市","卫东区","D1410","平顶山得普","130963"
		Dealer.new "河南","濮阳市","华龙区","D1411","濮阳华瑞璞光","792537"
		Dealer.new "河南","新乡市","卫滨区","D1412","新乡兆阳","715379"
		Dealer.new "河南","信阳市","羊山新区","D1414","信阳全程","510679"
		Dealer.new "河南","鹤壁市","淇滨区","D1415","鹤壁鹤海","355663"
		Dealer.new "河南","商丘市","梁园区","D1416","商丘宝志","871304"
		Dealer.new "河南","济源市","济源市","D1417","济源浩轩","178287"
		Dealer.new "河南","郑州市","金水区","D1418","郑州北环","711865"
		Dealer.new "河南","三门峡市","湖滨区","D1419","三门峡时尚博长","898406"
		Dealer.new "河南","开封市","金明区","D1420","开封天翔","385130"
		Dealer.new "河南","郑州市","中原区","D1421","河南天行健","148869"
		Dealer.new "河南","驻马店市","开发区","D1422","驻马店腾麟","108752"
		Dealer.new "河南","南阳市","卧龙区","D1423","南阳中澳","542856"
		Dealer.new "河南","南阳市","宛城区","D1424","南阳威佳","191444"
		Dealer.new "河南","洛阳市","涧西区","D1425","洛阳德众胜达","471277"
		Dealer.new "河南","许昌市","禹州市","D1426","许昌双亿","907578"
		Dealer.new "河南","周口市","川汇区","D1427","周口长达","296010"
		Dealer.new "河南","新乡市","卫滨区","D1428","新乡锦程","541298"
		Dealer.new "河南","商丘市","梁园区","D1429","商丘天泽","687268"
		Dealer.new "河南","安阳市","龙安区","D1430","安阳万源","412525"
		Dealer.new "河南","三门峡市","灵宝市","D1431","灵宝长来","967288"
		Dealer.new "河南","永城市","侯岭镇","D1432","永城金祥","573132"
		Dealer.new "河南","新乡市","长垣县","D1433","长垣大广","905815"
		Dealer.new "河南","郑州市","金水区","D1434","郑州恒业","603907"
		Dealer.new "河南","平顶山市","新华区","D1435","平顶山瑞格","748513"
		Dealer.new "河南","驻马店市","驿城区","D1436","驻马店腾威","677977"
		Dealer.new "河南","焦作市","解放区","D1437","焦作博大兴业","682924"
		Dealer.new "河南","信阳市","工业新区","D1438","信阳和润","102186"
		Dealer.new "河南","濮阳市","高新区","D1439","濮阳璞润机电","190815"
		Dealer.new "河南","洛阳市","瀍河区","D1441","洛阳众腾","254181"
		Dealer.new "河南","新乡市","红旗区","D1442","东安远达（新乡）","722806"
		Dealer.new "河南","郑州市","二七区","D1443","郑州汇翔","618042"
		Dealer.new "河南","郑州市","新郑市","D1444","新郑天河","616263"
		Dealer.new "河南","许昌市","长葛市","D1445","长葛兆通","364664"
		Dealer.new "湖北","武汉市","汉阳区","D1501","武汉华星鸿泰","965551"
		Dealer.new "湖北","武汉市","江汉区","D1502","湖北欣瑞","839280"
		Dealer.new "湖北","襄阳市","襄州区","D1503","襄樊神星","550971"
		Dealer.new "湖北","宜昌市","东山开发区","D1504","宜昌腾龙","850612"
		Dealer.new "湖北","武汉市","洪山区","D1505","湖北港田","462094"
		Dealer.new "湖北","荆州市","荆州区","D1506","荆州恒信德龙","360598"
		Dealer.new "湖北","十堰市","茅箭区","D1507","十堰泽泰","443887"
		Dealer.new "湖北","黄石市","下陆区","D1508","黄石新兴","475593"
		Dealer.new "湖北","恩施市","开发区","D1509","恩施恒星","971723"
		Dealer.new "湖北","荆门市","东宝区","D1510","荆门华通","142936"
		Dealer.new "湖北","随州市","开发区","D1511","随州华神","263738"
		Dealer.new "湖北","咸宁市","咸安区","D1512","咸宁恒信","513797"
		Dealer.new "湖北","孝感市","孝南区","D1513","孝感贤良","640644"
		Dealer.new "湖北","武汉市","洪山区","D1514","华星天佑","256702"
		Dealer.new "湖北","黄冈市","黄州区","D1515","黄冈广源","870542"
		Dealer.new "湖北","武汉市","洪山区","D1516","武汉广恒","645184"
		Dealer.new "湖北","武汉市","江岸区","D1517","武汉三环泽通","366862"
		Dealer.new "湖北","宜昌市","夷陵区","D1518","宜昌恒信华通","373316"
		Dealer.new "湖北","襄阳市","襄州区","D1519","襄阳永奥","338203"
		Dealer.new "湖北","十堰市","张湾区","D1520","十堰瑞实","382674"
		Dealer.new "湖北","武汉市","江夏区","D1521","武汉泽泰融通","221349"
		Dealer.new "湖北","仙桃市","干河区","D1522","仙桃仙旺","824341"
		Dealer.new "湖北","武汉市","洪山区","D1523","武汉恒信华通","417296"
		Dealer.new "湖北","黄石市","开发区","D1524","黄石新兴振宇","280343"
		Dealer.new "贵州","贵阳市","花溪区","D1601","贵州乾通","427591"
		Dealer.new "贵州","遵义市","红花岗区","D1603","遵义千乘","234762"
		Dealer.new "贵州","贵阳市","小河区","D1604","贵阳宏健东","955738"
		Dealer.new "贵州","贵阳市","乌当区","D1605","贵阳安泰和","228988"
		Dealer.new "贵州","铜仁市","万山区","D1606","铜仁恒信华通","107576"
		Dealer.new "贵州","六盘水市","红桥新区","D1607","六盘水远现","731444"
		Dealer.new "贵州","安顺市","西秀区","D1608","安顺恒信德龙","166557"
		Dealer.new "贵州","兴义市","木贾物流园","D1609","兴义林兴","214194"
		Dealer.new "贵州","凯里市","鸭塘镇","D1610","凯里恒信德龙","272642"
		Dealer.new "贵州","都匀市","甘塘园区","D1611","都匀恒信华通","892802"
		Dealer.new "贵州","毕节市","七星关区","D1613","毕节佰润京汉","374812"
		Dealer.new "四川","成都市","成华区","D1701","四川华星卓越","586535"
		Dealer.new "四川","成都市","金牛区","D1702","四川明嘉","106714"
		Dealer.new "四川","成都市","武侯区","D1703","四川港宏","970887"
		Dealer.new "四川","绵阳市","高新区","D1704","绵阳新川萨","430802"
		Dealer.new "四川","德阳市","旌阳区","D1706","德阳伯爵","145732"
		Dealer.new "四川","眉山市","东坡区","D1708","眉山天威","152167"
		Dealer.new "四川","成都市","武侯区","D1709","成都万吉","764231"
		Dealer.new "四川","自贡市","贡井区","D1710","自贡新成","676277"
		Dealer.new "四川","成都市","青羊区","D1711","成都鑫蓝","966843"
		Dealer.new "四川","凉山州","西昌市","D1713","西昌鸿源","361881"
		Dealer.new "四川","南充市","顺庆区","D1714","南充天成","669384"
		Dealer.new "四川","泸州市","龙马潭区","D1715","泸州都慧","882041"
		Dealer.new "四川","乐山市","市中区","D1716","乐山天威","596390"
		Dealer.new "四川","成都市","温江区","D1717","成都先锋","173180"
		Dealer.new "四川","成都市","武侯区","D1718","成都申蓉","279408"
		Dealer.new "四川","达州市","达川区","D1719","达州禾林","793646"
		Dealer.new "四川","宜宾市","翠屏区","D1720","宜宾尚远","677437"
		Dealer.new "四川","广安市","广安区","D1721","广安天骄","454131"
		Dealer.new "四川","成都市","金堂区","D1722","成都金驿","462538"
		Dealer.new "四川","德阳市","广汉市","D1723","广汉恩丽","976441"
		Dealer.new "四川","南充市","高坪区","D1724","南充弘博天成","210367"
		Dealer.new "四川","资阳市","雁江区","D1725","资阳港宏泰瑞","434864"
		Dealer.new "四川","遂宁市","船山区","D1726","遂宁瑞现","161425"
		Dealer.new "四川","成都市","都江堰市","D1727","都江堰明嘉","528469"
		Dealer.new "四川","攀枝花市","市仁和区","D1728","攀枝花明嘉皓升","564828"
		Dealer.new "四川","绵阳市","涪城区","D1729","绵阳汇平","709220"
		Dealer.new "四川","雅安市","雨城区","D1730","雅安乾康","568885"
		Dealer.new "四川","内江市","市中区","D1731","内江利恒孚","338301"
		Dealer.new "四川","成都市","崇州市","D1732","崇州中鑫店","541003"
		Dealer.new "四川","成都市","双流区","D1734","双流泽通车业","872754"
		Dealer.new "四川","广元市","元坝区","D1735","广元宇风","773238"
		Dealer.new "云南","昆明市","盘龙区","D1801","云南鑫源","292931"
		Dealer.new "云南","昆明市","五华区","D1802","云南宝龙","387370"
		Dealer.new "云南","玉溪市","红塔区","D1803","玉溪诚远","677926"
		Dealer.new "云南","大理市","下关开发区","D1804","大理博源","772866"
		Dealer.new "云南","芒市","芒市","D1806","瑞丽景泰","663184"
		Dealer.new "云南","昭通市","昭阳区","D1807","昭通和熠","720167"
		Dealer.new "云南","开远市","东联村","D1808","开远裕隆","545736"
		Dealer.new "云南","昆明市","官渡区","D1809","云南庞大兴业","903110"
		Dealer.new "云南","楚雄市","开发区","D1810","楚雄艺龙","704266"
		Dealer.new "云南","保山市","隆阳区","D1811","保山天马源","722403"
		Dealer.new "云南","昆明市","呈贡新区","D1812","云南星瑞达毅","960644"
		Dealer.new "云南","普洱市","思茅区","D1814","普洱普龙","998275"
		Dealer.new "云南","曲靖市","麒麟区","D1816","曲靖鹏龙瑞桓","144326"
		Dealer.new "青海","西宁市","开发区","D1902","西宁金岛","961570"
		Dealer.new "青海","西宁市","开发区","D1903","西宁金鳞宝","550171"
		Dealer.new "青海","格尔木市","开发区","D1904","格尔木","124516"
		Dealer.new "福建","泉州市","鲤城区","D2001","泉州中达","528094"
		Dealer.new "福建","福州市","仓山区","D2002","福州中诺","477248"
		Dealer.new "福建","厦门市","湖里区","D2003","厦门国戎","153525"
		Dealer.new "福建","泉州市","晋江市","D2004","晋江远通","396144"
		Dealer.new "福建","漳州市","龙文区","D2005","漳州捷诚","288779"
		Dealer.new "福建","福州市","晋安区","D2006","福建中源","496037"
		Dealer.new "福建","莆田市","荔城区","D2007","莆田奇奇","474725"
		Dealer.new "福建","龙岩市","新罗区","D2008","龙岩通顺","771358"
		Dealer.new "福建","三明市","梅列区","D2009","三明兴闽","401101"
		Dealer.new "福建","南平市","延平区","D2010","南平龙鑫","150923"
		Dealer.new "福建","宁德市","蕉城区","D2012","宁德联丰","396030"
		Dealer.new "福建","福州市","福清市","D2013","福清吉诺","980521"
		Dealer.new "福建","厦门市","湖里区","D2014","厦门国贸启润","168646"
		Dealer.new "福建","泉州市","丰泽区","D2015","泉州华友","523022"
		Dealer.new "福建","福州市","闽侯县","D2018","福建新锐","341218"
		Dealer.new "福建","龙岩市","新罗区","D2019","龙岩中天","125950"
		Dealer.new "福建","厦门市","海沧区","D2020","厦门国贸宝润","216813"
		Dealer.new "福建","漳州市","漳浦县","D2022","漳浦安泰","136482"
		Dealer.new "福建","莆田市","仙游县","D2023","仙游阿强","954238"
		Dealer.new "广东","广州市","天河区","D2101","广州南现","143380"
		Dealer.new "广东","深圳市","福田区","D2102","深圳大胜","232456"
		Dealer.new "广东","广州市","白云区","D2103","广东羊城","663668"
		Dealer.new "广东","佛山市","禅城区","D2104","佛山泰鑫","750578"
		Dealer.new "广东","佛山市","顺德区","D2105","顺德合现","328415"
		Dealer.new "广东","广州市","番禺区","D2106","广州宏现","961004"
		Dealer.new "广东","东莞市","南城区","D2107","东莞永怡","611039"
		Dealer.new "广东","深圳市","南山区","D2108","深圳顺和盈","295080"
		Dealer.new "广东","东莞市","寮步镇","D2110","东莞冠丰","936225"
		Dealer.new "广东","深圳市","福田区","D2111","深圳鹏峰","352397"
		Dealer.new "广东","中山市","西区","D2112","中山创现","856577"
		Dealer.new "广东","汕头市","龙湖区","D2114","汕头合民","207875"
		Dealer.new "广东","广州市","天河区","D2115","广东中现","526374"
		Dealer.new "广东","惠州市","惠城区","D2116","惠州展现","780007"
		Dealer.new "广东","珠海市","香洲区","D2117","珠海华德","506759"
		Dealer.new "广东","佛山市","南海区","D2118","南海禅昌","795112"
		Dealer.new "广东","广州市","花都区","D2119","广州龙腾花现","236914"
		Dealer.new "广东","揭阳市","榕城区","D2120","揭阳群记","899503"
		Dealer.new "广东","佛山市","顺德区","D2126","佛山乐现","467770"
		Dealer.new "广东","肇庆市","端州区","D2127","肇庆美现","954667"
		Dealer.new "广东","茂名市","茂南区","D2128","茂名卓粤","564010"
		Dealer.new "广东","湛江市","赤坎区","D2129","湛江中富","967843"
		Dealer.new "广东","东莞市","大朗镇","D2131","东莞大朗世达","294653"
		Dealer.new "广东","深圳市","龙岗区","D2133","深圳新力达","205589"
		Dealer.new "广东","东莞市","虎门镇","D2134","东莞广泰","762479"
		Dealer.new "广东","广州市","增城区","D2135","增城伟加","365074"
		Dealer.new "广东","江门市","江海区","D2136","江门瑞华宏现","876180"
		Dealer.new "广东","惠州市","惠城区","D2137","惠州三惠","753948"
		Dealer.new "广东","韶关市","浈江区","D2138","韶关联现","417401"
		Dealer.new "广东","广州市","荔湾区","D2139","广州东奇","260788"
		Dealer.new "广东","河源市","紫金县","D2140","河源冠丰行","430465"
		Dealer.new "广东","中山市","南区","D2141","中山创世纪城南","268619"
		Dealer.new "广东","梅州市","梅县","D2142","梅州宏达","370737"
		Dealer.new "广东","清远市","清城区","D2143","清远泰翔","626366"
		Dealer.new "广东","潮州市","潮安县","D2144","潮州南熙","679311"
		Dealer.new "广东","东莞市","长安镇","D2145","东莞东胜","629943"
		Dealer.new "广东","阳江市","江城区","D2146","阳江京泰","310128"
		Dealer.new "广东","中山市","西区","D2147","中山中启","971482"
		Dealer.new "广东","云浮市","云城区","D2148","云浮美轮运现","521475"
		Dealer.new "广东","东莞市","常平镇","D2149","东莞金世达","255880"
		Dealer.new "广东","江门市","蓬江区","D2150","江门精文","622446"
		Dealer.new "广东","深圳市","宝安区","D2151","深圳昊天林","878024"
		Dealer.new "广东","深圳市","宝安区","D2152","深圳威博","251873"
		Dealer.new "广东","东莞市","塘厦镇","D2153","塘厦新世达","346959"
		Dealer.new "广东","东莞市","石龙镇","D2155","石龙永信","440150"
		Dealer.new "广东","佛山市","南海区","D2157","佛山南海时利和","555452"
		Dealer.new "江西","南昌市","东湖区","D2201","江西国力","585992"
		Dealer.new "江西","萍乡市","安源区","D2205","萍乡国力赣源","711962"
		Dealer.new "江西","九江市","庐山区","D2206","九江金穗","406553"
		Dealer.new "江西","上饶市","上饶县","D2207","上饶宏旭","654392"
		Dealer.new "江西","宜春市","袁州区","D2208","宜春和丰","509906"
		Dealer.new "江西","南昌市","青云谱区","D2209","南昌华美","772884"
		Dealer.new "江西","赣州市","章贡区","D2210","赣州国力","261691"
		Dealer.new "江西","吉安市","吉州区","D2211","吉安上峰","389853"
		Dealer.new "江西","抚州市","临川区","D2212","抚州华宏金鑫","233086"
		Dealer.new "江西","新余市","渝水区","D2213","新余和元","471980"
		Dealer.new "江西","景德镇市","昌江区","D2214","景德镇璟瞳","555092"
		Dealer.new "江西","赣州市","赣县","D2215","赣州华宏","119457"
		Dealer.new "江西","南昌市","红谷滩区","D2216","南昌金汇","277416"
		Dealer.new "江西","宜春市","高安市","D2217","高安和福","184695"
		Dealer.new "江西","九江市","浔阳区","D2218","九江浔瑞","822900"
		Dealer.new "江西","上饶市","鄱阳县","D2219","鄱阳加西亚现泰","348906"
		Dealer.new "江西","南昌市","青山湖区","D2220","南昌汇银","882111"
		Dealer.new "江西","鹰潭市","月湖区","D2221","鹰潭弘鹰","654303"
		Dealer.new "江西","上饶市","信州区","D2222","上饶华宏名现","434970"
		Dealer.new "湖南","长沙市","开福区","D2301","湖南华运达","285281"
		Dealer.new "湖南","长沙市","雨花区","D2302","湖南瑞特","962139"
		Dealer.new "湖南","衡阳市","蒸湘区","D2304","衡阳华利","372497"
		Dealer.new "湖南","常德市","武陵区","D2305","常德星都","687448"
		Dealer.new "湖南","湘潭市","岳塘区","D2306","湘潭九城","114647"
		Dealer.new "湖南","郴州市","苏仙区","D2307","郴州京湘","433872"
		Dealer.new "湖南","株洲市","荷塘区","D2308","株洲蓝代","508563"
		Dealer.new "湖南","岳阳市","岳阳楼区","D2309","岳阳梦达","168205"
		Dealer.new "湖南","娄底市","娄星区","D2310","娄底和轩","755716"
		Dealer.new "湖南","邵阳市","双清区","D2311","邵阳宝京","987723"
		Dealer.new "湖南","益阳市","赫山区","D2312","益阳蓝马","656678"
		Dealer.new "湖南","长沙市","雨花区","D2313","长沙世代","426359"
		Dealer.new "湖南","永州市","零陵区","D2314","永州永通华悦","194711"
		Dealer.new "湖南","湘潭市","雨湖区","D2315","湘潭九现","849835"
		Dealer.new "湖南","株洲市","芦淞区","D2316","株洲蓝现","796986"
		Dealer.new "湖南","长沙市","高新区","D2317","长沙中拓瑞达","156887"
		Dealer.new "湖南","长沙市","岳麓区","D2318","长沙韩顺","809436"
		Dealer.new "湖南","长沙市","天心区","D2319","长沙永通华盛","516644"
		Dealer.new "湖南","衡阳市","石鼓区","D2320","衡阳铭星","226518"
		Dealer.new "湖南","长沙市","浏阳市","D2321","浏阳中拓瑞晟","404507"
		Dealer.new "湖南","怀化市","鹤城区","D2322","怀化永通华峰","175960"
		Dealer.new "湖南","常德市","开发区","D2323","常德双星星润","957693"
		Dealer.new "湖南","岳阳市","岳阳楼区","D2326","岳阳华阳凯达","686051"
		Dealer.new "海南","海口市","美兰区","D2401","海南京诚","530855"
		Dealer.new "海南","三亚市","河东区","D2402","三亚骏诚","465592"
		Dealer.new "海南","海口市","琼山区","D2403","海口华诚","448472"
		Dealer.new "黑龙江","哈尔滨市","道里区","D2501","哈尔滨百丰","706273"
		Dealer.new "黑龙江","哈尔滨市","道外区","D2502","哈尔滨亿发鸿运","774717"
		Dealer.new "黑龙江","大庆市","高新区","D2503","大庆润达新亚","538858"
		Dealer.new "黑龙江","佳木斯市","佳木斯市","D2505","佳木斯中天驭风","989192"
		Dealer.new "黑龙江","齐齐哈尔市","南苑开发区","D2506","齐齐哈尔瑞宝宏通","196021"
		Dealer.new "黑龙江","牡丹江市","阳明区","D2507","牡丹江百强丰源","295271"
		Dealer.new "黑龙江","七台河市","桃山区","D2508","七台河隆达","128097"
		Dealer.new "黑龙江","黑河市","北安市","D2509","北安成功万邦","945294"
		Dealer.new "黑龙江","大庆市","让胡路区","D2510","大庆业勤鸿润","621629"
		Dealer.new "黑龙江","齐齐哈尔市","龙沙区","D2511","齐齐哈尔骏发","310039"
		Dealer.new "黑龙江","绥化市","开发区","D2512","绥化圣亚","908855"
		Dealer.new "黑龙江","双鸭山市","尖山区","D2513","双鸭山顺雷","673697"
		Dealer.new "黑龙江","哈尔滨市","香坊区","D2514","哈尔滨利泰","569923"
		Dealer.new "黑龙江","哈尔滨市","道里区","D2515","哈尔滨汇华","439703"
		Dealer.new "黑龙江","鸡西市","鸡冠区","D2516","鸡西隆达鑫煜","332831"
		Dealer.new "吉林","长春市","开发区","D2601","长春华众","470020"
		Dealer.new "吉林","吉林市","丰满区","D2602","吉林宏利源","845475"
		Dealer.new "吉林","延吉市","开发区","D2603","延吉中诚","923446"
		Dealer.new "吉林","四平市","开发区","D2604","四平鑫韩亚","922843"
		Dealer.new "吉林","通化市","东昌区","D2605","通化华阳","703154"
		Dealer.new "吉林","松原市","前郭县","D2606","松原子余","392339"
		Dealer.new "吉林","长春市","汽车开发区","D2607","长春韩亚","672864"
		Dealer.new "吉林","吉林市","船营区","D2608","吉林荣阳","167545"
		Dealer.new "吉林","梅河口市","梅河口区","D2609","梅河口广通","603537"
		Dealer.new "吉林","长春市","宽城区","D2610","长春金达洲瑞威","552350"
		Dealer.new "吉林","辽源市","西安区","D2611","辽源洪鑫","264122"
		Dealer.new "吉林","长春市","高新区","D2612","长春成铭","290332"
		Dealer.new "吉林","延吉市","龙井区","D2613","延吉天鸿","457235"
		Dealer.new "吉林","白城市","洮北区","D2614","白城致诚","956187"
		Dealer.new "吉林","白山市","浑江区","D2615","白山益信","559053"
		Dealer.new "辽宁","沈阳市","铁西区","D2702","沈阳汇众","421885"
		Dealer.new "辽宁","沈阳市","沈河区","D2703","辽宁路鑫","407790"
		Dealer.new "辽宁","营口市","站前区","D2705","营口金富佳","952654"
		Dealer.new "辽宁","盘锦市","兴隆台区","D2706","盘锦永盛","602369"
		Dealer.new "辽宁","锦州市","太和区","D2707","锦州鑫汇众","790287"
		Dealer.new "辽宁","葫芦岛市","高新区","D2708","葫芦岛路赛得","175669"
		Dealer.new "辽宁","辽阳市","宏伟区","D2709","辽阳天合","191754"
		Dealer.new "辽宁","抚顺市","望花区","D2710","抚顺金博众","723790"
		Dealer.new "辽宁","鞍山市","铁西区","D2711","鞍山鑫路鑫","651641"
		Dealer.new "辽宁","朝阳市","双塔区","D2712","朝阳吉安","204458"
		Dealer.new "辽宁","沈阳市","大东区","D2713","通孚兴邦","777362"
		Dealer.new "辽宁","铁岭市","辽海园区","D2714","铁岭北方","377854"
		Dealer.new "辽宁","丹东市","振兴区","D2715","丹东东盛","299377"
		Dealer.new "辽宁","大连市","甘井子区","D2716","大连鑫昱佳","657503"
		Dealer.new "辽宁","沈阳市","于洪区","D2717","辽宁汇鑫","787196"
		Dealer.new "辽宁","沈阳市","皇姑区","D2718","京源鸿业","178272"
		Dealer.new "辽宁","大连市","保税区","D2719","大连汇航","818838"
		Dealer.new "辽宁","沈阳市","浑南新区","D2720","沈阳庞大华明","413784"
		Dealer.new "辽宁","本溪市","明山区","D2721","本溪汇丰","673828"
		Dealer.new "辽宁","阜新市","开发区","D2722","阜新汇龙","137564"
		Dealer.new "辽宁","鞍山市","铁西区","D2723","鞍山汇阳","396719"
		Dealer.new "辽宁","大连市","中山区","D2724","大连汇明","863631"
		Dealer.new "辽宁","瓦房店市","吴店村","D2725","恒岳伟业","694819"
		Dealer.new "辽宁","大连市","西岗区","D2726","大连金汇航","552496"
		Dealer.new "辽宁","抚顺市","望花区","D2727","抚顺鑫博众","748074"
		Dealer.new "河北","石家庄市","裕华区","D2801","河北骏通","465823"
		Dealer.new "河北","秦皇岛市","开发区","D2802","秦皇岛瑞通佰盛","820379"
		Dealer.new "河北","保定市","开发区","D2803","保定轩宇","448477"
		Dealer.new "河北","石家庄市","长安区","D2804","河北盛文","701460"
		Dealer.new "河北","邯郸市","高新区","D2805","邯郸嘉华","141474"
		Dealer.new "河北","唐山市","开平区","D2806","唐山海洋","571811"
		Dealer.new "河北","邢台市","桥东区","D2807","邢台京鹏","617490"
		Dealer.new "河北","唐山市","路南区","D2808","唐山冀东","168791"
		Dealer.new "河北","衡水市","高新区","D2810","衡水德昌","170981"
		Dealer.new "河北","张家口市","桥东区","D2811","张家口美华","345564"
		Dealer.new "河北","廊坊市","广阳区","D2812","廊坊瑞龙","965049"
		Dealer.new "河北","石家庄市","桥西区","D2813","石家庄广德行","532365"
		Dealer.new "河北","承德市","双桥区","D2814","承德冀东乐业","792284"
		Dealer.new "河北","保定市","南市区","D2815","保定天华","940802"
		Dealer.new "河北","保定市","涿州市","D2817","涿州朝阳世纪","294298"
		Dealer.new "河北","沧州市","新华区","D2819","沧州恒源","164262"
		Dealer.new "河北","廊坊市","霸州市","D2820","霸州亿龙","719250"
		Dealer.new "河北","沧州市","运河区","D2822","沧州安捷","780499"
		Dealer.new "河北","唐山市","高新区","D2823","唐山庞大广盛","534187"
		Dealer.new "河北","张家口市","桥东区","D2824","张家口泰成达","565112"
		Dealer.new "河北","石家庄市","新华区","D2825","天徽致远","416621"
		Dealer.new "河北","邯郸市","邯山区","D2826","邯郸华宝","495160"
		Dealer.new "河北","衡水市","开发区","D2827","衡水衡冲","988010"
		Dealer.new "河北","沧州市","运河区","D2828","沧州蓝池泰龙","497273"
		Dealer.new "河北","邢台市","任县","D2829","邢台德翔","192312"
		Dealer.new "河北","秦皇岛市","海港区","D2830","秦皇岛庞大广盈","198332"
		Dealer.new "河北","唐山市","迁安市","D2831","迁安庞大广发","225654"
		Dealer.new "河北","保定市","北市区","D2832","保定骊致","100854"
		Dealer.new "河北","邯郸市","复兴区","D2833","邯郸远洋","152417"
		Dealer.new "河北","沧州市","任丘市","D2834","任丘宏丰","102830"
		Dealer.new "河北","邢台市","清河县","D2835","清河德瑞达","267571"
		Dealer.new "河北","石家庄市","裕华区","D2836","国和众现达","947582"
		Dealer.new "河北","保定市","南市区","D2837","保定嘉通","562150"
		Dealer.new "河北","唐山市","遵化市","D2838","遵化广鸿","977594"
		Dealer.new "河北","廊坊市","开发区","D2839","廊坊万运","851384"
		Dealer.new "河北","邯郸市","武安市","D2840","邯郸悦华","615141"
		Dealer.new "河北","邯郸市","复兴区","D2841","邯郸恒信","933905"
		Dealer.new "河北","石家庄市","正定县","D2842","河北正博","670416"
		Dealer.new "河北","保定市","高碑店市","D2843","高碑店盛世金鼎","296312"
		Dealer.new "河北","保定市","定州市","D2844","保定轩宇瑞浩","475405"
		Dealer.new "河北","邢台市","桥西区","D2846","邢台蓝池洋龙","498761"
		Dealer.new "河北","承德市","双桥区","D2847","承德万森","800126"
		Dealer.new "河北","廊坊市","三河市","D2848","三河和鑫","617138"
		Dealer.new "山西","太原市","小店区","D2901","山西茂元","406128"
		Dealer.new "山西","太原市","小店区","D2902","山西黄河","888523"
		Dealer.new "山西","临汾市","尧都区","D2903","临汾嘉信","150594"
		Dealer.new "山西","运城市","盐湖区","D2904","运城泽龙","896311"
		Dealer.new "山西","太原市","万柏林区","D2906","山西恒润","163168"
		Dealer.new "山西","大同市","大同市","D2907","大同国贸","109918"
		Dealer.new "山西","晋城市","晋城市","D2908","晋城澜港","805441"
		Dealer.new "山西","长治市","长治市","D2909","长治霄云","172135"
		Dealer.new "山西","晋中市","介休市","D2910","介休通鑫","149368"
		Dealer.new "山西","吕梁市","离石市","D2911","吕梁金谷泓龙","611839"
		Dealer.new "山西","阳泉市","阳泉市","D2915","阳泉鼎晟","310333"
		Dealer.new "山西","运城市","河津市","D2916","河津晋诚","819374"
		Dealer.new "山西","临汾市","尧都区","D2917","临汾天健","882671"
		Dealer.new "山西","朔州市","朔州市","D2918","朔州鹏远","213817"
		Dealer.new "山西","忻州市","开发区","D2919","忻州唯众","378254"
		Dealer.new "山西","长治市","长治市","D2920","长治云烨","764900"
		Dealer.new "山西","晋中市","榆次区","D2921","晋中香山","816810"
		Dealer.new "山西","晋城市","泽州县","D2922","晋城瀚港","883364"
		Dealer.new "山西","大同市","大同市","D2923","大同庞大明悦","160184"
		Dealer.new "山西","阳泉市","阳泉市","D2924","阳泉海东","301090"
		Dealer.new "山西","晋城市","高平市","D2925","高平丹枫","758898"
		Dealer.new "山西","运城市","盐湖区","D2926","运城彩虹","933867"
		Dealer.new "山西","运城市","盐湖区","D2927","运城鑫田","606748"
		Dealer.new "山西","太原市","万柏林区","D2928","太原汇发","129796"
		Dealer.new "山西","太原市","小店区","D2929","太原传奇","190493"
		Dealer.new "陕西","西安市","未央区","D3001","陕西福达","418795"
		Dealer.new "陕西","西安市","高新区","D3002","西安华中","586671"
		Dealer.new "陕西","西安市","新城区","D3003","陕西彤立江","958814"
		Dealer.new "陕西","榆林市","开发区","D3005","榆林志成","868439"
		Dealer.new "陕西","延安市","宝塔区","D3006","延安鸿业","126412"
		Dealer.new "陕西","宝鸡市","渭滨区","D3008","宝鸡蓝天","380930"
		Dealer.new "陕西","汉中市","开发区","D3009","汉中冀祥","572237"
		Dealer.new "陕西","西安市","沣渭新区","D3010","陕西安利达","908776"
		Dealer.new "陕西","榆林市","横山县","D3011","榆林华明","833711"
		Dealer.new "陕西","西安市","灞桥区","D3012","西安庞大明祥","881494"
		Dealer.new "陕西","安康市","高新区","D3013","安康众诚","885933"
		Dealer.new "陕西","榆林市","神木县","D3014","神木天河","953349"
		Dealer.new "陕西","商洛市","商州区","D3015","商洛泽泰源瑞","726240"
		Dealer.new "陕西","咸阳市","秦都区","D3016","咸阳荣华","826006"
		Dealer.new "陕西","西安市","雁塔区","D3018","西安泽泰瑞钢","201498"
		Dealer.new "陕西","铜川市","王益区","D3019","铜川泽泰盛世","666092"
		Dealer.new "陕西","渭南市","临渭区","D3020","渭南新盛","392743"
		Dealer.new "陕西","咸阳市","秦都区","D3021","咸阳鹏龙鸿秦","532386"
		Dealer.new "甘肃","兰州市","七里河区","D3102","兰州永丰","529001"
		Dealer.new "甘肃","兰州市","城关区","D3103","甘肃通汇","936342"
		Dealer.new "甘肃","嘉峪关市","镜铁区","D3104","嘉峪关飞瑞","210256"
		Dealer.new "甘肃","兰州市","安宁区","D3105","兰州金岛兴合","346575"
		Dealer.new "甘肃","天水市","麦积区","D3106","天水永林","940082"
		Dealer.new "甘肃","平凉市","崆峒区","D3108","平凉恒信华通","915466"
		Dealer.new "甘肃","白银市","白银区","D3109","白银恒信华通","493849"
		Dealer.new "甘肃","张掖市","甘州区","D3110","张掖银通","982063"
		Dealer.new "甘肃","定西市","安定区","D3111","定西恒信华通","384594"
		Dealer.new "甘肃","庆阳市","西峰区","D3112","庆阳天驰嘉盛","961252"
		Dealer.new "新疆","乌鲁木齐市","新市区","D4001","新疆捷康","877820"
		Dealer.new "新疆","乌鲁木齐市","水磨沟区","D4002","新疆博望","918252"
		Dealer.new "新疆","库尔勒市","库尔勒市","D4003","库尔勒永达","766662"
		Dealer.new "新疆","克拉玛依市","克拉玛依市","D4004","克拉玛依天捷","186021"
		Dealer.new "新疆","昌吉市","昌吉市","D4005","昌吉庞大全汇","187598"
		Dealer.new "新疆","阿克苏市","阿克苏市","D4006","阿克苏银丰","733026"
		Dealer.new "新疆","乌鲁木齐市","米东区","D4007","新疆天汇华嘉","775707"
		Dealer.new "新疆","哈密市","哈密市","D4008","天汇华鹏","553867"
		Dealer.new "新疆","伊宁市","伊犁市","D4009","伊犁宏威","457307"
		Dealer.new "新疆","喀什市","喀什市","D4010","喀什华力","926007"
		Dealer.new "新疆","乌鲁木齐市","新市区","D4011","新疆鸿盛丰","880408"
		Dealer.new "新疆","奎屯市","奎屯市","D4012","奎屯嘉丰","385419"
		Dealer.new "西藏","拉萨市","城关区","D4102","拉萨康达","438471"
		Dealer.new "广西","桂林市","灵川县","D4201","桂林顺景","387352"
		Dealer.new "广西","南宁市","江南区","D4202","广西通源","347049"
		Dealer.new "广西","南宁市","西乡塘区","D4203","广西鑫广达","270537"
		Dealer.new "广西","柳州市","柳南区","D4204","柳州中冠","613449"
		Dealer.new "广西","玉林市","玉州区","D4207","玉林得利","800550"
		Dealer.new "广西","柳州市","柳北区","D4208","柳州恒翔","622705"
		Dealer.new "广西","贵港市","港北区","D4209","贵港中博","882878"
		Dealer.new "广西","钦州市","钦南区","D4210","钦州恒骋","219383"
		Dealer.new "广西","梧州市","万秀区","D4211","梧州金欣","205892"
		Dealer.new "广西","南宁市","兴宁区","D4212","南宁全越","845434"
		Dealer.new "广西","河池市","金城江区","D4213","河池明远","685786"
		Dealer.new "广西","桂林市","临桂区","D4214","桂林万亚","569550"
		Dealer.new "广西","百色市","右江区","D4215","百色联泰","556466"
		Dealer.new "内蒙","包头市","青山区","D4302","包头蒙驰","776844"
		Dealer.new "内蒙","呼和浩特市","新城区","D4303","内蒙古鹏顺","130920"
		Dealer.new "内蒙","鄂尔多斯市","东胜区","D4304","鄂尔多斯蒙天","660455"
		Dealer.new "内蒙","赤峰市","红山区","D4305","赤峰蒙恒","883325"
		Dealer.new "内蒙","呼伦贝尔市","海拉尔区","D4306","呼伦贝尔友邦","160040"
		Dealer.new "内蒙","锡林郭勒盟","锡林浩特市","D4307","锡林浩特威力斯","137005"
		Dealer.new "内蒙","乌海市","海勃湾区","D4308","乌海蒙达","955545"
		Dealer.new "内蒙","呼和浩特市","回民区","D4309","内蒙古明祥","315263"
		Dealer.new "内蒙","通辽市","开发区","D4310","通辽万鑫","648546"
		Dealer.new "内蒙","鄂尔多斯市","东胜区","D4311","鄂尔多斯华明","917544"
		Dealer.new "内蒙","巴彦淖尔市","临河区","D4312","巴彦淖尔丰圣","651924"
		Dealer.new "内蒙","包头市","九原区","D4313","包头庆祥","717064"
		Dealer.new "内蒙","兴安盟","乌兰浩特市","D4314","兴安盟泰信","409331"
		Dealer.new "内蒙","乌兰察布市","集宁区","D4315","乌兰察布广鹤","280165"
		Dealer.new "内蒙","包头市","高新区","D4316","包头金冠","538912"
		Dealer.new "内蒙","呼和浩特市","新城区","D4318","呼市丰胜","142023"
		Dealer.new "内蒙","包头市","九原区","D4319","包头蒙兴","854831"
		Dealer.new "内蒙","赤峰市","红山区","D4320","赤峰泰恒","161022"
		Dealer.new "内蒙","鄂尔多斯市","东胜区","D4322","鄂尔多斯天孚","594957"
		Dealer.new "内蒙","巴彦淖尔市","开发区","D4323","巴彦淖尔利丰泰昕","900928"
		Dealer.new "宁夏","银川市","贺兰县","D4402","银川德联","297814"
		Dealer.new "宁夏","银川市","金凤区","D4403","银川好世界","935776"
		Dealer.new "宁夏","银川市","金凤区","D4404","宁夏天创","553472"
		Dealer.new "宁夏","吴忠市","利通区","D4405","吴忠恒信华通","571843"
		Dealer.new "宁夏","固原市","原州区","D4406","固原磊腾","524937"
		Dealer.new "宁夏","石嘴山市","大武口区","D4407","石嘴山京石","114002"