component displayname='MailObjectComponent' hint='Mail object' output='false' {

	public any function init(struct emailLists=Application.Settings.emailLists) output='false' {
		this.Addresses = duplicate(Arguments.emailLists);
		this.mailService = new Mail();

		return(this);
	}

	public void function send(string from='#Application.applicationName#@#Application.Settings.rootDomain#', string to=this.Addresses.info, string subject='[no subject]', string msg='', any obj) output='false' {
		var mailBody = Arguments.msg;

		this.mailService.clear();
		if(structKeyExists(Arguments,'obj')) {
			saveContent variable='mailBody' {
				writeOutput(Arguments.msg);
				writeDump(var=Arguments.obj,expand='yes',format='html',hide='',keys=9999,label=Arguments.msg,metainfo='yes',output='browser',show='all',showUDFs='yes',top=9999,abort=false);
			}
		}
		this.mailService.setFrom(Arguments.from);
		this.mailService.setTo(Arguments.to);
		this.mailService.setSubject(Arguments.subject);
		this.mailService.setType('html');
		this.mailService.send(body=mailBody);
	}

	public boolean function isValidEmailAddress(required string address) output='false' {
		return(reFindNoCase('^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)', Arguments.address));
	}

	public void function onMissingMethod(string methodName, any methodArguments) output='false' {
		if(Application.Settings.isMailAvailable) this.send(to=this.Addresses.Errors,subject='[#Application.Settings.serverId#] Missing Method Error in the #this.Name# Application',msg='There was a Missing Method error in the #this.Name# Application at #cgi.SERVER_NAME#',obj=Arguments);
		return;
	}

}