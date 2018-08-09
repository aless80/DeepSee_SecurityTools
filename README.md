# DeepSee_SecurityTools
A class with methods that I commonly use to test or troubleshoot Security issues in IS Caché and DeepSee.

### Description
This class modifies the security settings in a Caché instance. For this reason I recommend using it only in **test environments**. By default, three users are created with the following roles and permissions. 



### Content

![Alt Text](https://github.com/aless80/DeepSee_SecurityTools/blob/master/img/.png)           


### Instructions
#### Programmatic import from Caché console
```
ZN "SAMPLES"
Set path="/home/amarin/DeepSee_SecurityTools/"  //Set your path
W $system.OBJ.Load(path_"SecurityTool.cls","cf")  //import the Patients2 cube
```

If your instance does not support UDL formatting please use the .xml files in the xml directory.

#### Manual import
1) In the SAMPLES namespace import the Patients2 cube in PatientsCube2.xml. This file contains the cube class for Patients2;
2) Build the cube:
```
W ##class(%DeepSee.Utils).%BuildCube("Patients2",1,1)
```
