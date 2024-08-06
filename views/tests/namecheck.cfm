<cfscript>
	function levDistance(s,t) {
		var d = arrayNew(2);
		var i = 1;
		var j = 1;
		var s_i = "A";
		var t_j = "A";
		var cost = 0;
		var n = len(s)+1;
		var m = len(t)+1;

		if((s & t) EQ "") return(0);
		
		d[n][m]=0;
		
		if(n EQ 1) return m;
    if(m EQ 1) return n;
		for(i=1; i LTE n; i=i+1) d[i][1] = i-1;
		for (j=1; j LTE m; j=j+1) d[1][j] = j-1;
		for (i=2; i LTE n; i=i+1) {
			s_i = mid(s,i-1,1);
			for(j=2; j LTE m; j=j+1) {
				t_j = mid(t,j-1,1);
        if(s_i EQ t_j) {
					cost = 0;
				} else {
					cost = 1;
				}
				d[i][j] = min(d[i-1][j]+1, d[i][j-1]+1);
				d[i][j] = min(d[i][j], d[i-1][j-1]+cost);
			}
		}
		return(d[n][m]);
	}

	function isCustomer(as400, bill) {
		var result = "";
		var wFname = 80;
		var wLname = 70;
		var wComp = 5;
		var wAddr1 = 80;
		var wAddr2 = 80;
		var wCity = 65;
		var wState = 50;
		var wZip = 75;
		var wPhone = 90;
		var wEmail = 80;

		var Fname = 0;
		var Lname = 0;
		var Comp = 0;
		var Addr1 = 0;
		var Addr2 = 0;
		var City = 0;
		var State = 0;
		var Zip = 0;
		var Phone = 0;
		var Email = 0;
		
		Fname = 100 - (levDistance(as400.FirstName,bill.FirstName) * 10);
		Lname = 100 - (levDistance(as400.LastName,bill.LastName) * 10);
		Comp = 100 - (levDistance(as400.Company,bill.Company) * 10);
		Addr1 = 100 - (levDistance(as400.Address1,bill.Address1) * 10);
		Addr2 = 100 - (levDistance(as400.Address2,bill.Address2) * 10);
		City = 100 - (levDistance(as400.City,bill.City) * 10);
		State = 100 - (levDistance(as400.State,bill.State) * 10);
		Zip = 100 - (levDistance(as400.Zip,bill.Zip) * 10);
		Phone = 100 - (levDistance(ReReplace(as400.Phone,"-(|)","","ALL"),ReReplace(bill.Phone,"-(|)","","ALL")) * 10);
		Email = 100 - (levDistance(as400.Email,bill.Email) * 10);

		result = {
			FirstName = Fname * 0.35,
			LastName = Lname * 1.1,
			Company = Comp * 0.5,
			Address1 = Addr1 * 0.35,
			Address2 = Addr2 * 0.5,
			City = City,
			State = State,
			Zip = Zip * 0.15,
			Phone = Phone * 0.15,
			Email = Email * 0.15,
			ProSet = [
				(((Fname+Lname+Comp+Addr1+Addr2+City+State+Zip+Phone+Email) / 10) * 1.35),
				((Lname+Addr1+City+State+Zip+Phone) / 6),
				((Lname+City+State+Zip+Phone+Email) / 6),
				((Lname+City+State+Zip+Phone) / 5),
				((Lname+City+State+Zip) / 4),
				(((Fname+Lname) / 2) * 1.18)
			],
			Probability = ((result.ProSet[1]+result.ProSet[2]+result.ProSet[3]+result.ProSet[4]+result.ProSet[5]+result.ProSet[6]) / 6)
		};
		return(result);
	}
	
	a = {
		FirstName = "Bill",
		LastName = "Fry",
		Company = "",
		Address1 = "450 Weeping Elm",
		Address2 = "",
		City = "Mt. Juliet",
		State = "TN",
		Zip = "37122",
		Phone = "615-316-5844",
		Email = "jgreenwell@oreck.com"
	};
	
	b = {
		FirstName = "William",
		LastName = "Fry",
		Company = "",
		Address1 = "450 Weeping Elm, Rd.",
		Address2 = "",
		City = "Mount Julet",
		State = "TN",
		Zip = "37122",
		Phone = "615-477-3150",
		Email = "jgreenwell@oreck.com"
	};

	result = isCustomer(a,b);
	matchProb = result.Probability;
	if(matchProb GTE 80) {
		writeoutput('Matches Customer Database<br>');
	} else {
		writeoutput('Does Not Match Customer Database<br>');
	}
	Application.base.dump(result);

	Application.base.dump(a);
	Application.base.dump(b);
</cfscript>