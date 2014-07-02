models = require './base'
User = models.User


exports.test = (req,res,next)->
  # 和组
  # group({keyf:{username:true},key:{mobile:true},initial:{num:0},$reduce:function(doc,prev){ prev.num++ }})


exports.findAll = (startime,endtime,next)->
  # body...
  star = new Date startime
  end = new Date endtime
  console.log star,end
  User.find {create_at:{$gte:star,$lt:end}},next
exports.getUserByCarType = (cartype,vin,callback)->
  User.findOne {cartype:cartype,vin:vin},callback

exports.otherUser = (mobile,next)->
  User.findOne {othermobile:mobile},next

exports.getUserByMobile = (mobile,next)->
  User.findOne {mobile:mobile},next

exports.getTenoff = (next)->
  User.find({tenoff:true}).count().exec next

exports.getUserByDealer = (dealer,callback)->
  # 获取经销商用户列表
  User.find({dealer:dealer}).exec callback
exports.GetUserByTime = (dealer,startime,endtime,type,callback)->

  if startime is "" and type is "1"
    return User.find {dealer:dealer,create_at:null},callback
  if startime is "" and type is "2"
    return User.find {dealer:dealer,reser_at:null},callback
  if startime is "" and type is "3"
    console.log type,startime
    return User.find {dealer:dealer,imp_at:null},callback

  star = new Date parseInt startime
  end = new Date parseInt endtime
  if type is "1"
    User.find {dealer:dealer,create_at:{$gte:star,$lt:end}},callback
  if type is "2"
    User.find {dealer:dealer,reser_at:{$gte:star,$lt:end}},callback
  if type is "3"
    User.find {dealer:dealer,imp_at:{$gte:star,$lt:end}},callback

getUserByCode = (code,dealer,callback)->
  User.findOne {code:code,dealer:dealer},callback
exports.getUserByCode = getUserByCode

getUserById = (id,callback)->
  User.findById id,callback
exports.getUserById = getUserById

updateInfo = (code,dealer_id,othername,othermobile,vin,mileage,customer,usedby,callback)->
  getUserByCode code,dealer_id,(err,user)->
    if user?
      user.othername = othername
      user.othermobile = othermobile
      user.vin = vin
      user.mileage = mileage
      user.customer = customer
      user.imp_at = new Date()
      user.usedby = usedby
      user.save callback
    else
      callback err,{}
exports.updateInfo = updateInfo

reged = (mobile,callback)->
  User.findOne {mobile:mobile},callback
exports.reged = reged
  # body...

# 999注册
exports.newUserNice = (code,dealer,thir,cartype,othername,othermobile,vin,mileage,customer,callback)->
  user = new User()
  user.code = code
  user.dealer = dealer
  user.othername = othername
  user.othermobile = othermobile
  user.vin = vin
  user.mileage = mileage
  user.customer = customer
  user.thir = thir
  user.cartype = cartype
  user.imp_at = new Date()
  user.save callback

# 自助注册
exports.newReg = (code,username,mobile,changed,cartype,lot,tenoff,thirtytwo,province,city,dealer,thir,callback)->
  reged mobile,(err,results)->
    if results?
      callback null,{}
    else
      user = new User()
      user.code = code
      user.username = username
      user.mobile = mobile
      user.from = 1
      user.changed = changed
      user.cartype = cartype
      if lot? and lot isnt ""
        console.log "选择了奖品:",lot
        user.lot = lot
      user.tenoff = tenoff
      user.thirtytwo = thirtytwo
      user.province = province
      user.city = city
      user.dealer = dealer
      # user.dealer_id = dealer_id
      user.thir = thir
      user.create_at = new Date()

      user.save callback