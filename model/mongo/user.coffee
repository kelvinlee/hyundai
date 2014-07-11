models = require './base'
User = models.User


exports.test = (req,res,next)->
  # 和组
  # group({keyf:{username:true},key:{mobile:true},initial:{num:0},$reduce:function(doc,prev){ prev.num++ }})

exports.usercount = (next)->
    
  User.find({}).count().exec next
exports.findAll = (startime,endtime,type,callback)->
  # body...
  if startime is "" and type is "1"
    return User.find({create_at:null}).exec callback
  if startime is "" and type is "2"
    return User.find({reser_at:null}).exec callback
  if startime is "" and type is "3"
    return User.find({imp_at:null}).exec callback

  star = new Date startime
  end = new Date endtime
  # User.find {create_at:{$gte:star,$lt:end}},callback
  # console.log star,end,type,type is ""

  console.log star,end
  # {create_at:{$gte:"Fri Jul 04 2014 00:00:00 GMT+0800 (CST)",$lt:"Fri Jul 04 2014 23:59:59 GMT+0800 (CST)"}}

  if type is "" 
    return User.find({create_at:{$gte:star,$lt:end}}).sort({create_at:1}).exec callback
  if type is "1"
    User.find({create_at:{$gte:star,$lt:end}}).sort({create_at:1}).exec callback
  if type is "2"
    User.find({reser_at:{$gte:star,$lt:end}}).sort({reser_at:1}).exec callback
  if type is "3"
    User.find({imp_at:{$gte:star,$lt:end}}).sort({imp_at:1}).exec callback

exports.findPages = (startime,endtime,type,callback)->
  star = new Date startime
  end = new Date endtime
  User.find({create_at:{$gte:star,$lt:end}}).count().exec callback
exports.findPage = (startime,endtime,type,page,callback)->
  star = new Date startime
  end = new Date endtime
  size = 100
  # console.log size,page,size*page

  User.find({create_at:{$gte:star,$lt:end}}).sort({create_at:1}).skip(size*page).limit(size).exec callback


exports.getUserByCarType = (cartype,vin,callback)->
  User.findOne {cartype:cartype,vin:vin},callback

exports.otherUser = (mobile,next)->
  User.findOne {othermobile:mobile},next

exports.getUserByMobile = (mobile,next)->
  User.findOne {mobile:mobile},next

exports.getTenoff = (next)->
  User.find({tenoff:true}).count().exec next

exports.getUserByDealer = (dealer,star,size,sortfield,startime,endtime,type,search,callback)->
  # 获取经销商用户列表
  data = {dealer:dealer}
  if type? and startime?
    st = new Date startime
    et = new Date endtime
    data.create_at = {$gte:st,$lt:et} if type is "1"
    data.reser_at = {$gte:st,$lt:et} if type is "2"
    data.imp_at = {$gte:st,$lt:et} if type is "3"
  if search? and search isnt ""
    eval "data.mobile = /^"+search+"/"


  console.log data,type?,startime?,type
  User.find(data).count().exec (err,count)->
    console.log count
    # ).skip(star).limit(size).exec
    # , {'group': 'mobile'}
    # ,["_id","create_at","username","mobile","cartype","reser_at","imp_at","changed"]
    User.find data,'_id create_at username mobile cartype reser_at imp_at changed',{sort:sortfield,skip:star,limit:size}, (err,users)->
      callback err,count,users

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
  getUserByCode code,dealer_id,(err,users)->
    console.log "update2"
    console.log callback
    if users?
      User.update(
        {mobile:users.mobile},
        {$set:{othername:othername,othermobile:othermobile,vin:vin,mileage:mileage,customer:customer,imp_at:new Date(),usedby:usedby}},
        {multi:true}
        callback
      )
      # user.othername = othername
      # user.othermobile = othermobile
      # user.vin = vin
      # user.mileage = mileage
      # user.customer = customer
      # user.imp_at = new Date()
      # user.usedby = usedby
      # user.save callback
      # callback null,user
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
      callback null,null
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