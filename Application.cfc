component output='no' {

	this.Name = 'Liberty';
	this.applicationName = 'Liberty';
	this.applicationTimeout = createTimeSpan(2,0,0,0);
	this.sessionManagement = true;
	this.sessionTimeout = createTimespan(0,1,0,0);
	this.clientManagement = false;
	this.setClientCookies = true;
	this.setDomainCookies = true;
	this.scriptProtect = 'ALL';
	this.customTagPaths = expandPath('/com/tagLibrary/');


// ---------------------< onApplicationStart >---------------------
	public boolean function onApplicationStart() {
		var errorLog = '';
		var mailService = new Mail();
		var result = '';

		// ---------------------< Application.Settings >---------------------
		Application.Settings = {
			sessionTimeoutMinutes = (timeFormat(this.sessionTimeout,'h') * 60) + timeFormat(this.sessionTimeout,'m'),
			sessionTimeoutSeconds = ((timeFormat(this.sessionTimeout,'h') * 60) + timeFormat(this.sessionTimeout,'m')) * 60,
			isDevEnvironment = true,
			combineJs = false,
			combineCss = false,
			compressJs = true,
			compressCss = true,
			pageCompress = true,
			gZip = true,
			rootPath = expandPath('/'),
			serverId = replace(Server.ColdFusion.ProductName & '-' & Server.ColdFusion.ProductLevel & '-' & Server.ColdFusion.ProductVersion,' ','','ALL'),
			serverIp = trim(listLast(createObject('java','java.net.InetAddress').getLocalHost(),'/')),

			useLogFile = true,
			logFile = expandPath('/') & 'frameworkError.log',
			isMailAvailable = false,
			emailLists = { info='hostmaster@thixo.net', errors='hostmaster@thixo.net', warnings='hostmaster@thixo.net', debug='hostmaster@thixo.net' },
			authorizations = {  // Hashed with 'SHA-256'
				reset='842996B63D5454AC176182A302BD2273CC7EBF04EE487B53FA7CEA8079BDFDFD',  // frisbee
				debug='842996B63D5454AC176182A302BD2273CC7EBF04EE487B53FA7CEA8079BDFDFD',
				cache='842996B63D5454AC176182A302BD2273CC7EBF04EE487B53FA7CEA8079BDFDFD',
				combine='842996B63D5454AC176182A302BD2273CC7EBF04EE487B53FA7CEA8079BDFDFD',
				compress='842996B63D5454AC176182A302BD2273CC7EBF04EE487B53FA7CEA8079BDFDFD',
				gzip='842996B63D5454AC176182A302BD2273CC7EBF04EE487B53FA7CEA8079BDFDFD',
				showErrors='842996B63D5454AC176182A302BD2273CC7EBF04EE487B53FA7CEA8079BDFDFD'
			},  
			DSN = { System='liberty' },
			rootDomain = 'thixo.liberty',
			defaultConical = 'www',
			mobileConicals = { general='mobile', iphone='iphone', droid='droid' },
			forceConical = true,
			forceMobile = true,
			abuseRedirect = '',
			processExceptions = ['/com/','/ramjax','/css/','/js/','/assets/','/flex2gateway','/cfide/','favicon.ico','robots.txt'],
			processOrder = 'conical,physical,virtual,uri',
			cache = true
		};

		// ---------------------< object initializations >---------------------
		try {
			structInsert(Application,'System',createObject('component','com.System.SystemComponent').init(),true);
		} catch(Any E) {
			saveContent variable='result' { writeDump(E); }
			mailService.setTo('hostmaster@thixo.net');
			mailService.setFrom('hostmaster@thixo.net');
			mailService.setSubject('createObject(component,com.System.SystemComponent).init() error in Application.cfc');
			mailService.setType('html');
			mailService.send(body=result);
			if(Application.Settings.useLogFile) {
				errorLog = fileOpen(Application.Settings.logFile,'append');
				fileWriteLine(errorLog,dateFormat(now(),'mm/dd/yy') & '@' & timeFormat(now(),'hh:mm:tt') & ': Error instanciating com.System.System object in onApplicationStart');
				fileClose(errorLog);
			}
		}

		try {
			Application.System.loadFrameworkObjects('Application');
		} catch(Any E) {
			saveContent variable='result' { writeDump(E); }
			mailService.setTo('hostmaster@thixo.net');
			mailService.setFrom('hostmaster@thixo.net');
			mailService.setSubject('Application.System.loadFrameworkObjects(Application) error in Application.cfc');
			mailService.setType('html');
			mailService.send(body=result);
			if(Application.Settings.useLogFile) {
				errorLog = fileOpen(Application.Settings.logFile,'append');
				fileWriteLine(errorLog,dateFormat(now(),'mm/dd/yy') & '@' & timeFormat(now(),'hh:mm:tt') & ': Error executing loadFrameworkObjects(Application) in onApplicationStart');
				fileClose(errorLog);
			}
		}

		try {
			if(Application.Settings.cache) Application.System.fillCache();
		} catch(Any E) {
			saveContent variable='result' { writeDump(E); }
			mailService.setTo('hostmaster@thixo.net');
			mailService.setFrom('hostmaster@thixo.net');
			mailService.setSubject('Application.System.fillCache() error in Application.cfc');
			mailService.setType('html');
			mailService.send(body=result);
			if(Application.Settings.useLogFile) {
				errorLog = fileOpen(Application.Settings.logFile,'append');
				fileWriteLine(errorLog,dateFormat(now(),'mm/dd/yy') & '@' & timeFormat(now(),'hh:mm:tt') & ': Error executing Application.System.fillCache() in onApplicationStart');
				fileClose(errorLog);
			}
		}

		if(structKeyExists(Application,'Mail')) Application.Settings.isMailAvailable = true;
		return(true);
	}


// ---------------------< onSessionStart >---------------------
	public void function onSessionStart() {
		var errorMsg = '';
		var errorLog = '';
		var tmpFile = '';

		// ---------------------< instantiate Session Visitor object >---------------------
		if(Application.System.loadIntoRam(filePath=Application.Settings.rootPath & 'com/Visitor/VisitorObject.cfc')) {
			try {
				structInsert(Session,'Visitor',createObject('component','inram.VisitorObject').init(),true);
			} catch(Any E) {
				errorMsg = dateFormat(now(),'mm/dd/yy') & '@' & timeFormat(now(),'hh:mm:tt') & ': Error executing loadFrameworkObjects(Session) in onApplicationStart';
				if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Errors,subject='Error executing loadFrameworkObjects(Session)',msg=errorMsg,obj=E);
				if(Application.Settings.useLogFile) {
					errorLog = fileOpen(Application.Settings.logFile,'append');
					fileWriteLine(errorLog,errorMsg);
					fileClose(errorLog);
				}
			}
		}

		// ---------------------< instantiate Session objects >---------------------
		try {
			Application.System.loadFrameworkObjects('Session');
		} catch(Any E) {
			errorMsg = dateFormat(now(),'mm/dd/yy') & '@' & timeFormat(now(),'hh:mm:tt') & ': Error executing loadFrameworkObjects(Session) in onApplicationStart';
			if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Errors,subject='Error executing loadFrameworkObjects(Session)',msg=errorMsg,obj=E);
			if(Application.Settings.useLogFile) {
				errorLog = fileOpen(Application.Settings.logFile,'append');
				fileWriteLine(errorLog,errorMsg);
				fileClose(errorLog);
			}
		}

		// ---------------------< cleanup Session startup && set UUID for visitor >---------------------
		if(!structKeyExists(Session,'Visitor')) {
			structInsert(Session,'Visitor',structNew(),true);
			if(!structKeyExists(cookie,'UUID')) Application.System.setCookie(cgi=CGI,name='UUID',value=createUUID());
		}
		Session.Visitor.foo = true;
		Session.Visitor.UUID = cookie.UUID;
		Session.Visitor.debug = false;
		Session.Visitor.showErrors = false;
		Session.Visitor.inMobile = false;
		Session.vPath = '/';
		if(structKeyExists(Session.Visitor,'GeoInfo')) Session.Visitor.GeoInfo.setFromIp(Application.System.getRequestIp(cgi=CGI));
	}


