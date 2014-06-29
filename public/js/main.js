// Generated by CoffeeScript 1.7.1

/*
--------------------------------------------
     Begin plugs.coffee
--------------------------------------------
 */
var DMHandler, Giccoo, SHAKE_THRESHOLD, bindstepbystep, checklots, deviceMotionHandler, fBindFormBtn, gico, last_update, last_x, last_y, last_z, myK, setCartype, _x, _y, _z;

Giccoo = (function() {
  function Giccoo(name) {
    this.name = name;
  }

  Giccoo.prototype.weixin = function(callback) {
    return document.addEventListener('WeixinJSBridgeReady', callback);
  };

  Giccoo.prototype.weixinHide = function() {
    return document.addEventListener('WeixinJSBridgeReady', function() {
      return WeixinJSBridge.call('hideToolbar');
    });
  };

  Giccoo.prototype.cWeek = function(week, pre) {
    if (pre == null) {
      pre = "周";
    }
    if (week === 1) {
      return pre + "一";
    }
    if (week === 2) {
      return pre + "二";
    }
    if (week === 3) {
      return pre + "三";
    }
    if (week === 4) {
      return pre + "四";
    }
    if (week === 5) {
      return pre + "五";
    }
    if (week === 6) {
      return pre + "六";
    }
    if (week === 0) {
      return pre + "日";
    }
  };

  Giccoo.prototype.getRandom = function(max, min) {
    return parseInt(Math.random() * (max - min + 1) + min);
  };

  Giccoo.prototype.getRandoms = function(l, min, max) {
    var i, idx, isEqu, num, val, _i, _j, _ref;
    num = new Array();
    for (i = _i = 0; 0 <= l ? _i < l : _i > l; i = 0 <= l ? ++_i : --_i) {
      val = Math.ceil(Math.random() * (max - min) + min);
      isEqu = false;
      for (idx = _j = 0, _ref = num.length; 0 <= _ref ? _j < _ref : _j > _ref; idx = 0 <= _ref ? ++_j : --_j) {
        if (num[idx] === val) {
          isEqu = true;
          break;
        }
      }
      if (isEqu) {
        _i--;
      } else {
        num[num.length] = val;
      }
    }
    return num;
  };

  Giccoo.prototype.getParam = function(name) {
    var r, reg;
    reg = new RegExp("(^|&)" + name + "=([^&]*)(&|$)", "i");
    r = window.location.search.substr(1).match(reg);
    if (r !== null) {
      return unescape(r[2]);
    }
    return null;
  };

  Giccoo.prototype.checkOrientation = function() {
    var orientationChange, reloadmeta;
    orientationChange = function() {
      switch (window.orientation) {
        case 0:
          return reloadmeta(640, 0);
        case 90:
          return reloadmeta(641, "no");
        case -90:
          return reloadmeta(641, "no");
      }
    };
    reloadmeta = function(px, us) {
      return setTimeout(function() {
        var viewport;
        viewport = document.getElementsByName("viewport")[0];
        return viewport.content = "width=" + px + ", user-scalable=" + us + ", target-densitydpi=device-dpi";
      }, 100);
    };
    window.addEventListener('load', function() {
      orientationChange();
      return window.onorientationchange = orientationChange;
    });
    return window.addEventListener("load", function() {
      return setTimeout(function() {
        return window.scrollTo(0, 1);
      });
    });
  };

  Giccoo.prototype.BindShare = function(content, url, pic) {
    var $ep, list;
    if (url == null) {
      url = window.location.href;
    }
    $ep = this;
    list = {
      "qweibo": "http://v.t.qq.com/share/share.php?title={title}&url={url}&pic={pic}",
      "renren": "http://share.renren.com/share/buttonshare?title={title}&link={url}&pic={pic}",
      "weibo": "http://v.t.sina.com.cn/share/share.php?title={title}&url={url}&pic={pic}",
      "qzone": "http://sns.qzone.qq.com/cgi-bin/qzshare/cgi_qzshare_onekey?url={url}&title={title}&pic={pic}",
      "facebook": "http://www.facebook.com/sharer/sharer.php?s=100&p[url]={url}}&p[title]={title}&p[summary]={title}&pic={pic}",
      "twitter": "https://twitter.com/intent/tweet?text={title}&pic={pic}",
      "kaixin": "http://www.kaixin001.com/rest/records.php?content={title}&url={url}&pic={pic}",
      "douban": "http://www.douban.com/share/service?bm=&image={pic}&href={url}&updated=&name={title}"
    };
    return $("[data-share]").unbind('click').bind('click', function() {
      var rep;
      if ($(this).attr('content')) {
        rep = $(this).attr('content');
        content = content.replace('{content}', rep);
      }
      return $ep.fShare(list[$(this).data('share')], content, url, pic);
    });
  };

  Giccoo.prototype.fShare = function(url, content, sendUrl, pic) {
    var backUrl, shareContent;
    if (pic == null) {
      pic = "";
    }
    content = content;
    shareContent = encodeURIComponent(content);
    pic = encodeURIComponent(pic);
    url = url.replace("{title}", shareContent);
    url = url.replace("{pic}", pic);
    backUrl = encodeURIComponent(sendUrl);
    url = url.replace("{url}", backUrl);
    return window.open(url, '_blank');
  };

  Giccoo.prototype.fBindRadio = function(e) {
    var $e;
    $e = this;
    return e.each(function(i) {
      var $div, $i;
      $div = $('<div>').addClass('radio-parent ' + $(this).attr('class'));
      $i = $('<i>');
      $(this).before($div);
      $div.addClass($(this).attr('class')).append($(this));
      $div.append($i);
      if ($(this).is(':checked')) {
        $div.addClass('on');
      }
      return $(this).change(function() {
        var $o;
        $o = $(this);
        $('[name=' + $o.attr('name') + ']').parent().removeClass('on');
        return setTimeout(function() {
          if ($o.is(':checked')) {
            return $o.parent().addClass('on');
          } else {
            return $o.parent().removeClass('on');
          }
        }, 10);
      });
    });
  };

  Giccoo.prototype.fBindCheckBox = function(e) {
    var $e;
    $e = this;
    return e.each(function(i) {
      var $div, $i;
      $div = $('<div>').addClass('checkbox-parent ' + $(this).attr('class'));
      $i = $('<i>');
      $(this).before($div);
      $div.addClass($(this).attr('class')).append($(this));
      $div.append($i);
      if ($(this).is(':checked')) {
        $div.addClass('on');
      }
      return $(this).change(function() {
        var $o;
        $o = $(this);
        return setTimeout(function() {
          if ($o.is(':checked')) {
            return $o.parent().addClass('on');
          } else {
            return $o.parent().removeClass('on');
          }
        }, 10);
      });
    });
  };

  Giccoo.prototype.fBindSelect = function(e) {
    var $e;
    $e = this;
    return e.each(function(i) {
      var $div, $i, $span;
      $div = $('<div>').addClass('select-parent');
      $span = $('<span>');
      $i = $('<i>');
      $(this).before($div);
      $div.addClass($(this).attr('class')).append($(this));
      if ($(this).val()) {
        $div.append($span.append($(this).find('option[value="' + $(this).val() + '"]').text()));
      } else {
        $div.append($span.append($(this).find('option').text()));
      }
      $div.append($i);
      return $(this).change(function() {
        var $o;
        $o = $(this);
        return setTimeout(function() {
          return $e.fChangeSelectVal($o);
        }, 10);
      });
    });
  };

  Giccoo.prototype.fChangeSelectVal = function(o) {
    if ($(o).val()) {
      return $(o).next().html($(o).find('option[value="' + $(o).val() + '"]').text());
    } else {
      return $(o).next().html($(o).find('option').text());
    }
  };

  Giccoo.prototype.mobilecheck = function() {
    if (navigator.userAgent.match(/Android/i) || navigator.userAgent.match(/webOS/i) || navigator.userAgent.match(/iPhone/i) || navigator.userAgent.match(/iPad/i) || navigator.userAgent.match(/iPod/i) || navigator.userAgent.match(/BlackBerry/i) || navigator.userAgent.match(/Windows Phone/i)) {
      return true;
    }
    return false;
  };

  Giccoo.prototype.fBindOrientation = function() {
    window.addEventListener('deviceorientation', this.orientationListener, false);
    window.addEventListener('MozOrientation', this.orientationListener, false);
    return window.addEventListener('devicemotion', this.orientationListener, false);
  };

  Giccoo.prototype.orientationListener = function(evt) {
    var alpha, beta, gamma;
    if (!evt.gamma && !evt.beta) {
      evt.gamma = evt.x * (180 / Math.PI);
      evt.beta = evt.y * (180 / Math.PI);
      evt.alpha = evt.z * (180 / Math.PI);
    }
    gamma = evt.gamma;
    beta = evt.beta;
    alpha = evt.alpha;
    if (evt.accelerationIncludingGravity) {
      gamma = event.accelerationIncludingGravity.x * 10;
      beta = -event.accelerationIncludingGravity.y * 10;
      alpha = event.accelerationIncludingGravity.z * 10;
    }
    if (this._lastGamma !== gamma || this._lastBeta !== beta) {
      oriencallback(beta.toFixed(2), gamma.toFixed(2), alpha !== (null ? alpha.toFixed(2) : 0), gamma, beta);
      this._lastGamma = gamma;
      return this._lastBeta = beta;
    }
  };

  Giccoo.prototype.fBindShake = function() {
    if (window.DeviceMotionEvent) {
      return window.addEventListener('devicemotion', deviceMotionHandler, false);
    }
  };

  Giccoo.prototype.fUnBindShake = function() {
    if (window.DeviceMotionEvent) {
      return window.removeEventListener('devicemotion', deviceMotionHandler, false);
    }
  };

  return Giccoo;

})();

