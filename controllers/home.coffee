# 基本类库
fs = require 'fs'
path = require 'path'
crypto = require 'crypto'
helper = require '../lib/helper'
URL = require 'url'
http = require 'http'

# 扩展类库
EventProxy = require 'eventproxy'
config = require('../config').config

# 数据库
User = require("../model/mongo").User
Lots = require("../model/mongo").Lots

str="qwertyuiopasdfghjklmnbvcxz1234567890"



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

exports.index = (req,res,next)->
	
	# sendMSG "Code:test,这是一条测试短信,试试中文好使么?",18610508726

	code = getCode()

	setDefaultLots()

	ep = new EventProxy.create "count","used","tenoff",(count,used,tenoff)->
		
		# addNewUser()
		list = getList count,used
		
		# console.log list,count
		# list 查看是否可以使用此奖品.
		# 如果can是false表示已经发放完了.
		can = true
		can = false if tenoff>=100000
		res.render "homepage",{code:code,list:list,count:count,tenoffcan:can}


	Lots.used (err,used)->
		ep.emit "used",used 
	Lots.count (err,count)->
		ep.emit "count",count 

	# User.getUserByCode code,(err,results)->
		# console.log results

	User.getTenoff (err,results)->
		console.log err,results
		ep.emit "tenoff",results

exports.success = (req,res,next)->
	res.render "success",{code:req.query.code}

exports.notfind = (req,res,next)->

	res.render "404"

# 测试用
addNewUser = ->
	list = ["53a7ea6a09b0d22c2ad93ee2","53a7ea6a09b0d22c2ad93ee1","53a7ea6a09b0d22c2ad93ee4","53a7ea6a09b0d22c2ad93ee3"]

	code = getCode()
	username = "李"+helper.random(1,99)
	mobile = helper.random(13000000000,1999999999)
	changed = if helper.random(1,2) is 1 then true else false
	cartype = ""+helper.random(1,6)
	lot = list[helper.random(1,4)-1]
	tenoff = false
	thirtytwo = "all"
	province = "北京"
	city = "北京"
	dealer = "经销商"
	dealer_id = "id"

	User.newReg code,username,mobile,changed,cartype,lot,tenoff,thirtytwo,province,city,dealer,dealer_id,(err,results)->
		console.log err,results

setDefaultLots = ->
	Lots.count (err,results)->
		if results? and results.length>=1
			console.log "奖品已存在."
		else
			# 24000,8500,5000,6000,1500,5000
			Lots.new {lotname:"雨刮片",description:"安装在前挡风玻璃前，下雨时刮除前挡风玻璃上的雨水，确保前方视野的清晰度。",cartype:true,nums:[24000,8500,5000,6000,1500,5000]},(err,results)->
				console.log results
			# 22500,11500,5000,6000,0,5000
			Lots.new {lotname:"空调滤芯",description:"过滤从外界进入车厢内部的空气，使空气的洁净度提高，一般的过滤物质是指空气中所包含的杂质，微小颗粒物、花粉、细菌、工业废气和灰尘等。",cartype:true,nums:[22500,11500,5000,6000,0,5000]},(err,results)->
				console.log results
			# 100000
			Lots.new {lotname:"室内消毒剂",description:"快速清除空调风口及室内有害细菌病毒。",cartype:false,nums:[100000]},(err,results)->
				console.log results
			# 100000
			Lots.new {lotname:"汽油清净剂",description:"偏重于节油性能的超短期添加剂，改善气缸摩擦，1.提高动力性，燃油经济性；2.保持进气阀、喷油嘴、燃烧室清洁。",cartype:false,nums:[100000]},(err,results)->
				console.log results


getCode = ->
	code = parseInt(new Date().getTime()/100)
	code = parseInt(code).toString(32);
	reg = /(\w{1})(\w{6})/
	code = code.replace reg,str[helper.random(1,36)]+"$2"


