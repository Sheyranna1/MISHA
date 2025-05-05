%% Clear Workspace and Define Sensor Parameters
clc; clear; close all;

sensorWidth_mm = 9;  
resolution_px = 5000;  
pixelPitch_mm = sensorWidth_mm / resolution_px;  

cutoff_freq_mm = 500;  
cutoff_freq_px = 0.5;  

%% Select Image Files
[f1, p1] = uigetfile('*.*', 'Select all image files', 'MultiSelect', 'on');

if ischar(f1)
    f1 = {f1};
end

amount_images = length(f1);
sym = {'m', 'k', 'b', ':k', '--r', '--g', '--b', '-m', '-c'};

%% Crop All Images Once
cropRegions = cell(amount_images, 1);
for ii = 1:amount_images
    img = imread(fullfile(p1, f1{ii}));
    figure, imshow(img, []), title(['Select cropping region for image ', num2str(ii), ' and double-click']);
    cropRegion = round(getrect);
    close;
    cropRegions{ii} = cropRegion;
end

%% Initialize MTF Plots
figure;
tiledlayout(1, 2);

nexttile; hold on;
legendTitles_mm = {};

nexttile; hold on;
legendTitles_px = {};

%% Compute and Plot MTFs
for ii = 1:amount_images
    img = imread(fullfile(p1, f1{ii}));
    croppedImg = imcrop(img, cropRegions{ii});

    camera_height = NaN;
    try
        parts = split(f1{ii}, '_');
        if numel(parts) > 1
            heightStr = strrep(parts{1}, 'cm', '');
            camera_height = str2double(heightStr);
        end
    catch
        disp(['Warning: Could not extract camera height for file: ', f1{ii}]);
    end

    esf = mean(croppedImg, 1);
    lsf = diff(esf);
    mtf = abs(fft(lsf, 2^nextpow2(length(lsf))));
    mtf = mtf / max(mtf);
    mtf = mtf(1:floor(numel(mtf)/2));

    sigma = 1;
    mtf_smooth = imgaussfilt(mtf, sigma);

    freq_px = linspace(0,0.5,numel(mtf_smooth));
    freq_mm = freq_px / pixelPitch_mm;

    valid_idx_mm = freq_mm <= cutoff_freq_mm;
    freq_mm = freq_mm(valid_idx_mm);
    mtf_mm = mtf_smooth(valid_idx_mm);

    valid_idx_px = freq_px <= cutoff_freq_px;
    freq_px = freq_px(valid_idx_px);
    mtf_px = mtf_smooth(valid_idx_px);

    markerIdx = mod(ii-1, numel(sym)) + 1;

    plot(freq_px, mtf_px, sym{markerIdx}, 'DisplayName', [num2str(camera_height), ' cm']);
    legendTitles_px{end+1} = [num2str(camera_height), ' cm'];
end

%% Finalize MTF Plots
nexttile(1);
xlabel('Frequency (cycles/mm)');
ylabel('MTF');
title('Slant Edge MTF (Cycles/mm)');
legend(legendTitles_mm, 'Location', 'bestoutside');
grid on; xlim([0 cutoff_freq_mm]); ylim([0 1]);

nexttile(2);
xlabel('Frequency (cycles/pixel)');
ylabel('MTF');
title('Slant Edge MTF (Cycles/pixel)');
legend(legendTitles_px, 'Location', 'bestoutside');
grid on; xlim([0 cutoff_freq_px]); ylim([0 1]);
hold off;

%% Create LUT: Camera Height vs MTF Contrast Values
LUT = [];

for ii = 1:amount_images
    img = imread(fullfile(p1, f1{ii}));
    croppedImg = imcrop(img, cropRegions{ii});

    parts = regexp(f1{ii}, '\d+', 'match');
    if ~isempty(parts)
        camera_height = str2double(parts{1});
    else
        disp(['Warning: Could not extract camera height for file: ', f1{ii}]);
        continue;
    end

    esf = mean(croppedImg, 1);
    lsf = diff(esf);
    mtf = abs(fft(lsf, 2^nextpow2(length(lsf))));
    mtf = mtf / max(mtf);
    mtf = mtf(1:floor(numel(mtf)/2));

    mtf_smooth = imgaussfilt(mtf, sigma);
    freq_px = linspace(0,0.5,numel(mtf_smooth));

    target_freq_px = [0, 0.25, 0.5, 1];
    contrast_values = NaN(1, length(target_freq_px));

    for jj = 1:length(target_freq_px)
        [~, idx] = min(abs(freq_px - target_freq_px(jj)));
        contrast_values(jj) = mtf_smooth(idx);
    end

    LUT = [LUT; camera_height, contrast_values];
