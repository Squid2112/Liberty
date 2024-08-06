<cfcomponent displayname="RootSystemComponent" hint="Root System Component">
	<cfsetting showdebugoutput="no" enablecfoutputonly="no">

	<cffunction name="init" returntype="any" access="public" output="no">
		<cfargument name="DSN" type="any" required="no" default="#Application.Settings.DSN.System#">
		<cfscript>
			var manifest = '';

			this.DSN = Arguments.DSN;
			this.dsnValid = this.dsnExists();

			this.Objects = {
				Application = arrayNew(1),
				Session = arrayNew(1),
				Request = arrayNew(1)
			};

			this.coreFramework = {
				Start = { content = '', cache = true },
				End = { content = '', cache = true }
			};

			this.baseFramework = {
				Start = { content = '', cache = true },
				End = { content = '', cache = true }
			};

			this.coreJS = arrayNew(1);
			if(fileExists(Application.Settings.rootPath & 'com\Manifests\Core.JavaScripts.manifest.json')) {
				manifest = fileRead(Application.Settings.rootPath & 'com\Manifests\Core.JavaScripts.manifest.json');
				this.coreJS = duplicate(this.jsonDecode(manifest));
				if(NOT isArray(this.coreJS)) this.coreJS = arrayNew(1);
			}

			this.coreCSS = arrayNew(1);
			if(fileExists(Application.Settings.rootPath & 'com\Manifests\Core.Styles.manifest.json')) {
				manifest = fileRead(Application.Settings.rootPath & 'com\Manifests\Core.Styles.manifest.json');
				this.coreCSS = duplicate(this.jsonDecode(manifest));
				if(NOT isArray(this.coreCSS)) this.coreCSS = arrayNew(1);
			}

			if(fileExists(Application.Settings.rootPath & 'com\Manifests\Application.manifest.json')) {
				manifest = fileRead(Application.Settings.rootPath & 'com\Manifests\Application.manifest.json');
				this.Objects.Application = duplicate(this.jsonDecode(manifest));
				if(NOT isArray(this.Objects.Application)) this.Objects.Application = arrayNew(1);
			}

			if(fileExists(Application.Settings.rootPath & 'com\Manifests\Session.manifest.json')) {
				manifest = fileRead(Application.Settings.rootPath & 'com\Manifests\Session.manifest.json');
				this.Objects.Session = duplicate(this.jsonDecode(manifest));
				if(NOT isArray(this.Objects.Session)) this.Objects.Session = arrayNew(1);
			}

			if(fileExists(Application.Settings.rootPath & 'com\Manifests\Request.manifest.json')) {
				manifest = fileRead(Application.Settings.rootPath & 'com\Manifests\Request.manifest.json');
				this.Objects.Request = duplicate(this.jsonDecode(manifest));
				if(NOT isArray(this.Objects.Request)) this.Objects.Request = arrayNew(1);
			}

			this.wrappers = createObject('component','com.System.Wrappers').init();

			return(this);
		</cfscript>
	</cffunction>

	<cffunction name="parseConicals" returntype="any" access="public" output="no">
		<cfargument name="rootDomain" type="any" required="yes">
		<cfargument name="requestHost" type="any" required="yes">
		<cfscript>
			return(listToArray(replaceNoCase(Arguments.requestHost,Arguments.rootDomain,'','ALL'),'.',false));
		</cfscript>
	</cffunction>

	<cffunction name="parse404" returntype="any" access="public" output="no">
		<cfargument name="Request" type="any" required="yes">
		<cfargument name="URL" type="any" required="yes">
		<cfargument name="queryString" type="any" required="yes">
		<cfscript>
			var fullPath = '/' & listFirst(listRest(listRest(Arguments.queryString, '//'), '/'), '?');
			var tParam = '';
			var item = '';
			var tmp = '';
			var virt = '';
			var virtS = 0;
			var virtW = 0;
			var virtRest = '';

			fullPath = urlDecode(fullPath);
			Arguments.Request.vArray = arrayNew(1);
			tmp = replaceNoCase(fullPath,'-Where-','|');
			virt = replaceNoCase(fullPath,'-Sort-By-','@');
			virtW = find('|',tmp);
			virtS = find('@',virt);
			if(virtW AND virtS) {
				if(virtW LT virtS) {
					fullPath = listFirst(tmp,'|');
					virtRest = listRest(tmp,'|');
				} else {
					fullPath = listFirst(virt,'@');
					virtRest = listRest(virt,'@');
				}
			} else {
				if(virtW) {
					fullPath = listFirst(tmp,'|');
					virtRest = listRest(tmp,'|');
				} else if(virtS) {
					fullPath = listFirst(virt,'@');
					virtRest = listRest(virt,'@');
				}
			}
			arrayAppend(Arguments.Request.vArray,trim(replace(fullPath,'/','')));

			if(trim(virtRest) GT '') {
				if(virtS) {
					if(virtW) {
						virtRest = replaceNoCase(virtRest,'-Sort-By-','@');
						arrayAppend(Arguments.Request.vArray,listFirst(virtRest,'@'));
						arrayAppend(Arguments.Request.vArray,'@' & listRest(virtRest,'@'));
					} else {
						arrayAppend(Arguments.Request.vArray,'@' & virtRest);
					}
				} else if(virtW) {
					arrayAppend(Arguments.Request.vArray,virtRest);
				}
			}

			Arguments.Request.vPath = '/';
			Arguments.Request.URLparams = '';
			Arguments.Request.fileName = '';

			if(find('404;', Arguments.queryString)) {
				if(find('.',right(listLast(fullPath,'/'),4))) Arguments.Request.fileName = listLast(fullPath,'/');
				if(arrayLen(Arguments.Request.vArray)) {
					Arguments.Request.vPath = '/' & Arguments.Request.vArray[1];
				} else {
					Arguments.Request.vPath = fullPath;
				}
				tParam = listFirst(listRest(Arguments.queryString, '?'), '&');
				structInsert(url, listFirst(tParam, '='), listRest(tParam, '='), true);

				for(item in Arguments.url) {
					if(left(item, 4) EQ '404;') {
						structDelete(Arguments.url, item, false);
						break;
					}
				}
			}
			return(this.flattenURL(Arguments.url));
		</cfscript>
	</cffunction>

	<cffunction name="virtualResolver" access="public" returntype="any" output="no">
		<cfargument name="vPath" type="any" required="yes">
		<cfscript>
			var viewName = '/';
			var	vInfo = {
				Active = false,
				contentType = 'cfm',
				doRedirect = false,
				isConical = false,
				isDefault = false,
				mapAsset = '',
				recordCount = 0,
				reDirectType = '',
				URI = 'Main',
				URL = '',
				viewName = 'Main',
				viewTemplate = 'index.cfm',
				virtualPath = '/',
				virtualUriId = 0
			};

			if(structKeyExists(Application,'Database')) {
				vInfo = Application.Database.getVirtualPath(Arguments.vPath);
				if(NOT vInfo.RecordCount) vInfo = Application.Database.getVirtualURI(vInfo);
				if(vInfo.RecordCount) viewName = vInfo.viewName;
				if(NOT vInfo.RecordCount) viewName = ListLast(Arguments.vPath,'/');
			}

			if((NOT vInfo.recordCount) AND fileExists(expandPath('/views' & Arguments.vPath) & "\index.cfm")) {
				vInfo = {
					Active = true,
					contentType = 'cfm',
					doRedirect = false,
					isConical = false,
					isDefault = false,
					mapAsset = '',
					recordCount = 0,
					reDirectType = '',
					URI = Arguments.vPath,
					URL = '',
					viewName = listLast(Arguments.vPath,'/'),
					viewTemplate = 'index.cfm',
					virtualPath = Arguments.vPath,
					virtualUriId = 0
				};
			}
			
			return(vInfo);
		</cfscript>
	</cffunction>

	<cffunction name="parseSearchUrl" returntype="any" access="public" output="no">
		<cfargument name="Request" type="any" required="yes">
		<cfargument name="Visitor" type="any" required="yes">
		<cfscript>
			var i = 0;
			var uri = '';
			var options = '';
			var sOptions = '';
			var sets = '';
			var tmp = '';
			var sortOptions = { sortBy='Relevance', perPage=9, onPage=1 };

			if(arrayLen(Arguments.Request.vArray) LT 2) return;

			if(find('@',Arguments.Request.vArray[2])) {
				sOptions = replace(Arguments.Request.vArray[2],'@','');
				sOptions = replaceNoCase(sOptions,'-With-','|','ALL');
				sOptions = replaceNoCase(sOptions,'-Page-','|','ALL');		
			} else {
				options = replace(Arguments.Request.vArray[2],';','.','ALL');
				options = replaceNoCase(options,'-Where-','|','ALL');
				options = replaceNoCAse(options,'-Is-',':','ALL');
				options = replaceNoCase(options,'-To-',':','ALL');
			}

			if((arrayLen(Arguments.Request.vArray) GT 2) AND find('@',Arguments.Request.vArray[3])){
				sOptions = replace(Arguments.Request.vArray[3],'@','');
				sOptions = replaceNoCase(sOptions,'-With-','|','ALL');
				sOptions = replaceNoCase(sOptions,'-Page-','|','ALL');		
			}

			sets = listToArray(options,'|',false);
			for(i=1; i LTE arrayLen(sets); i++) {
				tmp = sets[i];
				sets[i] = structNew();
				sets[i].original = tmp;
				sets[i].refinement = replace(listFirst(sets[i].original,':'),'-',' ','ALL');
				sets[i].value = replace(listRest(sets[i].original,':'),'-',' ','ALL');
				if(this.isTrueNumeric(replace(replace(sets[i].value,':','','ALL'),' ','','ALL'))) sets[i].value = replace(replace(sets[i].value,' ','.','ALL'),':','-','ALL');
			}

			if(listLen(sOptions,'|')) {
				sortOptions.sortBy = listFirst(sOptions,'|');
				sortOptions.perPage = val(listGetAt(sOptions,2,'|'));
				sortOptions.onPage = val(listLast(sOptions,'|'));
			}

			Arguments.Request.urlOptions = duplicate(sortOptions);
			Arguments.Request.urlSets = duplicate(sets);
			Arguments.Visitor.Search.setSearchFromUrl(vSearchUrl=duplicate(sets),vSortOptions=duplicate(sortOptions));
		</cfscript>
	</cffunction>

	<cffunction name="flattenURL" access="public" returntype="any" output="no">
		<cfargument name="url" type="any" required="yes">
		<cfscript>
			var result = '';
			var item = '';

			if(structCount(Arguments.url)) {
				for(item IN Arguments.url) if(trim(item) GT '') result = result & trim(item) & '=' & trim(Arguments.url[item]) & '&';
				if(result GT '') result = left(result, len(result) - 1);
			}
			return(result);
		</cfscript>
	</cffunction>

	<cffunction name="writeBaseDocument" access="public" returntype="any" output="yes">
		<cfargument name="virtualInfo" type="any" required="yes">
		<cfscript>
			var viewTemplateName = listFirst(Arguments.virtualInfo.viewTemplate,'.');
			var s = createObject('java','java.lang.StringBuffer').init('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">');
			var i = 0;

			s.append('<html xmlns="http://www.w3.org/1999/xhtml">');
			s.append('<head>');
			s.append('<title>');
