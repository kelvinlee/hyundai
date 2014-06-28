mongoose = require('mongoose')
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

ServSchema = new Schema({
  username:{type:String}
  password:{type:String}
  # 1是客服,2是管理员
  type:{type:Number}
  create_at: {type:Date, default:new Date()}
})

mongoose.model('Serv', ServSchema)
