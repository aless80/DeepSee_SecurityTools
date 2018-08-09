Class Ale.SecurityTools Extends %Persistent
{

/// Just list all methods and some tips
ClassMethod Info() As %Status
{
	Write !," .SecuritySetup(""samples"")         //Set up security on namepsace"
	Write !," .SecurityRestore(""samples"")       //Restore from what SecuritySetup did"
	Quit $$$OK
}

/// This method will implement the security model in Alessandro's post on DC. The aim is to speed up troubleshooting security issues. 
/// Given an input ns namespace this method will:
///   Create three roles associated to three new users, 
///   Set authentication methods for /csp/<ns>, /csp/sys, /csp/sys/bi web applications to Password, Login cookie
///   For /csp/<ns> ask to set the DeepSee Enable checkbox as enabled
///   Allow creation of Login Cookies (so that you don't have to login 100 times)
///   Remove public USE on %DeepSee_* resources
ClassMethod SecuritySetup(ns As %String = "samples", DBresource As %String = "%DB_SAMPLES")
{
	Set ns = $ZCONVERT(ns,"U")
	Set nsexists = ##class(%SYS.Namespace).Exists(ns)
	If ('nsexists) {
		Write !,ns," namespace does not exist. Aborting"
		Return
	}
	//Get the default resource for the input namespace
	Do ##class(%SYS.Namespace).GetNSInfo(ns,.info)
	Set DBresource = info("Resource")
	Set nsfrom = $SYSTEM.SYS.NameSpace()
	ZN "%SYS"	
	///Create roles
	Set st = ##class(Security.Roles).Create("DSUser", "DSUser", "%DeepSee_Portal:U,%Service_Terminal:U,%Development:U,"_DBresource_":RW")
	Write:st !,"New role created: DSUser with %DeepSee_Portal,%Service_Terminal,%Development,"_DBresource
	Write:'st !,"Error on the DSUser role: ",$System.Status.GetOneErrorText(st)
	Set st = ##class(Security.Roles).Create("DSPowerUser", "DSPowerUser", "%DeepSee_AnalyzerEdit:U,%DeepSee_Portal:U,%DeepSee_PortalEdit:U,%Service_Terminal:U,%Development:U,"_DBresource_":RW")
	Write:st !,"New role created: DSPowerUser with %DeepSee_AnalyzerEdit,%DeepSee_Portal,",!,?35,"%DeepSee_PortalEdit,%Service_Terminal,%Development,"_DBresource
	Write:'st !,"Error on the DSPowerUser role: ",$System.Status.GetOneErrorText(st)
	Set st = ##class(Security.Roles).Create("DSAdmin", "DSAdmin", "%DeepSee_ArchitectEdit:U,%DeepSee_AnalyzerEdit:U,%DeepSee_Portal:U,%DeepSee_Admin:U,%Service_Terminal:U,%Development:U,%DB_CACHESYS:RW,"_DBresource_":RW")
	Write:st !,"New role created: DSAdmin user with %DeepSee_Portal,%DeepSee_ArchitectEdit,%DeepSee_AnalyzerEdit,",!,?36,"%DeepSee_Admin,%Service_Terminal,%Development,%DB_CACHESYS,"_DBresource
	Write:'st !,"Error on the DSAdmin role:",$System.Status.GetOneErrorText(st)
	///Create users
	Set st = ##class(Security.Users).Create("simpleuser", "DSUser", "SYS", "SimpleUser", ns,,,, 1, "Created by Ale.myimports:LockDown",,,,,1,1)
	Write:st !,"Created simpleuser with password SYS and DSUser role"
	Write:'st !,"Failed creating simpleuser: ",$System.Status.GetOneErrorText(st)
	Set st = ##class(Security.Users).Create("poweruser", "DSPowerUser", "SYS", "PowerUser", ns,,,, 1, "Created by Ale.myimports:LockDown",,,,,1,1)
	Write:st !,"Created poweruser with password SYS and DSPowerUser role"
	Write:'st !,"Failed creating poweruser: ",$System.Status.GetOneErrorText(st)
	Set st = ##class(Security.Users).Create("admin", "DSPowerUser,DSAdmin", "SYS", "Admin", ns,,,, 1, "Created by Ale.myimports:LockDown",,,,,1,1)
	Write:st !,"Created admin user with password SYS and DSAdmin role"
	Write:'st !,"Failed creating admin user: ",$System.Status.GetOneErrorText(st)
	//Change Terminal service to Password
	Set prop("AutheEnabled")=32
	Set st = ##class(Security.Services).Modify("%Service_Terminal",.prop)
	Write:'st !,"Failed to give %Service_Terminal to Password authentication ",$System.Status.GetOneErrorText(st)
	///Change authentication methods for three web applications to Password, Login cookie
	Set list = $LB("/csp/"_$ZCONVERT(ns,"L"),"/csp/sys","/csp/sys/bi")
	Set ptr = 0
	While $ListNext(list,ptr,webapp){
		Set web = ##class(Security.Applications).%OpenId(webapp)
		Set web.AutheEnabled = 16416
		//Ask to enable DeepSee on "namespace" webapp that is different than /csp/samples, which is special
		If (webapp = ("/csp/"_$ZCONVERT(ns,"L"))) && (webapp '= "/csp/samples") {
			Set DeepSeeEnabled = web.DeepSeeEnabled
			If ('DeepSeeEnabled) { 
				Write !!,"The DeepSee checkbox for ",webapp," seems to be disabled.",!,"Do you want to set it as enabled? [Y] "
				//as ",$S(DeepSeeEnabled:"enabled",'DeepSeeEnabled:"disabled")," ? [Y] "
				Read ans
				Set ans = $CASE($ZCONVERT(ans,"U"),"Y":1,"YES":1,"N":0,"NO":0,:1)
				Set:ans web.DeepSeeEnabled = 1
				Write:ans !,webapp_" is now DeepSee enabled"
				Write:'ans !,webapp_" is left DeepSee disabled"
			}
		}		
		Set st = web.%Save()
		Write:st !,"Allowed authentication methods for "_webapp_": Password, Login Cookie"
		Write:'st !,"Failed editing ",webapp," : ",$System.Status.GetOneErrorText(st)
	}
	//Enable cookie creation
	Set st = ##Class(Security.System).Get("SYSTEM",.prop)
	If ('st) {
		Write:'st !,"Failed to edit Security Authentication/CSP Session Option: ",$System.Status.GetOneErrorText(st)
	} Else {
		Set prop("AutheEnabled")=17520
		Set st = ##Class(Security.System).Modify("SYSTEM",.Properties)
		Write:st !,"Allowed creation of login cookies"
		Write:'st !,"Failed to enable cookie creation in Security Authentication/CSP Session Option: ",$System.Status.GetOneErrorText(st)
	}
	///Remove public USE on %DeepSee_* resources
	Set list = $LB("%DeepSee_Admin","%DeepSee_Analyzer","%DeepSee_AnalyzerEdit","%DeepSee_Architect","%DeepSee_ArchitectEdit",
					"%DeepSee_ListingGroup","%DeepSee_ListingGroupEdit","%DeepSee_ListingGroupSQL",
					"%DeepSee_Portal","%DeepSee_PortalEdit","%DeepSee_ReportBuilder")
	Set ptr = 0
	While $ListNext(list,ptr,resource){
		Do ##class(Security.Resources).Get($ZCONVERT(resource,"L"),.prop)
		Set prop("PublicPermission")=""
		Set st=##class(Security.Resources).Modify($ZCONVERT(resource,"L"),.prop)
		Write:st !,"Removed USE permission on "_resource
		Write:'st !,"Failed to remove USE permission on "_resource
	}		
	ZN nsfrom
}

/// Restore what was done by the SecuritySetup method except for:
///   the DeepSee Enabled checkbox, which is left as is
///   Allow creation of Login Cookies settings in in Security Authentication/CSP Session Option, which is left as is
ClassMethod SecurityRestore(ns As %String = "samples")
{
	Set ns = $ZCONVERT(ns,"U")
	Set nsexists = ##class(%SYS.Namespace).Exists(ns)
	If ('nsexists) {
		Write !,ns," namespace does not exist. Aborting"
		Return
	}
	Set nsfrom = $SYSTEM.SYS.NameSpace()
	ZN "%SYS"	
	//Delete roles
	Set list = $LB("DSUser","DSPowerUser","DSAdmin")
	Set ptr = 0
	While $ListNext(list,ptr,role){
		Set st = ##class(Security.Roles).Delete(role)
		Write:st !,role," role deleted"
		Write:'st !,"Failed to deleting the ",role," role: ",$System.Status.GetOneErrorText(st)
	}
	//Change Terminal service to Unauthenticated
	Set prop("AutheEnabled")=64
	Set st = ##class(Security.Services).Modify("%Service_Terminal",.prop)
	Write:'st !,"Failed to give %Service_Terminal Anuthenticated authentication ",$System.Status.GetOneErrorText(st)
	//Delete users
	Set list = $LB("simpleuser","poweruser","admin")
	Set ptr = 0
	While $ListNext(list,ptr,user){
		Set st = ##class(Security.Users).Delete(user)
		Write:st !,"Deleted "_user
		Write:'st !,"Failed to delete "_user_": ",$System.Status.GetOneErrorText(st)
	}	
	///Change authentication methods for three web applications to Password, Login cookie
	Set list = $LB("/csp/sys","/csp/sys/bi","/csp/"_$ZCONVERT(ns,"L"))
	Set ptr = 0
	While $ListNext(list,ptr,webapp){
		Set web = ##class(Security.Applications).%OpenId(webapp)
		If ('web) {
			Write !,"Failed to do %OpenId on "_webapp_" : ",$System.Status.GetOneErrorText(web)
			Write !,"Aborting"
			ZN nsfrom
			Return
		}
		Set web.AutheEnabled = 64
		/*
		//Skipping this because the DeepSee enabled checkbox in Security for /csp/samples is disabled by default but samples is DeepSee enabled. 
		// One can always manually disable DeepSee
		//Ask what to do with DeepSee enabled or not
		If (webapp = ("/csp/"_$ZCONVERT(ns,"L"))) {
			Set DeepSeeEnabled = web.DeepSeeEnabled
			Write !!,"Do you want to keep the DeepSee checkbox for ",webapp," as ",$S(DeepSeeEnabled:"enabled",'DeepSeeEnabled:"disabled")," ? [Y] "
			Read ans
			Set ans = $CASE($ZCONVERT(ans,"U"),"Y":1,"YES":1,"N":0,"NO":0,:1)
			If (ans=0) {
				Set web.DeepSeeEnabled = 'DeepSeeEnabled
				Write:st !,webapp_" is now DeepSee ",$S('DeepSeeEnabled:"enabled",DeepSeeEnabled:"disabled")
			} Else {
				Write:st !,webapp_" is left with DeepSee ",$S(DeepSeeEnabled:"enabled",'DeepSeeEnabled:"disabled")
			}
		}*/		
		Set st = web.%Save()
		Write:st !,"Allowed authentication methods for "_webapp_": Unauthenticated"
		Write:'st !,"Failed to edit "_webapp_" : ",$System.Status.GetOneErrorText(st)
	}	
	//Ask to remove public USE on %DeepSee_* resources
	Write !!,"Do you want to give %DeepSee_ roles public USE permission? [N] "
	Read ans
	Set ans = $CASE($ZCONVERT(ans,"U"),"Y":1,"YES":1,"N":0,"NO":0,:0)
	If (ans=0) {
		Write !,"%DeepSee_* resources are left as they are"
	} ElseIf ans {
		//Remove public USE on %DeepSee_* resources
		Set list = $LB("%DeepSee_Admin","%DeepSee_Analyzer","%DeepSee_AnalyzerEdit","%DeepSee_Architect","%DeepSee_ArchitectEdit",
					"%DeepSee_ListingGroup","%DeepSee_ListingGroupEdit","%DeepSee_ListingGroupSQL",
					"%DeepSee_Portal","%DeepSee_PortalEdit","%DeepSee_ReportBuilder")
		Set ptr = 0
		While $ListNext(list,ptr,resource){
			Do ##class(Security.Resources).Get($ZCONVERT(resource,"L"),.prop)
			Set prop("PublicPermission")="U"
			Set st=##class(Security.Resources).Modify($ZCONVERT(resource,"L"),.prop)
			Write:st !,"Added USE permission on "_resource
			Write:'st !,"Failed to add USE permission on ",resource,": ",$System.Status.GetOneErrorText(st)
		}	
	}
	ZN nsfrom
}

Storage Default
{
<Data name="SecurityToolsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^Ale.SecurityToolsD</DataLocation>
<DefaultData>SecurityToolsDefaultData</DefaultData>
<IdLocation>^Ale.SecurityToolsD</IdLocation>
<IndexLocation>^Ale.SecurityToolsI</IndexLocation>
<StreamLocation>^Ale.SecurityToolsS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

