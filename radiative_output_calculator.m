function output = radiative_output_calculator(obj_file, texture_file, parameters, obj)

% Copyright (C) 2020  Mark Leggiero
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <https://www.gnu.org/licenses/>.

obj = obj;

obj_file = string(obj_file);
texture_file = string(texture_file);

toLow = parameters(1);
toHigh = parameters(2);
Tamb = parameters(3);
Emissivity = parameters(4);
wall_ang = parameters(5);
T_dew_point = parameters(6);
T_ground = parameters(7);
obj_distance = parameters(8);
real_distance = parameters(9);

tic

progress = waitbar(0, 'Creating Face/Texture/Vertex Vectors...');

objReadTime = toc;
imageMat = imread(texture_file);
imageMat = imageMat(:,:,1);
[imRow, imCol] = size(imageMat);
pts = [];
[verts, ~] = size(obj.v);
vt_tex = obj.vt;
v = obj.v;
vf = obj.f.v;
vt = obj.f.vt;

% Triangle Area Formula Addition
% by Mark Leggiero - 5/21/2019
faces = obj.f.v;
vert = obj.v;
[facesSize, ~] = size(faces);
mult = real_distance/obj_distance;

a = zeros(1,length(facesSize));
for i = (1:facesSize)
    %Find coordinate points associated with each triangle
    point1 = vert(faces(i,1),[1:3]);
    point2 = vert(faces(i,2),[1:3]);
    point3 = vert(faces(i,3),[1:3]);
    
    %3D Distance formula
    side1 = ((point2(1) - point1(1))^2 + (point2(2) - point1(2))^2 + (point2(3) - point1(3))^2)^(1/2);
    side2 = ((point2(1) - point3(1))^2 + (point2(2) - point3(2))^2 + (point2(3) - point3(3))^2)^(1/2);
    side3 = ((point3(1) - point1(1))^2 + (point3(2) - point1(2))^2 + (point3(3) - point1(3))^2)^(1/2);
    side1 = side1*mult; side2 = side2*mult; side3 = side3*mult;
    
    %Heron's formula - calculates area
    s = (side1 + side2 + side3)/2;
    area = sqrt(s * (s-side1) * (s-side2) * (s-side3));
    
    a(i) = area;
    obj.f.a = a;
end

areas = obj.f.a;
[vfsize, ~] = size(vf);
powers = zeros(1, vfsize);
sb_powers = zeros(1, vfsize);
waitbar(0.75,progress, 'Creating Face/Texture/Vertex Vectors...');

%Creates vetor which contains temperature by vertex 
    temps = zeros(verts,1);