/*
			if(structKeyExists(Request.pageData,'Title')) {
				s.append(this.proccessDirectives(Request.pageData['Title'][1].Contents));
				s.append(' | ');
			}
*/
			s.append(Application.Settings.rootDomain);
			s.append('</title>');
			s.append('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />');
//			s.append(this.proccessDirectives(this.getMetaTags(Request.VirtualInfo.ViewTemplate)));
			s.append('<meta name="HOME_URL" content="http://#Application.Settings.defaultConical#.#Application.Settings.rootDomain#/" />');
			s.append('<meta name="LANGUAGE" content="ENGLISH" />');
			s.append('<meta name="MSSmartTagsPreventParsing" content="TRUE" />');
			s.append('<meta name="DOC-TYPE" content="PUBLIC" />');
			s.append('<meta name="DOC-CLASS" content="COMPLETED" />');
			s.append('<meta name="DOC-RIGHTS" content="PUBLIC DOMAIN" />');

/***  NEED to modify the JS and CSS manifest mechanism so that it loads a -min version if available ***
			if(fileExists(Application.Settings.rootPath & 'css/global-min.css')) {
				this.css('/css/global_min.css');
			} else if(fileExists(Application.Settings.rootPath & 'css/global.css')) {
				this.css('/css/global.css');
			}
*/

			for(i=1; i LTE arrayLen(this.coreCSS); i++) s.append('<link rel="stylesheet" type="text/css" href="' & this.coreCSS[i].file & '" />');

			if(fileExists(Application.Settings.rootPath & "views/" & Arguments.virtualInfo.viewName & '/css/' & viewTemplateName & '-min.css')) {
				s.append('<link rel="stylesheet" type="text/css" href="/views/#Arguments.virtualInfo.viewName#/css/#viewTemplateName#-min.css" />');
			} else if(fileExists(Application.Settings.rootPath & 'views/' & Arguments.virtualInfo.viewName & '/css/' & viewTemplateName & '.css')) {
				s.append('<link rel="stylesheet" type="text/css" href="/views/#Arguments.virtualInfo.viewName#/css/#viewTemplateName#.css" />');
			}

			for(i=1; i LTE arrayLen(this.coreJS); i++) s.append('<script type="text/javascript" src="' & this.coreJS[i].file & '"></script>');

			if(fileExists(Application.Settings.rootPath & 'views/' & Arguments.virtualInfo.viewName & '/js/' & viewTemplateName & '-min.js')) {
				s.append('<script type="text/javascript" src="/views/#Arguments.virtualInfo.viewName#/js/#viewTemplateName#-min.js"></script>');
			} else if(fileExists(Application.Settings.rootPath & 'views/' & Arguments.virtualInfo.viewName & '/js/' & viewTemplateName & '.js')) {
				s.append('<script type="text/javascript" src="/views/#Arguments.virtualInfo.viewName#/js/#viewTemplateName#.js"></script>');
			}
			s.append('</head>');
			writeOutput(s.toString());

			if(Application.Settings.cache AND this.baseFramework.Start.cache) {
				writeOutput(this.baseFramework.Start.content);
			} else {
				if(fileExists(Application.Settings.rootPath & 'com\Framework\baseFrameworkStart.cfm')) this.include('/com/Framework/baseFrameworkStart.cfm');
			}
		</cfscript>
		<cfheader name="Cache-Control" value="post-check=#getHttpTimeString(dateAdd('n', (Application.Settings.sessionTimeoutMinutes * 60), Now()))#,pre-check=#getHttpTimeString(dateAdd('n', (Application.Settings.sessionTimeoutMinutes * 120), Now()))#,max-age=#getHttpTimeString(DateAdd('d', 3, Now()))#">
		<cfheader name="Expires" value="#getHttpTimeString(dateAdd('d', 3, Now()))#">
	</cffunction>

	<cffunction name="processView" access="public" returntype="any" output="yes">
		<cfargument name="virtualInfo" type="any" required="yes">
		<cfscript>
			this.include('/views/' & Arguments.virtualInfo.viewName & '/' & Arguments.virtualInfo.viewTemplate);
		</cfscript>
	</cffunction>

	<cffunction name="closePageContents" access="public" returntype="any" output="yes">
		<cfscript>
			var i = 0;
			var buffer = createObject('java','java.lang.StringBuffer').init('');
			var filename = '';

			if(Application.Settings.cache AND this.baseFramework.End.cache) {
				writeOutput(this.baseFramework.End.content);
			} else {
				if(fileExists(Application.Settings.rootPath & 'com\Framework\baseFrameworkEnd.cfm')) this.include('/com/Framework/baseFrameworkEnd.cfm');
			}
			if(Application.Settings.cache AND this.coreFramework.End.cache) {
				writeOutput(this.coreFramework.End.content);
			} else {
				if(fileExists(Application.Settings.rootPath & 'com\Framework\coreFrameworkEnd.cfm')) this.include('/com/Framework/coreFrameworkEnd.cfm');
			}
		</cfscript>
		<cfheader name="Cache-Control" value="post-check=#(Application.Settings.sessionTimeoutSeconds)#,pre-check=#(Application.Settings.sessionTimeoutSeconds)#,max-age=#(Application.Settings.sessionTimeoutSeconds)#">
		<cfheader name="Expires" value="#getHttpTimeString(dateAdd('n', Application.Settings.sessionTimeoutMinutes, Now()))#">
	</cffunction>

	<cffunction name="cleanPageContents" returntype="any" access="public" output="yes">
		<cfscript>
			var pageContent = request.context.getOut().getString().trim();

			request.context.getOut().clearBuffer();
			pageContent = reReplace(pageContent, ">\s+<", ">" & chr(13) & chr(10) & "<", "ALL");  //strip whitespace between tags
			pageContent = reReplace(pageContent, "[\n\r\f]+", chr(13) & chr(10), "ALL");  //condense excessive new lines into one new line
			pageContent = reReplace(pageContent, "\t+", "", "ALL");  //condense excessive tabs into a single space
			writeOutput(trim(pageContent));
		</cfscript>
	</cffunction>

	<cffunction name="fillCache" returntype="any" access="public" output="no">
		<cfscript>
			if(fileExists(Application.Settings.rootPath & 'com\Framework\coreFrameworkStart.cfm')) this.coreFramework.Start.content = this.cfmFileRead('/com/Framework/coreFrameworkStart.cfm');
			if(fileExists(Application.Settings.rootPath & 'com\Framework\coreFrameworkEnd.cfm')) this.coreFramework.End.content = this.cfmFileRead('/com/Framework/coreFrameworkEnd.cfm');
			if(fileExists(Application.Settings.rootPath & 'com\Framework\baseFrameworkStart.cfm')) this.baseFramework.Start.content = this.cfmFileRead('/com/Framework/baseFrameworkStart.cfm');
			if(fileExists(Application.Settings.rootPath & 'com\Framework\baseFrameworkEnd.cfm')) this.baseFramework.End.content = this.cfmFileRead('/com/Framework/baseFrameworkEnd.cfm');
		</cfscript>
	</cffunction>

	<cffunction name="setCookie" access="public" returntype="any" output="yes">
		<cfargument name="CGI" type="any" required="yes">
		<cfargument name="Name" type="any" required="yes">
		<cfargument name="Value" type="any" required="yes">
 		<cfcookie domain="#Arguments.CGI.SERVER_NAME#" name="#Arguments.Name#" value="#Arguments.Value#" expires="never">
	</cffunction>

	<cffunction name="deleteCookie" access="public" returntype="any" output="yes">
		<cfargument name="CGI" type="any" required="yes">
		<cfargument name="Cookie" type="any" required="yes">
		<cfargument name="Name" type="any" required="no" default="">

		<cfset var theCookie = "">
		<cfif Arguments.Name EQ "">
			<cfloop collection="#Arguments.Cookie#" item="theCookie">
				<cfif NOT listFindNoCase("UUID,CFID,CFTOKEN,JSESSIONID",theCookie)>
					<cfcookie domain="#Arguments.CGI.SERVER_NAME#" name="#theCookie#" value="" expires="now">
					<cfset structDelete(Arguments.Cookie,"#theCookie#",false)>
				</cfif>
			</cfloop>
		<cfelse>
			<cfcookie domain="#cgi.SERVER_NAME#" name="#Arguments.Name#" value="" expires="now">
			<cfset structDelete(Cookie, "#Arguments.Name#", false)>
		</cfif>
	</cffunction>

	<cffunction name="loadObjects" access="public" returntype="any" output="no">
		<cfargument name="scope" type="any" required="yes">
		<cfscript>
			var i = 0;
			var ptrScope = '';
			
			switch(lCase(Arguments.scope)) {
				case 'application' : ptrScope = Application;
					break;
				case 'session' : ptrScope = Session;
					break;
				case 'request' : ptrScope = Request;
					break;
				default : return;
			}

			for(i=1; i LTE arrayLen(this.Objects[Arguments.scope]); i++) {
				if(this.Objects[Arguments.scope][i].init) {
					ptrScope[this.Objects[Arguments.scope][i].name] = createObject(this.Objects[Arguments.scope][i].type,this.Objects[Arguments.scope][i].class).init();
				} else {
					ptrScope[this.Objects[Arguments.scope][i].name] = createObject(this.Objects[Arguments.scope][i].type,this.Objects[Arguments.scope][i].class);
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="isMethod" access="public" returntype="any" output="no">
		<cfargument name="obj" type="any" required="yes">
		<cfreturn structKeyExists(getMetaData(obj),"Parameters")>
	</cffunction>

	<cffunction name="addHTMLHeader" access="public" returntype="any" output="no">
		<cfargument name="Header" type="any" required="yes">
		<cfhtmlhead text="#Arguments.Header#">
	</cffunction>

	<cffunction name="css" access="public" returntype="any" output="no">
		<cfargument name="Request" type="any" required="yes">
		<cfargument name="filename" type="any" required="yes">
		<cfargument name="protocol" type="any" required="no">
		<cfscript>
			var s = createObject('java', 'java.lang.StringBuffer').init('');
			var conical = '';
			var file = listDeleteAt(Arguments.filename,listLen(Arguments.filename,'.'),'.');

			if(Application.Settings.defaultConical NEQ 'www') conical = Application.Settings.defaultConical & '.';

			if(NOT structKeyExists(Arguments.Request,'cssQueue') OR Arguments.Request.cssQueue.indexOf(Arguments.filename)) return;
			Arguments.Request.cssQueue.push(Arguments.filename);

			if(fileExists(Application.Settings.rootPath & file & '-min.css')) {
				s.append('<link rel="stylesheet" type="text/css" href="');
				if(structKeyExists(Arguments,'protocol')) s.append(Arguments.Protocol & '://styles.' & conical & Application.Settings.rootDomain);
				s.append(file & '-min.css');
				s.append('" />');
				this.AddHTMLHeader(s.toString());
			} else if(fileExists(Application.Settings.rootPath & file & '.css')) {
				s.append('<link rel="stylesheet" type="text/css" href="');
				if(structKeyExists(Arguments,'protocol')) s.append(Arguments.Protocol & '://styles.' & conical & Application.Settings.rootDomain);
				s.append(file & '.css');
				s.append('" />');
				this.AddHTMLHeader(s.toString());
			}
		</cfscript>
	</cffunction>

	<cffunction name="js" access="public" returntype="any" output="no">
		<cfargument name="filename" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="protocol" type="any" required="no">
		<cfargument name="inHead" type="any" required="no">
		<cfscript>
			var s = createObject('java', 'java.lang.StringBuffer').init('');
			var i = 0;
			var conical = '';
			if(Application.Settings.defaultConical NEQ 'www') conical = Application.Settings.defaultConical & '.';

			if(NOT structKeyExists(Arguments,'inHead')) {
				if(NOT structKeyExists(Request,'jsQueue') OR Request.jsQueue.indexOf(Arguments.Filename)) return;
				Request.jsQueue.push(Arguments.Filename);
			} else {
				if(FindNoCase('http',Arguments.filename) OR fileExists(Application.Settings.rootPath & right(Arguments.filename, len(Arguments.filename)-1))) {
					s.append('<script type="text/javascript" src="');
						if(NOT findNoCase('http',Arguments.filename) AND structKeyExists(Arguments,'protocol')) s.append(Arguments.Protocol & '://scripts.' & conical & Application.Settings.rootDomain);
					s.append(Arguments.filename);
					for(i=1; i LTE listLen(Arguments.params, ','); i=i++) s.append(' ' & listGetAt(Arguments.params,i,',') & ' ');
					s.append('"></script>');
					this.AddHTMLHeader(s.toString());
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="forward" returntype="any" access="public" output="yes">
		<cfargument name="url" type="any" required="yes">
		<cfset getPageContext().forward(Arguments.url)>
	</cffunction>

	<cffunction name="redirectToConical" access="public" returntype="any" output="no">
		<cfargument name="conical" type="any" required="no" default="www">
		<cfscript>
			location(Request.Protocol & '://' & Arguments.conical & '.' & cgi.SERVER_NAME & Request.vPath & IIF(FindNoCase('index.cfm', cgi.SCRIPT_NAME), DE(''), DE(cgi.SCRIPT_NAME)) & IIF(Request.URLparams GT '', DE('?' & Request.URLparams), DE('')),false,'302');
		</cfscript>
	</cffunction>

	<cffunction name="getRequestProtocol" returntype="any" access="public" output="no">
		<cfargument name="HTTPS" type="any" required="yes">
		<cfargument name="requestData" type="any" required="yes">
		<cfscript>
			if(structKeyExists(Arguments.requestData.headers,'SSL')) {
				return(IIF(Arguments.requestData.headers['SSL'] EQ 1, DE('https'), DE('http')));
			} else {
				return(IIF(Arguments.HTTPS EQ 'on', DE('https'), DE('http')));
			}
		</cfscript>
	</cffunction>

	<cffunction name="getSslProtocol" returntype="any" access="public" output="no">
		<cfscript>
			var result = getHttpRequestData().headers;

			if(structKeyExists(result, "SSL")) return(iif(result.SSL EQ 1, DE("https"), DE("http")));
			if(structKeyExists(cgi, "HTTPS")) return(iif(cgi.HTTPS EQ "on", DE("https"), DE("http")));
			return("http");
		</cfscript>
	</cffunction>

	<cffunction name="jsondecode" returntype="any" access="public" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfscript>
			var ar = arrayNew(1);
			var st = structNew();
			var dataType = '';
			var inQuotes = false;
			var startPos = 1;
			var nestingLevel = 0;
			var dataSize = 0;
			var skipIncrement = false;
			var i = 1;
			var j = 0;
			var loopVar = 0;
			var char = '';
			var dataStr = '';
			var structVal = '';
			var structKey = '';
			var colonPos = '';
			var qRows = 0;
			var qCol = '';
			var qData = '';
			var curCharIndex = '';
			var curChar = '';
			var unescapeVals = '\\,\",\/,\b,\t,\n,\f,\r';
			var unescapeToVals = '\,",/,#chr(8)#,#Chr(9)#,#Chr(10)#,#Chr(12)#,#Chr(13)#';
			var unescapeVals2 = '\,",/,b,t,n,f,r';
			var unescapetoVals2 = '\,",/,#chr(8)#,#chr(9)#,#chr(10)#,#chr(12)#,#chr(13)#';
			var dJSONString = '';
			var _data = trim(Arguments.data);
	
			if(isNumeric(_data)) return(_data);
			if(_data EQ 'null')	return('');
			if(listFindNoCase('true,false', _data)) return(_data);
			if((_data EQ "''") OR (_data EQ '""')) return('');
	
			if((reFind('^"[^\\"]*(?:\\.[^\\"]*)*"$', _data) EQ 1) OR (reFind("^'[^\\']*(?:\\.[^\\']*)*'$", _data) EQ 1)) {
				_data = mid(_data, 2, Len(_data)-2);
				if(find('\b', _data) OR find('\t', _data) OR find('\n', _data) OR find('\f', _data) OR find('\r', _data)) {
					curCharIndex = 0;
					curChar = '';
					dJSONString = createObject('java', 'java.lang.StringBuffer').init('');
					for(loopVar=1; loopVar LTE 100000; loopVar++) {
						curCharIndex++;
						if(curCharIndex GT len(_data)) {
							loopVar = 100001;
							break;
						} else {
							curChar = mid(_data, curCharIndex, 1);
							if(curChar EQ '\') {
								curCharIndex++;
								curChar = mid(_data, curCharIndex,1);
								pos = listFind(unescapeVals2, curChar);
								if(pos) {
									dJSONString.append(listGetAt(unescapetoVals2, pos));
								} else {
									dJSONString.append('\' & curChar);
								}
							}
							dJSONString.append(curChar);
						}
					}
					return(dJSONString.toString());
				}
				return(replaceList(_data, unescapeVals, unescapeToVals));
			}
	
			if(((left(_data, 1) EQ '[') AND (right(_data, 1) EQ ']')) OR ((left(_data, 1) EQ '{') AND (right(_data, 1) EQ '}'))) {
				if((left(_data, 1) EQ '[') AND (right(_data, 1) EQ ']')) {
					dataType = 'array';
				} else if(reFindNoCase('^\{"recordcount":[0-9]+,"columnlist":"[^"]+","data":\{("[^"]+":\[[^]]*\],?)+\}\}$', _data, 0) EQ 1) {
					dataType = 'query';
				} else {
					dataType = 'struct';
				}
				_data = trim(mid(_data, 2, len(_data)-2));
				if(len(_data) EQ 0) {
					if(dataType EQ 'array') return(ar);
					return(st);
				}
				dataSize = len(_data) + 1;
				for(; i LTE dataSize; ) {
					skipIncrement = false;
					char = mid(_data, i, 1);
					if(char EQ '"') {
						inQuotes = (NOT inQuotes);
					} else if((char EQ '\') AND inQuotes) {
						i = i + 2;
						skipIncrement = true;
					} else if(((char EQ ',') AND (NOT inQuotes) AND (nestingLevel EQ 0)) OR (i EQ (len(_data)+1))) {
						dataStr = mid(_data, startPos, i-startPos);
						if(dataType EQ 'array') {
							arrayAppend(ar, jsondecode(dataStr));
						} else if((dataType EQ 'struct') OR (dataType EQ 'query')) {
							dataStr = mid(_data, startPos, i-startPos);
							colonPos = find('":', dataStr);
							if(colonPos) {
								colonPos++;    
							} else {
								colonPos = find(':', dataStr);    
							}
							structKey = trim(mid(dataStr, 1, colonPos-1));
							if((left(structKey, 1) EQ "'") OR (left(structKey, 1) EQ '"')) structKey = mid(structKey, 2, len(structKey)-2);
							structVal = mid(dataStr, colonPos+1, len(dataStr)-colonPos);
							if(dataType EQ 'struct') structInsert(st, structKey, jsondecode(structVal));
							if(structKey EQ 'recordcount') {
								qRows = jsondecode(structVal);
							} else if(structKey EQ 'columnlist') {
								st = queryNew(jsondecode(structVal));
								if(qRows) queryAddRow(st, qRows);
							} else if(structKey EQ 'data') {
								qData = jsondecode(structVal);
								ar = structKeyArray(qData);
								for(j=1; j LTE arrayLen(ar); j++) {
									for(qRows=1; qRows LTE st.recordCount; j++) {
										qCol = ar[j];
										querySetCell(st, qCol, qData[qCol][qRows], qRows);
									}
								}
							}
						}
						startPos = i + 1;
					} else if(('{[' CONTAINS char) AND (NOT inQuotes)) {
						nestingLevel++;
					} else if((']}' CONTAINS char) AND (NOT inQuotes)) {
						nestingLevel--;
					}
					if(NOT skipIncrement) i++;
				}
				if(dataType EQ 'array') return(ar);
				return(st);
			}
		</cfscript>
	</cffunction>

	<cffunction name="dsnExists" access="public" returntype="any" output="no">
		<cftry>
			<cfquery name="test" datasource="#this.DNS#">
				SELECT * FROM INFORMATION_SCHEMA.TABLES
			</cfquery>
			<cfcatch type="any">
				<cfreturn false>
			</cfcatch>
		</cftry>
		<cfreturn false>
	</cffunction>

	<cffunction name="showDebug" access="public" returntype="any" output="yes">
		<cfscript>
			writeOutput('<hr width="100%">');
			if(structKeyExists(Request, 'endTime')) writeOutput('Elapsed Time: ' & (Request.endTime - Request.startTime) & 'ms.');
			this.dumpScope('Application');
			this.dumpScope('Session');
			this.dumpScope('Request');
			this.dumpScope('URL');
			this.dumpScope('Cookie');
			this.dumpScope('Variables');
			this.dumpScope('CGI');
		</cfscript>
	</cffunction>

	<cffunction name="dumpScope" access="public" returntype="any" output="yes">
		<cfargument name="Scope" type="any" required="yes">
		<cfscript>
			var s = createObject('java', 'java.lang.StringBuffer').init('');
			
			s.append('<table border=0 cellspacing=0 cellpadding=2 style="margin-bottom:4px;border:1px solid ##C0C0C0; color:##000000;">');
			s.append('<tr style="cursor:pointer; background-color:##D0D0D0;"');
			s.append(" onclick=""(document.getElementById('scope_" & Arguments.Scope & "').style.display=='')?document.getElementById('scope_" & Arguments.Scope & "').style.display='none':document.getElementById('scope_" & Arguments.Scope & "').style.display='';""");
			s.append(" onmouseover=""this.style.backgroundColor='##FFFFFF';""");
			s.append(" onmouseout=""this.style.backgroundColor='##D0D0D0';""><td style=""font-family:Arial;font-size:11px;font-weight:bold;padding-left:5px;padding-right:5px;"">" & Arguments.Scope & "</td></tr></table>");
			s.append('<table border=0 id="scope_' & Arguments.Scope & '" style="display:none; color:##000000;"><tr><td>');
			writeOutput(s.toString());
			writeDump(getPageContext().SymTab_findBuiltinScope(Arguments.Scope));
			writeOutput("</td></tr></table>");
		</cfscript>
	</cffunction>

	<cffunction name="include" access="public" returntype="any" output="yes">
		<cfargument name="template" type="any" required="yes">
		<cfinclude template="#Arguments.template#">
	</cffunction>

	<cffunction name="cfmFileRead" returntype="any" access="public" output="no">
		<cfargument name="cfmFile" type="any" required="yes">
		<cfset var result = "">
		<cfsavecontent variable="result"><cfinclude template="#Arguments.cfmFile#"></cfsavecontent>
		<cfreturn result>
	</cffunction>

	<cffunction name="onMissingMethod" returntype="any" access="public" output="no">
		<cfreturn>
	</cffunction>

</cfcomponent>