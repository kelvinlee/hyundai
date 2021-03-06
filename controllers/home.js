// Generated by CoffeeScript 1.7.1
var EventProxy, Lots, URL, User, addNewUser, config, crypto, fs, getCode, getList, getNewCode, helper, http, msgurl, path, sendMSG, setDefaultLots, str, _mobile;

fs = require('fs');

path = require('path');

crypto = require('crypto');

helper = require('../lib/helper');

URL = require('url');

http = require('http');

EventProxy = require('eventproxy');

config = require('../config').config;

User = require("../model/mongo").User;

Lots = require("../model/mongo").Lots;

str = "qwertyuiopasdfghjklmnbvcxz1234567890";

getList = function(count, used) {
  var a, b, d, list, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _len5, _m, _n, _s;
  _s = new Date();
  list = [];
  for (_i = 0, _len = count.length; _i < _len; _i++) {
    d = count[_i];
    if (!d.cartype) {
      list.push({
        lot: d._id,
        used: 0,
        count: d.nums[0]
      });
    }
  }
  for (_j = 0, _len1 = used.length; _j < _len1; _j++) {
    a = used[_j];
    for (_k = 0, _len2 = count.length; _k < _len2; _k++) {
      b = count[_k];
      if (a._id.lot + "" === b._id + "") {
        if (b.cartype) {
          if (a.total >= b.nums[parseInt(a._id.cartype) - 1]) {
            a.can = false;
            list.push({
              lot: a._id.lot,
              cartype: a._id.cartype,
              used: a.total,
              count: b.nums[parseInt(a._id.cartype) - 1],
              can: false
            });
          } else {
            a.can = true;
            list.push({
              lot: a._id.lot,
              cartype: a._id.cartype,
              used: a.total,
              count: b.nums[parseInt(a._id.cartype) - 1],
              can: true
            });
          }
        }
      }
    }
  }
  for (_l = 0, _len3 = used.length; _l < _len3; _l++) {
    a = used[_l];
    if (a.can != null) {
      continue;
    }
    for (_m = 0, _len4 = list.length; _m < _len4; _m++) {
      b = list[_m];
      if (b.lot + "" === a._id.lot + "") {
        b.used += a.total;
      }
    }
  }
  for (_n = 0, _len5 = list.length; _n < _len5; _n++) {
    a = list[_n];
    if (a.used >= a.count) {
      a.can = false;
    } else {
      a.can = true;
    }
  }
  return list;
};

exports.index = function(req, res, next) {
  var code, ep, _s;
  _s = new Date();
  code = getCode();
  setDefaultLots();
  ep = new EventProxy.create("count", "used", "tenoff", function(count, used, tenoff) {
    var can, list;
    list = getList(count, used);
    can = true;
    if (tenoff >= 101305) {
      can = false;
    }
    console.log("all used:", ((new Date().getTime() - _s.getTime()) / 1000) + "s");
    return res.render("homepage", {
      code: code,
      list: list,
      count: count,
      tenoffcan: can
    });
  });
  Lots.used(function(err, used) {
    ep.emit("used", used);
    return console.log("lot used:", ((new Date().getTime() - _s.getTime()) / 1000) + "s");
  });
  Lots.count(function(err, count) {
    ep.emit("count", count);
    return console.log("count:", ((new Date().getTime() - _s.getTime()) / 1000) + "s");
  });
  return User.getTenoff(function(err, results) {
    console.log("tenoff:", ((new Date().getTime() - _s.getTime()) / 1000) + "s");
    return ep.emit("tenoff", results);
  });
};

exports.success = function(req, res, next) {
  return res.render("success", {
    code: req.query.code
  });
};

exports.notfind = function(req, res, next) {
  return res.render("404");
};

addNewUser = function() {
  var cartype, changed, city, code, dealer, dealer_id, list, lot, mobile, province, tenoff, thirtytwo, username;
  list = ["53a7ea6a09b0d22c2ad93ee2", "53a7ea6a09b0d22c2ad93ee1", "53a7ea6a09b0d22c2ad93ee4", "53a7ea6a09b0d22c2ad93ee3"];
  code = getCode();
  username = "李" + helper.random(1, 99);
  mobile = helper.random(13000000000, 1999999999);
  changed = helper.random(1, 2) === 1 ? true : false;
  cartype = "" + helper.random(1, 6);
  lot = list[helper.random(1, 4) - 1];
  tenoff = false;
  thirtytwo = "all";
  province = "北京";
  city = "北京";
  dealer = "经销商";
  dealer_id = "id";
  return User.newReg(code, username, mobile, changed, cartype, lot, tenoff, thirtytwo, province, city, dealer, dealer_id, function(err, results) {
    return console.log(err, results);
  });
};

