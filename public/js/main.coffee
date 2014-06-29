# here is your CoffeeScript.
# @codekit-prepend "coffee/plugs.coffee";

# already = false
if typeof window.addEventListener isnt "undefined"
	document.addEventListener 'WeixinJSBridgeReady', ->
		WeixinJSBridge.call 'hideToolbar'

$(document).ready ->

	# alert _pc["广东"]["茂名市"]["茂南区"][0].name

	setCartype()
	bindstepbystep()
	fBindFormBtn()

	if gico.mobilecheck()
		$(".mobilestep1").show()
		$(".mobilestep2").hide()


	if myK("province")
		# myK("province").innerHTML = fGetHTMLP()
		$("#province").html fGetHTMLP()
		# myK("city").innerHTML = fGetHTMLC myK("province").value
		$("#city").html fGetHTMLC myK("province").value
		# myK("county").innerHTML = fGetHTMLT myK("province").value,myK("city").value
		$("#county").html fGetHTMLT myK("province").value,myK("city").value
		# console.log myK("county").value
		# myK("dealer").innerHTML = fGetHTMLS myK("province").value,myK("city").value,myK("county").value
		$("#dealer").html fGetHTMLS myK("province").value,myK("city").value,myK("county").value
		# console.log myK("county").value
		myK("province").onchange = ->
			setTimeout ->
				$("#city").html fGetHTMLC myK("province").value
				$("#county").html fGetHTMLT myK("province").value,myK("city").value
				$("#dealer").html fGetHTMLS myK("province").value,myK("city").value,myK("county").value
				$('#city').change()
				$("#county").change()
				$('#dealer').change() 
			,20
		myK("city").onchange = ->
			setTimeout -> 
				# myK("dealer").innerHTML = fGetHTMLS myK("province").value,myK("city").value,myK("county").value
				# $('#dealer').change()
				# $("#county").html = fGetHTMLT myK("province").value,myK("city").value
				# $("#dealer").html = fGetHTMLS myK("province").value,myK("city").value,myK("county").value
				# console.log myK("province").value,myK("city").value,myK("county").value
				# $("#county").change()
				# $('#dealer').change()

				# $("#city").html fGetHTMLC myK("province").value
				$("#county").html fGetHTMLT myK("province").value,myK("city").value
				$("#dealer").html fGetHTMLS myK("province").value,myK("city").value,myK("county").value
				# $('#city').change()
				$("#county").change()
				$('#dealer').change() 
			,20
		myK("county").onchange = ->
			setTimeout ->
				# $("#dealer").html = fGetHTMLS myK("province").value,myK("city").value,myK("county").value
				# $('#dealer').change()
				# $("#city").html fGetHTMLC myK("province").value
				# $("#county").html fGetHTMLT myK("province").value,myK("city").value
				$("#dealer").html fGetHTMLS myK("province").value,myK("city").value,myK("county").value
				# $('#city').change()
				# $("#county").change()
				$('#dealer').change() 
			,20
		# myK("type").innerHTML = fGetCarTypeHTML()
		# myK("cartype").innerHTML = fGetCarTypeHTMLS myK("type").value
		# myK("type").onchange = ->
			# setTimeout ->
			# 	myK("cartype").innerHTML = fGetCarTypeHTMLS myK("type").value
			# 	# $("#type").change()
			# 	$("#cartype").change()
			# ,20

	gico.fBindSelect $ 'select'
	gico.fBindCheckBox $ 'input[type=checkbox]'
	gico.fBindRadio $ 'input[type=radio]'
	# gico.fBindCheckbox $ '[type=checkbox]'
	$(".m-btn").click ->
		$(".m-content").addClass "hidden"
		$(this).next().removeClass "hidden"

myK = (id)->
	document.getElementById(id)
fBindFormBtn = ->
	$('[name=submit]').click ->
		return alert '姓名不能为空' if $('[name=username]').val().length <=0
		# return alert '请选择性别' if $('[name=sex]').val().length <=0
		return alert '手机号码不能为空' if $('[name=mobile]').val().length <=0
		return alert '手机号码必须是11位数字' if $('[name=mobile]').val().length isnt 11 
		# return alert '邮箱地址不能为空' if $('[name=email]').val().length <=0
		# reg = /^([a-zA-Z0-9]+[_|\_|\.]?)*[a-zA-Z0-9]+@([a-zA-Z0-9]+[_|\_|\.]?)*[a-zA-Z0-9]+\.[a-zA-Z]{2,3}$/
		# return alert '邮箱格式不正确' if not reg.test $('[name=email]').val() 2580
		# return alert '请选择欲购车时间' if $('[name=buytime]').val().length <=0
		# return alert '请选择感兴趣车型' if $('[name=cartype]').val().length <=0
		# return alert '请选择感兴趣车系' if $('[name=hope]').val().length <=0
		return alert '请选择省份' if $('[name=province]').val() is "省份"
		return alert '请选择城市' if $('[name=city]').val() is "城市"
		return alert '请选择经销商' if $('[name=dealer]').val() is "经销商"
		# return alert '请选择车系' if $('[name=type]').val() is "选择车系"
		# return alert '请选择车型' if $('[name=cartype]').val() is "选择车型"
		# return alert '请选择欲购车时间' if $('[name=buytime]').val() is "欲购车时间"
		# console.log $('[name=register]').serializeArray()
		# alert $("[name=lot]").val()
		# return false

		$.ajax
			url:$('[name=register]').attr "action"
			type: 'POST'
			data: $('[name=register]').serializeArray()
			dataType: 'json',
			context: $('body'), 
			success: (msg)->
				# console.log msg
				if msg.recode is 200 
					# alert '预约成功'
					# $(".resertform").html '<img src="img/success-text.png" class="formsuccess" />'
					window.location.href = "/success?code="+msg.reason
				else
					alert msg.reason
		return false

