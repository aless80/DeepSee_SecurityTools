# DeepSee_SecurityTools
A class with methods that I commonly use to test or troubleshoot Security issues in IS Caché and DeepSee.

### Description
This class modifies the security settings in a Caché instance. For this reason I recommend using it **only in test environments**. By default, three users are created with the following roles and permissions:  


| User | Role | Resource  |
|: --------- |:--------------------------------------:|:-----:|
|  | DSUser | :U,%Service_Terminal:U,%Development:U DBresource_":RW |



| User        | Role        | Resource  | Permission   |
| ----------- |:----------- | :-------- | :----------- |
| simpleuser  | DSUser      | %DeepSee_Portal<br>%Service_Terminal<br>%Development<br>DB&lt;database> | U<br>U<br>U<br>RW |
| poweruser   | DSPowerUser | %DeepSee_AnalyzerEdit<br>%DeepSee_Portal<br>%DeepSee_PortalEdit<br>%Service_Terminal<br>%Development<br>DB&lt;database> | U<br>U<br>U<br>U<br>U<br>RW |
| admin       | DSAdmin     | %DeepSee_ArchitectEdit<br>%DeepSee_AnalyzerEdit<br>%DeepSee_Portal<br>%DeepSee_Admin<br>%Service_Terminal<br>%Development<br>%DB_CACHESYS<br>DBresource<br>DB&lt;database> | U<br>U<br>U<br>U<br>U<br>U<br>U<br>RW<br>RW |





<!--
### Content

![Alt Text](https://github.com/aless80/DeepSee_SecurityTools/blob/master/img/.png)           
-->

### Instructions
#### Programmatic import from Caché console
```
ZN "SAMPLES"
Set path="/home/amarin/DeepSee_SecurityTools/"  //Set your path
W $system.OBJ.Load(path_"SecurityTool.cls","cf")  //import the Patients2 cube
```
If your instance does not support UDL formatting please use the .xml file.

#### Manual import
Import the SecurityTool.cls class or the .xml if your instance does not support UDL formatting. 

#### Using the class
TODO