for i = (1:verts)
    vX = round(v(i,1),2); vY = round(v(i,2),2); vZ = round(v(i,3),2);
    
    %% Old OBJ Temps code - for finding temps vector %%
    vertMat = obj.v;
    roundedOBJ = vertMat(:,[1:3]);
    roundedOBJ = round(roundedOBJ,2);
    [desiredRow, ~] = find(roundedOBJ(:,1) == vX &  roundedOBJ(:,2) == vY & roundedOBJ(:,3) == vZ);
    
    %find row(Rv) from obj.faces
    [Rt, ~] = find(obj.f.v == desiredRow(1));
    
    textVec = obj.f.vt(Rt,:);
    textVec = textVec(1:end)';
    [vecRow, ~] = size(textVec);
    sizeVec = sum(sum(ones(vecRow, 1)));
    
    meanDigNum = zeros(sizeVec-1,1);
    for cont = (1:sizeVec-1)

         myRow = textVec(cont);
         
        [objTrow, ~] = size(obj.vt);
        objTec = [(1:objTrow)', obj.vt(1:end,1:2)]; %Creates the matrix with verts with reference #s
        [imageRow, imageCol] = size(imageMat);
        
        digNumheight = abs(round(imageRow * objTec(myRow,2))); %gets the second column of the vt matrix = height index
        if digNumheight > imageRow
            digNumheight = digNumheight - 1;
        end
        if digNumheight == 0
            digNumheight = 1;
        end
        
        digNumwidth = abs(round(imageCol * objTec(myRow,3))); %gets the third column of the vt matrix = width index
        if digNumwidth > imageCol
            digNumwidth = digNumwidth - 1;
        end
        if digNumwidth == 0
            digNumwidth = 1;
        end
        meanDigNum(cont) =  imageMat(digNumheight, digNumwidth); %finds digNum pixel in image
    end
    meanDigNum = round(mean(meanDigNum));
    temp1 = (meanDigNum) * (toHigh - toLow) / (255) + toLow + 273.15;
    temps(i,1) = temp1;
end
waitbar(1,progress, 'Creating Face/Texture/Vertex Vectors...');

%scale C parameters to K
Tamb = Tamb + 273.15;
T_ground = T_ground + 273.15;
T_dew_point = T_dew_point + 273.15;

parfor i = 1:vfsize %Calculating power output for each triangle face, and compiling them
    x1 = (obj.vt(obj.f.vt(i,1),1)*imCol);
    x2 = (obj.vt(obj.f.vt(i,2),1)*imCol);
    x3 = (obj.vt(obj.f.vt(i,3),1)*imCol);
    
    y1 = (obj.vt(obj.f.vt(i,1),2)*imRow);
    y2 = (obj.vt(obj.f.vt(i,2),2)*imRow);
    y3 = (obj.vt(obj.f.vt(i,3),2)*imRow);
    
    pts = [x1, x2, x3, y1, y2, y3];
    
    %% old triPixelFind function now in calculation
    xpts = [x1 x2 x3 x1]; ypts = [y1 y2 y3 y1];
    [poly_x, poly_y, intensity] = improfile(imageMat,xpts,ypts);
    face_vals = [poly_x, poly_y, round(poly_x), round(poly_y), intensity];
    
    y_max = max(ypts);
    y_min = min(ypts);
    inner_pixels = zeros(1,1);
%     for i1 = y_min:y_max
%         x_min = min(face_vals(face_vals(:,4) == i1,3));
%         x_max = max(face_vals(face_vals(:,4) == i1,3));
%         for j = x_min:x_max
%             inner_pixels(1,round((i1-y_min)*(y_max-y_min + x_max-x_min))) = imageMat(i1,j);
%         end
%     end
    
    for i1 = y_min:y_max
    x_min = min(face_vals(face_vals(:,4) == i1,3));
    x_max = max(face_vals(face_vals(:,4) == i1,3));
    for j = x_min:x_max
        inner_pixels = [inner_pixels, imageMat(i1,j)];
    end
end
    
    inner_pixels(inner_pixels == 0) = [];
    face_pixels = [intensity', inner_pixels];
    avDigNum = mean(face_pixels);
    newTemp = double(((avDigNum) .* (toHigh - toLow) ./ (255) + toLow) + 273.15);
    
    %% Stephan - Boltzmann Law %%
    pw0 = areas(i) * Emissivity * 5.670374419*10^(-8) * (newTemp^4 - Tamb^4);
    
    %% NEW FORMULA %%
    Em_sky = 0.787 + 0.764 * log(T_dew_point/273.15);
    T_sky = (Em_sky)^(1/4) * Tamb;
    h_r = 5.670374419*10^(-8)*(newTemp + T_sky) * (newTemp^2 + T_sky^2);
    pw1 = areas(i)*Emissivity*h_r*(newTemp-(0.5*(1-cos(wall_ang))*T_ground + (1-0.5*(1-cos(wall_ang)))*T_sky));
    
    %Sum powers and increase index
    powers(i) = pw1;
    sb_powers(i) = pw0;
    
%         if i == 1
%        waitbar(i/vfsize,progress, sprintf("Calculating Power Output... %.0f Faces",vfsize));
%         elseif i == round(vfsize/4)
%        %time_f = toc;   change_time = round(time_f - time_o,1);
%        waitbar(i/vfsize,progress, sprintf("Calculating Power Output... %.0f Faces",vfsize));
%         elseif i == round(vfsize/3)
%        %time_f = toc;   change_time = round(time_f - time_o,1);
%        waitbar(i/vfsize,progress, sprintf("Calculating Power Output... %.0f Faces",vfsize));
%        elseif i == round(vfsize/2)
%        %time_f = toc;   change_time = round(time_f - time_o,1);
%        waitbar(i/vfsize,progress, sprintf("Calculating Power Output... %.0f Faces",vfsize));
%        elseif i == round(vfsize)
%        %time_f = toc;   change_time = round(time_f - time_o,1);
%        waitbar(i/vfsize,progress, sprintf("Calculating Power Output... %.0f Faces",vfsize));
%         end
    
end
waitbar(1,progress,'Calculation Complete');

%Check for how many faces have been excluded due to triPixelFind errors
[row, col] = find(isnan(powers));
faulty_Powers = length(col);
if faulty_Powers >= (0.01*length(areas))
    fprintf("WARNING: %3.1f %% of faces have been excluded from power calculation.\n", 100*faulty_Powers/length(areas));
end
powers(row,col) = 0;

[row, col] = find(isnan(sb_powers));
faulty_Powers = length(col);
if faulty_Powers >= (0.01*length(areas))
    fprintf("WARNING: %3.1f %% of faces have been excluded from power calculation.\n", 100*faulty_Powers/length(areas));
end
sb_powers(row,col) = 0;

%Sum matrices of power output
RadiativePower = sum(powers); %Radiated power from heat loss in W
RadiativePower_SB = sum(sb_powers); %Radiated power from heat loss in W (by stephan boltzmann law)
tot_area = sum(sum(areas));
d6 = toc;

%Create output file text
output =  table('Size',[4 2],'VariableTypes',{'string','double'});
output{1,1} = obj_file;
output{2,1} = texture_file;
output{3,1} = "Total Area (m^2)";                   output{3,2} = tot_area;
output{4,1} = "Radiative Power (kW - New Formula)"; output{4,2} = RadiativePower/1000;
output{5,1} = "Radiative Power (kW - S.B. Law)";    output{5,2} = RadiativePower_SB/1000;
output{6,1} = "Total Calculation Time (s)";         output{6,2} = d6;
output{7,1} = "Scaling Factor";                     output{7,2} = mult;
output{8,1} = "Low Temperature (C)";                output{8,2} = toLow;
output{9,1} = "High Temperature (C)";               output{9,2} = toHigh;
output{10,1} = "Ambient Temp (C)";                  output{10,2} = Tamb-273.15;
output{11,1} = "Emissivity";                        output{11,2} = Emissivity;
output{12,1} = "Wall Angle (radians)";              output{12,2} = wall_ang;
output{13,1} = "Dew Point Temp (C)";                output{13,2} = T_dew_point-273.15;
output{14,1} = "Ground Temp (C)";                   output{14,2} = T_ground-273.15;
end
