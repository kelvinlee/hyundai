mongoose = require('mongoose')
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

DealerSchema = new Schema({
  dealer_id:{type:String,index:true}
  password:{type:String}
  dealer:{type:String}
  province:{type:String}
  city:{type:String}
  county:{type:String}
  adr:{type:String}
  create_at: {type:Date, default:new Date()}
})

mongoose.model('Dealer', DealerSchema)

