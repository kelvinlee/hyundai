models = require './base'
User = models.User


exports.getUserByDealer = (dealer,callback)->
  # 获取经销商用户列表
  User.find {dealer:dealer},callback
exports.GetUserByTime = (dealer,startime,endtime,type,callback)->
  star = new Date parseInt startime
  end = new Date parseInt endtime
  if type is "1"
    User.find {dealer:dealer,create_at:{$gte:star,$lt:end}},callback
  if type is "2"
    User.find {dealer:dealer,reser_at:{$gte:star,$lt:end}},callback
  if type is "3"
    User.find {dealer:dealer,imp_at:{$gte:star,$lt:end}},callback

getUserByCode = (code,callback)->
  User.findOne {code:code},callback
exports.getUserByCode = getUserByCode

getUserById = (id,callback)->
  User.findById id,callback
exports.getUserById = getUserById

updateInfo = (code,othername,othermobile,vin,mileage,customer,callback)->
  getUserByCode code,(err,user)->
    if user?
      user.othername = othername
      user.othermobile = othermobile
      user.vin = vin
      user.mileage = mileage
      user.customer = customer
      user.imp_at = new Date()
      user.save callback
    else
      callback err,{}
exports.updateInfo = updateInfo

exports.reged = (mobile,callback)->
  User.findOne {mobile:mobile},callback

# 自助注册
exports.newReg = (code,username,mobile,changed,cartype,lot,tenoff,thirtytwo,province,city,dealer,thir,callback)->
  user = new User()
  user.code = code
  user.username = username
  user.mobile = mobile
  user.from = 1
  user.changed = changed
  user.cartype = cartype
  if lot? and lot isnt ""
    user.lot = lot
  user.tenoff = tenoff
  user.thirtytwo = thirtytwo
  user.province = province
  user.city = city
  user.dealer = dealer
  # user.dealer_id = dealer_id
  user.thir = thir

  user.save callback