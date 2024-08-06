component displayname='VisitorAjaxComponent' hint='Component for visitor ajax requests' output='false' {

	remote string function encodedJsonTest(required string data) output='true' returnformat='plain' {
		var result = { status='ok' };

		Application.Mail.send(to='hostmaster@thixo.net',subject='visitor Ajax test',obj=deserializeJson(Application.System.fromHexTrig(Arguments.data)));
		return(serializeJson(result));
	}

	remote string function ping() output='true' returnformat='plain' {
		var result = { status='ok' };
		return(serializeJson(result));
	}
}