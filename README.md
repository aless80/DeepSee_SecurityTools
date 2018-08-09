# DeepSee_SecurityTools
A class with methods that I commonly use to test or troubleshoot Security issues in IS Caché and DeepSee.

### Description
This class modifies the security settings in a Caché instance. For this reason I recommend using it **only in test environments**. By default, three users are created with the following roles and permissions:  

| User        | Role        | Resource  | Permission   |
| ----------- |:----------- | :-------- | :----------- |
| simpleuser  | DSUser      | %DeepSee_Portal<br>%Service_Terminal<br>%Development<br>DB&lt;database> | U<br>U<br>U<br>RW |
| poweruser   | DSPowerUser | %DeepSee_AnalyzerEdit<br>%DeepSee_Portal<br>%DeepSee_PortalEdit<br>%Service_Terminal<br>%Development<br>DB&lt;database> | U<br>U<br>U<br>U<br>U<br>RW |
| admin       | DSAdmin     | %DeepSee_ArchitectEdit<br>%DeepSee_AnalyzerEdit<br>%DeepSee_Portal<br>%DeepSee_Admin<br>%Service_Terminal<br>%Development<br>%DB_CACHESYS<br>DB&lt;database> | U<br>U<br>U<br>U<br>U<br>U<br>RW<br>RW |


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
This example calls the three methods in the Ale.SecurityTools class on the SAMPLES namespace: 

```
SAMPLES>**Do ##class(Ale.SecurityTools).Info()**

 .SecuritySetup("samples")         //Set up security on namepsace
 .SecurityRestore("samples")       //Restore from what SecuritySetup did

SAMPLES>**Do ##class(Ale.SecurityTools).SecuritySetup("SAMPLES")**

New role created: DSUser with %DeepSee_Portal,%Service_Terminal,%Development,%DB_SAMPLES
New role created: DSPowerUser with %DeepSee_AnalyzerEdit,%DeepSee_Portal,
                                   %DeepSee_PortalEdit,%Service_Terminal,%Development,%DB_SAMPLES
New role created: DSAdmin user with %DeepSee_Portal,%DeepSee_ArchitectEdit,%DeepSee_AnalyzerEdit,
                                    %DeepSee_Admin,%Service_Terminal,%Development,%DB_CACHESYS,%DB_SAMPLES
Created simpleuser with password SYS and DSUser role
Created poweruser with password SYS and DSPowerUser role
Failed creating admin user: ERROR #837: User admin already exists
Allowed authentication methods for /csp/samples: Password, Login Cookie
Allowed authentication methods for /csp/sys: Password, Login Cookie
Allowed authentication methods for /csp/sys/bi: Password, Login Cookie
Allowed creation of login cookies
Removed USE permission on %DeepSee_Admin
Removed USE permission on %DeepSee_Analyzer
Removed USE permission on %DeepSee_AnalyzerEdit
Removed USE permission on %DeepSee_Architect
Removed USE permission on %DeepSee_ArchitectEdit
Removed USE permission on %DeepSee_ListingGroup
Removed USE permission on %DeepSee_ListingGroupEdit
Removed USE permission on %DeepSee_ListingGroupSQL
Removed USE permission on %DeepSee_Portal
Removed USE permission on %DeepSee_PortalEdit
Removed USE permission on %DeepSee_ReportBuilder
SAMPLES>**Do ##class(Ale.SecurityTools).SecurityRestore("SAMPLES")**

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

```