// ---------------------< onRequestStart >---------------------
	public function onRequestStart(required string requestPage) {
		var item = '';
		var idx = 0;

		Request.startTime = getTickCount();

//			Application.System.XSSfilter(scopes='form|url|cookie',form=form,url=url,cookie=cookie);

		Request.isCFC = false;
		Request.isException = false;

		for(idx=1; idx <= arrayLen(Application.Settings.processExceptions); idx++) {
			if(findNoCase(Application.Settings.processExceptions[idx],Arguments.requestPage)) {
				Request.isException = true;
				structDelete(this,'onRequest',false);
				structDelete(variables,'onRequest',false);
				return(true);
			}
		}
		if(lCase(listLast(Arguments.requestPage,'.')) == 'cfc') {
			Request.isCFC = true;
			structDelete(this,'onRequest',false);
			structDelete(variables,'onRequest',false);
			return(true);
		}

		if(structKeyExists(url,'Reload')) {
			if(Application.Settings.isDevEnvironment || (structKeyExists(url,'auth') && (hash(url.auth,'SHA-256') == Application.Settings.authorizations.reset))) {
				switch(lcase(url.Reload)) {
					case 'all' :
						onApplicationStart();
						onSessionStart();
						break;
					case 'application' :
						onApplicationStart();
						break;
					case 'session' :
						onSessionStart();
						break;
					default : break;
				}
			}
		}
		if(!structKeyExists(Session,'Visitor') || !structKeyExists(Session.Visitor,'foo')) onSessionStart();
		Application.System.processUrlSwitchs(Session=Session,Url=Url);

		Request.cssQueue = createObject('java','java.util.Stack');
		Request.jsQueue = createObject('java','java.util.Stack');
		Request.taggingQueue = createObject('java','java.util.Stack');
		Request.trackingQueue = createObject('java','java.util.Stack');

		// ---------------------< instantiate Request objects >---------------------
		try {
			Application.System.loadFrameworkObjects('Request');
		} catch(Any E) {
			errorMsg = dateFormat(now(),'mm/dd/yy') & '@' & timeFormat(now(),'hh:mm:tt') & ': Error executing loadFrameworkObjects(Session) in onApplicationStart';
			if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Errors,subject='Error executing loadFrameworkObjects(Request)',msg=errorMsg,obj=E);
			if(Application.Settings.useLogFile) {
				errorLog = fileOpen(Application.Settings.logFile,'append');
				fileWriteLine(errorLog,errorMsg);
				fileClose(errorLog);
			}
		}

		// parse domain, 404 && URL information
		Request.Protocol = Application.System.getRequestProtocol(HTTPS=CGI.HTTPS,requestData=getHttpRequestData());
		Request.Conicals = duplicate(Application.System.parseConicals(rootDomain=Application.Settings.rootDomain,requestHost=CGI.SERVER_NAME));
		Request.URLparams = duplicate(Application.System.parse404(Request=Request,url=URL,queryString=CGI.QUERY_STRING));

		if(arrayLen(Request.vArray) > 1) Application.System.parseSearchUrl(Request=Request,Visitor=Session.Visitor);
		if(!Request.isException && structKeyExists(Session,'Visitor')) {
			structInsert(Session.Visitor,'url',structNew(),true);
			structAppend(Session.Visitor.url,URL,true);
		}

		if(Request.fileName != '') {
			if(!fileExists(Application.Settings.rootPath & replace(right(Request.vPath,(len(Request.vPath)-1)),'/','\','ALL'))) {
				if(listLast(Request.vPath,'.') != 'cfm') {
					Request.isException = true;
					if(isNumeric(listFirst(cgi.HTTP_HOST,'.'))) {
						if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Warnings,subject='[#cgi.SERVER_NAME#] File !found in the #this.Name# Application - Direct IP request',msg='The file "#Application.Settings.rootPath##replace(right(Request.vpath,(len(Request.vpath)-1)),"/","\","ALL")#" was !found in the #this.Name# Application at #cgi.SERVER_NAME#<br />Forwarded to #Application.Settings.abuseRedirect#');
						structDelete(this,'onRequest',false);
						structDelete(variables,'onRequest',false);
						location(Application.Settings.abuseRedirect,false);
					}
					if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Warnings,subject='[#cgi.SERVER_NAME#] File !found in the #this.Name# Application',msg='The file "#Application.Settings.rootPath##replace(right(Request.vpath,(len(Request.vpath)-1)),"/","\","ALL")#" was !found in the #this.Name# Application at #cgi.SERVER_NAME#<br />Forwarded to /Request-Not-Found');
					structDelete(this,'onRequest',false);
					structDelete(variables,'onRequest',false);
				}
				location('/Request-Not-Found',false);
			}
		}

		if(!Application.Settings.cache) Application.System.fillCache();
		// if forceConical && !accessing a conical, then redirect to default conical or if is mobile device, redirect to mobile conical
		if(Application.Settings.forceMobile && !Session.Visitor.inMobile && Application.System.isMobile(cgi=cgi)) {
			Session.Visitor.inMobile = true;
			Application.System.redirectToConical(Request=Request,CGI=CGI,conical=Application.Settings.mobileConicals.general);
		}
		if(Application.Settings.forceConical && !arrayLen(Request.Conicals)) Application.System.redirectToConical(Request=Request,CGI=CGI,conical=Application.Settings.defaultConical);

		// set up the page context && put into a Request var for manipulation
		Request.context = getPageContext();
		Request.context.setFlushOutput(false);

		Request.virtualInfo = duplicate(Application.System.virtualResolver(vPath=Request.vPath));
		if(Request.virtualInfo.URI == '') Request.virtualInfo.URI = Request.virtualInfo.viewName;

		if(structKeyExists(Request.virtualInfo,'url') && isStruct(Request.virtualInfo.url))
			for(item IN Request.virtualInfo.url)
				if(trim(Request.virtualInfo.url[item]) != '') structInsert(url,item,Request.virtualInfo.url[item],true);

		// all is good, lets send our visitor info back to the DB through the Visitor object
		if(structKeyExists(Session.Visitor,'set')) Session.Visitor.set(virtualPath=Request.vPath);

		return(true);
	}


