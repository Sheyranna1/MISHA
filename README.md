# MTF Analysis Script

This MATLAB script performs a **Modulation Transfer Function (MTF)** analysis on slanted-edge images captured at various camera heights. The tool computes MTF curves, extracts contrast values at specific spatial frequencies, and generates a look-up table (LUT) mapping camera height to MTF metrics.

## Features

- Batch processing of slanted-edge images
- Interactive cropping for consistent region selection across all images
- MTF computation (both cycles/mm and cycles/pixel)
- Visualization of MTF curves per image
- Generation and CSV export of a Camera Height vs MTF Contrast LUT
- Polynomial regression and correlation analysis of MTF vs camera height

## Getting Started

### Prerequisites

- MATLAB R2020b or newer recommended
- Image Processing Toolbox (for `imgaussfilt`, `imcrop`, etc.)

### How to Use

1. **Run the script**  
   Execute the `.m` file in MATLAB.

2. **Select image files**  
   You'll be prompted to select slanted-edge images taken at different camera heights.

3. **Crop each image**  
   You'll be asked to define a cropping rectangle once per image. Ensure you select the same slanted edge across all images.

4. **View results**  
   - The script will plot MTF curves (cycles/mm and cycles/pixel).
   - It will generate and display a LUT relating camera height to MTF contrast at 0, 0.25, 0.5, and 1 cycles/pixel.
   - It will perform a polynomial regression analysis on MTF trends with height.

5. **Save the LUT**  
   You'll be prompted to choose a folder to save the resulting CSV file.

## Output Files

- `LUT_CameraHeight_Contrast.csv`  
  A table mapping camera height (in cm) to MTF contrast at selected frequencies.

## Output Plots

- MTF vs Frequency (for each image)
- MTF Contrast vs Camera Height
- Mean MTF vs Camera Height (with polynomial fit)

## Notes

- Image filenames should ideally include the camera height (e.g., `30cm_image1.jpg`) for automatic parsing.
- If camera height cannot be parsed, a warning will be shown and the file may be skipped in LUT analysis.

## Author

Sheyranna Cajigas  
Senior, BS Imaging Science  
Rochester Institute of Technology
