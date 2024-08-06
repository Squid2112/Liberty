<cfcomponent displayname="TrackingComponent" hint="Banners Component">
	<cfsetting showdebugoutput="no" enablecfoutputonly="no">

	<cffunction name="init" returntype="Tracking" access="remote" output="no">
		<cfreturn this>
	</cffunction>

	<cffunction name="trackLink" returntype="any" access="remote" output="yes">
		<cfquery datasource="#Application.Settings.ApplicationDSN#">
			INSERT INTO LinkClicks (
				Link,
				Title,
				Stamp,
				CookieID,
				REMOTE_ADDR,
				HTTP_USER_AGENT,
				HTTP_REFERER,
				AffiliateID,
				AdvertiserID,
				City,
				State,
				Portal
			) VALUES (
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Form.Link)#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Form.Title)#">,
				<cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Form.CookieID)#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Form.REMOTE_ADDR)#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Form.HTTP_USER_AGENT)#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Form.HTTP_REFERER)#">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#Form.AffiliateID#">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#Form.AdvertiserID#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Form.City)#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Form.State)#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Form.Portal)#">
			)
		</cfquery>
		<cfreturn>
	</cffunction>

</cfcomponent>