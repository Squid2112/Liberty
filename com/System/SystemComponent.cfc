component displayname='CoreSystemObjectComponent' hint='Core System Object Component' output='false' {

	public any function init(string dsn=Application.Settings.DSN.System) output='false' {
		var manifest = '';

		this.Wrappers = createObject('component','com.System.WrappersComponent').init();

		this.DSN = Arguments.DSN;
		this.dsnValid = this.dsnExists(this.DSN);

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

		this.virtualMappings = arrayNew(1);
		if(fileExists(Application.Settings.rootPath & 'com\Manifests\VirtualMappings.manifest.json')) {
			manifest = fileRead(Application.Settings.rootPath & 'com\Manifests\VirtualMappings.manifest.json');
			this.virtualMappings = duplicate(this.jsonDecode(manifest));
			if(!isArray(this.virtualMappings)) this.virtualMappings = arrayNew(1);
		}

		this.coreJS = arrayNew(1);
		if(fileExists(Application.Settings.rootPath & 'com\Manifests\Core.JavaScripts.manifest.json')) {
			manifest = fileRead(Application.Settings.rootPath & 'com\Manifests\Core.JavaScripts.manifest.json');
			this.coreJS = duplicate(this.jsonDecode(manifest));
			if(!isArray(this.coreJS)) this.coreJS = arrayNew(1);
		}

		this.coreCSS = arrayNew(1);
		if(fileExists(Application.Settings.rootPath & 'com\Manifests\Core.Styles.manifest.json')) {
			manifest = fileRead(Application.Settings.rootPath & 'com\Manifests\Core.Styles.manifest.json');
			this.coreCSS = duplicate(this.jsonDecode(manifest));
			if(!isArray(this.coreCSS)) this.coreCSS = arrayNew(1);
		}

		if(fileExists(Application.Settings.rootPath & 'com\Manifests\Application.manifest.json')) {
			manifest = fileRead(Application.Settings.rootPath & 'com\Manifests\Application.manifest.json');
			this.Objects.Application = duplicate(this.jsonDecode(manifest));
			if(!isArray(this.Objects.Application)) this.Objects.Application = arrayNew(1);
		}

		if(fileExists(Application.Settings.rootPath & 'com\Manifests\Session.manifest.json')) {
			manifest = fileRead(Application.Settings.rootPath & 'com\Manifests\Session.manifest.json');
			this.Objects.Session = duplicate(this.jsonDecode(manifest));
			if(!isArray(this.Objects.Session)) this.Objects.Session = arrayNew(1);
		}

		if(fileExists(Application.Settings.rootPath & 'com\Manifests\Request.manifest.json')) {
			manifest = fileRead(Application.Settings.rootPath & 'com\Manifests\Request.manifest.json');
			this.Objects.Request = duplicate(this.jsonDecode(manifest));
			if(!isArray(this.Objects.Request)) this.Objects.Request = arrayNew(1);
		}

		return(this);
	}

	public array function parseConicals(required string rootDomain, required string requestHost) output='false' {
		return(listToArray(replaceNoCase(Arguments.requestHost,Arguments.rootDomain,'','ALL'),'.',false));
	}

	public string function parse404(required any request, required any url, required string queryString) output='false' {
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
		if(virtW && virtS) {
			if(virtW < virtS) {
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

		if(trim(virtRest) != '') {
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
				if(left(item, 4) == '404;') {
					structDelete(Arguments.url, item, false);
					break;
				}
			}
		}
		return(this.flattenURL(Arguments.url));
	}

	public struct function virtualResolver(required string vPath) output='false' {
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
			if(!vInfo.RecordCount) vInfo = Application.Database.getVirtualURI(vInfo);
			if(vInfo.RecordCount) viewName = vInfo.viewName;
			if(!vInfo.RecordCount) viewName = ListLast(Arguments.vPath,'/');
		}

		if(!vInfo.recordCount) {
			if(fileExists(expandPath('/views' & Arguments.vPath) & "\index.cfm")) {
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
			} else {
				if(fileExists(expandPath('/') & 'Views' & cgi.SCRIPT_NAME)) {
					vInfo = {
						Active = true,
						contentType = listLast(cgi.SCRIPT_NAME,'.'),
						doRedirect = false,
						isConical = false,
						isDefault = false,
						mapAsset = '',
						recordCount = 1,
						reDirectType = '',
						URI = replace(cgi.SCRIPT_NAME,listLast(cgi.SCRIPT_NAME,'/'),''),
						URL = '',
						viewName = replace(cgi.SCRIPT_NAME,listLast(cgi.SCRIPT_NAME,'/'),''),
						viewTemplate = listLast(cgi.SCRIPT_NAME,'/'),
						virtualPath = replace(cgi.SCRIPT_NAME,listLast(cgi.SCRIPT_NAME,'/'),''),
						virtualUriId = 0
					};
					if(len(vInfo.viewName) > 2) {
						vInfo.viewName = mid(vInfo.viewName,2,len(vInfo.viewName)-2);
						vInfo.virtualPath = left(vInfo.virtualPath,len(vInfo.virtualPath)-2);
					}
				}
			}
		}
		return(vInfo);
	}

	public void function parseSearchUrl(required any Request, required any Visitor) output='false' {
		var i = 0;
		var uri = '';
		var options = '';
		var sOptions = '';
		var sets = '';
		var tmp = '';
		var sortOptions = { sortBy='Relevance', perPage=9, onPage=1 };

		if(arrayLen(Arguments.Request.vArray) < 2) return;

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

		if((arrayLen(Arguments.Request.vArray) > 2) && find('@',Arguments.Request.vArray[3])){
			sOptions = replace(Arguments.Request.vArray[3],'@','');
			sOptions = replaceNoCase(sOptions,'-With-','|','ALL');
			sOptions = replaceNoCase(sOptions,'-Page-','|','ALL');		
		}

		sets = listToArray(options,'|',false);
		for(i=1; i <= arrayLen(sets); i++) {
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
	}

	public string function flattenUrl(required any url) output='false' {
		var result = '';
		var item = '';

		if(structCount(Arguments.url)) {
			for(item IN Arguments.url) if(trim(item) > '') result = result & trim(item) & '=' & trim(Arguments.url[item]) & '&';
			if(result > '') result = left(result, len(result) - 1);
		}
		return(result);
	}

	public void function processUrlSwitchs(required struct Session, required struct Url) output='false' {
		if(!structCount(Arguments.Url)) return;

		if(structKeyExists(Arguments.Url,'clearCache') && (Application.Settings.isDevEnvironment || (structKeyExists(Arguments.Url,'auth') && (hash(Arguments.Url.auth,'SHA-256') == Application.Settings.Authorizations.cache)))) {
			directoryDelete('/inram/*',true);
			this.fillCache();
		}

		if(structKeyExists(Arguments.Url,'Debug') && (Application.Settings.isDevEnvironment || (structKeyExists(Arguments.Url,'auth') && (hash(Arguments.Url.auth,'SHA-256') == Application.Settings.Authorizations.debug)))) Arguments.Session.Visitor.Debug = (Arguments.Url.debug == 'on') ? true : false;
		if(structKeyExists(Arguments.Url,'Cache') && (Application.Settings.isDevEnvironment || (structKeyExists(Arguments.Url,'auth') && (hash(Arguments.Url.auth,'SHA-256') == Application.Settings.Authorizations.cache)))) Application.Settings.cache = (Arguments.Url.cache == 'on') ? true : false;
		if(structKeyExists(Arguments.Url,'combineAll') && (Application.Settings.isDevEnvironment || (structKeyExists(Arguments.Url,'auth') && (hash(Arguments.Url.auth,'SHA-256') == Application.Settings.Authorizations.combine)))) {
			Application.Settings.combineJs = (Arguments.Url.combineAll == 'on') ? true : false;
			Application.Settings.combineCss = (Arguments.Url.combineAll == 'on') ? true : false;
		}
		if(structKeyExists(Arguments.Url,'combineJs') && (Application.Settings.isDevEnvironment || (structKeyExists(Arguments.Url,'auth') && (hash(Arguments.Url.auth,'SHA-256') == Application.Settings.Authorizations.combine)))) Application.Settings.combineJs = (Arguments.Url.combineJs == 'on') ? true : false;
		if(structKeyExists(Arguments.Url,'combineCss') && (Application.Settings.isDevEnvironment || (structKeyExists(Arguments.Url,'auth') && (hash(Arguments.Url.auth,'SHA-256') == Application.Settings.Authorizations.combine)))) Application.Settings.combineCss = (Arguments.Url.combineCss == 'on') ? true : false;
		if(structKeyExists(Arguments.Url,'compressAll') && (Application.Settings.isDevEnvironment || (structKeyExists(Arguments.Url,'auth') && (hash(Arguments.Url.auth,'SHA-256') == Application.Settings.Authorizations.compress)))) {
			Application.Settings.combineJs = (Arguments.Url.compressAll == 'on') ? true : false;
			Application.Settings.combineCss = (Arguments.Url.compressAll == 'on') ? true : false;
		}
		if(structKeyExists(Arguments.Url,'compressJs') && (Application.Settings.isDevEnvironment || (structKeyExists(Arguments.Url,'auth') && (hash(Arguments.Url.auth,'SHA-256') == Application.Settings.Authorizations.compress)))) Application.Settings.compressJs = (Arguments.Url.compressJs == 'on') ? true : false;
		if(structKeyExists(Arguments.Url,'compressCss') && (Application.Settings.isDevEnvironment || (structKeyExists(Arguments.Url,'auth') && (hash(Arguments.Url.auth,'SHA-256') == Application.Settings.Authorizations.compress)))) Application.Settings.compressCss = (Arguments.Url.compressCss == 'on') ? true : false;
		if(structKeyExists(Arguments.Url,'pageCompress') && (Application.Settings.isDevEnvironment || (structKeyExists(Arguments.Url,'auth') && (hash(Arguments.Url.auth,'SHA-256') == Application.Settings.Authorizations.compress)))) Application.Settings.pageCompress = (Arguments.Url.pageCompress == 'on') ? true : false;
		if(structKeyExists(Arguments.Url,'gZip') && (Application.Settings.isDevEnvironment || (structKeyExists(Arguments.Url,'auth') && (hash(Arguments.Url.auth,'SHA-256') == Application.Settings.Authorizations.gZip)))) Application.Settings.gZip = (Arguments.Url.gZip == 'on') ? true : false;
	}

	public void function writeBaseDocument(required any Request, required struct virtualInfo) output='true' {
		var s = createObject('java','java.lang.StringBuffer').init('');
		var viewTemplateName = listFirst(Arguments.virtualInfo.viewTemplate,'.');
		var i = 0;

		if(Application.Settings.cache && this.coreFramework.Start.cache) {
			writeOutput(this.coreFramework.Start.content);
		} else {
			if(fileExists(Application.Settings.rootPath & 'com\Framework\coreFrameworkStart.cfm')) this.Wrappers.include('/com/Framework/coreFrameworkStart.cfm');
		}

		s.append('<title>');
/*
		if(structKeyExists(Arguments.Request.pageData,'Title')) {
			s.append(this.proccessDirectives(Arguments.Request.pageData['Title'][1].Contents));
			s.append(' | ');
		}
*/
		s.append(Application.Settings.rootDomain);
		s.append('</title>');
		s.append('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />');
//			s.append(this.proccessDirectives(this.getMetaTags(Arguments.virtualInfo.viewTemplate)));
		s.append('<meta name="HOME_URL" content="http://#Application.Settings.defaultConical#.#Application.Settings.rootDomain#/" />');
		s.append('<meta name="LANGUAGE" content="ENGLISH" />');
		s.append('<meta name="MSSmartTagsPreventParsing" content="TRUE" />');
		s.append('<meta name="DOC-TYPE" content="PUBLIC" />');
		s.append('<meta name="DOC-CLASS" content="COMPLETED" />');
		s.append('<meta name="DOC-RIGHTS" content="PUBLIC DOMAIN" />');

/***  NEED to modify the JS && CSS manifest mechanism so that it loads a -min version if available ***
		if(fileExists(Application.Settings.rootPath & 'css/global.min.css')) {
			this.css('/css/global.min.css');
		} else if(fileExists(Application.Settings.rootPath & 'css/global.css')) {
			this.css('/css/global.css');
		}
*/

		for(i=1; i <= arrayLen(this.coreCSS); i++) s.append('<link rel="stylesheet" type="text/css" href="' & this.coreCSS[i].file & '" />');
		for(i=1; i <= arrayLen(this.coreJS); i++) s.append('<script type="text/javascript" src="' & this.coreJS[i].file & '"></script>');
		s.append('</head>');
		writeOutput(s.toString());

		if(Application.Settings.cache && this.baseFramework.Start.cache) {
			writeOutput(this.baseFramework.Start.content);
		} else {
			if(fileExists(Application.Settings.rootPath & 'com\Framework\baseFrameworkStart.cfm')) this.Wrappers.include('/com/Framework/baseFrameworkStart.cfm');
		}

		this.Wrappers.headers(name="Cache-Control", value="post-check=#getHttpTimeString(dateAdd('n', (Application.Settings.sessionTimeoutMinutes * 60), Now()))#,pre-check=#getHttpTimeString(dateAdd('n', (Application.Settings.sessionTimeoutMinutes * 120), Now()))#,max-age=#getHttpTimeString(DateAdd('d', 3, Now()))#");
		this.Wrappers.headers(name="Expires", value="#getHttpTimeString(dateAdd('d', 3, Now()))#");
	}

	public void function closePageContents(required struct Request) output='true' {
		if(!structKeyExists(Arguments.Request,'virtualInfo')) return;

		var i = 0;
		var buffer = createObject('java','java.lang.StringBuffer').init('');
		var viewTemplateName = listFirst(Arguments.Request.virtualInfo.viewTemplate,'.');
		var filename = '';
		var content = '';

		if(fileExists(Application.Settings.rootPath & "views/" & Arguments.Request.virtualInfo.viewName & '/css/' & viewTemplateName & '-min.css')) {
			content = fileRead(Application.Settings.rootPath & "views/" & Arguments.Request.virtualInfo.viewName & '/css/' & viewTemplateName & '-min.css');
			if(Application.Settings.compressCss) content = cssCompressor(content);
			if(len(content)) this.Wrappers.htmlHead(text='<style type="text/css">' & content & '</style>');			
		} else if(fileExists(Application.Settings.rootPath & 'views/' & Arguments.Request.virtualInfo.viewName & '/css/' & viewTemplateName & '.css')) {
			content = fileRead(Application.Settings.rootPath & "views/" & Arguments.Request.virtualInfo.viewName & '/css/' & viewTemplateName & '.css');
			if(Application.Settings.compressCss) content = cssCompressor(content);
			if(len(content)) this.Wrappers.htmlHead(text='<style type="text/css">' & content & '</style>');
		}

		if(fileExists(Application.Settings.rootPath & 'views/' & Arguments.Request.virtualInfo.viewName & '/js/' & viewTemplateName & '-min.js')) {
			content = fileRead(Application.Settings.rootPath & 'views/' & Arguments.Request.virtualInfo.viewName & '/js/' & viewTemplateName & '-min.js');
			if(Application.Settings.compressJs) content = this.jsCompressor(content);
			if(len(content)) this.Wrappers.htmlHead(text='<script type="text/javascript">' & content & '</script>');
		} else if(fileExists(Application.Settings.rootPath & 'views/' & Arguments.Request.virtualInfo.viewName & '/js/' & viewTemplateName & '.js')) {
			content = fileRead(Application.Settings.rootPath & 'views/' & Arguments.Request.virtualInfo.viewName & '/js/' & viewTemplateName & '.js');
			if(Application.Settings.compressJs) content = this.jsCompressor(content);
			if(len(content)) this.Wrappers.htmlHead(text='<script type="text/javascript">' & content & '</script>');
		}

		if(Application.Settings.cache && this.baseFramework.End.cache) {
			writeOutput(this.baseFramework.End.content);
		} else {
			if(fileExists(Application.Settings.rootPath & 'com\Framework\baseFrameworkEnd.cfm')) this.Wrappers.include('/com/Framework/baseFrameworkEnd.cfm');
		}
		if(Application.Settings.cache && this.coreFramework.End.cache) {
			writeOutput(this.coreFramework.End.content);
		} else {
			if(fileExists(Application.Settings.rootPath & 'com\Framework\coreFrameworkEnd.cfm')) this.Wrappers.include('/com/Framework/coreFrameworkEnd.cfm');
		}

this.Wrappers.htmlHead(text='<!-- cssQueue: -->');
		while(!Arguments.Request.cssQueue.empty()) {
			filename = Arguments.Request.cssQueue.pop();
Application.mail.send(to='hostmaster@thixo.net',subject=Application.Settings.rootPath & filename,obj=Arguments.Request.cssQueue);
			if(fileExists(Application.Settings.rootPath & filename)) {
				content = fileRead(Application.Settings.rootPath & filename);
				if(Application.Settings.compressCss) content = this.cssCompressor(content);
				if(len(content)) this.Wrappers.htmlHead(text='<style type="text/css">' & content & '</style>');
			}
		}
		while(!Arguments.Request.jsQueue.empty()) {
			filename = Arguments.Request.jsQueue.pop();
this.Wrappers.htmlHead(text='<!-- jsQueue:#filename# -->');
Application.mail.send(to='hostmaster@thixo.net',subject=Application.Settings.rootPath & filename,obj=Arguments.Request.jsQueue);
			if(fileExists(Application.Settings.rootPath & filename)) {
				content = fileRead(Application.Settings.rootPath & filename);
				if(Application.Settings.compressJs) content = this.jsCompressor(content);
				if(len(content)) this.Wrappers.htmlHead(text='<script type="text/javascript">' & content & '</script>');
			}
		}

		this.Wrappers.headers(name="Cache-Control", value="post-check=#(Application.Settings.sessionTimeoutSeconds)#,pre-check=#(Application.Settings.sessionTimeoutSeconds)#,max-age=#(Application.Settings.sessionTimeoutSeconds)#");
		this.Wrappers.headers(name="Expires", value="#getHttpTimeString(dateAdd('n', Application.Settings.sessionTimeoutMinutes, Now()))#");
	}

	public void function processView(required struct virtualInfo) output='true' {
		this.Wrappers.include('/views/' & Arguments.virtualInfo.viewName & '/' & Arguments.virtualInfo.viewTemplate);
	}

	public void function loadFrameworkObjects(required string scope) output='false' {
		var i = 0;
		var ptrScope = '';
		var tmpFile = '';
		
		switch(lCase(Arguments.scope)) {
			case 'application' : ptrScope = Application;
				break;
			case 'session' : ptrScope = Session;
				break;
			case 'request' : ptrScope = Request;
				break;
			default : return;
		}

		if(lcase(Arguments.scope) == 'application') {
			for(i=1; i <= arrayLen(this.Objects[Arguments.scope]); i++) {
				if(this.Objects[Arguments.scope][i].init) {
					ptrScope[this.Objects[Arguments.scope][i].name] = createObject(this.Objects[Arguments.scope][i].type,this.Objects[Arguments.scope][i].class).init();
				} else {
					ptrScope[this.Objects[Arguments.scope][i].name] = createObject(this.Objects[Arguments.scope][i].type,this.Objects[Arguments.scope][i].class);
				}
			}
		} else {
			if(!directoryExists('ram:///' & Arguments.scope)) directoryCreate('ram:///' & Arguments.scope);
			for(i=1; i <= arrayLen(this.Objects[Arguments.scope]); i++) {
				if(!fileExists('ram:///' & Arguments.scope & '/' & listLast(this.Objects[Arguments.scope][i].class,'.') & '.cfc')) {
					tmpFile = fileRead(Application.Settings.rootPath & replace(this.Objects[Arguments.scope][i].class,'.','\','ALL') & '.cfc');
					fileWrite('ram:///' & Arguments.scope & '/' & listLast(this.Objects[Arguments.scope][i].class,'.') & '.cfc',tmpFile);
				}
				if(this.Objects[Arguments.scope][i].init) {
					ptrScope[this.Objects[Arguments.scope][i].name] = createObject(this.Objects[Arguments.scope][i].type,'inram.' & Arguments.scope & listLast(this.Objects[Arguments.scope][i].class,'.')).init();
				} else {
					ptrScope[this.Objects[Arguments.scope][i].name] = createObject(this.Objects[Arguments.scope][i].type,'inram.' & Arguments.scope & listLast(this.Objects[Arguments.scope][i].class,'.'));
				}
			}
		}
	}

	public void function redirectToConical(required any Request, required any CGI, string conical='www') output='false' {
		var urlParms = (trim(Arguments.Request.URLparams) != '') ? '?' & Arguments.Request.URLparams : '';
		var nCons = listLen(Arguments.cgi.SERVER_NAME,'.');
		location(Arguments.Request.Protocol & '://' & Arguments.conical & '.' & listGetAt(Arguments.cgi.SERVER_NAME,nCons-1,'.') & '.' & listLast(Arguments.cgi.SERVER_NAME,'.') & Arguments.Request.vPath & ((findNoCase('index.cfm', Arguments.cgi.SCRIPT_NAME)) ? '' : Arguments.cgi.SCRIPT_NAME) & urlParms, false, '302');
	}

	public string function getRequestProtocol(required string HTTPS, required struct requestData) output='false' {
		if(structKeyExists(Arguments.requestData.headers,'SSL')) {
			return((Arguments.requestData.headers['SSL'] == 1) ? 'https' : 'http');
		} else {
			return((Arguments.HTTPS == 'on') ? 'https' : 'http');
		}
	}

	public string function getSslProtocol(required any CGI) output='false' {
		var result = getHttpRequestData().headers;

		if(structKeyExists(result, 'SSL')) return((result.SSL == 1) ? 'https' : 'http');
		if(structKeyExists(Arguments.CGI, 'HTTPS')) return((cgi.HTTPS == 'on') ? 'https' : 'http');
		return('http');
	}

	public void function showDebug() output='false' {
		writeOutput('<hr width="100%">');
		if(structKeyExists(Request, 'endTime')) writeOutput('Elapsed Time: ' & (Request.endTime - Request.startTime) & 'ms.');
		this.dumpScope('Application');
		this.dumpScope('Session');
		this.dumpScope('Request');
		this.dumpScope('URL');
		this.dumpScope('Cookie');
		this.dumpScope('Variables');
		this.dumpScope('CGI');
	}

	public void function dumpScope(required string Scope) output='false' {
		var s = createObject('java','java.lang.StringBuffer').init('');
		
		s.append('<table border=0 cellspacing=0 cellpadding=2 style="margin-bottom:4px;border:1px solid ##C0C0C0; color:##000000;">');
		s.append('<tr style="cursor:pointer; background-color:##D0D0D0;"');
		s.append(" onclick=""(document.getElementById('scope_" & Arguments.Scope & "').style.display=='')?document.getElementById('scope_" & Arguments.Scope & "').style.display='none':document.getElementById('scope_" & Arguments.Scope & "').style.display='';""");
		s.append(" onmouseover=""this.style.backgroundColor='##FFFFFF';""");
		s.append(" onmouseout=""this.style.backgroundColor='##D0D0D0';""><td style=""font-family:Arial;font-size:11px;font-weight:bold;padding-left:5px;padding-right:5px;"">" & Arguments.Scope & "</td></tr></table>");
		s.append('<table border=0 id="scope_' & Arguments.Scope & '" style="display:none; color:##000000;"><tr><td>');
		writeOutput(s.toString());
		writeDump(getPageContext().SymTab_findBuiltinScope(Arguments.Scope));
		writeOutput("</td></tr></table>");
	}

	public any function cfmFileRead(required string filename) output='false' {
		return(this.Wrappers.cfmFileRead(argumentCollection));
	}

	public boolean function loadIntoRam(required string filePath) output='false' {
		var tmpFile = '';
		var errorLog = '';

		if(fileExists(Arguments.filePath)) {
			try {
				tmpFile = fileRead(Arguments.filePath);
				fileWrite('ram:///' & listLast(Arguments.filePath,'/'),tmpFile);
			} catch(Any E) {
				errorMsg = dateFormat(now(),'mm/dd/yy') & '@' & timeFormat(now(),'hh:mm:tt') & ': Error: loading file into RAM [' & Arguments.filePath & ']';
				if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Errors,subject='Error: loading file into RAM',msg=errorMsg,obj=E);
				if(Application.Settings.useLogFile) {
					errorLog = fileOpen(Application.Settings.rootPath & 'frameworkError.log','write');
					fileWriteLine(errorLog,errorMsg);
					fileClose(errorLog);
				}
			}
			return(true);
		}
		return(false);
	}

	public void function css(required struct Request, required string filename) output='false' {
		if(!structKeyExists(Arguments.Request,'cssQueue') || Arguments.Request.cssQueue.indexOf(Arguments.filename)) return;
		Arguments.Request.cssQueue.push(Arguments.filename);
	}

	public void function js(required struct Request, required string filename, string params) output='false' {
		if(!structKeyExists(Arguments.Request,'jsQueue') || Arguments.Request.jsQueue.indexOf(Arguments.filename)) return;
		Arguments.Request.jsQueue.push(Arguments.filename);
	}

	public void function cleanPageContents(required struct Request) output='true' {
		if(!structKeyExists(Arguments.Request,'context')) return;
		var pageContent = Arguments.Request.context.getOut().getString();

		Arguments.Request.context.getOut().clear();
		getPageContext().getOut().clear();
		pageContent = reReplace(pageContent,'>[[:space:]]{2,}<','><','ALL');  // strip whitespace between tags
		pageContent = reReplace(pageContent,'^[!NOCOMP!][\n\r\f]+^[!NOCOMP!]',' ','ALL');  // condense excessive new lines into one new line
		pageContent = replaceNoCase(pageContent,'!NOCOMP!','','ALL');		// remove the !NOCOMP! (no compress) marker
		pageContent = reReplace(pageContent,'\t+','','ALL');  // condense excessive tabs into a single space
		Arguments.Request.context.getOut().write(pageContent);
	}

// *** need to resolve how to actually gZip and send back to browser *** //
	public void function gZipPageContents(required struct request) output='true' {
		if(!structKeyExists(Arguments.request,'context')) return;
		var pageContent = Arguments.request.context.getOut().getString();

//		var requestData = getHttpRequestData();
//		if(!findNoCase('gzip',requestData.headers['Accept-Encoding'])) return;
//		this.Wrappers.headers(name='Content-Encoding',value='gzip');

		this.Wrappers.headers(name='Content-Length',value=len(Arguments.request.context.getOut().getString()));
	}

	public string function jsCompressor(required string jscode) output='false' {
		Arguments.jscode = reReplace(Arguments.jscode,'/\*',chr(172),'all');
		Arguments.jscode = reReplace(Arguments.jscode,'\*/',chr(172),'all');
		Arguments.jscode = reReplace(Arguments.jscode,'#chr(172)#[^#chr(172)#]*#chr(172)#','','all');
		Arguments.jscode = reReplace(Arguments.jscode,'[^:]\/\/[^#chr(13)##chr(10)#]*','','all'); // remove single line comments
		Arguments.jscode = reReplace(Arguments.jscode,'[\s]*([\=|\{|\}|\(|\)|\;|[|\]|\+|\-|\n|\r]+)[\s]*','\1','all');
		Arguments.jscode = reReplace(Arguments.jscode,'[\r\n\f]*','','all');
		return(Arguments.jscode);
	}

	public string function cssCompressor(required string sInput) output='false' {
		Arguments.sInput = reReplace(Arguments.sInput,'[[:space:]]{2,}',' ','all');
		Arguments.sInput = reReplace(Arguments.sInput,'/\*[^\*]+\*/',' ','all');
		Arguments.sInput = reReplace(Arguments.sInput,'[ ]*([:{};,])[ ]*','\1','all');
		return(Arguments.sInput);
	}

	public void function fillCache() output='false' {
		if(fileExists(Application.Settings.rootPath & 'com\Framework\coreFrameworkStart.cfm')) this.coreFramework.Start.content = this.Wrappers.cfmFileRead('/com/Framework/coreFrameworkStart.cfm');
		if(fileExists(Application.Settings.rootPath & 'com\Framework\coreFrameworkEnd.cfm')) this.coreFramework.End.content = this.Wrappers.cfmFileRead('/com/Framework/coreFrameworkEnd.cfm');
		if(fileExists(Application.Settings.rootPath & 'com\Framework\baseFrameworkStart.cfm')) this.baseFramework.Start.content = this.Wrappers.cfmFileRead('/com/Framework/baseFrameworkStart.cfm');
		if(fileExists(Application.Settings.rootPath & 'com\Framework\baseFrameworkEnd.cfm')) this.baseFramework.End.content = this.Wrappers.cfmFileRead('/com/Framework/baseFrameworkEnd.cfm');
	}

	public void function include(required string template) output='true' {
		this.Wrappers.include(argumentCollection=Arguments);
	}

	public void function headers(required string name, required string value) output='true' {
		this.Wrappers.headers(argumentCollection=Arguments);
	}

	public void function htmlHead(required string text) output='true' {
		this.Wrappers.htmlHead(argumentCollection=Arguments);
	}

	public void function setCookie(required any CGI, required string name, required string value) output='true' {
		this.Wrappers.setCookie(argumentCollection=Arguments);
	}

	public void function deleteCookie(required any CGI, required string cookie, required string name) output='true' {
		this.Wrappers.deleteCookie(argumentCollection=Arguments);
	}

	public any function jsonDecode(required string data) output='false' {
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
		if(_data == 'null')	return('');
		if(listFindNoCase('true,false', _data)) return(_data);
		if((_data == "''") || (_data == '""')) return('');

		if((reFind('^"[^\\"]*(?:\\.[^\\"]*)*"$', _data) == 1) || (reFind("^'[^\\']*(?:\\.[^\\']*)*'$", _data) == 1)) {
			_data = mid(_data, 2, Len(_data)-2);
			if(find('\b', _data) || find('\t', _data) || find('\n', _data) || find('\f', _data) || find('\r', _data)) {
				curCharIndex = 0;
				curChar = '';
				dJSONString = createObject('java', 'java.lang.StringBuffer').init('');
				for(loopVar=1; loopVar <= 100000; loopVar++) {
					curCharIndex++;
					if(curCharIndex > len(_data)) {
						loopVar = 100001;
						break;
					} else {
						curChar = mid(_data, curCharIndex, 1);
						if(curChar == '\') {
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

		if(((left(_data, 1) == '[') && (right(_data, 1) == ']')) || ((left(_data, 1) == '{') && (right(_data, 1) == '}'))) {
			if((left(_data, 1) == '[') && (right(_data, 1) == ']')) {
				dataType = 'array';
			} else if(reFindNoCase('^\{"recordcount":[0-9]+,"columnlist":"[^"]+","data":\{("[^"]+":\[[^]]*\],?)+\}\}$', _data, 0) == 1) {
				dataType = 'query';
			} else {
				dataType = 'struct';
			}
			_data = trim(mid(_data, 2, len(_data)-2));
			if(len(_data) == 0) {
				if(dataType == 'array') return(ar);
				return(st);
			}
			dataSize = len(_data) + 1;
			for(; i <= dataSize; ) {
				skipIncrement = false;
				char = mid(_data, i, 1);
				if(char == '"') {
					inQuotes = (!inQuotes);
				} else if((char == '\') && inQuotes) {
					i = i + 2;
					skipIncrement = true;
				} else if(((char == ',') && (!inQuotes) && (nestingLevel == 0)) || (i == (len(_data)+1))) {
					dataStr = mid(_data, startPos, i-startPos);
					if(dataType == 'array') {
						arrayAppend(ar, jsondecode(dataStr));
					} else if((dataType == 'struct') || (dataType == 'query')) {
						dataStr = mid(_data, startPos, i-startPos);
						colonPos = find('":', dataStr);
						if(colonPos) {
							colonPos++;    
						} else {
							colonPos = find(':', dataStr);    
						}
						structKey = trim(mid(dataStr, 1, colonPos-1));
						if((left(structKey, 1) == "'") || (left(structKey, 1) == '"')) structKey = mid(structKey, 2, len(structKey)-2);
						structVal = mid(dataStr, colonPos+1, len(dataStr)-colonPos);
						if(dataType == 'struct') structInsert(st, structKey, jsondecode(structVal));
						if(structKey == 'recordcount') {
							qRows = jsondecode(structVal);
						} else if(structKey == 'columnlist') {
							st = queryNew(jsondecode(structVal));
							if(qRows) queryAddRow(st, qRows);
						} else if(structKey == 'data') {
							qData = jsondecode(structVal);
							ar = structKeyArray(qData);
							for(j=1; j <= arrayLen(ar); j++) {
								for(qRows=1; qRows <= st.recordCount; j++) {
									qCol = ar[j];
									querySetCell(st, qCol, qData[qCol][qRows], qRows);
								}
							}
						}
					}
					startPos = i + 1;
				} else if(('{[' CONTAINS char) && (!inQuotes)) {
					nestingLevel++;
				} else if((']}' CONTAINS char) && (!inQuotes)) {
					nestingLevel--;
				}
				if(!skipIncrement) i++;
			}
			if(dataType == 'array') return(ar);
			return(st);
		}
	}

	public string function toHexTrig(required string inData) output='false' {
		var result = '';
		var i = 0;
		var char36 = '';

		for(i=1; i <= len(inData); i++) {
			char36 = formatBaseN(Asc(mid(inData,i,1)),36);
			if(len(char36) < 2) char36 = '0' & char36;
			result = result & char36;
		}
		return(result);
	}

	public string function fromHexTrig(required string inData) output='false' {
		var result = '';
		var i = 0;
		var char36 = '';
		var nchar = '';

		for(i=1; i < len(inData); i+=2) {
			char36 = mid(inData,i,2);
			nchar = Chr(inputBaseN(char36,36));
			result = result & nchar;
		}
		return(result);
	}

	public boolean function dsnExists(required string dsn) output='false' {
		return(this.Wrappers.dsnExists(argumentCollection=Arguments));
	}

	public boolean function isMobile(required struct cgi) output='false' {
		var result = reFindNoCase('android|avantgo|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino',Arguments.CGI.HTTP_USER_AGENT)
									OR
								reFindNoCase('1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|e\-|e\/|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(di|rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|xda(\-|2|g)|yas\-|your|zeto|zte\-',left(Arguments.CGI.HTTP_USER_AGENT,4));
		return(result);
	}

	public void function onMissingMethod(string methodName, any methodArguments) output='false' {
		if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Errors,subject='[#Application.Settings.serverId#] Missing Method Error in the #this.Name# Application',msg='There was a Missing Method error in the #this.Name# Application at #cgi.SERVER_NAME#',obj=Arguments);
		return;
	}

}