setCartype = ->
	for a in _car_type
	  $("[name=cartype]").append "<option value='#{a.type}'>#{a.name}</option>"
checklots = ->
	$(".lot-item").show()
	$(".lot-item input").removeAttr "checked"
	console.log lots
	_cartype = $("[name=cartype]").val()

	for a in lots
		if a.cartype?
			if a.cartype is _cartype and not a.can
				$("[value=#{a.lot}]").parents(".lot-item").hide()
		else
			$("[value=#{a.lot}]").parents(".lot-item").hide() if not a.can
	for a in lotscounts
		if a.nums[parseInt(_cartype)-1] <= 0
			$("[value=#{a._id}]").parents(".lot-item").hide()

	return ""
bindstepbystep = ->
	$(".thirzk").click ->
		if $(".thirlist").is(".autohight")
			$(".thirlist").removeClass "autohight"
		else
			$(".thirlist").addClass "autohight"
	$("[name=mobilestep]").click ->
		$(".mobilestep1").hide()
		$(".mobilestep2").show()

	$("[name=step1]").click ->
		if $("[name=cartype]").val() isnt "请选择车型"
			$("[name=cartypetemp]").val(_car_type[parseInt($("[name=cartype]").val())-1].name)
			$("#cartype-show").text(_car_type[parseInt($("[name=cartype]").val())-1].name)
			$(".homepage").hide()
			$(".form-list").show()
			checklots()
			# 对比奖品,然后隐藏.
			window.scrollTo 0,1


	$("[name=step2]").click ->
		return alert "用户名不能为空" if $("[name=username]").val() is ""
		return alert '手机号码不能为空' if $('[name=mobile]').val().length <=0
		return alert '手机号码必须是11位数字' if $('[name=mobile]').val().length isnt 11 
		return alert "请选择省份" if $("[name=province]").val() is "" or $("[name=province]").val() is "省份"
		return alert "请选择城市" if $("[name=city]").val() is "" or $("[name=city]").val() is "城市"
		return alert "请选择经销商" if $("[name=dealer]").val() is "" or $("[name=dealer]").val() is "经销商"

		$("#thirthytwo-show").attr "class",$("[name=thirtytwo]").parent().attr("class")
		$(".select32 input").each (i)->
			$(".select321 li").eq(i).find("div").attr "class",$(this).parent().attr "class"
		# alert $("[name=tenoff]").parent().attr "class"

		$(".tenoff div").removeClass("checkbox-parent undefined on").attr "class",$("[name=tenoff]").parent().attr "class"
		# console.log $("[name=tenoff]").parent().attr "class"
		if $("#freelot .on").parent().length>=0
			$("#lot-show").html $("#freelot .on").parent().clone()
			$("#lot-show input").remove()

		if $("[name=changed]:checked").length <= 0
			$("#changed-show").html $("[name=changed][value="+$("[name=changed]").val()+"]").parents(".lot-item").clone()
		else
			$("#changed-show").html $("[name=changed]:checked").parents(".lot-item").clone()
			
		$("#changed-show input").remove()
		$("#username-show").text $("[name=username]").val()
		$("#mobile-show").text $("[name=mobile]").val()
		$("#province-show").html $("[name=province]").parents(".select-parent").html()
		$("#province-show").attr "class",$("[name=province]").parents(".select-parent").attr "class"
		$("#province-show select").remove()
		$("#city-show").html $("[name=city]").parents(".select-parent").html()
		$("#city-show").attr "class",$("[name=city]").parents(".select-parent").attr "class"
		$("#city-show select").remove()
		$("#county-show").html $("[name=county]").parents(".select-parent").html()
		$("#county-show").attr "class",$("[name=county]").parents(".select-parent").attr "class"
		$("#county-show select").remove()
		$("#dealer-show").html $("[name=dealer]").parents(".select-parent").html()
		$("#dealer-show").attr "class",$("[name=dealer]").parents(".select-parent").attr "class"
		$("#dealer-show select").remove()



		$(".form-list").hide()
		$(".confirm").show()
		window.scrollTo 0,1
	$(".goback").click ->
		if gico.mobilecheck()
			$(".mobilestep1").show()
			$(".mobilestep2").hide()
		$(".form-list").show()
		$(".confirm").hide()
		window.scrollTo 0,1



