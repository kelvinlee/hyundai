$("#browser").remove()
fileref=document.createElement("link")
fileref.setAttribute("rel", "stylesheet")
fileref.setAttribute("type", "text/css")
fileref.setAttribute("href", "/css/ie.css")
document.getElementsByTagName("head")[0].appendChild fileref
$(document).ready ->
	# alert "IE 适配,测试"
