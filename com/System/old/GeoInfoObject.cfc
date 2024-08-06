<cfcomponent displayname="GeoInfoObjectComponent">
	<cfsetting showdebugoutput="no" enablecfoutputonly="no">

	<cffunction name="init" returntype="any" access="remote" output="no">
		<cfscript>
			this.GeoInfoCRUD = createObject("component", "com.Database.GeoInfoCRUD").init();

			return(this);
		</cfscript>
	</cffunction>

	<cffunction name="getByZipcode" returntype="any" access="remote" output="no">
		<cfargument name="zipcode" type="any" required="yes">
		<cfscript>
			return(this.GeoInfoCRUD.getByZipcode(argumentCollection=Arguments));
		</cfscript>
	</cffunction>

	<cffunction name="OnMissingMethod" access="public" returntype="any" output="no">
		<cfargument name="MissingMethodName" type="string" required="true">
		<cfargument name="MissingMethodArguments" type="struct" required="true">
		<cfreturn "">
	</cffunction>

</cfcomponent>