// ---------------------< onRequest >---------------------
	public void function onRequest(required string requestPage) {
		if(!Request.isException && !Request.isCFC) {
			if(fileExists(Application.Settings.rootPath & 'views\' & Request.virtualInfo.viewName & '\' & Request.virtualInfo.viewTemplate)) {
				try {
					Application.System.writeBaseDocument(virtualInfo=Request.virtualInfo,Request=Request);
				} catch(Any e) {
					if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Errors,subject='[#cgi.SERVER_NAME#] Application Error in the #this.Name# Application',msg='There was an Application error in the #this.Name# Application at #cgi.SERVER_NAME#',obj=e);
				}
				try {
					Application.System.processView(virtualInfo=Request.virtualInfo);
				} catch(Any e) {
					if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Errors,subject='[#cgi.SERVER_NAME#] Application Error in the #this.Name# Application',msg='There was an Application error in the #this.Name# Application at #cgi.SERVER_NAME#',obj=e);
				}
			} else {
				Request.onMissing = true;
				onMissingTemplate(Arguments.requestPage);
			}
		}
	}


// ---------------------< onRequestEnd >---------------------
	public boolean function onRequestEnd() {
		if((structKeyExists(Request,'isException') && Request.isException) || (structKeyExists(Request,'isCFC') && Request.isCFC)) return(true);
		try {
			Request.endTime = getTickCount();
			if(!structKeyExists(Request,'virtualInfo')) Request.virtualInfo = duplicate(Application.System.virtualResolver(vPath=''));
			if(Application.Settings.pageCompress) Application.System.cleanPageContents(Request=Request);
			if(Session.Visitor.Debug) this.showDebug();
			Application.System.closePageContents(Request=Request);
			if(Application.Settings.gZip) Application.System.gZipPageContents(Request=Request);
			if(structKeyExists(Request,'context')) Request.context.getOut().flush();
		} catch(Any e) {
			if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Errors,subject='[#cgi.SERVER_NAME#] Application Error in the #this.Name# Application',msg='There was an Application error in the #this.Name# Application at #cgi.SERVER_NAME#',obj=e);
		}

		structDelete(Session,'Request', false);
		structDelete(this,'onRequest',false);
		structDelete(variables,'onRequest',false);
		
		return(true);
	}


