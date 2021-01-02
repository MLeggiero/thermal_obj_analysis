# thermal_obj_analysis
     Copyright (C) 2020  Mark Leggiero
 
     This program is free software: you can redistribute it and/or modify
     it under the terms of the GNU General Public License as published by
     the Free Software Foundation, either version 3 of the License, or
     (at your option) any later version.
 
     This program is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     GNU General Public License for more details.
 
     You should have received a copy of the GNU General Public License
     along with this program.  If not, see <https://www.gnu.org/licenses/>.
     

We hope this software proves beneficial to your research. While not required by the license, if you use this software in your research, we hope you will consider citing the original article associated with the software:

<Include full reference to article here>

   Thank you!          :+1:

## **SOFTWARE GUIDE**

*Important background information on OBJ file analysis such as the measurements to be made (which are input into the VAMPIRE Tools software) and how these measurements should be preprocessed is detailed in the original article associated with this software (see reference above). If more detailed help is needed, you can contact the author at mleggiero@gatech.edu*

### **1. Installation and Use**

- The VAMPIRE Tools software can be used as downloaded (no installation process required), and is proven fully functional when used with the MATLAB R2020a environment. To begin, open 'VAMPIRE_Tools.mlapp'.
- OBJ files (along with associated texture image file) must be stored in the same directory as the VAMPIRE Tools application and other relevant files. It is most convienient to store relevant OBJ files in folders within this directory, and copy/paste the OBJ and texture file into the main directory for analysis. Then use the file's designated original folder as the output folder when results are generated.
 
### **2. Operating the Vampire Tools GUI**

A. File Selection
- First, select the 'OBJ File' button on the top of the GUI, which will open the file explorer and allow you to select the thermal OBJ file being analyzed.
- Select the 'Texture File' button, and select the thermal texture file associated with the OBJ file.
- Next select 'Output Folder' and find the folder which you wish the results of the radiative heat loss analysis to be stored upon completed. Results will be tabulated in an excel spreadsheet with the same name as the OBJ file.

B. Analysis Parameters
*For important information on how these parameters can be obtained, please refer to the article associated with this software: <Include full reference to article here>*
     
- *Hottest Temperature:* In Celcius - The highest temperature represented in the thermal imagery used to generate the thermal OBJ model.
- *Coldest Temperature:* In Celcius - The lowest temperature represented in the thermal imagery used to generate the thermal OBJ model.
- *Ambient Temperature:* In Celcius - Average temperature of the air surrounding the analyzed structure while measurements are made.
- *Ground Temperature:* In Celcius - Average temperature of the ground surface surrounding the analyzed structure while measurements are made.
- *Dew Point Temperature:* Dew point temperature of the ambient air surrounding the structure at the time of measurement.
- *Emissivity:* Average emissivity of the surfaces of the structure.
- *Wall Angle:* The average angle between the wall (of the structure being analyzed) and the ground immediately next to the structure.
     - *Wall Angle* will only be an option if *Use Global Angle* is checked. If not checked, the software will calculate the angle of the OBJ model faces with respect to the ground plane (defined by local OBJ coordinates). This method is more accurate if the ground plane is correctly defined when the model is oriented (and local coordinated redefined) with software such as [Blender](https://www.blender.org/).

### **3. **

### **4. Other Important Notes**

- The software is set to utilize the parallel processing functionality of MATLAB. If the user desires _not_ to have the software utilize multiple cores when running, on line 208 of 'radiative_output_calculator.m', replace the 'parfor' loop with 'for'.
