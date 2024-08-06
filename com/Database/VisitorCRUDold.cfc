<cfcomponent displayname="VisitorsCRUDComponent" hint="System Component">
	<cfsetting showdebugoutput="no" enablecfoutputonly="no">

	<cffunction name="init" returntype="any" access="public" output="no">
		<cfargument name="DSN" type="any" required="no" default="#Application.Settings.applicationDSN#">
		<cfscript>
			this.DSN = Arguments.DSN;

			return(this);
		</cfscript>
	</cffunction>

	<cffunction name="set" returntype="any" access="public" output="no">
		<cfargument name="Visitor" type="any" required="yes">

		<cfset var result = "">
		<cfquery name="result" datasource="#this.DSN#">
			SELECT VisitorID
			FROM Visitors WITH (NOLOCK)
			WHERE
				UUID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Visitor.UUID#">
				AND SERVER_NAME = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Visitor.SERVER_NAME#">
				AND VirtualPath = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Visitor.VirtualPath#">
		</cfquery>

		<cfif result.RecordCount>
			<cfquery datasource="#this.DSN#">
				UPDATE Visitors
				SET
					LastAccess = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#">,
					HTTP_REFERER = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Visitor.HTTP_REFERER#">,
					SCRIPT_NAME = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Visitor.SCRIPT_NAME#">
				WHERE VisitorID = <cfqueryparam cfsqltype="cf_sql_integer" value="#result.VisitorID[1]#">
			</cfquery>
		<cfelse>
			<cfquery name="result" datasource="#this.DSN#">
				INSERT INTO Visitors (
					UUID,
					SERVER_NAME,
					SCRIPT_NAME,
					LastAccess,
					REMOTE_ADDR,
					HTTP_REFERER,
					HTTP_USER_AGENT,
					VirtualPath,
					EntryPath
				) VALUES (
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Visitor.UUID#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Visitor.SERVER_NAME#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Visitor.SCRIPT_NAME#">,
					<cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Visitor.REMOTE_ADDR#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Visitor.HTTP_REFERER#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Visitor.HTTP_USER_AGENT#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Visitor.VirtualPath#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Visitor.EntryPath#">
				)

				SELECT Scope_Identity() AS VisitorID
			</cfquery>
		</cfif>
		<cfreturn result.VisitorID>
	</cffunction>

	<cffunction name="get" returntype="any" access="public" output="no">
		<cfargument name="Visitor" type="any" required="yes">

		<cfset var result = "">
		<cfquery name="result" datasource="#this.DSN#">
			SELECT *
			FROM Visitors V WITH (NOLOCK)
			WHERE V.UUID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Visitor.UUID#">
		</cfquery>
		<cfreturn result>
	</cffunction>

	<cffunction name="visitorCount" returntype="any" access="public" output="no">
		<cfset var result="">
		<cfquery name="result" datasource="#this.DSN#">
			SELECT COUNT(DISTINCT UUID) AS CNT
			FROM Visitors WITH (NOLOCK)
			WHERE (DATEDIFF(minute, LastAccess, GETDATE()) <= <cfqueryparam value="30" cfsqltype="cf_sql_integer">)
		</cfquery>
		<cfreturn val(result.CNT)>
	</cffunction>

	<cffunction name="OnMissingMethod" access="public" returntype="any" output="no">
		<cfargument name="MissingMethodName" type="string" required="true">
		<cfargument name="MissingMethodArguments" type="struct" required="true">
		<cfreturn "">
	</cffunction>

</cfcomponent>