exports.post = (req,res,next)->
	re = new helper.recode()
	code = getCode()
	username = req.body.username
	mobile = req.body.mobile
	changed = req.body.changed
	cartype = req.body.cartype
	lot = req.body.lot
	tenoff = req.body.tenoff
	thirtytwo = req.body.thirtytwo
	province = req.body.province
	city = req.body.city
	dealer = req.body.dealer
	# dealer_id = req.body.dealer_id
	thir = req.body.thir




	# console.log "post: ",req.body
	# res.send {recode:201,reason:"error"}
	# return ""
	# if req.body.thir.length < 32
	# 	re.recode = 203
	# 	re.reason = "32项检查格式不正确"
	# 	
	User.reged mobile,(err,results)->
		if results?
			re.recode = 202
			re.reason = "此手机号码已经注册过了1."
			res.send re
			return ""
		else
			if not username? or username is ""
				re.recode = 201
				re.reason = "用户名不能为空"
			if not mobile? or mobile is ""
				re.recode = 201
				re.reason = "手机号码不能为空"
			if not changed? or changed is "" or changed is "no"
				changed = false
			else
				changed = true 
			if not cartype? or cartype is "" or cartype is "请选择车型"
				re.recode = 201
				re.reason = "请选择车型"
			if not lot?
				lot = ""
			if not tenoff? or tenoff is "" or tenoff is "false"
				tenoff = false
			else
				tenoff = true
			if not province? or province is "" or province is "省份/直辖市"
				re.recode = 201
				re.reason = "请选择省份"
			if not city? or city is "" or city is "城市"
				re.recode = 201
				re.reason = "请选择城市"
			if not dealer? or dealer is "" or dealer is "店名"
				re.recode = 201
				re.reason = "请选择经销商"
				
			if lot? and lot is "53b18294ecfe820279c03331" and cartype is "5"
				re.recode = 201
				re.reason = "您选择奖品已经派放完了,请刷新页面选择其它奖品."



			if re.recode is 200
				ep = new EventProxy.create "count","used","user","tenoffcount", (count,used,user,tenoffcount)->
					# console.log count,used,cartype
					if tenoffcount>=100000
						re.recode = 201
						re.reason = "您选择的原厂保养配件已经派发完了"
						res.send re
						return ""
					if user?
						re.recode = 202
						re.reason = "此手机号码已经注册过了."
						res.send re
						return ""
					else
						list = getList count,used
						for a in list
							if a.lot+"" is lot+"" and a.cartype is cartype and not a.can
								re.recode = 210
								re.reason = "您选择奖品已经派放完了,请刷新页面选择其它奖品."
							if a.lot+"" is lot+"" and not a.cartype? and not a.can
								re.recode = 210
								re.reason = "您选择奖品已经派放完了,请刷新页面选择其它奖品."

						if re.recode is 200 
							User.reged mobile,(err,results)->
								if results?
									re.recode = 210
									re.reason = "此手机号码已经注册过了"
									res.send re
									return ""
								else
									User.newReg code,username,mobile,changed,cartype,lot,tenoff,thirtytwo,province,city,dealer,thir,(err,results)->
										console.log err,results
										if results?
											res.cookie "mobile",mobile
											res.cookie "code",code
											content = "【北京现代感恩活动验证码#{code}】请妥善保存。7月16日-8月31日期间凭此码到您选择的经销商处参加此次活动。感谢您的参与。"
											sendMSG content,mobile
											re.reason = code
											res.send re
											return ""
										else
											re.recode = 210
											re.reason = "连接失败,请重试."
											res.send re
						else
							res.send re
				User.reged mobile,(err,results)->
					ep.emit "user",results
				Lots.used (err,used)->
					ep.emit "used",used
				Lots.count (err,count)->
					ep.emit "count",count
				User.getTenoff (err,results)->
					console.log err,results
					ep.emit "tenoffcount",results

			else
				res.send re

exports.backcode = (req,res,next)->
	mobile = req.query.mobile
	re = new helper.recode()

	if not mobile? or mobile is ""
		re.recode = 201
		re.reason = "手机号码不能为空"
		return res.send re

	User.getUserByMobile mobile,(err,user)->
		console.log err,user
		if user?
			code = user.code
			content = "【北京现代感恩活动验证码#{code}】请妥善保存。7月16日-8月31日期间凭此码到您选择的经销商处参加此次活动。感谢您的参与。"
			sendMSG content,mobile
			res.send re
		else
			re.recode = 201
			re.reason = "您并没有注册过此次活动"
			res.send re


# http://116.213.72.20/SMSHttpService/send.aspx
# 短信发送
# http://116.213.72.20/SMSHttpService/send.aspx?username=#{username}&password=#{password}&mobile=#{mobile}&content=#{content}&Extcode=&senddate=&batchID=
# username={username}&password={password}&mobile={mobile}&content={content}&Extcode=106&senddate=
msgurl = "http://116.213.72.20/SMSHttpService/send.aspx?"

sendMSG = (content,mobile)->
	u = URL.parse msgurl
	 # p = if u['port'] then u['port'] else 80
	pa = "username={username}&password={password}&mobile={mobile}&content={content}&Extcode=106"
	pa = pa.replace "{username}",config.msguser
	pa = pa.replace "{password}",config.msgpass
	pa = pa.replace "{mobile}",mobile
	pa = pa.replace "{content}",encodeURIComponent content

	post_data = 
		success:"test"
	op = 
		hostname: u['host']
		port: 80
		path: u['path']+pa
		method: 'POST'
	# console.log op,pa
	request = http.request op, (res)->
		# console.log "statusCode: ",res.statusCode
		# console.log "headers: ",res.headers

		res.on 'data', (chunk)->
			obj = JSON.parse chunk
			console.log obj
	# console.log JSON.stringify post_data
	request.write JSON.stringify(post_data)+'\n'
	request.end()

