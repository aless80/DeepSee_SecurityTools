# DeepSee_SecurityTools
A class with methods that I commonly use to test or troubleshoot Security issues in IS Caché and DeepSee.

### Description
This class modifies the security settings in a Caché instance. For this reason I recommend using it **only in test environments**. By default, three users are created with the following roles and permissions:  

| User        | Role        | Resource  | Permission   |
| ----------- |:----------- | :-------- | :----------- |
| simpleuser  | DSUser      | %DeepSee_Portal<br>%Service_Terminal<br>%Development<br>DB&lt;database> | U<br>U<br>U<br>RW |
| poweruser   | DSPowerUser | %DeepSee_AnalyzerEdit<br>%DeepSee_Portal<br>%DeepSee_PortalEdit<br>%Service_Terminal<br>%Development<br>DB&lt;database> | U<br>U<br>U<br>U<br>U<br>RW |
| admin       | DSAdmin     | %DeepSee_ArchitectEdit<br>%DeepSee_AnalyzerEdit<br>%DeepSee_Portal<br>%DeepSee_Admin<br>%Service_Terminal<br>%Development<br>%DB_CACHESYS<br>DB&lt;database> | U<br>U<br>U<br>U<br>U<br>U<br>RW<br>RW |

This allows you to test Caché and DeepSee using three users having increasingly broad permissions. See also [my articles on this topic](https://community.intersystems.com/post/deepsee-setting-security-part-1-5) on InterSystems' Developer Community.


<!--
### Content

![Alt Text](https://github.com/aless80/DeepSee_SecurityTools/blob/master/img/.png)           
-->

### Instructions
#### Programmatic import from Caché console
```
ZN "SAMPLES"
Set path="/home/amarin/DeepSee_SecurityTools/"  //Set your path
W $system.OBJ.Load(path_"SecurityTools.cls","cf")  //import the Patients2 cube
```
If your instance does not support UDL formatting please use the .xml file.

#### Manual import
Import the SecurityTools.cls class or the .xml if your instance does not support UDL formatting. 

#### Using the class
This example calls the four methods in the Ale.SecurityTools class on the SAMPLES namespace: 

<pre>
SAMPLES><b>Do ##class(Ale.SecurityTools).Info()</b>
 .DefaultSecuritySetup("samples")         //Set up security on namepsace
 .SecurityRestore("samples")       //Restore from what DefaultSecuritySetup did
 .SecuritySetup("samples","user","role","%DeepSee_Portal:U,%Development:U")
                                   //Create a user with role and resources. You can omit user to create a role
 .SecuritySetup("samples","user","role1,role2",)  //Create a user with two existing roles

SAMPLES><b>Do ##class(Ale.SecurityTools).SecuritySetup("samples","user","role","%DeepSee_Portal:U,%Development:U")</b>
New role created: role with %DeepSee_Portal:U,%Development:U
Created user with password SYS and role role
Allowed authentication methods for /csp/samples: Password, Login Cookie
Allowed authentication methods for /csp/sys: Password, Login Cookie
Allowed authentication methods for /csp/sys/bi: Password, Login Cookie

SAMPLES><b>Do ##class(Ale.SecurityTools).DefaultSecuritySetup("SAMPLES")</b>
New role created: DSUser with %DeepSee_Portal:U,%Service_Terminal:U,%Development:U,%DB_SAMPLES:RW
Created simpleuser with password SYS and DSUser role
Allowed authentication methods for /csp/samples: Password, Login Cookie
Allowed authentication methods for /csp/sys: Password, Login Cookie
Allowed authentication methods for /csp/sys/bi: Password, Login Cookie
New role created: DSPowerUser with %DeepSee_AnalyzerEdit:U,%DeepSee_Portal:U,%DeepSee_PortalEdit:U,%Service_Terminal:U,%Development:U,%DB_SAMPLES:RW
Created poweruser with password SYS and DSPowerUser role
New role created: DSAdmin with %DeepSee_AnalyzerEdit:U,%DeepSee_Portal:U,%DeepSee_PortalEdit:U,%Service_Terminal:U,%Development:U,%DB_SAMPLES:RW
Created admin with password SYS and DSPowerUser,DSAdmin roles

SAMPLES><b>Do ##class(Ale.SecurityTools).SecurityRestore()</b>
DSUser role deleted
DSPowerUser role deleted
DSAdmin role deleted
Deleted simpleuser
Deleted poweruser
Deleted admin
Allowed authentication methods for /csp/sys: Unauthenticated
Allowed authentication methods for /csp/sys/bi: Unauthenticated
Allowed authentication methods for /csp/samples: Unauthenticated

Do you want to give %DeepSee_ roles public USE permission? [N] 
%DeepSee_* resources are left as they are
</pre>

### Limitations

This routine is not officially supported by InterSystems Co. I suggest using this routine only in test environments.
