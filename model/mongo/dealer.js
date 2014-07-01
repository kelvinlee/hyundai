// Generated by CoffeeScript 1.7.1
var Dealer, models;

models = require('./base');

Dealer = models.Dealer;

exports.login = function(dealer, password, callback) {
  return Dealer.findOne({
    dealer_id: dealer,
    password: password
  }, callback);
};

exports.get = function(next) {
  return Dealer.find({}, next);
};

exports.getbyid = function(id, next) {
  return Dealer.findOne({
    dealer_id: id
  }, next);
};

exports.findAll = function(next) {
  return Deaker.find({}, next);
};

exports["new"] = function(province, city, county, id, name, password) {
  var d;
  d = new Dealer();
  d.province = province;
  d.city = city;
  d.dealer_id = id;
  d.password = password;
  d.dealer = name;
  d.county = county;
  return d.save();
};
