<cfscript>
	myQuery = new Query(datasource='thixo');
	myQuery.setSql('select [name],[principal_id],[diagram_id],[version] from dbo.sysdiagrams');
	result = myQuery.execute();

	writeDump(result);

</cfscript>