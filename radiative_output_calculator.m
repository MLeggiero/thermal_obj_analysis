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
%
%
% We hope this software proves beneficial to your research. While not
% required by the license, if you use this software in your research, we 
% hope you will consider citing the original article associated with the
% software:
% <Include full reference to article here>
%
%   Thank you!  :)

%
%
% INPUTS:
%
% obj_file
%   Description: name of the .obj thermal model for analysis
%   Type: string/char
%   Example: "thermal_model.obj"
%
% texture_file
%   Description: name of the .jpg file used for the thermal model texture
%   Type: string/char
%   Example: "thermal_model_texture.jpg"
%
% parameters
%   Description: array of calculation parameters (see lines 60-68) for radiaitve power output
%       formulas (see lines 222-244).
%       Contains (in order) the lowest temperature in the
%       thermal image (in Celcius), the highest temperature in the thermal image (in Celcius), the
%       ambient temperature (in Celcius), the average material emissivity (values between 0-1), the
%       angle between the walls and the outside ground (in radians), the dew
%       point temperature (in Celcius), the arbitrary distance choosen from
%       the .obj model, and the arbitrary real distance from the building.
%   Type: int, long
%   Example: [-20, 25, 18, 0.95, 1.5707, 9.2, 17.5, 15, 27]
%
% obj
%   Description: structure of .obj file data (see readObj.m function)
%       containing the obj vertices (obj.v), vertex textures (obj.vt), faces (obj.f), vertex face
%       reference (obj.f.v), and texture face reference (obj.f.vt)
%   Type: struct
%   Example: obj, obj.v, obj.vt, obj.f, obj.f.v, obj.f.vt
%
% OUTPUTS:
%
% output
%   Description: table of input values (for use in later calculations),
%       and output values from the power output models.

obj = obj;

obj_file = string(obj_file);
texture_file = string(texture_file);

%Extracting paramters from the 'parameters' input array
toLow = parameters(1);
toHigh = parameters(2);
Tamb = parameters(3);
Emissivity = parameters(4);
wall_ang = deg2rad(parameters(5));
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
vn = obj.f.vn;
vec_norm = obj.vn;

% Create vector (obj.f.a) of areas for each face
vert = obj.v;
[facesSize, ~] = size(vf);
mult = real_distance/obj_distance;

a = zeros(1,facesSize);
angle_z = ones(1,facesSize);
for i = (1:facesSize)
    %Find coordinate points associated with each triangle
    point1 = vert(vf(i,1),[1:3]);
    point2 = vert(vf(i,2),[1:3]);
    point3 = vert(vf(i,3),[1:3]);
    
    
    %Calculate local wall angles for oriented model
    if isnan(wall_ang)
        av_norm = cross(point1 - point2,  point3 - point2);
        norm_mag = sqrt((point2(3) - point1(3))^2+(point3(3) - point2(3))^2);
        angle_z(i) = real(acos(av_norm(3)/norm_mag));
    else
        angle_z(i) = angle_z(i) * wall_ang;
    end
    
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

%Create empty array for storing power calculations
powers = zeros(1, vfsize);
powers_b = zeros(1, vfsize);
sb_powers = zeros(1, vfsize);
m1_powers = zeros(1, vfsize);
m2_powers = zeros(1, vfsize);
m3_powers = zeros(1, vfsize);

waitbar(0.5,progress, 'Creating Face/Texture/Vertex Vectors...');

