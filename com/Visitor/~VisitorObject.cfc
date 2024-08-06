<cfcomponent displayname="VisitorObjectComponent" hint="Visitor Object Component">
	<cfsetting showdebugoutput="no" enablecfoutputonly="no">

	<cffunction name="init" returntype="any" access="public" output="no">
		<cfscript>
			this.Debug = false;
			this.SERVER_NAME = cgi.SERVER_NAME;
			this.SCRIPT_NAME = cgi.SCRIPT_NAME;
			this.REMOTE_ADDR = cgi.REMOTE_ADDR;
			this.HTTP_REFERER = cgi.HTTP_REFERER;
			this.HTTP_USER_AGENT = cgi.HTTP_USER_AGENT;

			if(structKeyExists(Arguments, "VirtualPath")) {
				this.VirtualPath = Arguments.VirtualPath;
				this.EntryPath = Arguments.VirtualPath;
			} else if(structKeyExists(Request, "VirtualInfo")) {
				this.VirtualPath = Request.VirtualInfo.VirtualPath;
				this.EntryPath = Request.VirtualInfo.VirtualPath;
			} else {
				this.VirtualPath = "";
				this.EntryPath = "";
			}
			this.isAuthorized = false;
			this.VisitorID = 0;

			this.UUID = createUUID();
			if(structKeyExists(Cookie, "UUID") AND len(trim(Cookie.UUID))) this.UUID = trim(Cookie.UUID);
			Application.System.setCookie(name="UUID", value=this.UUID);

			this.get();

			this.set(this.VirtualPath);

			return(this);
		</cfscript>
	</cffunction>
	
	<cffunction name="set" returntype="any" access="public" output="no">
		<cfargument name="VirtualPath" type="any" required="no" default="">
		<cfscript>
			this.SERVER_NAME = cgi.SERVER_NAME;
			this.SCRIPT_NAME = cgi.SCRIPT_NAME;
			this.REMOTE_ADDR = cgi.REMOTE_ADDR;
			this.HTTP_REFERER = cgi.HTTP_REFERER;
			this.HTTP_USER_AGENT = cgi.HTTP_USER_AGENT;
			if(StructKeyExists(Arguments, "VirtualPath")) {
				this.VirtualPath = Arguments.VirtualPath;
			} else if(StructKeyExists(Request, "VirtualInfo")) {
				this.VirtualPath = Request.VirtualInfo.VirtualPath;
			}

			Application.CAGE.init(task=Application.VisitorCRUD, method="set");
			Application.CAGE.run(Visitor=this);
		</cfscript>
	</cffunction>

	<cffunction name="get" returntype="any" access="public" output="no">
		<cfscript>
			var qVisitor = Application.VisitorCRUD.get(Visitor=this);
			if(isQuery(qVisitor)) {
				this.VisitorID = qVisitor.VisitorID[1];
				this.SERVER_NAME = qVisitor.SERVER_NAME[1];
				this.SCRIPT_NAME = qVisitor.SCRIPT_NAME[1];
				this.LastAccess = qVisitor.LastAccess[1];
				this.REMOTE_ADDR = qVisitor.REMOTE_ADDR[1];
				this.HTTP_REFERER = qVisitor.HTTP_REFERER[1];
				this.HTTP_USER_AGENT = qVisitor.HTTP_USER_AGENT[1];
				this.EntryPath = qVisitor.EntryPath[1];
				this.VirtualPath = qVisitor.VirtualPath[1];
			}
		</cfscript>
	</cffunction>

	<cffunction name="visitorCount" access="public" returntype="any" output="no">
		<cfscript>
			if(StructKeyExists(Application, "VisitorCRUD")) return(Application.VisitorCRUD.visitorCount());
			return("");
		</cfscript>
	</cffunction>

	<cffunction name="OnMissingMethod" access="public" returntype="any" output="no">
		<cfargument name="MissingMethodName" type="string" required="true">
		<cfargument name="MissingMethodArguments" type="struct" required="true">
		<cfreturn "">
	</cffunction>

</cfcomponent>