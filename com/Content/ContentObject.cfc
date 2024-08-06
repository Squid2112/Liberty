component displayname='ContentObjectComponent' hint='Core Content Object Component' output='false' {

	public any function init(string dsn=Application.Settings.DSN.System) output='false' {
		this.DSN = Arguments.dsn;
		return(this);
	}

	public void function childView(required struct Request, required string name='') output='true' {
		Application.System.css(Request=Arguments.Request,filename='childViews/' & Arguments.name & '/css/index.css');
		Application.System.js(Request=Arguments.Request,filename='childViews/' & Arguments.name & '/js/index.js');
		Application.System.Wrappers.include('/childViews/' & Arguments.name & '/index.cfm');
	}

	public void function object(required struct Request, required string name, string scope, struct params) output='true' {
		if(!structKeyExists(Arguments.Request,'objectParams')) Arguments.Request.objectParams = structNew();
		Arguments.Request.objectParams[name] = structNew();

		if(structKeyExists(Arguments,'params')) {
			var item = '';
			for(item IN Arguments.params) Arguments.Request.params[name][item] = Arguments.params[item];
		}

		Application.System.css(Request=Arguments.Request,filename='contentObjects/' & Arguments.name & '/css/index.css');
		Application.System.js(Request=Arguments.Request,filename='contentObjects/' & Arguments.name & '/js/index.js');
		Application.System.Wrappers.include('/contentObjects/' & Arguments.name & '/index.cfm');
	}

}