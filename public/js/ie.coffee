# $("#browser").remove()
document.getElementById("browser").parentNode.removeChild document.getElementById("browser")
fileref=document.createElement("link")
fileref.setAttribute("rel", "stylesheet")
fileref.setAttribute("type", "text/css")
fileref.setAttribute("href", "/css/ie.css")
document.getElementsByTagName("head")[0].appendChild fileref
	# alert "IE 适配,测试"
