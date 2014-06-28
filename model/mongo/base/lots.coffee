mongoose = require('mongoose')
Schema = mongoose.Schema
ObjectId = Schema.Types.ObjectId

LotsSchema = new Schema({
  lotname:{type:String}
  description:{type:String}
  cartype:{type:Boolean}
  nums: [{type:Number}]
  create_at: {type:Date, default:new Date()}
})

mongoose.model('Lots', LotsSchema)