SHAKE_THRESHOLD = 1000;

if (navigator.userAgent.indexOf('iPhone') > -1) {
  SHAKE_THRESHOLD = 700;
} else if (navigator.userAgent.indexOf('QQ') > -1) {
  SHAKE_THRESHOLD = 1000;
}

last_update = 0;

_x = _y = _z = last_x = last_y = last_z = 0;

DMHandler = function() {};

deviceMotionHandler = function(eventData) {
  var acceleration, curTime, diffTime, speed;
  acceleration = eventData.accelerationIncludingGravity;
  curTime = new Date().getTime();
  if ((curTime - last_update) > 50) {
    diffTime = parseInt(curTime - last_update);
    last_update = curTime;
    _x = acceleration.x;
    _y = acceleration.y;
    _z = acceleration.z;
    speed = Math.abs(_x + _y + _z - last_x - last_y - last_z) / diffTime * 10000;
    console.log(_x, _y, _z);
    if (speed > SHAKE_THRESHOLD) {
      DMHandler();
    }
    last_x = _x;
    last_y = _y;
    return last_z = _z;
  }
};

gico = new Giccoo('normal');


/*
--------------------------------------------
     Begin main.coffee
--------------------------------------------
 */

document.addEventListener('WeixinJSBridgeReady', function() {
  return WeixinJSBridge.call('hideToolbar');
});

