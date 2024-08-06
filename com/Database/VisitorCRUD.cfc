component displayname='VisitorCrudComponent' hint='Visitor CRUD Component' output='false' {

	public any function init(string dsn=Application.Settings.DSN.System) output='false' {
		this.DSN = Arguments.DSN;
		return(this);
	}

	public int function set(required struct Visitor,struct Request) output='false' {
		var result = 0;
		var q = new Query();
		var metaInfo = '';
		var visitorRecord = '';

		q.setDatasource(this.DSN);
		q.setName('Visitor');
		if(structKeyExists(Arguments,'Request')) {
			q.addParam(name='entrancePath',value=Arguments.Request.virtualInfo.virtualPath,cfsqltype='VARCHAR');
		} else {
			q.addParam(name='entrancePath',value=Arguments.Visitor.requestData.path_info,cfsqltype='VARCHAR');
		}
		q.addParam(name='UUID',value=Arguments.Visitor.UUID,cfsqltype='VARCHAR');

		if(!Arguments.Visitor.visitorId) {
			result = q.execute(sql='SELECT VisitorId FROM VisitorMaster WHERE UUID = :UUID');
			q.addParam(name='lastAccess',value=dateFormat(now(),'yyyy-mm-dd') & ' ' & timeFormat(now(),'HH:mm:ss.l'),cfsqltype='TIMESTAMP');
			metaInfo = result.getPrefix();
			if(!metaInfo.recordCount) {
				result = q.execute(sql='INSERT INTO VisitorMaster (UUID,lastAccess,entrancePath) VALUES (:UUID,:lastAccess,:entrancePath)');
				metaInfo = result.getPrefix();
				visitorRecord = result.getResult();
				Arguments.Visitor.visitorId = metaInfo.generatedKey;
			} else {
				metaInfo = result.getPrefix();
				visitorRecord = result.getResult();
				Arguments.Visitor.visitorId = visitorRecord.VisitorId[1];
				q.addParam(name='visitorId',value=Arguments.Visitor.visitorId,cfsqltype='BIGINT');
				result = q.execute(sql='UPDATE VisitorMaster SET lastAccess=:lastAccess WHERE VisitorId=:visitorId');
				visitorRecord = result.getResult();
			}
		}

		if(Arguments.Visitor.visitorId) {
			q.addParam(name='visitorId',value=Arguments.Visitor.visitorId,cfsqltype='BIGINT');
			if(structKeyExists(Arguments,'Request')) {
				q.addParam(name='virtualPath',value=Arguments.Request.virtualInfo.virtualPath,cfsqltype='VARCHAR');
			} else {
				q.addParam(name='virtualPath',value=Arguments.Visitor.requestData.path_info,cfsqltype='VARCHAR');
			}
			q.addParam(name='accessStamp',value=dateFormat(now(),'yyyy-mm-dd') & ' ' & timeFormat(now(),'HH:mm:ss.l'),cfsqltype='TIMESTAMP');
			result = q.execute(sql='UPDATE VisitorMaster SET lastAccess=:accessStamp WHERE VisitorId=:visitorId');
			result = q.execute(sql='SELECT VisitorId,Accesses FROM VisitorDetail WHERE VisitorId=:visitorId AND virtualPath=:virtualPath');
			metaInfo = result.getPrefix();
			if(metaInfo.recordCount) {
				visitorRecord = result.getResult();
				q.addParam(name='Accesses',value=val(visitorRecord.Accesses[1])+1,cfsqltype='BIGINT');
				result = q.execute(sql='UPDATE VisitorDetail SET accessStamp=:accessStamp, Accesses=:Accesses WHERE VisitorId = :visitorId AND virtualPath = :virtualPath');
			} else {
				// insert new visitor detail record
				q.addParam(name='accessStamp',value=dateFormat(now(),'yyyy-mm-dd') & ' ' & timeFormat(now(),'HH:mm:ss.l'),cfsqltype='TIMESTAMP');
				q.addParam(name='Accesses',value=1,cfsqltype='BIGINT');
				result = q.execute(sql='INSERT INTO VisitorDetail (VisitorId,accessStamp,Accesses,virtualPath) VALUES (:visitorId,:accessStamp,:Accesses,:virtualPath)');
			}
		}
		return(Arguments.Visitor.visitorId);
	}

	public void function onMissingMethod(string methodName, any methodArguments) output='false' {
		if(Application.Settings.isMailAvailable) Application.Mail.send(to=Application.Settings.emailLists.Errors,subject='[#Application.Settings.serverId#] Missing Method Error in the #this.Name# Application',msg='There was a Missing Method error in the #this.Name# Application at #cgi.SERVER_NAME#',obj=Arguments);
		return;
	}

}