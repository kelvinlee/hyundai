// Generated by CoffeeScript 1.7.1
var User, getUserByCode, getUserById, models, updateInfo;

models = require('./base');

User = models.User;

exports.getUserByDealer = function(dealer, callback) {
  return User.find({
    dealer: dealer
  }, callback);
};

exports.GetUserByTime = function(dealer, startime, endtime, type, callback) {
  var end, star;
  star = new Date(parseInt(startime));
  end = new Date(parseInt(endtime));
  if (type === "1") {
    User.find({
      dealer: dealer,
      create_at: {
        $gte: star,
        $lt: end
      }
    }, callback);
  }
  if (type === "2") {
    User.find({
      dealer: dealer,
      reser_at: {
        $gte: star,
        $lt: end
      }
    }, callback);
  }
  if (type === "3") {
    return User.find({
      dealer: dealer,
      imp_at: {
        $gte: star,
        $lt: end
      }
    }, callback);
  }
};

getUserByCode = function(code, callback) {
  return User.findOne({
    code: code
  }, callback);
};

exports.getUserByCode = getUserByCode;

getUserById = function(id, callback) {
  return User.findById(id, callback);
};

exports.getUserById = getUserById;

updateInfo = function(code, othername, othermobile, vin, mileage, customer, callback) {
  return getUserByCode(code, function(err, user) {
    if (user != null) {
      user.othername = othername;
      user.othermobile = othermobile;
      user.vin = vin;
      user.mileage = mileage;
      user.customer = customer;
      user.imp_at = new Date();
      return user.save(callback);
    } else {
      return callback(err, {});
    }
  });
};

exports.updateInfo = updateInfo;

exports.reged = function(mobile, callback) {
  return User.findOne({
    mobile: mobile
  }, callback);
};

exports.newReg = function(code, username, mobile, changed, cartype, lot, tenoff, thirtytwo, province, city, dealer, thir, callback) {
  var user;
  user = new User();
  user.code = code;
  user.username = username;
  user.mobile = mobile;
  user.from = 1;
  user.changed = changed;
  user.cartype = cartype;
  if ((lot != null) && lot !== "") {
    user.lot = lot;
  }
  user.tenoff = tenoff;
  user.thirtytwo = thirtytwo;
  user.province = province;
  user.city = city;
  user.dealer = dealer;
  user.thir = thir;
  return user.save(callback);
};