$(document).ready(function() {
  setCartype();
  bindstepbystep();
  fBindFormBtn();
  if (gico.mobilecheck()) {
    $(".mobilestep1").show();
    $(".mobilestep2").hide();
  }
  if (myK("province")) {
    myK("province").innerHTML = fGetHTMLP();
    myK("city").innerHTML = fGetHTMLC(myK("province").value);
    myK("county").innerHTML = fGetHTMLT(myK("province").value, myK("city").value);
    console.log(myK("county").value);
    myK("dealer").innerHTML = fGetHTMLS(myK("province").value, myK("city").value, myK("county").value);
    console.log(myK("county").value);
    myK("province").onchange = function() {
      return setTimeout(function() {
        myK("city").innerHTML = fGetHTMLC(myK("province").value);
        myK("county").innerHTML = fGetHTMLT(myK("province").value, myK("city").value);
        myK("dealer").innerHTML = fGetHTMLS(myK("province").value, myK("city").value, myK("county").value);
        $('#city').change();
        $("#county").change();
        return $('#dealer').change();
      }, 20);
    };
    myK("city").onchange = function() {
      return setTimeout(function() {
        myK("county").innerHTML = fGetHTMLT(myK("province").value, myK("city").value);
        $("#county").change();
        return $('#dealer').change();
      }, 20);
    };
    myK("county").onchange = function() {
      return setTimeout(function() {
        myK("dealer").innerHTML = fGetHTMLS(myK("province").value, myK("city").value, myK("county").value);
        return $('#dealer').change();
      }, 20);
    };
  }
  gico.fBindSelect($('select'));
  gico.fBindCheckBox($('input[type=checkbox]'));
  gico.fBindRadio($('input[type=radio]'));
  return $(".m-btn").click(function() {
    $(".m-content").addClass("hidden");
    return $(this).next().removeClass("hidden");
  });
});

myK = function(id) {
  return document.getElementById(id);
};

fBindFormBtn = function() {
  return $('[name=submit]').click(function() {
    if ($('[name=username]').val().length <= 0) {
      return alert('姓名不能为空');
    }
    if ($('[name=mobile]').val().length <= 0) {
      return alert('手机号码不能为空');
    }
    if ($('[name=mobile]').val().length !== 11) {
      return alert('手机号码必须是11位数字');
    }
    if ($('[name=province]').val() === "省份") {
      return alert('请选择省份');
    }
    if ($('[name=city]').val() === "城市") {
      return alert('请选择城市');
    }
    if ($('[name=dealer]').val() === "经销商") {
      return alert('请选择经销商');
    }
    $.ajax({
      url: $('[name=register]').attr("action"),
      type: 'POST',
      data: $('[name=register]').serializeArray(),
      dataType: 'json',
      context: $('body'),
      success: function(msg) {
        console.log(msg);
        if (msg.recode === 200) {
          return window.location.href = "/success?code=" + msg.reason;
        } else {
          return alert(msg.reason);
        }
      }
    });
    return false;
  });
};