end

LUT = sortrows(LUT, 1);

disp('Camera Height (cm) vs. MTF Contrast at 0, 0.25, 0.5, and 1 cycles/pixel');
disp(array2table(LUT, 'VariableNames', {'Camera_Height_cm', 'Contrast_0', 'Contrast_0_25', 'Contrast_0_5', 'Contrast_1'}));

%% Save LUT to CSV
outputFileName = 'LUT_CameraHeight_Contrast.csv';
outputFolder = uigetdir('', 'Select Folder to Save LUT');
if outputFolder ~= 0
    outputFilePath = fullfile(outputFolder, outputFileName);
    writetable(array2table(LUT, 'VariableNames', {'Camera_Height_cm', 'Contrast_0', 'Contrast_0_25', 'Contrast_0_5', 'Contrast_1'}), outputFilePath);
    disp(['LUT saved to: ', outputFilePath]);
else
    disp('Save operation canceled.');
end

%% Plot Contrast vs Camera Height
figure;
hold on;
plot(LUT(:,1), LUT(:,2), 'bo-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'MTF at 0 cycles/px');
plot(LUT(:,1), LUT(:,3), 'go-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'MTF at 0.25 cycles/px');
plot(LUT(:,1), LUT(:,4), 'ro-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'MTF at 0.5 cycles/px');
plot(LUT(:,1), LUT(:,5), 'ko-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'MTF at 1 cycle/px');
xlabel('Camera Height (cm)');
ylabel('MTF Contrast');
title('MTF Contrast vs. Camera Height');
legend('Location', 'bestoutside');
grid on;
hold off;

%% Mean MTF vs Camera Height with Polynomial Fit
meanMTF_perImage = [];

for ii = 1:amount_images
    img = imread(fullfile(p1, f1{ii}));
    croppedImg = imcrop(img, cropRegions{ii});

    parts = regexp(f1{ii}, '\d+', 'match');
    camera_height = NaN;
    if ~isempty(parts)
        camera_height = str2double(parts{1});
    else
        disp(['Warning: Could not extract camera height for file: ', f1{ii}]);
        continue;
    end

    esf = mean(croppedImg, 1);
    lsf = diff(esf);

    mtf = abs(fft(lsf, 2^nextpow2(length(lsf))));
    mtf = mtf / max(mtf);
    mtf = mtf(1:floor(numel(mtf)/2));

    mtf_smooth = imgaussfilt(mtf, 1);
    freq_px = linspace(0,0.5,numel(mtf_smooth));

    valid_idx = freq_px <= 1;
    freq_px = freq_px(valid_idx);
    mtf_smooth = mtf_smooth(valid_idx);

    mean_mtf = mean(mtf_smooth);
    meanMTF_perImage = [meanMTF_perImage; camera_height, mean_mtf];
end

meanMTF_perImage = sortrows(meanMTF_perImage, 1);
heights = meanMTF_perImage(:,1);
mean_MTFs = meanMTF_perImage(:,2);

p = polyfit(heights, mean_MTFs, 3);
[R, Pval] = corr(heights, mean_MTFs);

figure;
plot(heights, mean_MTFs, 'ko-', 'LineWidth', 2, 'MarkerFaceColor', 'k');
hold on;
plot(heights, polyval(p, heights), 'r--', 'LineWidth', 2);
xlabel('Camera Height (cm)');
ylabel('Mean MTF (0-1 cycles/pixel)');
title('Mean MTF vs Camera Height (Polynomial Fit)');
legend('Data', 'Cubic Polynomial Fit', 'Location', 'best');
grid on;

disp(['Polynomial fit coefficients: ', num2str(p)]);
disp(['Correlation R = ', num2str(R), ', p-value = ', num2str(Pval)]);

if (Pval < 0.05)
    disp('There is a statistically significant correlation.');
else
    disp('No statistically significant relationship detected.');
end

%% Polynomial Regression and Correlation per Frequency
freq_labels = {'0', '0.25', '0.5', '1'};

fprintf('\nPolynomial Regression and Correlation Analysis Results:\n');

for i = 2:size(LUT,2)
    coeffs = polyfit(LUT(:,1), LUT(:,i), 3);
    y_fit = polyval(coeffs, LUT(:,1));
    % (Continue with correlation analysis or plotting if needed)
end
