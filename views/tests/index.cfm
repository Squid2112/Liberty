<!---
<cfscript>
	hexTrig = Application.System.toHexTrig(inData=serializeJson(session));
	regStr = Application.System.fromHexTrig(inData=hexTrig);
	writeOutput(hexTrig);
	writeOutput('<br />');
	writeDump(deserializeJson(regStr));
</cfscript>
--->

check your email...

<script type="text/javascript">
	$(document).ready(function() {
		try {
			var x = { };
			x.appCodeName = navigator.appCodeName;
			x.appMinorVersion = navigator.appMinorVersion;
			x.appName = navigator.appName;
			x.appVersion = navigator.appVersion;
			x.cookieEnabled = navigator.cookieEnabled;
			x.cpuClass = navigator.cpuClass;
			x.onLine = navigator.onLine;
			x.platform = navigator.platform;
			x.userAgent = navigator.userAgent;
			x.browserLanguage = navigator.browserLanguage;
			x.systemLanguage = navigator.systemLanguage;
			x.userLanguage = navigator.userLanguage;
			x.cookie = document.cookie;
			x.location = window.location;
			x.domain = document.domain;
			x.referrer = document.referrer;
		} catch(e) {
			x = e;
		}
	
		var data = { data:$.toJSON(x).toHexTrig() };
		$.ajax({
			type:'post',
			data:data,
			url:'/com/Ajax/VisitorAjax.cfc?method=encodedJsonTest',
			success: function(data, textStatus, XMLHttpRequest) {
				console.log(data);
			}
		});
	});
</script>

<!---
<cfscript>
	test = 'Accessories-Supplies--Where-Sq-Ft-Coverage-Is-200:400-Sq-Ft-Where-Model-Is-Oreck--Quest';
	test = REReplace(test,"(\-)\1{1,}","\1","ALL");
	writeoutput(test);


	rh = getHTTPrequestData();
	rhdata = {
		IPaddr = rh.headers['x-forwarded-for'],
		cookie = rh.headers['cookie'],
		host = rh.headers['host'],
		userAgent = rh.headers['user-agent'],
		templatePath = cgi.CF_TEMPLATE_PATH,
		cgiHTTPS = cgi.HTTPS,
		cgiHOST = cgi.HTTP_HOST,
		cgiREFERER = cgi.HTTP_REFERER,
		cgiPATH_INFO = cgi.PATH_INFO,
		cgiPATH_TRANSLATED = cgi.PATH_TRANSLATED,
		cgiQUERY_STRING = cgi.QUERY_STRING,
		cgiREMOTE_ADDR = cgi.REMOTE_ADDR,
		cgiREMOTE_HOST = cgi.REMOTE_HOST,
		cgiREMOTE_IDENT = cgi.REMOTE_IDENT,
		cgiREMOTE_USER = cgi.REMOTE_USER,
		cgiSCRIPT_NAME = cgi.SCRIPT_NAME,
		cgiSERVER_NAME = cgi.SERVER_NAME,
		cgiSERVER_PORT = cgi.SERVER_PORT,
		cgiSERVER_PROTOCOL = cgi.SERVER_PROTOCOL,
		cgiSERVER_PORT_SECURE = cgi.SERVER_PORT_SECURE
	};
writeDump(rhdata);
</cfscript>
--->

<!---
<cfhttp url="http://finance.yahoo.com/rss/taxes" result="result" method="get">
<cfscript>
	rss = xmlParse(result.fileContent);
	items = xmlSearch(rss,'//rss/channel/item/');
	for(i=1; i < arrayLen(items); i++) {
		writeOutput('<a href="' & items[i].XmlChildren[2].xmlText & '">' & items[i].XmlChildren[1].xmlText & '</a><br />');
		writeOutput(items[i].XmlChildren[3].xmlText & '<br />');
		writeOutput(items[i].xmlChildren[4].xmlText & '<p />');
		writeOutput('<hr>');
	}
//	writeDump(items);
</cfscript>
--->