setCartype = function() {
  var a, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = _car_type.length; _i < _len; _i++) {
    a = _car_type[_i];
    _results.push($("[name=cartype]").append("<option value='" + a.type + "'>" + a.name + "</option>"));
  }
  return _results;
};

checklots = function() {
  var a, _i, _len;
  $(".lot-item").show();
  $(".lot-item input").removeAttr("checked");
  for (_i = 0, _len = lots.length; _i < _len; _i++) {
    a = lots[_i];
    if (a.cartype != null) {
      if (a.cartype === $("[name=cartype]").val() && !a.can) {
        $("[value=" + a.lot + "]").parents(".lot-item").hide();
      }
    } else {
      if (!a.can) {
        $("[value=" + a.lot + "]").parents(".lot-item").hide();
      }
    }
  }
  return "";
};

bindstepbystep = function() {
  $(".thirzk").click(function() {
    if ($(".thirlist").is(".autohight")) {
      return $(".thirlist").removeClass("autohight");
    } else {
      return $(".thirlist").addClass("autohight");
    }
  });
  $("[name=mobilestep]").click(function() {
    $(".mobilestep1").hide();
    return $(".mobilestep2").show();
  });
  $("[name=step1]").click(function() {
    if ($("[name=cartype]").val() !== "请选择车型") {
      $("[name=cartypetemp]").val(_car_type[parseInt($("[name=cartype]").val()) - 1].name);
      $("#cartype-show").text(_car_type[parseInt($("[name=cartype]").val()) - 1].name);
      $(".homepage").hide();
      $(".form-list").show();
      checklots();
      return window.scrollTo(0, 1);
    }
  });
  $("[name=step2]").click(function() {
    if ($("[name=username]").val() === "") {
      return alert("用户名不能为空");
    }
    if ($("[name=mobile]").val() === "") {
      return alert("手机号码不能为空");
    }
    if ($("[name=mobile]").val() === "") {
      return alert("手机号码不能为空");
    }
    if ($("[name=province]").val() === "" || $("[name=province]").val() === "省份") {
      return alert("请选择省份");
    }
    if ($("[name=city]").val() === "" || $("[name=city]").val() === "城市") {
      return alert("请选择城市");
    }
    if ($("[name=dealer]").val() === "" || $("[name=dealer]").val() === "经销商") {
      return alert("请选择经销商");
    }
    $("#thirthytwo-show").attr("class", $("[name=thirtytwo]").parent().attr("class"));
    $(".select32 input").each(function(i) {
      return $(".select321 li").eq(i).find("div").attr("class", $(this).parent().attr("class"));
    });
    $(".tenoff div").removeClass("checkbox-parent undefined on").attr("class", $("[name=tenoff]").parent().attr("class"));
    console.log($("[name=tenoff]").parent().attr("class"));
    if ($("#freelot .on").parent().length >= 0) {
      $("#lot-show").html($("#freelot .on").parent().clone());
      $("#lot-show input").remove();
    }
    if ($("[name=changed]:checked").length <= 0) {
      $("#changed-show").html($("[name=changed][value=" + $("[name=changed]").val() + "]").parents(".lot-item").clone());
    } else {
      $("#changed-show").html($("[name=changed]:checked").parents(".lot-item").clone());
    }
    $("#changed-show input").remove();
    $("#username-show").text($("[name=username]").val());
    $("#mobile-show").text($("[name=mobile]").val());
    $("#province-show").html($("[name=province]").parents(".select-parent").html());
    $("#province-show").attr("class", $("[name=province]").parents(".select-parent").attr("class"));
    $("#province-show select").remove();
    $("#city-show").html($("[name=city]").parents(".select-parent").html());
    $("#city-show").attr("class", $("[name=city]").parents(".select-parent").attr("class"));
    $("#city-show select").remove();
    $("#county-show").html($("[name=county]").parents(".select-parent").html());
    $("#county-show").attr("class", $("[name=county]").parents(".select-parent").attr("class"));
    $("#county-show select").remove();
    $("#dealer-show").html($("[name=dealer]").parents(".select-parent").html());
    $("#dealer-show").attr("class", $("[name=dealer]").parents(".select-parent").attr("class"));
    $("#dealer-show select").remove();
    $(".form-list").hide();
    $(".confirm").show();
    return window.scrollTo(0, 1);
  });
  return $(".goback").click(function() {
    if (gico.mobilecheck()) {
      $(".mobilestep1").show();
      $(".mobilestep2").hide();
    }
    $(".form-list").show();
    $(".confirm").hide();
    return window.scrollTo(0, 1);
  });
};