// ---------------------< onSessionEnd >---------------------
	public void function onSessionEnd(required struct sessionScope, struct applicationScope) {
		// ---------------------< Request the JVM to perform garbage collection >---------------------
		// Application.System.ApplicationTracker.getApplicationScope(sessionScope).cleanup();
		createObject('Java','java.lang.System').gc();
	}


// ---------------------< onApplicationEnd >---------------------
	public void function onApplicationEnd(struct ApplicationScope=structNew()) {
		return;
	}


// ---------------------< onMissingMethod >---------------------
	public void function onMissingMethod(string methodName, any methodArguments) output='false' {
		if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Errors,subject='[#cgi.SERVER_NAME#] Missing Method Error in the #this.Name# Application',msg='There was a Missing Method error in the #this.Name# Application at #cgi.SERVER_NAME#',obj=Arguments);
		return;
	}


// ---------------------< onMissingTemplate >---------------------
	public boolean function onMissingTemplate(required string requestPage) {
		var infoStruct = { };
		var virtualMappingData = '';
		var item = '';
		var idx = 0;

		// check for virtualMapping of this request && redirect to it if found
		if(structKeyExists(Application,'Database')) {
			virtualMappingData = Application.Database.getVirtualMapping(cgi.SCRIPT_NAME);
			if(virtualMappingData.recordCount && structCount(url)) {
				location(virtualMappingData.dest[1] & '?' & cgi.QUERY_STRING,false,'301');
			} else if(virtualMappingData.recordCount) {
				location(virtualMappingData.dest[1],false,'301');
			}
		}

//			Application.System.XSSfilter(scopes='form|url|cookie',form=form,url=url,cookie=cookie);

		if(structKeyExists(url,'Reload')) {
			switch(lcase(url.Reload)) {
				case 'all' :
					onApplicationStart();
					onSessionStart();
					break;
				case 'application' :
					onApplicationStart();
					break;
				case 'session' :
					onSessionStart();
					break;
				default : break;
			}
		}
		if(!structKeyExists(Session,'Visitor') || !structKeyExists(Session.Visitor,'foo')) onSessionStart();

		// parse domain, 404 && URL information
		Request.Protocol = Application.System.getRequestProtocol(HTTPS=CGI.HTTPS,requestData=getHttpRequestData());
		Request.Conicals = duplicate(Application.System.parseConicals(rootDomain=Application.Settings.rootDomain,requestHost=CGI.SERVER_NAME));
		Request.URLparams = duplicate(Application.System.parse404(Request=Request,url=URL,queryString=CGI.QUERY_STRING));

		if(structKeyExists(Session,'Visitor')) {
			structInsert(Session.Visitor,'url',structNew(),true);
			structAppend(Session.Visitor.url,URL,true);
		}

		if(Request.fileName != '') {
			if(!fileExists(Application.Settings.rootPath & replace(right(Request.vPath,(len(Request.vPath)-1)),'/','\','ALL'))) {
				if(listLast(Request.vPath,'.') != 'cfm') {
					Request.isException = true;
					if(isNumeric(listFirst(cgi.HTTP_HOST,'.'))) {
						if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Warnings,subject='[#cgi.SERVER_NAME#] File !found in the #this.Name# Application - Direct IP request',msg='The file "#Application.Settings.rootPath##replace(right(Request.vpath,(len(Request.vpath)-1)),"/","\","ALL")#" was !found in the #this.Name# Application at #cgi.SERVER_NAME#<br />Forwarded to #Application.Settings.abuseRedirect#');
						structDelete(this,'onRequest',false);
						structDelete(variables,'onRequest',false);
						location(Application.Settings.abuseRedirect,false);
					}
					if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Warnings,subject='[#cgi.SERVER_NAME#] File !found in the #this.Name# Application',msg='The file "#Application.Settings.rootPath##replace(right(Request.vpath,(len(Request.vpath)-1)),"/","\","ALL")#" was !found in the #this.Name# Application at #cgi.SERVER_NAME#<br />Forwarded to /Request-Not-Found');
					structDelete(this,'onRequest',false);
					structDelete(variables,'onRequest',false);
				}
				location('/Request-Not-Found',false);
			}
		}

		// if forceConical && !accessing a conical, then direct to default conical
		if(Application.Settings.forceConical && !arrayLen(Request.Conicals)) Application.System.redirectToConical(Request=Request,CGI=CGI,concical=Application.Settings.defaultConical);

		Request.virtualInfo = duplicate(Application.System.virtualResolver(vPath=Request.vPath));
		if(Request.virtualInfo.URI == '') Request.virtualInfo.URI = Request.virtualInfo.viewName;

		if(structKeyExists(Request.virtualInfo,'url') && isStruct(Request.virtualInfo.url))
			for(item IN Request.virtualInfo.url)
				if(trim(Request.virtualInfo.url[item]) != '') structInsert(url,item,Request.virtualInfo.url[item],true);

		// all is good, lets send our visitor info back to the DB through the Visitor object
		if(structKeyExists(Session.Visitor,'set')) Session.Visitor.set(virtualPath=Request.vPath);

		if(Request.virtualInfo.recordCount) {
			Application.System.Wrappers.include('/Views' & Request.virtualInfo.uri & Request.virtualInfo.viewTemplate);
			return(true);
		}

		infoStruct = {
			requestPage = Arguments.requestPage,
			Request = Request,
			CGI = CGI
		};

		if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Warnings,subject='[#cgi.SERVER_NAME#] File !Found in the #this.Name# Application',msg='From Application.cfc, file was !found in the #this.Name# Application at #cgi.SERVER_NAME#',obj=infoStruct);	
		location('/',false,'301');
		
		return(true);
	}

