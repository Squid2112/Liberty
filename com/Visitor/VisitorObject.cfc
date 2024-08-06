component displayname='VisitorObjectComponent' hint='Visitor Object Component' output='false' {

	public any function init(string dsn=Application.Settings.DSN.System) output='false' {
		var rh = getHTTPrequestData();

		this.firstRequest = true;
		this.isAuthorized = false;
		this.Debug = false;
		this.UUID = createUUID();
		this.DSN = Arguments.dsn;
		this.visitorId = 0;
		this.visitorRecord = '';

		this.requestData = {
			ipAddress = (structKeyExists(rh.headers,'x-forwarded-for')) ? rh.headers['x-forwarded-for'] : '',
			cookie = (structKeyExists(rh.headers,'cookie')) ? rh.headers['cookie'] : '',
			host = (structKeyExists(rh.headers,'host')) ? rh.headers['host'] : '',
			userAgent = (structKeyExists(rh.headers,'user-agent')) ? rh.headers['user-agent'] : '',
			templatePath = cgi.CF_TEMPLATE_PATH,
			HTTPS = cgi.HTTPS,
			referer = cgi.HTTP_REFERER,
			path_info = cgi.PATH_INFO,
			path_translated = cgi.PATH_TRANSLATED,
			query_string = cgi.QUERY_STRING,
			remote_addr = cgi.REMOTE_ADDR,
			remote_host = cgi.REMOTE_HOST,
			remote_ident = cgi.REMOTE_IDENT,
			remote_user = cgi.REMOTE_USER,
			script_name = cgi.SCRIPT_NAME,
			server_name = cgi.SERVER_NAME,
			server_port = cgi.SERVER_PORT,
			server_protocol = cgi.SERVER_PROTOCOL,
			server_port_secure = cgi.SERVER_PORT_SECURE
		};

		if(structKeyExists(Cookie,'UUID') && len(trim(Cookie.UUID))) this.UUID = trim(Cookie.UUID);
		Application.System.setCookie(cgi=cgi,name='UUID',value=this.UUID);

		this.visitorId = this.set(Visitor=this);
		return(this);
	}

// ---------------------< set >---------------------
	public integer function set(struct vInfo=structNew()) output='false' {
//		if(this.DSN != '') return(Application.VisitorCRUD.set(Visitor=this,vInfo=Arguments.vInfo));
		return(0);
	}

// ---------------------< get >---------------------
	public any function get() output='false' {
//		if(this.DSN != '') this.visitorRecord = duplicate(Application.VisitorCRUD.get(visitorId=this.visitorId));
		return(this.visitorRecord);
	}

// ---------------------< onMissingMethod >---------------------
	function onMissingMethod(MethodName, MethodArguments) {
		if(Application.Settings.isMailAvailable) Application.Mail.send(from='#cgi.SERVER_NAME#@#Application.Settings.rootDomain#',to=Application.Settings.emailList.Errors,subject='[#Application.Settings.serverId#] Missing Method Error in the #this.Name# Application',msg='There was a Missing Method error in the #this.Name# Application at #cgi.SERVER_NAME# within component VisitorObject.cfc',obj=Arguments);
		return;
	}
}