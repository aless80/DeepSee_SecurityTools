Class Ale.SecurityTools Extends %Persistent
{

/// Just list all methods and some tips
ClassMethod Info() As %Status
{
	Write " .DefaultSecuritySetup(""samples"")         //Set up security on namepsace"
	Write !," .SecurityRestore(""samples"")       //Restore from what DefaultSecuritySetup did"
	Write !," .SecuritySetup(""samples"",""user"",""role"",""%DeepSee_Portal:U,%Development:U"")"
	Write !,?30,"     //Create a user with role and resources. You can omit user to create a role"
	Write !," .SecuritySetup(""samples"",""user"",""role1,role2"",)  //Create a user with two existing roles"
	Quit $$$OK
}

/// This method will implement the security model in Alessandro's post on DC. The aim is to speed up troubleshooting security issues. 
/// <var>ns</var> is the namespace. Default is SAMPLES.<br/>
/// Given an input ns namespace this method will:
/// Create three roles associated to three new users, 
/// Set authentication methods for /csp/<ns>, /csp/sys, /csp/sys/bi web applications to Password, Login cookie
/// For /csp/<ns> ask to set the DeepSee Enable checkbox as enabled
/// Allow creation of Login Cookies (so that you don't have to login 100 times)
/// Remove public USE on %DeepSee_* resources
ClassMethod DefaultSecuritySetup(ns As %String = "SAMPLES")
{
	//Get the default resource for the input namespace
	Do ##class(%SYS.Namespace).GetNSInfo(ns,.info)
	Set DBresource = info("Resource")
	//Create three users with roles
	Set resources = "%DeepSee_Portal:U,%Service_Terminal:U,%Development:U,"_DBresource_":RW"
	Do ..SecuritySetup(ns, "simpleuser", "DSUser", resources)
	Set resources = "%DeepSee_AnalyzerEdit:U,%DeepSee_Portal:U,%DeepSee_PortalEdit:U,%Service_Terminal:U,%Development:U,"_DBresource_":RW"
	Do ..SecuritySetup(ns, "poweruser","DSPowerUser", resources)
	//Set resources = "%DeepSee_ArchitectEdit:U,%DeepSee_AnalyzerEdit:U,%DeepSee_Portal:U,%DeepSee_Admin:U,%Service_Terminal:U,%Development:U,%DB_CACHESYS:RW,"_DBresource_":RW"
	Do ..SecuritySetup(ns, , "DSAdmin", resources) //Create the DSAdmin role
	Do ..SecuritySetup(ns, "admin", "DSPowerUser,DSAdmin") //admin user created with two roles
}

/// Create a user with roles containing resources eg
/// <var>ns</var> is the namespace. Default is SAMPLES.<br/>
/// <var>user</var> is the user. Leave empty if you want to create a role with resources.<br/>
/// <var>roles</var> comma separated list of existing roles to be added to the user. Use one single role if you want to create it.<br/>
/// <var>resources</var> list of resources in the format role1:permission,role2:permission. The resource on the database corresponding to ns will be added automatically<br/>
/// Examples
/// Create a user with one role having three permission (plus %DB_SAMPLES):
/// Do ##class(Ale.SecurityTools).SecuritySetup("SAMPLES", "simpleuser", "DSUser", "%DeepSee_Portal:U,%Service_Terminal:U,%Development:U")
/// Create a new role:
/// Do ##class(Ale.SecurityTools).SecuritySetup("SAMPLES", , "DSAdmin", "%DeepSee_ArchitectEdit:U,%DeepSee_AnalyzerEdit:U")
/// Create a user with two existing roles:
/// Do ##class(Ale.SecurityTools).SecuritySetup("SAMPLES", "admin", "DSPowerUser,DSAdmin")
ClassMethod SecuritySetup(ns As %String = "SAMPLES", user As %String = "", roles As %String = "", resources As %String)
{
	Set ns = $ZCONVERT(ns,"U")
	Set nsexists = ##class(%SYS.Namespace).Exists(ns)
	If ('nsexists) {
		Write !,ns," namespace does not exist. Aborting"
		Return
	}
	Set nsfrom = $SYSTEM.SYS.NameSpace()
	ZN "%SYS"	
	///Create role
	If roles '[ "," {
		Set st = ##class(Security.Roles).Create(roles, roles, resources)
		Write:st "New role created: "_roles_" with "_resources
		Write:'st !,"Error on the "_roles_" role: ",$System.Status.GetOneErrorText(st)
	}
	///Create user with associated roles
	If user '="" {
		Set st = ##class(Security.Users).Create(user, roles, "SYS", user, ns,,,, 1, "Created by Ale.SecurityTools",,,,,1,1)
		Write:st !,"Created "_user_" with password SYS and "_roles_" role"_$S(roles[",":"s",1:"")
		Write:'st !,"Failed creating "_user_": ",$System.Status.GetOneErrorText(st)
	}
	//Change Terminal service to Password
	Set prop("AutheEnabled")=32
	Set st = ##class(Security.Services).Modify("%Service_Terminal",.prop)
	Write:'st !,"Failed to give %Service_Terminal to Password authentication ",$System.Status.GetOneErrorText(st)
	///Change authentication methods for three web applications to Password, Login cookie
	Set list = $LB("/csp/"_$ZCONVERT(ns,"L"),"/csp/sys","/csp/sys/bi")
	Set ptr = 0
	While $ListNext(list,ptr,webapp){
		Set web = ##class(Security.Applications).%OpenId(webapp)
		Set changed = 0
		If web.AutheEnabled '= 16416 {
			Set web.AutheEnabled = 16416
			Set changed = 1
		}
		//Ask to enable DeepSee on "namespace" webapp that is different than /csp/samples, which is a special one
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
				Set changed = 1
			}
		}
		If changed {
			Set st = web.%Save()
			Write:st !,"Allowed authentication methods for "_webapp_": Password, Login Cookie"
			Write:'st !,"Failed editing ",webapp," : ",$System.Status.GetOneErrorText(st)
		}
	}
	//Enable cookie creation
	Set st = ##Class(Security.System).Get("SYSTEM",.prop)
	If ('st) {
		Write:'st !,"Failed to edit Security Authentication/CSP Session Option: ",$System.Status.GetOneErrorText(st)
	} Else {
		if prop("AutheEnabled")'=17520 {
			Set prop("AutheEnabled")=17520
			Set st = ##Class(Security.System).Modify("SYSTEM",.prop)
			Write:st !,"Allowed creation of login cookies"
			Write:'st !,"Failed to enable cookie creation in Security Authentication/CSP Session Option: ",$System.Status.GetOneErrorText(st)
		}
	}
	///Remove public USE on %DeepSee_* resources
	Set list = $LB("%DeepSee_Admin","%DeepSee_Analyzer","%DeepSee_AnalyzerEdit","%DeepSee_Architect","%DeepSee_ArchitectEdit",
					"%DeepSee_ListingGroup","%DeepSee_ListingGroupEdit","%DeepSee_ListingGroupSQL",
					"%DeepSee_Portal","%DeepSee_PortalEdit","%DeepSee_ReportBuilder")
	Set ptr = 0
	While $ListNext(list,ptr,resource){
		Do ##class(Security.Resources).Get($ZCONVERT(resource,"L"),.prop)
		If prop("PublicPermission")'="" {
			Set prop("PublicPermission")=""
			Set st=##class(Security.Resources).Modify($ZCONVERT(resource,"L"),.prop)
			Write:st !,"Removed USE permission on "_resource
			Write:'st !,"Failed to remove USE permission on "_resource
		}
	}
	Write !
	ZN nsfrom
}

/// Restore what was done by the DefaultSecuritySetup method except for:
///   the DeepSee Enabled checkbox, which is left as is
///   Allow creation of Login Cookies settings in in Security Authentication/CSP Session Option, which is left as is
ClassMethod SecurityRestore(ns As %String = "samples")
{
	Set ns = $ZCONVERT(ns,"U")
	Set nsexists = ##class(%SYS.Namespace).Exists(ns)
	If ('nsexists) {
		Write ns," namespace does not exist. Aborting"
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