/*
// ---------------------< onCfcRequest >---------------------
	public function onCfcRequest(required string cfcname, required string method, required string args) {
		return;
	}
*/


// ---------------------< onError >---------------------
	public void function onError(required any Exception, required string eventName) {
		var errorLog = '';

		// check to see if the root Exception is "AbortException", && if so, then simply return
		if(structKeyExists(Arguments.Exception,'rootCause') && (Arguments.Exception.rootCause == 'coldfusion.runtime.AbortException')) return(true);

		if(Session.Visitor.showErrors) {
			writeDump(Arguments.Exception);
			writeDump(Arguments.eventName);
			writeOutput('Exception occured in event: ' & Arguments.eventName);
			writeDump(Arguments.Exception);
		}
		if(structKeyExists(Application,'System')) Application.System.closePageContents(Request=Request);
		if(structKeyExists(Request,'context')) Request.context.getOut().flush();

		if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Errors,subject='[#cgi.SERVER_NAME#] Application Error in the #this.Name# Application',msg='There was an Application error in the #this.Name# Application at #cgi.SERVER_NAME#',obj=Arguments);
		if(Application.Settings.useLogFile) {
			errorLog = fileOpen(Application.Settings.logFile,'append');
			errorMsg = dateFormat(now(),'mm/dd/yy') & '@' & timeFormat(now(),'hh:mm:tt') & ': Error executing loadFrameworkObjects(Session) in onApplicationStart';
			fileWriteLine(errorLog,errorMsg);
			fileClose(errorLog);
		}
	}

