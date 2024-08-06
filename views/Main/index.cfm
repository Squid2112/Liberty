<!---
<p>
	Work is shaping up nicely, "Liberty", the new advanced ColdFusion framework,<br />
	is nearing completion and is being prepared for release.
</p>
--->

<cfscript>
Application.Content.object(Request=Request,name='test');

	writeOutput('Browser Platform: ');
	Application.System.isMobile(cgi=cgi) ? writeOutput('Mobile<br />') : writeOutput('Desktop<br />');

geoCRUD = createObject('component','com.System.GeoInfoObject').init('Global');
test = geoCRUD.getByIp(ip='75.145.55.90',getALL=false);
test2 = geoCRUD.getByZipcode(zipcode=test.zipcode[1],getAll=true);
//writeDump(test);
//writeDump(test2);
if(test.recordCount) {
	writeOutput('City: ' & test.city[1] & '<br />');
	writeOutput('State: ' & test.state[1] & '<br />');
	writeOutput('Area Code: ' & test.areaCode[1] & '<br />');
	writeOutput('Zip Code: ' & test.zipCode[1] & '<br />');
	writeOutput('County: ' & test2.countyName[1] & '<br />');
	writeOutput('Time Zone: ' & test2.timeZone[1] & '<br />');
	writeOutput('City Latitude: ' & test2.city_Latitude[1] & '<br />');
	writeOutput('City Longitude: ' & test2.city_Longitude[1] & '<br />');
	writeOutput('State Latitude: ' & test2.state_Latitude[1] & '<br />');
	writeOutput('State Longitude: ' & test2.state_Longitude[1] & '<br />');
}

/*
	vdb = createObject('component','com.database.VisitorCRUD').init();
	meta = vdb.set(Visitor=Session.Visitor,Request=Request);
	writeDump(meta);

	q = new Query();
	q.setDatasource('thixo');
	q.setName('Visitor');
	result = q.execute(sql='SELECT * FROM VisitorDetail');

	metaInfo = result.getPrefix();
	record = result.getResult();
	writeDump(result);
	writeDump(metaInfo);
*/
</cfscript>

<cfscript>
// writeDump(hash('frisbee','SHA-256'));  // create password
/*
	manifest = fileRead(Application.Settings.rootPath & 'com\Manifests\VirtualMapping.manifest.json');
	mappings = Application.System.jsonDecode(manifest);
	writeDump(mappings);	

writeDump(structFindValue(mappings,'Tests'));
*/
/*
	omniture = fileRead(expandPath('/') & 'omniture.xml');
//fileWrite(expandPath('/') & 'omniture.xml',omniture);
	omniture = xmlParse(omniture);
writeOutput('[ PackageId ]');
	writeDump(xmlSearch(omniture,"/Root/Result/result/sets/xinfonSet[@nm='products']/e[*]/xinfon/Products/PROD_ID"));

writeOutput('[ Related Products ]');
	writeDump(xmlSearch(omniture,"/Root/Result/result/sets/xinfonSet[@nm='related_products']/e[*]/xinfon/Products/PROD_ID"));

writeOutput('[ Related Documents ]');
	writeDump(xmlSearch(omniture,"/Root/Result/result/sets/xinfonSet[@nm='related_documents']/e[*]/xinfon/Products/PROD_ID"));

writeOutput('[ Banners Top ]<br>');
	banners_top = xmlSearch(omniture,"/Root/Result/result/sets/valueSet[@nm='CMC_banners_top']/e/value/text()");
	for(i=1; i LTE arrayLen(banners_top); i++) writeOutput('[#i#] <xmp>' & banners_top[i].xmlValue & '</xmp>');

writeOutput('[ Banners Side ]<br>');
	banners_side = xmlSearch(omniture,"/Root/Result/result/sets/valueSet[@nm='CMC_banners_side']/e/value/text()");
	for(i=1; i LTE arrayLen(banners_side); i++) writeOutput('[#i#] <xmp>' & banners_side[i].xmlValue & '</xmp>');

writeOutput('[ Banners Bottom ]<br>');
	banners_bottom = xmlSearch(omniture,"/Root/Result/result/sets/valueSet[@nm='CMC_banners_bottom']/e/value/text()");
	for(i=1; i LTE arrayLen(banners_bottom); i++) writeOutput('[#i#] <xmp>' & banners_bottom[i].xmlValue & '</xmp>');

//omniture.find('//*').flattenCompoundCollection(omniture.get());
*/
</cfscript>