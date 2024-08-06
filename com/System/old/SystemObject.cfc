<cfcomponent displayname="RootSystemComponent" hint="Root System Component">
	<cfsetting showdebugoutput="no" enablecfoutputonly="no">

	<cffunction name="init" returntype="any" access="public" output="no">
		<cfargument name="DSN" type="any" required="no" default="#Application.Settings.applicationDSN#">
		<cfscript>
			this.DSN = Arguments.DSN;
			this.DsnExists = checkDSN();
			this.sessionTracker = createObject('java','coldfusion.runtime.SessionTracker');
			this.applicationTracker = createObject('java','coldfusion.runtime.ApplicationScopeTracker').init();

			return(this);
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
			writeoutput(s.toString());
			Application.Base.dump(getPageContext().SymTab_findBuiltinScope(Arguments.Scope));
			writeoutput("</td></tr></table>");
		</cfscript>
	</cffunction>

	<cffunction name="parseConicals" returntype="any" access="public" output="no">
		<cfscript>
//			if(NOT FindNoCase(Application.Settings.RootDomain, cgi.SERVER_NAME)) this.permanentRedirect(url=Application.Settings.AbuseRedirect);
			Request.Conicals = duplicate(listToArray(reReplaceNoCase(cgi.SERVER_NAME, "#Application.Settings.RootDomain#", "", "ALL"), ".", false));
		</cfscript>
	</cffunction>

	<cffunction name="parse404" returntype="any" access="public" output="no">
		<cfscript>
			var virt = "";
			var tParam = "";
			var item = "";

			Request.vPath = "/";
			Request.URLparams = "";

			if(find("404;", cgi.QUERY_STRING)) {
				virt = "/" & listFirst(listRest(listRest(cgi.QUERY_STRING, "//"), "/"), "?");
				if(right(virt, 1) EQ "/") virt = left(virt, len(virt)-1);
				if(len(virt) GT 0) {
					Request.vPath = virt;
					tParam = listFirst(listRest(cgi.QUERY_STRING, "?"), "&");
					structInsert(url, listFirst(tParam, "="), listRest(tParam, "="), true);
				}
				for(item in url) {
					if(left(item, 4) EQ "404;") {
						structDelete(url, item, false);
						break;
					}
				}
			}
			Request.URLparams = duplicate(this.flattenURL());
		</cfscript>
	</cffunction>

	<cffunction name="getMetaTags" returntype="any" access="public" output="no">
		<cfargument name="Template" type="any" required="no" default="global">
		<cfscript>
			var s = createObject('java', 'java.lang.StringBuffer').init('');
			var idx = 0;
			var Meta = "";
			var Columns = 0;

			Meta = Application.Database.getMetaTags(Template=Arguments.Template);
			if(NOT Meta.RecordCount) return("");
			Columns = listToArray(Meta.ColumnList);
			for(idx=1; idx LTE arrayLen(Columns); idx = idx + 1) s.append('<meta name="' & Columns[idx] & '" content="' & Meta[Columns[idx]][1] & '" />');
			return(s.toString());
		</cfscript>
	</cffunction>

	<cffunction name="cleanPageContents" returntype="any" access="public" output="yes">
		<cfscript>
			var pageContent = request.context.getOut().getString().trim();

			request.context.getOut().clearBuffer();
			pageContent = reReplace(pageContent, ">\s+<", ">" & chr(13) & chr(10) & "<", "ALL");  //strip whitespace between tags
			pageContent = reReplace(pageContent, "[\n\r\f]+", chr(13) & chr(10), "ALL");  //condense excessive new lines into one new line
			pageContent = reReplace(pageContent, "\t+", "", "ALL");  //condense excessive tabs into a single space
			writeoutput(trim(pageContent));
		</cfscript>
	</cffunction>

	<cffunction name="writeBaseDocument" access="public" returntype="any" output="yes">
		<cfscript>
			var ViewTemplateName = listFirst(Request.VirtualInfo.ViewTemplate, ".");
			var s = createObject('java', 'java.lang.StringBuffer').init('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">');

			s.append('<html xmlns="http://www.w3.org/1999/xhtml">');
			s.append('<head>');
			s.append('<title>');
			if(structKeyExists(Request.PageData, "Title")) {
				s.append(this.proccessDirectives(Request.PageData["Title"][1].Contents));
				s.append(' | ');
			}
			s.append(Application.Settings.RootDomain);
			s.append('</title>');
			s.append('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />');
			s.append(this.proccessDirectives(this.getMetaTags(Request.VirtualInfo.ViewTemplate)));
			s.append('<meta name="HOME_URL" content="http://#Application.Settings.RootDomain#/" />');
			s.append('<meta name="LANGUAGE" content="ENGLISH" />');
			s.append('<meta name="MSSmartTagsPreventParsing" content="TRUE" />');
			s.append('<meta name="DOC-TYPE" content="PUBLIC" />');
			s.append('<meta name="DOC-CLASS" content="COMPLETED" />');
			s.append('<meta name="DOC-RIGHTS" content="PUBLIC DOMAIN" />');

			if(Application.Settings.useExt) s.append('<link rel="stylesheet" type="text/css" href="/ext-' & Application.Settings.ExtVersion & '/resources/css/ext-all.css" />');
			if(fileExists(Application.Settings.RootPath & 'css/global_min.css')) {
				this.css('/css/global_min.css');
			} else if(fileExists(Application.Settings.RootPath & 'css/global.css')) {
				this.css('/css/global.css');
			}
			if(Application.Settings.useExt) {
				s.append('<script type="text/javascript" src="/ext-' & Application.Settings.ExtVersion & '/adapter/ext/ext-base.js"></script>');
				s.append('<script type="text/javascript" src="/ext-' & Application.Settings.ExtVersion & '/ext-all.js"></script>');
				s.append('<script type="text/javascript">Ext.BLANK_IMAGE_URL = ''/ext-' & Application.Settings.ExtVersion & '/resources/images/default/s.gif'';</script>');
			}

			if(fileExists(Application.Settings.RootPath & "views/" & Request.VirtualInfo.ViewName & "/css/" & ViewTemplateName & "_min.css")) {
				s.append('<link rel="stylesheet" type="text/css" href="/views/#Request.VirtualInfo.ViewName#/css/#ViewTemplateName#_min.css" />');
			} else if(fileExists(Application.Settings.RootPath & "views/" & Request.VirtualInfo.ViewName & "/css/" & ViewTemplateName & ".css")) {
				s.append('<link rel="stylesheet" type="text/css" href="/views/#Request.VirtualInfo.ViewName#/css/#ViewTemplateName#.css" />');
			}
			if(fileExists(Application.Settings.RootPath & "views/" & Request.VirtualInfo.ViewName & "/css/" & ViewTemplateName & ".cfm")) s.append('<link rel="stylesheet" type="text/css" href="/views/#Request.VirtualInfo.ViewName#/css/#ViewTemplateName#.cfm" />');

			if(fileExists(Application.Settings.RootPath & "views/" & Request.VirtualInfo.ViewName & "/js/" & ViewTemplateName & "_min.js")) {
				s.append('<script type="text/javascript" src="/views/#Request.VirtualInfo.ViewName#/js/#ViewTemplateName#_min.js"></script>');
			} else if(fileExists(Application.Settings.RootPath & "views/" & Request.VirtualInfo.ViewName & "/js/" & ViewTemplateName & ".js")) {
				s.append('<script type="text/javascript" src="/views/#Request.VirtualInfo.ViewName#/js/#ViewTemplateName#.js"></script>');
			}
			if(fileExists(Application.Settings.RootPath & "views/" & Request.VirtualInfo.ViewName & "/js/" & ViewTemplateName & ".cfm")) s.append('<script type="text/javascript" src="/views/#Request.VirtualInfo.ViewName#/js/#ViewTemplateName#.cfm"></script>');

			s.append('</head><body onload="if(typeof(bodyOnLoad) != ''undefined'') bodyOnload();" onunload="if(typeof(bodyOnUnload) != ''undefined'') bodyOnUnload();">');
			writeoutput(s.toString());
		</cfscript>
		<cfheader name="Cache-Control" value="post-check=#GetHttpTimeString(DateAdd('n', (Application.Settings.SessionTimeoutMinutes * 60), Now()))#,pre-check=#GetHttpTimeString(DateAdd('n', (Application.Settings.SessionTimeoutMinutes * 120), Now()))#,max-age=#GetHttpTimeString(DateAdd('d', 3, Now()))#">
		<cfheader name="Expires" value="#GetHttpTimeString(DateAdd('d', 3, Now()))#">
	</cffunction>

	<cffunction name="closePageContents" access="public" returntype="any" output="yes">
		<cfscript>
			writeoutput("</body></html>");
		</cfscript>
	</cffunction>

	<cffunction name="proccessDirectives" access="public" returntype="any" output="no">
		<cfargument name="input" type="any" required="yes">
		<cfscript>
			var result = Arguments.input;
			var finds = StructNew();
			var isMethod = false;
			var idx = 1;
			var directive = "";
			var scope = "";
			var method = "";
			var params = "";
			var methodResult = "";

			do {
				finds = reFind("##[a-zA-Z0-9\.]+(\x28[^\x28\x29]*\x29)*##", result, idx, true);
				if(finds.len[1]) {
					if(finds.len[2]) {
						directive = SpanExcluding(mid(result, finds.pos[1]+1, finds.len[1]-2), "(");
						method = ListLast(directive, ".");
						scope = ListDeleteAt(directive, ListLen(directive, "."), ".");
						params = mid(result, finds.pos[2]+1, finds.len[2]-2);
						isMethod = true;
					} else {
						directive = mid(result, finds.pos[1]+1, finds.len[1]-2);
						scope = ListDeleteAt(directive, ListLen(directive, "."), ".");
						method = ListLast(directive, ".");
						isMethod = false;
					}
					idx = idx + finds.pos[1] + finds.len[1];
		
					if(isMethod) {
						if(isDefined("#directive#")) {
							ptrMethod = Evaluate("#directive#");
							if(len(params)) {
								methodResult = ptrMethod(Evaluate(params));
							} else {
								methodResult = ptrMethod();
							}
							if(NOT isDefined("methodResult")) methodResult = "";
							result = Replace(result, mid(result, finds.pos[1], finds.len[1]), methodResult, "ALL");
						}
					} else {
						if(isDefined("#directive#")) {
							methodResult = Evaluate("#directive#");
							if(NOT isDefined("methodResult")) methodResult = "";
							result = Replace(result, mid(result, finds.pos[1], finds.len[1]), methodResult, "ALL");
						}
					}
					
				}
			} while(finds.len[1]);

			return(result);
		</cfscript>
	</cffunction>

	<cffunction name="proccessContextDirectives" access="public" returntype="any" output="no">
		<cfscript>
			var idx = 1;
			var finds = StructNew();
			var directive = "";
			var type = "";
			var method = "";
			var eMethod = "";
			var cObject = "";
			var pageContent = request.context.getOut().getString().trim();

			request.context.getOut().clearBuffer();

			StructInsert(finds, "len", ArrayNew(1), true);
			StructInsert(finds, "pos", ArrayNew(1), true);
			ArrayAppend(finds.len, 0);
			ArrayAppend(finds.pos, 0);

			do {
				finds = reFind("##[a-zA-Z0-9.()]+##", pageContent, idx, true);
				if(finds.len[1]) {
					idx = finds.pos[1] + 1;
					directive = mid(pageContent, finds.pos[1]+1, finds.len[1]-2);
					type = ListFirst(directive, ".");
					method = ListLast(directive, ".");
					if(len(type) AND len(method)) {
						if(StructKeyExists(Application, type & "Objects") AND StructKeyExists(Application[type & "Objects"], method)) {
							eMethod = Evaluate("Application.#type#Objects.#method#");
							cObject = eMethod();
						}
						pageContent = Replace(pageContent, mid(pageContent, finds.pos[1], finds.len[1]), cObject, "ALL");
					}
				}
			} while(finds.len[1]);

			writeoutput(pageContent);
		</cfscript>
	</cffunction>

	<cffunction name="redirectToWWW" access="public" returntype="any" output="no">
		<cfscript>
			this.location(Request.Protocol & "://www." & cgi.SERVER_NAME & Request.vPath & IIF(FindNoCase("index.cfm", cgi.SCRIPT_NAME), DE(""), DE(cgi.SCRIPT_NAME)) & IIF(Request.URLparams GT "", DE("?" & Request.URLparams), DE("")));
		</cfscript>
	</cffunction>

	<cffunction name="include" access="public" returntype="any" output="yes">
		<cfargument name="template" type="any" required="yes">
		<cfinclude template="#Arguments.Template#">
	</cffunction>

	<cffunction name="setCookie" access="public" returntype="any" output="yes">
		<cfargument name="Name" type="any" required="yes">
		<cfargument name="Value" type="any" required="yes">
 		<cfcookie domain="#cgi.SERVER_NAME#" name="#Arguments.Name#" value="#Arguments.Value#" expires="never">
	</cffunction>

	<cffunction name="deleteCookie" access="public" returntype="any" output="yes">
		<cfargument name="Name" type="any" required="no" default="">
		<cfset var theCookie = "">
		<cfif Arguments.Name EQ "">
			<cfloop collection="#Cookie#" item="theCookie">
				<cfif NOT listFindNoCase("UUID,CFID,CFTOKEN,JSESSIONID", theCookie)>
					<cfcookie domain="#cgi.SERVER_NAME#" name="#theCookie#" value="" expires="now">
					<cfset structDelete(Cookie, "#theCookie#", false)>
				</cfif>
			</cfloop>
		<cfelse>
			<cfcookie domain="#cgi.SERVER_NAME#" name="#Arguments.Name#" value="" expires="now">
			<cfset structDelete(Cookie, "#Arguments.Name#", false)>
		</cfif>
	</cffunction>

	<cffunction name="setJavaScriptVariables" access="public" returntype="any" output="yes">
		<cfscript>
			var tStr = "";
			var sessionVars = "";

			writeoutput('<script type="text/javascript">');
			tStr = 'document["Session"] = { ';
			for(i=1; i LTE ListLen(sessionVars, "|"); i=i+1) {
				sessionKey = listRest(listGetAt(sessionVars, i, "|"), ".");
				sessionVal = Session[sessionKey];
				tStr = tStr & "'" & sessionKey & "' : '" & sessionVal & "'";
				if(i LT listLen(sessionVars, "|")) tStr = tStr & ", ";
			}
			tStr = tStr & " };";
			writeoutput(tStr);
			writeoutput('</script>');
		</cfscript>
	</cffunction>

	<cffunction name="visitorCount" access="public" returntype="any" output="no">
		<cfquery name="qVisitors" datasource="#this.DSN#">
			SELECT COUNT(DISTINCT UUID) AS CNT
			FROM Visitors WITH (NOLOCK)
			WHERE (DATEDIFF(minute, LastAccess, GETDATE()) <= <cfqueryparam cfsqltype="cf_sql_integer" value="30">)
		</cfquery>
		<cfreturn qVisitors.CNT>
	</cffunction>

	<cffunction name="loadConfig" access="public" returntype="any" output="no">
		<cfargument name="configFile" type="any" required="yes">
		<cfscript>
			var oFilename = Application.Settings.RootPath & Arguments.configFile;
			var oStruct = "";
			var xmlFile = "";
			var keys = "";
			var key = "";
			var i = 1;
		
			if(FileExists(oFilename)) {
				xmlFile = FileRead(oFilename);
				oStruct = this.XmlToStruct(xmlFile, StructNew());
				keys = StructKeyList(oStruct);
				for(i=1; i LTE ListLen(keys); i=i+1) {
					key = ListGetAt(keys, i);
					if(isSimpleValue(oStruct[key])) StructInsert(Application, key, oStruct[key], true);
				}
			}
		</cfscript>	
	</cffunction>

	<cffunction name="loadObjectNodes" access="public" returntype="any" output="no">
		<cfargument name="scopeName" type="any" required="yes">
		<cfargument name="objectNodes" type="any" required="yes">
		<cfscript>
			var scope = "";
			var objectXml = "";
			var i = 1;

			switch(lCase(Arguments.scopeName)) {
				case "application" : Scope = Application;
					break;
				case "session" : Scope = Session;
					break;
				case "request" : Scope = Request;
					break;
				default : break;
			}

			if(isArray(arguments.objectNodes)) {
				for(i=1; i LTE arrayLen(arguments.objectNodes); i=i+1) {
					objectXml = xmlParse(arguments.objectNodes[i]);
					if(structKeyExists(objectXml.object, "init") AND (reFindNoCase("true|yes", objectXml.object.init.xmlText) GT 0)) {
						if(structKeyExists(objectXml.object, "param")) {
							structInsert(Scope, objectXml.object.name.xmlText, createObject(objectXml.object.type.xmlText, objectXml.object.path.xmlText).init(objectXml.object.path.xmlText), true);
						} else if(structKeyExists(objectXml.object, "tablename") AND structKeyExists(objectXml.object, "dsn")) {
							structInsert(Scope, objectXml.object.name.xmlText, createObject(objectXml.object.type.xmlText, objectXml.object.path.xmlText).init(tablename=objectXml.object.tablename.xmlText, dsn=objectXml.object.dsn.xmlText), true);
						} else {
							structInsert(Scope, objectXml.object.name.xmlText, createObject(objectXml.object.type.xmlText, objectXml.object.path.xmlText).init(), true);
						}
					} else {
						structInsert(Scope, objectXml.object.name.xmlText, createObject(objectXml.object.type.xmlText, objectXml.object.path.xmlText), true);
					}
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="loadXmlData" access="public" returntype="any" output="no">
		<cfargument name="scopeName" type="any" required="yes">
		<cfscript>
			var oFilename = Application.Settings.RootPath & Arguments.scopeName & "Objects.xml";
			var xmlFile = "";
			var xml = "";
			var objectNodes =  "";

			if(fileExists(oFilename)) {
				xmlFile = fileRead(oFilename);
				xml = xmlParse(xmlFile);
				objectNodes = xmlSearch(xml,'/objects/object');
			}
			return(objectNodes);		
		</cfscript>
	</cffunction>

	<cffunction name="loadObjects" access="public" returntype="any" output="no">
		<cfargument name="scopeName" type="any" required="yes">
		<cfscript>
			var oFilename = Application.Settings.RootPath & Arguments.scopeName & "Objects.xml";
			var xmlFile = "";
			var Scope = "";
			var xml = "";
			var objectNodes =  "";
			var i = 1;

			switch(lCase(Arguments.scopeName)) {
				case "application" : Scope = Application;
					break;
				case "session" : Scope = Session;
					break;
				case "request" : Scope = Request;
					break;
				default : break;
			}

			if(isStruct(Scope) AND fileExists(oFilename)) {
				xmlFile = fileRead(oFilename);
				xml = xmlParse(xmlFile);
				objectNodes = xmlSearch(xml,'/objects/object');
				for(i=1; i LTE arrayLen(objectNodes); i=i+1) {
					objectXml = xmlParse(objectNodes[i]);
					if(structKeyExists(objectXml.object, "init") AND (reFindNoCase("true|yes", objectXml.object.init.xmlText) GT 0)) {
						if(structKeyExists(objectXml.object, "param")) {
							structInsert(Scope, objectXml.object.name.xmlText, createObject(objectXml.object.type.xmlText, objectXml.object.path.xmlText).init(objectXml.object.path.xmlText), true);
						} else if(structKeyExists(objectXml.object, "tablename") AND structKeyExists(objectXml.object, "dsn")) {
							structInsert(Scope, objectXml.object.name.xmlText, createObject(objectXml.object.type.xmlText, objectXml.object.path.xmlText).init(tablename=objectXml.object.tablename.xmlText, dsn=objectXml.object.dsn.xmlText), true);
						} else {
							structInsert(Scope, objectXml.object.name.xmlText, createObject(objectXml.object.type.xmlText, objectXml.object.path.xmlText).init(), true);
						}
					} else {
						structInsert(Scope, objectXml.object.name.xmlText, createObject(objectXml.object.type.xmlText, objectXml.object.path.xmlText), true);
					}
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="loadPageData" access="public" returntype="any" output="no">
		<cfargument name="vInfo" type="any" required="yes">
		<cfscript>
			var result = StructNew();
			var qData = "";
			var idx = 0;
			var tArea = "";
			var tStruct = "";
			qData = Application.Database.getPageContents(Template=Arguments.vInfo.ViewTemplate);

			for(idx=1; idx LTE qData.RecordCount; idx=idx +1) {
				if(qData.Area[idx] NEQ tArea) {
					tArea = qData.Area[idx];
					structInsert(result, tArea, ArrayNew(1), true);
				}
				tStruct = { ContentID=qData.ContentID[idx], Scope=qData.Scope[idx], Area=qData.Area[idx], Contents=qData.Contents[idx] };
				arrayAppend(result[tArea], duplicate(tStruct));
			}
			return(result);
		</cfscript>
	</cffunction>

	<cffunction name="virtualResolver" access="public" returntype="any" output="no">
		<cfscript>
			var ViewName = "";
			var vInfo = Application.Database.getVirtualPath(Request.vPath);

			if(NOT vInfo.RecordCount) vInfo = Application.Database.getVirtualURI(vInfo);
			if(vInfo.RecordCount) ViewName = vInfo.ViewName;
			if(NOT vInfo.RecordCount) ViewName = ListLast(Request.vPath, "/");

			if((NOT vInfo.RecordCount) AND fileExists(expandPath("/views" & Request.vPath) & "\index.cfm")) {
				vInfo = {
					VirtualPath = Request.vPath,
					ViewName = ViewName,
					ViewTemplate = "index.cfm",
					MapAsset = "",
					ContentType = "cfm",
					isConical = false,
					doRedirect = false,
					Active = true,
					RecordCount = 0
				};
			}
			
			return(vInfo);
		</cfscript>
	</cffunction>

	<cffunction name="permanentRedirect" access="public" returntype="any" output="no">
		<cfargument name="URL" type="string" required="yes">
		<cfheader statuscode="301" statustext="Moved Permanently">
		<cfheader name="Location" value="#Arguments.URL#">
	</cffunction>

	<cffunction name="location" access="public" returntype="any" output="no">
		<cfargument name="url" type="any" required="Yes">
		<cfargument name="statusCode" type="any" required="no" default="302">
		<cflocation url="#Arguments.url#" addtoken="No" statuscode="#Arguments.statusCode#">
	</cffunction>

	<cffunction name="abort" access="public" returntype="any" output="no">
		<cfabort>
	</cffunction>

	<cffunction name="isMethod" access="public" returntype="any" output="no">
		<cfargument name="obj" type="any" required="yes">
		<cfreturn StructKeyExists(getMetaData(obj), "Parameters")>
	</cffunction>

	<cffunction name="newEmptyQuery" access="public" returntype="any" output="no">
		<cfargument name="struct" type="any" required="yes">
		<cfset var item = "">
		<cfset var result = "">
		<cfset var columns = "">
		<cfset var types = "">

		<cfloop collection="#Arguments.struct#" item="item">
			<cfset columns = columns & "," & listFirst(item, "|")>
			<cfset types = types & "," & listLast(item, "|")>
		</cfloop>
		<cfset columns = right(columns, len(columns) - 1)>
		<cfset types = right(types, len(types) - 1)>
		<cfset result = queryNew(columns, types)>

		<cfset queryAddRow(result)>
    
		<cfloop collection="#Arguments.struct#" item="item">
			<cfset querySetCell(result, item, Arguments.struct[item])>
		</cfloop>
    
		<cfreturn result>
	</cffunction>

	<cffunction name="implicitQuery" access="public" returntype="any" output="no">
		<cfargument name="queryData" type="any" required="true" />
		<cfscript>
			var i = 0;
			var columnName = "";
			var myQuery = "";
			var queryLength = arrayLen(Arguments.queryData[listFirst(structKeyList(arguments.queryData))]);
		</cfscript>
		<cfquery name="myQuery" datasource="#this.DSN#">
			<cfloop from="1" to="#queryLength#" index="i">
				SELECT <cfloop collection="#Arguments.queryData#" item="columnName"><cfif isNumeric(Arguments.queryData[columnName][i])>#Arguments.queryData[columnName][i]#<cfelse>'#Arguments.queryData[columnName][i]#'</cfif> AS #columnName#<cfif columnName NEQ listLast(structKeyList(Arguments.queryData))>,</cfif></cfloop>
				<cfif i NEQ queryLength>UNION</cfif>
			</cfloop>
		 </cfquery>
		 <cfreturn myQuery />
	</cffunction>

	<cffunction name="flattenURL" access="public" returntype="any" output="no">
		<cfscript>
			var result = "";

			if(structCount(url)) {
				for(item in url) if(trim(item) GT "") result = result & trim(item) & "=" & trim(url[item]) & "&";
				if(result GT "") result = Left(result, Len(result) - 1);
			}
			return(result);
		</cfscript>
	</cffunction>

	<cffunction name="addHTMLHeader" access="public" returntype="any" output="no">
		<cfargument name="Header" type="any" required="yes">
		<cfhtmlhead text="#Arguments.Header#">
	</cffunction>

	<cffunction name="xmlToStruct" access="public" returntype="any" output="no">
		<cfargument name="xmlNode" type="any" required="yes">
		<cfargument name="str" type="any" required="yes">
		
		<cfscript>
			var i = 0;
			var aXml = "";
			var aStr = Arguments.str;
			var n = "";
			var tmpContainer = "";
			var at_list = "";
			var atr = 1;
			var attrib_list = "";
			var attrib = 1;
			
			aXml = xmlSearch(xmlParse(Arguments.xmlNode), "/node()");
			aXml = aXml[1];
			
			for(i=1; i LTE arrayLen(aXml.XmlChildren); i=i+1) {
				n = replace(aXml.XmlChildren[i].XmlName, aXml.XmlChildren[i].XmlNsPrefix & ":", "");
				if(structKeyExists(aStr, n)) {
					if(NOT isArray(aStr[n])) {
						tmpContainer = aStr[n];
						aStr[n] = arrayNew(1);
						aStr[n][1] = tmpContainer;
					}
					if(arrayLen(aXml.XmlChildren[i].XmlChildren) GT 0) {
						aStr[n][arrayLen(aStr[n])+1] = this.xmlToStruct(aXml.XmlChildren[i], StructNew());
					} else {
						aStr[n][arrayLen(aStr[n])+1] = aXml.XmlChildren[i].XmlText;
					}
				} else {
					if(arrayLen(aXml.XmlChildren[i].XmlChildren) GT 0) {
						aStr[n] = this.xmlToStruct(aXml.XmlChildren[i], structNew());
					} else {
						if(isStruct(aXml.XmlAttributes) AND (structCount(aXml.XmlAttributes) GT 0)) {
							at_list = structKeyList(aXml.XmlAttributes);
							for(atr=1; atr LTE listLen(at_list); atr=atr+1) {
								if(listGetAt(at_list, atr) CONTAINS "xmlns:") {
									structDelete(aXml.XmlAttributes, listGetAt(at_list, atr));
								}
							}
							if(structCount(aXml.XmlAttributes) GT 0) {
								aStr['_attributes'] = aXml.XmlAttributes;
							}
						}
					
						if(isStruct(aXml.XmlChildren[i].XmlAttributes) AND (structCount(aXml.XmlChildren[i].XmlAttributes) GT 0)) {
							aStr[n] = aXml.XmlChildren[i].XmlText;
							attrib_list = structKeyList(aXml.XmlChildren[i].XmlAttributes);
							for(attrib=1; attrib LTE listLen(attrib_list, attrib); attrib=attrib+1) {
								if(listGetAt(attrib_list, attrib) CONTAINS "xmlns:") {
									structDelete(aXml.XmlChildren[i].XmlAttributes, listGetAt(attrib_list, attrib));
								}
							}
							if(structCount(aXml.XmlChildren[i].XmlAttributes) GT 0) {
								aStr[n & '_attributes'] = aXml.XmlChildren[i].XmlAttributes;
							}
						} else {
							aStr[n] = aXml.XmlChildren[i].XmlText;
						}
					}
				}
			}
			return(aStr);
		</cfscript>
	</cffunction>

	<cffunction name="arrayToXML" returntype="any" access="public" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="rootElement" type="any" required="yes">
		<cfargument name="itemElement" type="any" required="yes">
		
		<cfscript>
			var s = createObject('java', 'java.lang.StringBuffer').init('<?xml version="1.0" encoding="UTF-8"?>');
			var i = 1;
			
			s.append("<#Arguments.rootElement#>");
			for(i=1; i LTE ArrayLen(Arguments.data); i=i+1) s.append("<#Arguments.itemElement#>#xmlFormat(Arguments.data[i])#</#Arguments.itemElement#>");
			s.append("</#Arguments.rootElement#>");
			return(s.toString());
		</cfscript>
	</cffunction>
	
	<cffunction name="listToXML" returnType="any" access="public" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="rootElement" type="any" required="yes">
		<cfargument name="itemElement" type="any" required="yes">
		<cfargument name="delimiter" type="any" required="no" default=",">
		
		<cfreturn arrayToXML(listToArray(Arguments.data, Arguments.delimiter), Arguments.rootElement, Arguments.itemElement)>
	</cffunction>
	
	<cffunction name="queryToXML" returnType="any" access="public" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="rootElement" type="any" required="yes">
		<cfargument name="itemElement" type="any" required="yes">
		<cfargument name="cDataCols" type="any" required="no" default="">
		
		<cfscript>
			var s = createObject('java', 'java.lang.StringBuffer').init('<?xml version="1.0" encoding="UTF-8"?>');
			var col = "";
			var columns = Arguments.data.columnList;
			var txt = "";
			var i = 1;
			var j = 1;
			
			s.append("<#Arguments.rootElement#>");
			for(i=1; i LTE Arguments.data.Recordcount; i=i+1) {
				s.append("<#Arguments.itemElement#>");
				for(j=1; j LTE ListLen(columns); j=j+1) {
					col = ListGetAt(columns,j);
					txt = Arguments.data[col][i];
					if(isSimpleValue(txt)) {
						if(ListFindNoCase(Arguments.cDataCols, col)) {
							txt = "<![CDATA[" & txt & "]]>";
						} else {
							txt = xmlFormat(txt);
						}
					} else {
						txt = "";
					}
					s.append("<#col#>#txt#</#col#>");
				}
				s.append("</#Arguments.itemElement#>");
			}
			s.append("</#Arguments.rootElement#>");
			return(s.toString());
		</cfscript>
	</cffunction>
	
	<cffunction name="structToXML" returnType="any" access="public" output="no">
		<cfargument name="data" type="any" required="no">
		<cfargument name="rootElement" type="any" required="no">
		<cfargument name="itemElement" type="any" required="no">
	
		<cfscript>
			var s = createObject('java', 'java.lang.StringBuffer').init('<?xml version="1.0" encoding="UTF-8"?>');
			var keys = StructKeyList(Arguments.data);
			var key = "";
			var aKeys = "";
			var aKey = "";
			var tArr = "";
			var aStr = "";
			var i = 1;
			var j = 1;
			
			s.append("<#Arguments.rootElement#>");
			s.append("<#Arguments.itemElement#>");
			for(i=1; i LTE ListLen(keys); i=i+1) {
				key = ListGetAt(keys, i);
				if(isSimpleValue(Arguments.data[key])) {
					s.append("<#key#>#xmlFormat(Arguments.data[key])#</#key#>");
				} else {
					if(isArray(Arguments.data[key])) {
						tArr = Arguments.data[key];
						for(j=1; j LTE ArrayLen(tArr); j=j+1) {
							aStr = tArr[j];
							aKeys = StructKeyList(aStr);
							for(k=1; k LTE ListLen(aKeys); k=k+1) {
								aKey = ListGetAt(aKeys, k);
								if(isSimpleValue(aStr[aKey])) s.append("<#aKey#>#xmlFormat(aStr[aKey])#</#aKey#>");
							}
						}
					}
				}
			}
			s = s.append("</#Arguments.itemElement#>");
			s = s.append("</#Arguments.rootElement#>");
			return(s);
		</cfscript>
	</cffunction>

	<cffunction name="ProcessURL" returntype="any" access="public" output="no">
		<cfscript>
			return;
		</cfscript>
	</cffunction>

	<cffunction name="getResultLabel" returntype="any" access="public" output="no">
		<cfargument name="resultObj" type="any" required="yes">
		<cfargument name="labelTypeID" type="any" required="no">
		<cfargument name="labelTypeName" type="any" required="no">

		<cfset var result = "">
		<cfif listFindNoCase(resultObj.ColumnList, "Label")>
			<cfquery name="result" dbtype="query">
				SELECT Label
				FROM Arguments.resultObj
				WHERE
					<cfif structKeyExists(Arguments, "labelTypeName")>
						LabelType = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.labelTypeName#">
					<cfelseif structKeyExists(Arguments, "labelTypeID")>
						LabelTypeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#Arguments.labelTypeID#">
					<cfelse>
						1 = <cfqueryparam cfsqltype="cf_sql_integer" value="1">
					</cfif>
			</cfquery>
			<cfif result.RecordCount>
				<cfreturn result.Label[1]>
			</cfif>
		</cfif>
		<cfreturn "*label*">
	</cffunction>

	<cffunction name="MSWordFix" returnType="any" access="public" output="no">
		<cfargument name="text" type="any" required="yes">
		<cfscript>
			var i = 0;
	
			text = Replace(text, Chr(128), "&euro;", "All");
			text = Replace(text, Chr(130), ",", "All");
			text = Replace(text, Chr(131), "<em>f</em>", "All");
			text = Replace(text, Chr(132), ",,", "All");
			text = Replace(text, Chr(133), "...", "All");
			text = Replace(text, Chr(136), "^", "All");
			text = Replace(text, Chr(139), ")", "All");
			text = Replace(text, Chr(140), "Oe", "All");
			text = Replace(text, Chr(145), "`", "All");
			text = Replace(text, Chr(146), "'", "All");
			text = Replace(text, Chr(147), """", "All");
			text = Replace(text, Chr(148), """", "All");
			text = Replace(text, Chr(149), "*", "All");
			text = Replace(text, Chr(150), "-", "All");
			text = Replace(text, Chr(151), "--", "All");
			text = Replace(text, Chr(152), "~", "All");
			text = Replace(text, Chr(153), "&trade;", "All");
			text = Replace(text, Chr(155), ")", "All");
			text = Replace(text, Chr(156), "oe", "All");
			for (i=128; i LTE 159; i=i+1) text = replace(text, Chr(i), "", "All");
			text = replace(text, Chr(160), "&nbsp;", "All");
			text = replace(text, Chr(163), "&pound;", "All");
			text = replace(text, Chr(169), "&copy;", "All");
			text = replace(text, Chr(176), "&deg;", "All");
			for (i=160; i LTE 255; i=i+1) text = reReplace(text, "(#Chr(i)#)", "&###i#;", "All");
			text = reReplace(text, "&##([0-2][[:digit:]]{2})([^;])", "&##\1;\2", "All");
			text = reReplace(text, "&##038;", "&amp;", "All");
			text = reReplace(text, "&##060;", "&lt;", "All");
			text = reReplace(text, "&##062;", "&gt;", "All");
			text = reReplace(text, "&amp(^;)", "&amp;\1", "All");
			text = reReplace(text, "&quot(^;)", "&quot;\1", "All");
			return(text);
		</cfscript>
	</cffunction>

	<cffunction name="css" access="public" returntype="any" output="no">
		<cfargument name="filename" type="any" required="yes">
		<cfscript>
			var s = createObject('java', 'java.lang.StringBuffer').init('');

			if(Request.cssQueue.indexOf(Arguments.Filename)) return;
			Request.cssQueue.push(Arguments.Filename);

			if(fileExists(Application.Settings.RootPath & Replace(Right(Arguments.filename, Len(Arguments.filename)-1), "/", "\", "ALL"))) {
				s.append('<link rel="stylesheet" type="text/css" href="');
				s.append(arguments.filename);
				s.append('" />');
				this.AddHTMLHeader(s.toString());
			}
		</cfscript>
	</cffunction>

	<cffunction name="js" access="public" returntype="any" output="no">
		<cfargument name="filename" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfscript>
			var s = createObject('java', 'java.lang.StringBuffer').init('');
			var i = 0;

			if(Request.jsQueue.indexOf(Arguments.Filename)) return;
			Request.jsQueue.push(Arguments.Filename);

			if(fileExists(Application.Settings.RootPath & replace(right(Arguments.filename, len(Arguments.filename)-1), "/", "\", "ALL"))) {
				s.append('<script type="text/javascript" src="');
				s.append(arguments.filename);
				for(i=1; i LTE listLen(arguments.params, ","); i=i+1) s.append(" " & listGetAt(arguments.params, i, ",") & " ");
				s.append('"></script>');
				this.AddHTMLHeader(s.toString());
			}
		</cfscript>
	</cffunction>

	<cffunction name="queryRowToStruct" returntype="any" access="public" output="no">
		<cfargument name="qry" type="any" required="yes">
		<cfargument name="row" type="any" required="no" default="1">
		<cfscript>
			var i = 1;
			var cols = listToArray(Arguments.qry.columnList);
			var result = structnew();

			for(i=1; i LTE arrayLen(cols); i=i+1) result[cols[i]] = Arguments.qry[cols[i]][Arguments.row];

			return(result);
		</cfscript>
	</cffunction>

	<cffunction name="queryToArrayOfStruct" returntype="any" access="public" output="no">
		<cfargument name="theQuery" type="any" required="yes">
		<cfscript>
			var result = arrayNew(1);
			var cols = listToArray(Arguments.theQuery.columnList);
			var col = 1;
			var row = 1;
			var thisRow = "";

			for(row=1; row LTE Arguments.theQuery.recordCount; row=row+1) {
					thisRow = structNew();
					for(col=1; col LTE arrayLen(cols); col=col+1) thisRow[cols[col]] = Arguments.theQuery[cols[col]][row];
					arrayAppend(result, duplicate(thisRow));
			}
			return(result);
		</cfscript>
	</cffunction>

	<cffunction name="forward" returntype="any" access="public" output="yes">
		<cfargument name="url" type="any" required="yes">
		<cfset getPageContext().forward(Arguments.url)>
	</cffunction>

	<cffunction name="ccMask" returntype="any" access="public" output="no">
		<cfargument name="ccnum" type="any" required="yes">
		<cfreturn "#repeatString('*',val(len(Arguments.ccnum)-4))##right(Arguments.ccnum,4)#">
	</cffunction>

	<cffunction name="cssCompactFormat" returntype="any" access="public" output="no">
		<cfargument name="sInput" type="any" required="yes">
		<cfscript>
			Arguments.sInput = reReplace(Arguments.sInput, "[[:space:]]{2,}", " ", "all");
			Arguments.sInput = reReplace(Arguments.sInput, "/\*[^\*]+\*/", " ", "all");
			Arguments.sInput = reReplace(Arguments.sInput, "[ ]*([:{};,])[ ]*", "\1", "all");
			return(Arguments.sInput);
		</cfscript>
	</cffunction>

	<cffunction name="htmlCompressFormat" returntype="any" access="public" output="no">
		<cfargument name="sInput" type="any" required="yes">
		<cfargument name="level" type="any" required="no" default="2">
		<cfscript>
			switch(Arguments.level) {
				case "3" :
					// extra compression can screw up a few little pieces of HTML, doh
					Arguments.sInput = reReplace(Arguments.sInput, "[[:space:]]{2,}", " ", "all");
					Arguments.sInput = replace(Arguments.sInput, "> <", "><", "all");
					Arguments.sInput = reReplace(sInput, "<!--[^>]+>", "", "all");
					break;

				case "2" :
					Arguments.sInput = reReplace(Arguments.sInput, "[[:space:]]{2,}", chr( 13 ), "all");
					break;
				
				case "1":
					// only compresses after a line break
					Arguments.sInput = reReplace(Arguments.sInput, "(" & chr( 10 ) & "|" & chr( 13 ) & ")+[[:space:]]{2,}", chr( 13 ), "all");
					break;
			}
			return(Arguments.sInput);
		</cfscript>
	</cffunction>

	<cffunction name="alphaPng" returntype="any" access="public" output="yes">
		<cfargument name="src" type="any" required="no" default="">
		<cfargument name="width" type="any" required="no" default="">
		<cfargument name="height" type="any" required="no" default="">
		<cfargument name="spacer" type="any" required="no" default="">
		<cfargument name="cursor" type="any" required="no" default="">
		<cfargument name="alt" type="any" required="no" default="">
		<cfscript>
			var s = CreateObject('java', 'java.lang.StringBuffer').init('');
	
			s.append('<!--[if !IE]>--><img src="' & Arguments.src & '" alt="' & Arguments.alt & '" /><!--<![endif]-->');
			s.append('<!--[if gte IE 7]><img src="' & Arguments.src & '" alt="' & Arguments.alt & '" /><![endif]-->');
			s.append('<!--[if lt IE 7]><span style="cursor:' & Arguments.cursor & '; display:block; width:' & Arguments.width & 'px; height:' & Arguments.height & 'px; filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src=' & Arguments.src & ',sizingMethod=scale);"><img src="' & Arguments.src & '" width="' & Arguments.width & '" height="' & Arguments.height & '" alt="' & Arguments.alt & '" /></span><![endif]-->');
			writeoutput(s.toString());
		</cfscript>
	</cffunction>

	<cffunction name="nameCase" returntype="any" access="public" output="no">
		<cfargument name="name" type="string" required="true">
		<cfset Arguments.name = uCase(Arguments.name)>
		<cfreturn reReplace(Arguments.name,"([[:upper:]])([[:upper:]]*)","\1\L\2\E","all")>
	</cffunction>

	<cffunction name="arrayOfStructToQuery" returntype="any" access="public" output="no">
		<cfargument name="theArray" type="any" required="yes">
		<cfscript>
			var columns = "";
			var result = queryNew("");
			var i=0;
			var j=0;

			if(NOT arrayLen(Arguments.theArray)) return(result);
			
			columns = structKeyArray(Arguments.theArray[1]);
			result = queryNew(arrayToList(columns));
			queryAddRow(result, arrayLen(Arguments.theArray));
			for(i=1; i LTE arrayLen(Arguments.theArray); i=i+1) {
				for(j=1; j LTE arrayLen(columns); j=j+1) {
					querySetCell(result, columns[j], Arguments.theArray[i][columns[j]], i);
				}
			}
			return(result);
		</cfscript>
	</cffunction>

	<cffunction name="structToQueryUpdateString" returntype="any" access="public" output="no">
		<cfargument name="struct" type="any" required="yes">
		<cfargument name="typeStruct" type="any" required="no">
		<cfscript>
			var result = createObject('java', 'java.lang.StringBuffer').init('');
			var typeCheck = structKeyExists(arguments, "typeStruct");
			var key = "";

			for(key in Arguments.struct) {
				if(typeCheck) {
					if(structKeyExists(Arguments.typeStruct, key)) {
						switch(arguments.typeStruct[key]) {
							case 'varchar' :
								result.append(key & "='" & Arguments.struct[key] & "',");
								break;
							case 'integer' :
								result.append(key & "=" & Arguments.struct[key] & ",");
								break;
							default :
								result.append(key & "='" & Arguments.struct[key] & "',");
								break;
						}
					} else {
						result.append(key & "='" & Arguments.struct[key] & "',");
					}
				} else {
					if(isSimpleValue(Arguments.struct[key])) {
						if(isNumeric(Arguments.struct[key])) {
							result.append(key & "=" & Arguments.struct[key] & ",");
						} else {
							result.append(key & "='" & Arguments.struct[key] & "',");
						}
					}
				}
			}
			result.deleteCharAt(result.length()-1);

			return(result.toString());
		</cfscript>
	</cffunction>

	<cffunction name="structToQueryInsertString" returntype="any" access="public" output="no">
		<cfargument name="struct" type="any" required="yes">
		<cfargument name="typeStruct" type="any" required="no">
		<cfscript>
			var result = createObject('java', 'java.lang.StringBuffer').init('');
			var typeCheck = structKeyExists(arguments, "typeStruct");
			var key = "";

			result.append('(');
			for(key in Arguments.struct) result.append(key & ',');
			result.deleteCharAt(result.length()-1);
			result.append(') VALUES (');
			
			for(key in Arguments.struct) {
				if(typeCheck) {
					if(structKeyExists(Arguments.typeStruct, key)) {
						switch(arguments.typeStruct[key]) {
							case 'varchar' :
								result.append("'" & Arguments.struct[key] & "',");
								break;
							case 'integer' :
								result.append(Arguments.struct[key] & ',');
								break;
							default :
								result.append("'" & Arguments.struct[key] & "',");
								break;
						}
					} else {
						result.append("'" & Arguments.struct[key] & "',");
					}
				} else {
					if(isSimpleValue(Arguments.struct[key])) {
						if(isNumeric(Arguments.struct[key])) {
							result.append(Arguments.struct[key] & ',');
						} else {
							result.append("'" & Arguments.struct[key] & "',");
						}
					}
				}
			}
			result.deleteCharAt(result.length()-1);
			result.append(')');

			return(result.toString());
		</cfscript>
	</cffunction>

	<cffunction name="structToQueryUpdateString400" returntype="any" access="public" output="no">
		<cfargument name="struct" type="any" required="yes">
		<cfargument name="typeStruct" type="any" required="no">
		<cfscript>
			var result = createObject('java', 'java.lang.StringBuffer').init('');
			var typeCheck = structKeyExists(arguments, "typeStruct");			
			var key = "";

			for(key in Arguments.struct) {
				if(typeCheck) {
					if(structKeyExists(Arguments.typeStruct, key)) {
						switch(Arguments.typeStruct[key]) {
							case 'varchar' :
								result.append(replace(key,"$$","##","ALL") & "='" & Arguments.struct[key] & "',");
								break;
							case 'integer' :
							result.append(replace(key,"$$","##","ALL") & "=" & Arguments.struct[key] & ",");
								break;
							default :
							result.append(replace(key,"$$","##","ALL") & "='" & Arguments.struct[key] & "',");
								break;
						}
					} else {
						result.append(replace(key,"$$","##","ALL") & "='" & Arguments.struct[key] & "',");
					}
				} else {
					if(isSimpleValue(Arguments.struct[key])) {
						if(isNumeric(Arguments.struct[key])) {
							result.append(replace(key,"$$","##","ALL") & "=" & Arguments.struct[key] & ",");
						} else {
							result.append(replace(key,"$$","##","ALL") & "='" & Arguments.struct[key] & "',");
						}
					}
				}
			}
			result.deleteCharAt(result.length()-1);

			return(result.toString());
		</cfscript>
	</cffunction>

	<cffunction name="structToQueryInsertString400" returntype="any" access="public" output="no">
		<cfargument name="struct" type="any" required="yes">
		<cfargument name="typeStruct" type="any" required="no">
		<cfscript>
			var result = createObject('java', 'java.lang.StringBuffer').init('');
			var typeCheck = structKeyExists(arguments, "typeStruct");
			var key = "";

			result.append('(');
			for(key in Arguments.struct) result.append(replace(key,"$$","##","ALL") & ',');
			result.deleteCharAt(result.length()-1);
			result.append(') VALUES (');
			
			for(key in Arguments.struct) {
				if(isSimpleValue(Arguments.struct[key])) {
					if(typeCheck) {
						if(structKeyExists(Arguments.typeStruct, key)) {
							switch(Arguments.typeStruct[key]) {
								case 'varchar' :
									result.append("'" & Arguments.struct[key] & "',");
									break;
								case 'integer' :
									result.append(Arguments.struct[key] & ",");
									break;
								default :
									result.append("'" & Arguments.struct[key] & "',");
									break;
							}
						} else {
							result.append("'" & Arguments.struct[key] & "',");
						}
					} else {
						if(isNumeric(Arguments.struct[key])) {
							result.append(Arguments.struct[key] & ',');
						} else {
							result.append("'" & Arguments.struct[key] & "',");
						}
					}
				}
			}
			result.deleteCharAt(result.length()-1);
			result.append(')');

			return(result.toString());
		</cfscript>
	</cffunction>

	<cffunction name="filterFilename" returntype="any" access="public" output="no">
		<cfargument name="filename" type="any" required="true">
		<cfscript>
			var filenameRE = "[" & "'" & '"' & "##" & "/\\%&`@~!,:;=<>\+\*\?\[\]\^\$\(\)\{\}\|]";
			var newfilename = reReplace(arguments.filename,filenameRE, "", "ALL");
			newfilename = replace(newfilename, " ", "-", "ALL");
			return(newfilename);
		</cfscript>
	</cffunction>

	<cffunction name="dumpToString" returntype="any" access="public" output="no">
		<cfargument name="variable" type="any" required="yes">
		<cfargument name="delim" type="any" required="no" default="#chr(13)#">
		<cfargument name="label" type="any" required="no" default="">
		<cfscript>
			var var2dump = Arguments.variable;
			var newDump = "";
			var keyName = "";
			var loopCount = 0;
			var s = createObject('java', 'java.lang.StringBuffer').init('');

			if(isSimpleValue(var2dump)) {
				if(Arguments.label NEQ "") {
					s.append(uCase(Arguments.label) & " = " & Arguments.variable & Arguments.delim);
			} else {
					s.append(Arguments.variable & Arguments.delim);
				}
			} else if(isArray(var2dump)) {
				if(Arguments.label NEQ "") {
					s.append(uCase(Arguments.label) & " = [Array]" & Arguments.delim);
				} else {
					s.append("[Array]" & Arguments.delim);
				}
				for(loopCount=1; loopCount LTE arrayLen(var2dump); loopCount=loopCount+1) {
					if(isSimpleValue(var2dump[loopcount])) {
						s.append("[" & loopCount & "] = " & var2dump[loopCount] & Arguments.delim);
					} else {
						s.append(this.dumpToString(var2dump[loopCount], Arguments.delim, Arguments.label));
					}
				}
			} else if(isStruct(var2dump)) {
				if(Arguments.label NEQ "") {
					s.append(uCase(Arguments.label) & " = [Struct]" & Arguments.delim);
				} else {
					s.append("[Struct]" & Arguments.delim);
				}
				for(keyName in var2dump) {
					if(isSimpleValue(var2dump[keyName])) {
						if(Arguments.label NEQ "") {
							s.append(uCase(Arguments.label) & "." & uCase(keyName) & " = " & var2dump[keyName] & Arguments.delim);
						} else {
							s.append(uCase(keyName) & " = " & var2dump[keyName] & Arguments.delim);
						}
					} else {
						s.append(this.dumpToString(var2dump[keyName], Arguments.delim, keyname));
					}
				}
			} else {
				if(Arguments.label NEQ "") {
					s.append(uCase(Arguments.label) & " = [Unsupported type]" & Arguments.delim);
				} else {
					s.append("[Unsupported type]" & Arguments.delim);
				}
			}

			return(s.toString());
		</cfscript>
	</cffunction>

	<cffunction name="getRequestOrigin" returntype="any" access="public" output="no">
		<cfscript>
			if(NOT structKeyExists(getHttpRequestData().headers, "Host")) return(Application.Constants.BIGIP_REQUEST);
			return(Application.Constants.CLIENT_REQUEST);
		</cfscript>
	</cffunction>

	<cffunction name="getRequestProtocol" returntype="any" access="public" output="no">
		<cfscript>
			var h = getHttpRequestData();

			if(structKeyExists(h.headers, "SSL")) {
				return(IIF(h.headers["SSL"] EQ 1, DE("https"), DE("http")));
			} else {
				return(IIF(cgi.HTTPS EQ "on", DE("https"), DE("http")));
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

	<cffunction name="ftp" returntype="any" access="public" output="no">
		<cfargument name="server" type="any" required="yes">
		<cfargument name="localFile" type="any" required="yes">
		<cfargument name="remoteFile" type="any" required="yes">
		<cfargument name="action" type="any" required="no" default="PUTFILE">
		<cfargument name="port" type="any" required="no" default="21">
		<cfargument name="username" type="any" required="no" default="">
		<cfargument name="password" type="any" required="no" default="">
		<cfargument name="fingerPrint" type="any" required="no" default="">
		<cfargument name="secure" type="any" required="no" default="No">
		<cfargument name="stopOnError" type="any" required="no" default="Yes">

		<cfftp connection="results"
			action="#Arguments.Action#"
			server="#Arguments.Server#"
			port="#Arguments.Port#"
			localfile="#Arguments.localFile#"
			remotefile="#Arguments.remoteFile#"
			username="#Arguments.userName#"
			password="#Arguments.password#"
			secure="#Arguments.secure#"
			stoponerror="#Arguments.stopOnError#"
			fingerprint="#Arguments.fingerPrint#">
		<cfreturn results>
	</cffunction>

	<cffunction name="checkDSN" access="public" returntype="any" output="no">
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

</cfcomponent>