// ---------------------< showDebug >---------------------
	public void function showDebug() output='yes' {
		writeOutput('<hr width="100%">');
		if(structKeyExists(Request, 'endTime')) writeOutput('Elapsed Time: ' & (Request.endTime - Request.startTime) & 'ms.');
		this.dumpScope('Application');
		this.dumpScope('Session');
		this.dumpScope('Request');
		this.dumpScope('URL');
		this.dumpScope('Cookie');
		this.dumpScope('Variables');
		this.dumpScope('CGI');
		this.dumpScope(scope='HTTP Request Data',dump=getHttpRequestData());
	}

// ---------------------< dumpScope >---------------------
	public void function dumpScope(required any Scope, any Dump) output='yes' {
		var s = createObject('java','java.lang.StringBuffer').init('');

		s.append('<table border=0 cellspacing=0 cellpadding=2 style="margin-bottom:4px;border:1px solid ##C0C0C0; color:##000000;">');
		s.append('<tr style="cursor:pointer; background-color:##D0D0D0;"');
		s.append(" onclick=""(document.getElementById('scope_" & Arguments.Scope & "').style.display=='')?document.getElementById('scope_" & Arguments.Scope & "').style.display='none':document.getElementById('scope_" & Arguments.Scope & "').style.display='';""");
		s.append(" onmouseover=""this.style.backgroundColor='##FFFFFF';""");
		s.append(" onmouseout=""this.style.backgroundColor='##D0D0D0';""><td style=""font-family:Arial;font-size:11px;font-weight:bold;padding-left:5px;padding-right:5px;"">" & Arguments.Scope & "</td></tr></table>");
		s.append('<table border=0 id="scope_' & Arguments.Scope & '" style="display:none; color:##000000;"><tr><td>');
		writeOutput(s.toString());
		if(structKeyExists(Arguments,'dump')) {
			writeDump(var=Arguments.Dump,metaInfo='yes',output='browser');
		} else {
			writeDump(var=getPageContext().SymTab_findBuiltinScope(Arguments.Scope),metaInfo='yes',output='browser');
		}
		writeOutput('</td></tr></table>');
	}

}