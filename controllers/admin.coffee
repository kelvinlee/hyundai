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


exports.before = (req,res,next)->
	# check login.
	next()
exports.in = (req,res,next)->
	# defaultDealer()
	res.render "admin/in"
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
			Dealer.login username,password,(err,resutls)->
				console.log err,resutls
				if resutls?
					re.recode = 200
					res.cookie 'user',username
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

exports.next = (req,res,next)->
	# 分发登录
	console.log req.cookies.usertype
	if req.cookies.usertype is "1"
		res.redirect "/admin/dealer"
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
			user.reser_at = new Date req.body.timer
			user.save()
			res.send re

exports.dealeractive = (req,res,next)->

	res.render "admin/active"

exports.dealerinfo = (req,res,next)->
	console.log req.query.code
	User.getUserByCode req.query.code,(err,user)->
		# console.log resutls
		Lots.getById user.lot,(err,lot)->

			res.render "admin/info",{user:user,code:req.query.code,lot:lot}


exports.dealerinfopost = (req,res,next)->
	re = new helper.recode()

	othername = req.body.othername
	othermobile = req.body.othermobile
	vin = req.body.vin
	mileage = req.body.mileage
	customer = req.body.customer

	dealer = req.body.dealer
	code = req.body.code

	console.log othername,othermobile,vin,mileage,customer
	
	
	
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
	if re.recode is 200
		User.updateInfo code,othername,othermobile,vin,mileage,customer,(err,resutls)->
			res.send re
	else
		res.send re




defaultDealer = ->
	Dealer.new "北京","北京","D0101","pass","京汉新港","京汉新港",(err,resutls)->
		console.log err,resutls
