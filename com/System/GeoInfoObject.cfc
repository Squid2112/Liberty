component displayname='GeoInfoComponent' hint='GEO Info Component' output='false' {

	public any function init(string dsn=Application.Settings.DSN.Global) output='false' {
		this.geoCRUD = createObject('component','com.Database.GeoCRUD').init(Arguments.dsn);
		return(this);
	}

	public any function getByZipcode(required string zipcode, boolean getAll=false) output='false' {
		return(this.geoCRUD.getByZipcode(argumentCollection=Arguments));
	}

	public any function getByIp(required string ip, boolean getAll=false) output='false' {
		return(this.geoCRUD.getByIp(argumentCollection=Arguments));
	}

	public void function onMissingMethod(string methodName, any methodArguments) output='false' {
		if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Errors,subject='[#Application.Settings.serverId#] Missing Method Error in the #this.Name# Application',msg='There was a Missing Method error in the #this.Name# Application at #cgi.SERVER_NAME#',obj=Arguments);
		return;
	}
}