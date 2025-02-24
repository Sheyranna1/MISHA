%% Updated MTF Script with Spatial Frequency Cutoff and Pixels/Cycle Plot
clc;

% Sensor parameters (example values; update with actual sensor specs)
sensorWidth_mm = 10;  % Sensor width in mm
resolution_px = 5472;  % Horizontal resolution in pixels
pixelPitch_mm = sensorWidth_mm / resolution_px;  % Pixel pitch in mm/pixel

% Cutoff frequencies
cutoff_freq_mm = 100;  % Maximum frequency to display (cycles/mm)
cutoff_freq_px = 0.3; % Maximum frequency to display (cycles/pixel)

%% Part 1: Select around 10 image files for 10 different bands
[f1, p1] = uigetfile('*.*', 'Select 10 image files', 'MultiSelect', 'on');
if ischar(f1)
    f1 = {f1}; % In case only 1 file
end
amount_images = length(f1);

% Symbol colors for pixels/inch setting for each file
dx = zeros(1, amount_images);
sym = [{'r'} {'g'} {'b'} {'k'} {'--r'} {'--g'} {'--b'} {':k'} {'-m'} {'-c'} {'-y'} ...
       {'--m'} {'--c'} {'--y'} {':m'} {':c'} {':y'} {'-.r'} {'-.g'} {'-.b'} {'-.k'} ...
       {'-.m'} {'-.c'} {'-.y'} {'r-o'} {'g-s'} {'b-d'} {'k-^'} {'m-v'} {'c-p'} {'y-*'} ...
       {'--r-o'} {'--g-s'} {'--b-d'} {'--k-^'} {'--m-v'} {'--c-p'} {'--y-*'} {':r-o'} ...
       {':g-s'} {':b-d'} {':k-^'} {':m-v'} {':c-p'} {':y-*'} {'-.r-o'} {'-.g-s'} {'-.b-d'} ...
       {'-.k-^'} {'-.m-v'} {'-.c-p'} {'-.y-*'}];

%% Placeholder for Crop Region
manualCropRegion = [];  % Will store the cropping region selected for the first image

%% Initialize Plots
figure;
tiledlayout(1, 2);  % Create a side-by-side layout for the plots (remove the third plot)
nexttile; hold on;  % First tile for cycles/mm
legendTitles_mm = {};  % Band info for cycles/mm

nexttile; hold on;  % Second tile for cycles/pixel
legendTitles_px = {};  % Band info for cycles/pixel

%% Updated MTF Computation with Slant Edge Method
for ii = 1:amount_images
    % Extract wavelength from the filename
    wavelength = NaN;  
    try
        parts = split(f1{ii}, '-');  
        wavelengthStr = split(parts{end}, '.');
        wavelength = str2double(wavelengthStr{1});  % Convert to numeric
    catch
        disp(['Error extracting wavelength from filename: ', f1{ii}]);
    end
    
    % Reading in image
    img = imread(fullfile(p1, f1{ii}));
    if size(img, 3) > 1
        img = rgb2gray(img);  
    end
    
    % For the first image, let the user select the cropping region
    if ii == 1
        figure, imshow(img, []), title('Select a cropping region and double-click to confirm');
        manualCropRegion = round(getrect);  % Get user-defined cropping region
        close;
    end
    
    % Crop using the manualCropRegion
    croppedImg = imcrop(img, manualCropRegion);
    if isempty(croppedImg)
        error('Cropped image is empty. Check the cropping region or image data.');
    end
    
    % Compute Edge Spread Function (ESF)
    esf = mean(croppedImg, 1);  % Average intensity across rows to create 1D ESF
    
    % Compute the Line Spread Function (LSF)
    lsf = diff(esf);  % Derivative of ESF
    
    % Compute MTF
    mtf = abs(fft(lsf));
    mtf = mtf(1:floor(numel(mtf)/2));  % Positive frequencies only
    freq_px = linspace(0, 0.5, numel(mtf));  % Normalized frequency (cycles/pixel)
    freq_mm = freq_px / pixelPitch_mm;  % Convert to cycles/mm
    freq_pc = 1 ./ freq_px;  % Convert to pixels/cycle
    freq_pc(freq_px == 0) = Inf;  % Handle division by zero

    % Normalize MTF
    if max(mtf) > 0
        mtf = mtf / max(mtf);
    end
    
    % Apply cutoff for cycles/mm
    valid_idx_mm = freq_mm <= cutoff_freq_mm;
    freq_mm = freq_mm(valid_idx_mm);
    mtf_mm = mtf(valid_idx_mm);
    
    % Apply cutoff for cycles/pixel
    valid_idx_px = freq_px <= cutoff_freq_px;
    freq_px = freq_px(valid_idx_px);
    mtf_px = mtf(valid_idx_px);

    % Apply cutoff for pixels/cycle
    valid_idx_pc = freq_pc <= (1 / cutoff_freq_px) & freq_pc ~= Inf;
    freq_pc = freq_pc(valid_idx_pc);
    mtf_pc = mtf(valid_idx_pc);
    
    % Plot MTF in cycles/mm
    nexttile(1);  % Switch to the first tile
    markerIdx = mod(ii-1, numel(sym)) + 1;
    plot(freq_mm, mtf_mm, sym{markerIdx}, 'DisplayName', [num2str(wavelength), ' nm']);
    legendTitles_mm{end+1} = [num2str(wavelength), ' nm'];
    
    % Plot MTF in cycles/pixel
    nexttile(2);  % Switch to the second tile
    plot(freq_px, mtf_px, sym{markerIdx}, 'DisplayName', [num2str(wavelength), ' nm']);
    legendTitles_px{end+1} = [num2str(wavelength), ' nm'];
end

%% Finalize Plots
% Cycles/mm Plot
nexttile(1);
xlabel('Frequency (cycles/mm)');
ylabel('MTF');
title('Slant Edge MTF Analysis (Cycles/mm)');
legend(legendTitles_mm, 'Location', 'northeast');
grid on;
axis([0 cutoff_freq_mm 0 1]);  % Adjust axis limits

% Cycles/pixel Plot
nexttile(2);
xlabel('Frequency (cycles/pixel)');
ylabel('MTF');
title('Slant Edge MTF Analysis (Cycles/pixel)');
legend(legendTitles_px, 'Location', 'northeast');
grid on;
axis([0 cutoff_freq_px 0 1]);  % Adjust axis limits

hold off;
