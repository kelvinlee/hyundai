mongoose = require('mongoose')
Schema = mongoose.Schema
ObjectId = Schema.Types.ObjectId

UserSchema = new Schema({
	# 随机码
  code:{type:String,index:true}
  username:{type:String}
  mobile:{type:String}
  # 到店人,客服代表
  othername:{type:String}
  othermobile:{type:String}
  customer:{type:String}
  mileage:{type:String}
  # 是否已经实施过了
  usedby:{type:Boolean,default:false}
  # 来自,客服还是自助注册
  from:{type:Number}
  # 置换
  changed:{type:Boolean,default:false}
  # 车型
  cartype:{type:String}
  # 奖品 ObjectId
  lot:{type:ObjectId, ref:"Lots"}
  # 9折保养
  tenoff:{type:Boolean,default:false}
  # 32项
  thirtytwo: {type:String}
  thir: [{type:String}]
  usedbynine:{type:Boolean,default:false}

  province:{type:String}
  city:{type:String}
  dealer:{type:String}
  dealer_name:{type:String} #,ref:dealer

  vin: {type:String}

  # 实施时间
  imp_at:{type:Date}
  # 预约时间
  reser_at: {type:Date}
  create_at: {type:Date, default:new Date()}
})

mongoose.model('User', UserSchema)