%Creates vetor which contains temperature by vertex
temps = zeros(verts,1);
for i = (1:verts)
    vX = round(v(i,1),2); vY = round(v(i,2),2); vZ = round(v(i,3),2);
    
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
        %Creates the matrix with verts with reference #s
        objTec = [(1:objTrow)', obj.vt(1:end,1:2)];
        [imageRow, imageCol] = size(imageMat);
        
        %gets the second column of the vt matrix = height index
        digNumheight = abs(round(imageRow * objTec(myRow,2)));
        if digNumheight > imageRow
            digNumheight = digNumheight - 1;
        end
        if digNumheight == 0
            digNumheight = 1;
        end
        
        %gets the third column of the vt matrix = width index
        digNumwidth = abs(round(imageCol * objTec(myRow,3)));
        if digNumwidth > imageCol
            digNumwidth = digNumwidth - 1;
        end
        if digNumwidth == 0
            digNumwidth = 1;
        end
        %finds digNum pixel(brightness) in image
        meanDigNum(cont) =  imageMat(digNumheight, digNumwidth);
    end
    meanDigNum = round(mean(meanDigNum));
    temp1 = (meanDigNum) * (toHigh - toLow) / (255) + toLow + 273.15;
    temps(i,1) = temp1;
end
waitbar(0.75,progress, 'Creating Face/Texture/Vertex Vectors...');

%scale C parameters to K
Tamb = Tamb + 273.15;
T_ground = T_ground + 273.15;
T_dew_point = T_dew_point + 273.15;

parfor i = 1:vfsize %Calculating power output for each triangle face, and compiling them
    x1 = (obj.vt(obj.f.vt(i,1),1)*imCol);
    x2 = (obj.vt(obj.f.vt(i,2),1)*imCol);
    x3 = (obj.vt(obj.f.vt(i,3),1)*imCol);
    
    y1 = (abs(1-obj.vt(obj.f.vt(i,1),2))*imRow);
    y2 = (abs(1-obj.vt(obj.f.vt(i,2),2))*imRow);
    y3 = (abs(1-obj.vt(obj.f.vt(i,3),2))*imRow);
    
    pts = [x1, x2, x3, y1, y2, y3];
    
    %% old triPixelFind function now in calculation
    xpts = [x1 x2 x3 x1]; ypts = [y1 y2 y3 y1];
    [poly_x, poly_y, intensity] = improfile(imageMat,xpts,ypts);
    face_vals = [poly_x, poly_y, round(poly_x), round(poly_y), intensity];
    
    y_max = max(ypts);
    y_min = min(ypts);
    inner_pixels = zeros(1,1);
    
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
    
    %% Stephan - Boltzmann Law - Model 1%%
    sigma = 5.670374419*10^(-8);
    pw0 = areas(i) * Emissivity * sigma * (newTemp^4 - Tamb^4);
    
    %Sum powers and increase index
    m1_powers(i) = pw0;
    
    %% NEW FORMULA - Model 2%%
    Em_sky = 0.787 + 0.764 * log(T_dew_point/273.15);
    T_sky = (Em_sky)^(1/4) * Tamb;
    h_r = 4*sigma*newTemp^3
    pw1 = areas(i)*Emissivity*h_r*(newTemp-(0.5*(1-cos(angle_z(i)))*T_ground + (1-0.5*(1-cos(angle_z(i))))*T_sky));
    
    %Sum powers and increase index
    m2_powers(i) = pw1;
    
    %% Model 3 %%
    F_ground = 0.5*(1-cos(angle_z(i)));
    F_sky = 0.5*(1+cos(angle_z(i)));
    Beta = sqrt(0.5*(1+cos(angle_z(i))));
    
    h_ground = (Emissivity*sigma*F_ground*(newTemp^4-Tamb^4))/(newTemp-Tamb);
    h_sky = (Emissivity*sigma*F_sky*Beta*(newTemp^4-T_sky^4))/(newTemp-T_sky);
    h_air = (Emissivity*sigma*F_sky*(1-Beta)*(newTemp^4-Tamb^4))/(newTemp-Tamb);
    
    pw2 = areas(i)*(h_ground*(newTemp-T_ground)+h_sky*(newTemp-T_sky)+h_air*(newTemp-Tamb));
    
    %Sum powers and increase index
    m3_powers(i) = pw2;
    
end
waitbar(1,progress,'Calculation Complete');

%Check for how many faces have been excluded due to algorithmic errors
% - delete NaN entries
[row, col] = find(isnan(m1_powers));
faulty_Powers = length(col);
if faulty_Powers >= (0.01*length(areas))
    fprintf("WARNING: %3.1f %% of faces have been excluded from M2 power calculation.\n", 100*faulty_Powers/length(areas));
end
m1_powers(row,col) = 0;

[row, col] = find(isnan(m2_powers));
faulty_Powers = length(col);
if faulty_Powers >= (0.01*length(areas))
    fprintf("WARNING: %3.1f %% of faces have been excluded from SB power calculation.\n", 100*faulty_Powers/length(areas));
end
m2_powers(row,col) = 0;

[row, col] = find(isnan(m3_powers));
faulty_Powers = length(col);
if faulty_Powers >= (0.01*length(areas))
    fprintf("WARNING: %3.1f %% of faces have been excluded from M3 power calculation.\n", 100*faulty_Powers/length(areas));
end
m3_powers(row,col) = 0;


%Sum matrices of power output
RadiativePower_M1 = sum(m1_powers); %Radiated power from heat loss in W (by stephan boltzmann law)
RadiativePower_M2 = sum(m2_powers); %Radiated power from heat loss in W
RadiativePower_M3 = sum(m3_powers); %Radiated power from heat loss in W (by Model 3)
tot_area = sum(sum(areas));
d6 = toc;

%Create output file text
output =  table('Size',[4 2],'VariableTypes',{'string','double'});
output{1,1} = obj_file;
output{2,1} = texture_file;
output{3,1} = "Total Area (m^2)";                   output{3,2} = tot_area;
output{4,1} = "Radiative Power (kW - Model 1)"; output{4,2} = RadiativePower_M1/1000;
output{5,1} = "Radiative Power (kW - Model 2)";    output{5,2} = RadiativePower_M2/1000;
output{6,1} = "Radiative Power (kW - Model 3)";    output{6,2} = RadiativePower_M3/1000;
output{7,1} = "Total Calculation Time (s)";         output{7,2} = d6;
output{8,1} = "Scaling Factor";                     output{8,2} = mult;
output{9,1} = "Low Temperature (C)";                output{9,2} = toLow;
output{10,1} = "High Temperature (C)";               output{10,2} = toHigh;
output{11,1} = "Ambient Temp (C)";                  output{11,2} = Tamb-273.15;
output{12,1} = "Emissivity";                        output{12,2} = Emissivity;
output{13,1} = "Wall Angle (radians)";              output{13,2} = wall_ang;
output{14,1} = "Dew Point Temp (C)";                output{14,2} = T_dew_point-273.15;
output{15,1} = "Ground Temp (C)";                   output{15,2} = T_ground-273.15;
end
