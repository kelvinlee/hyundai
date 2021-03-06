// Generated by CoffeeScript 1.7.1
var arstr, crypto, decrypt, encrypt, random, recode;

crypto = require('crypto');

exports.format_date = function(date, friendly) {
  var day, hour, minute, month, mseconds, now, second, thisYear, time_std, year, _ref;
  year = date.getFullYear();
  month = date.getMonth() + 1;
  day = date.getDate();
  hour = date.getHours();
  minute = date.getMinutes();
  second = date.getSeconds();
  if (friendly) {
    now = new Date();
    mseconds = -(date.getTime() - now.getTime());
    time_std = [1000, 60 * 1000, 60 * 60 * 1000, 24 * 60 * 60 * 1000];
    if (mseconds < time_std[3]) {
      if (mseconds > 0 && mseconds < time_std[1]) {
        return Math.floor(mseconds / time_std[0]).toString() + ' 秒前';
      }
      if (mseconds > time_std[1] && mseconds < time_std[2]) {
        return Math.floor(mseconds / time_std[1]).toString() + ' 分钟前';
      }
      if (mseconds > time_std[2]) {
        return Math.floor(mseconds / time_std[2]).toString() + ' 小时前';
      }
    }
  }
  month = (month < 10 ? '0' : '') + month;
  day = (day < 10 ? '0' : '') + day;
  hour = (hour < 10 ? '0' : '') + hour;
  minute = (minute < 10 ? '0' : '') + minute;
  second = (second < 10 ? '0' : '') + second;
  thisYear = new Date().getFullYear();
  year = (_ref = thisYear === year) != null ? _ref : {
    '': year + '-'
  };
  return year + month + '-' + day + ' ' + hour + ':' + minute;
};

encrypt = function(str, secret) {
  var cipher, enc;
  cipher = crypto.createCipher('aes192', secret);
  enc = cipher.update(str, 'utf8', 'hex');
  enc += cipher.final('hex');
  return enc;
};

exports.encrypt = encrypt;

decrypt = function(str, secret) {
  var dec, decipher;
  decipher = crypto.createDecipher('aes192', secret);
  dec = decipher.update(str, 'hex', 'utf8');
  dec += decipher.final('utf8');
  return dec;
};

exports.decrypt = decrypt;

recode = function() {
  return {
    recode: 200,
    reason: "success"
  };
};

exports.recode = recode;

arstr = function(data, str) {
  var k, newdata, v;
  if (str == null) {
    str = ",";
  }
  newdata = "";
  for (k in data) {
    v = data[k];
    newdata += "`" + k + "`='" + v + "' " + str;
  }
  return newdata = newdata.substring(0, newdata.length - str.length);
};

exports.arstr = arstr;

random = function(min, max) {
  return Math.floor(Math.random() * (max - min)) + min;
};

exports.random = random;