setDefaultLots = function() {
  return Lots.count(function(err, results) {
    if ((results != null) && results.length >= 1) {
      return console.log("奖品已存在.");
    } else {
      Lots["new"]({
        lotname: "雨刮片",
        description: "安装在前挡风玻璃前，下雨时刮除前挡风玻璃上的雨水，确保前方视野的清晰度。",
        cartype: true,
        nums: [24000, 8500, 5000, 6000, 1500, 5000]
      }, function(err, results) {
        return console.log(results);
      });
      Lots["new"]({
        lotname: "空调滤芯",
        description: "过滤从外界进入车厢内部的空气，使空气的洁净度提高，一般的过滤物质是指空气中所包含的杂质，微小颗粒物、花粉、细菌、工业废气和灰尘等。",
        cartype: true,
        nums: [22500, 11500, 5000, 6000, 0, 5000]
      }, function(err, results) {
        return console.log(results);
      });
      Lots["new"]({
        lotname: "室内消毒剂",
        description: "快速清除空调风口及室内有害细菌病毒。",
        cartype: false,
        nums: [100000]
      }, function(err, results) {
        return console.log(results);
      });
      return Lots["new"]({
        lotname: "汽油清净剂",
        description: "偏重于节油性能的超短期添加剂，改善气缸摩擦，1.提高动力性，燃油经济性；2.保持进气阀、喷油嘴、燃烧室清洁。",
        cartype: false,
        nums: [100000]
      }, function(err, results) {
        return console.log(results);
      });
    }
  });
};

getNewCode = function(mobile) {
  var code;
  code = parseInt(mobile).toString(32);
  return code;
};

getCode = function() {
  var code, reg;
  code = parseInt(new Date().getTime() / 100);
  code = parseInt(code).toString(32);
  reg = /(\w{1})(\w{6})/;
  return code = code.replace(reg, str[helper.random(1, 36)] + "$2");
};

_mobile = {};

exports.post = function(req, res, next) {
  var cartype, changed, city, dealer, lot, mobile, province, re, tenoff, thir, thirtytwo, username;
  re = new helper.recode();
  username = req.body.username;
  mobile = req.body.mobile;
  changed = req.body.changed;
  cartype = req.body.cartype;
  lot = req.body.lot;
  tenoff = req.body.tenoff;
  thirtytwo = req.body.thirtytwo;
  province = req.body.province;
  city = req.body.city;
  dealer = req.body.dealer;
  thir = req.body.thir;
  re.recode = 202;
  re.reason = "活动已经结束,无法注册了.";
  return res.send(re);
};

exports.backcode = function(req, res, next) {
  var mobile, re;
  mobile = req.query.mobile;
  re = new helper.recode();
  if ((mobile == null) || mobile === "") {
    re.recode = 201;
    re.reason = "手机号码不能为空";
    return res.send(re);
  }
  return User.getUserByMobile(mobile, function(err, user) {
    var code, content, msgcode;
    console.log(err, user);
    if (user != null) {
      code = user.code;
      msgcode = code.split("").join(" ");
      content = "【北－京－现－代】验证码:" + msgcode + "。7月16日-8月31日凭此码到您选择的经销商处参加此次活动。感谢参与。";
      sendMSG(content, mobile);
      return res.send(re);
    } else {
      re.recode = 201;
      re.reason = "您并没有注册过此次活动";
      return res.send(re);
    }
  });
};

msgurl = "http://116.213.72.20/SMSHttpService/send.aspx?";

sendMSG = function(content, mobile) {
  var op, pa, post_data, request, u;
  u = URL.parse(msgurl);
  pa = "username={username}&password={password}&mobile={mobile}&content={content}&Extcode=106";
  pa = pa.replace("{username}", config.msguser);
  pa = pa.replace("{password}", config.msgpass);
  pa = pa.replace("{mobile}", mobile);
  pa = pa.replace("{content}", encodeURIComponent(content));
  post_data = {
    success: "test"
  };
  op = {
    hostname: u['host'],
    port: 80,
    path: u['path'] + pa,
    method: 'POST'
  };
  request = http.request(op, function(res) {
    return res.on('data', function(chunk) {
      var obj;
      obj = JSON.parse(chunk);
      return console.log(obj);
    });
  });
  request.write(JSON.stringify(post_data) + '\n');
  return request.end();
};
