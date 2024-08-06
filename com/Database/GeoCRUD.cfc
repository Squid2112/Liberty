component displayname='GeoCrudComponent' hint='GEO CRUD Component' output='false' {

	public any function init(string dsn=Application.Settings.DSN.Global) output='false' {
		this.DSN = Arguments.DSN;
		return(this);
	}

// *** NEED TO FIGURE OUT HOW TO GET cityTypes TO WORK WITH THE SQL "IN" DIRECTIVE
	public query function getByZipcode(required string zipcode, boolean getAll=false, string cityTypes='D') output='false' {
		Arguments.zipcode = trim(Arguments.zipcode);
		if(!len(Arguments.zipcode)) return(result);

		var q = new Query();
		q.setDatasource(this.DSN);
		q.setName('zips');
		q.addParam(name='zipcode',value=Arguments.zipcode,cfsqltype='VARCHAR');
		q.addParam(name='cityTypes',value=Arguments.cityTypes,cfsqltype='VARCHAR');
		var sqlStr = 'SELECT ' & ((!Arguments.getAll) ? 'TOP (1)' : '') & ' * FROM Zipcodes WITH (NOLOCK) WHERE Zipcode=:zipcode AND CityType IN (:cityTypes)';
		var qryResult = q.execute(sql=sqlStr);
		var metaInfo = qryResult.getPrefix();
		return(qryResult.getResult());
	}

	public query function getByIp(required string ip, boolean getAll=false) output='false' {
		var arr = listToArray(Arguments.ip,'.');
		var IPADDR = (val(arr[1]) * 16777216) + (val(arr[2]) * 65536) + (val(arr[3]) * 256) + val(arr[4]);

		var q = new Query();
		q.setDatasource(this.DSN);
		q.setName('zips');
		q.addParam(name='ipaddr',value=IPADDR,cfsqltype='BIGINT');
		var sqlStr = 'SELECT ' & ((!Arguments.getAll) ? 'TOP (1) ' : '');
		sqlStr &= 'GI.city,GI.Region AS State,GI.latitude,GI.longitude,GI.areaCode,Z.zipcode,Z.TimeZone,Z.UTC,Z.DST,Z.City_Latitude,Z.City_Longitude,Z.State_Latitude,Z.State_Longitude ';
		sqlStr &= 'FROM GeoLoc AS GL WITH (NOLOCK) LEFT OUTER JOIN GeoIP AS GI WITH (NOLOCK) ON GI.locId = GL.locId LEFT OUTER JOIN Zipcodes AS Z WITH (NOLOCK) ON Z.CityName = GI.City AND Z.StateAbbr = GI.Region ';
		sqlStr &= 'WHERE (:ipaddr BETWEEN GL.startIpNum AND GL.endIpNum)';
		var qryResult = q.execute(sql=sqlStr);
		var metaInfo = qryResult.getPrefix();
		return(qryResult.getResult());
	}

	public void function onMissingMethod(string methodName, any methodArguments) output='false' {
		if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Errors,subject='[#Application.Settings.serverId#] Missing Method Error in the #this.Name# Application',msg='There was a Missing Method error in the #this.Name# Application at #cgi.SERVER_NAME#',obj=Arguments);
		return;
	}

}