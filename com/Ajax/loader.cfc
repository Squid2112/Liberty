component displayname='VisitorAjaxComponent' hint='Component for visitor ajax requests' output='false' {

	remote string function process(required string id) output='true' returnformat='plain' {
		return('<p>Work is shaping up nicely, "Liberty", the new advanced ColdFusion framework,<br />is nearing completion and is being prepared for release.</p>');
	}

}