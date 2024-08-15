function colours = findColours(filename)
    
    image = loadImage(filename);
    circleCoordinates = findCircles(image);
    correctedImage = processImage(circleCoordinates, image, filename);
    colours = getColours(correctedImage);
end

function [image] = loadImage(filename)
   
     image=imread(filename); %read in file using imread

    if isa(image,'uint8')
       image=double(image)/255;
    else
        error('The image is of unknown type');
    end
end

function [circleCoordinates] = findCircles(image)
    % Convert to grayscale
    grayImage = rgb2gray(image);

    binaryImage = ~imbinarize(grayImage);
    connectCompnents=bwconncomp(binaryImage);

    % Measure properties of labeled regions
    regionMeasurements = regionprops(connectCompnents, 'Area', 'Centroid');
    minArea=200;
    MaxArea=10000;
    limitedarea=regionMeasurements([regionMeasurements.Area]>minArea & [regionMeasurements.Area]< MaxArea);
    circleCoordinates=vertcat(limitedarea.Centroid);
    % Sort circles from top-left to top-right, then bottom-left to bottom-right
    medianY = median(circleCoordinates(:,2));
    topHalf = circleCoordinates(circleCoordinates(:,2) <= medianY, :);
    bottomHalf = circleCoordinates(circleCoordinates(:,2) > medianY, :);
    
    % Sort each half by x-coordinate
    [~, topOrder] = sort(topHalf(:,1));
    [~, bottomOrder] = sort(bottomHalf(:,1));
    
    % Combine the sorted halves
    sortedTopHalf = topHalf(topOrder, :);
    sortedBottomHalf = bottomHalf(bottomOrder, :);
    circleCoordinates = [sortedTopHalf; sortedBottomHalf];
    
    % Debugging: Print circleCoordinates after sorting
    %disp('Sorted circleCoordinates:');
    %disp(circleCoordinates);
end


function [alignedImage] = alignWithNoise(Circlecoordinates, image)
    % Load the noisy image
    noisyImage = loadImage('images/org_2.png');
    noisyCircles = findCircles(noisyImage);
    
    T = fitgeotrans(Circlecoordinates, noisyCircles ,'projective');
    alignedImage=imwarp(image,T,'OutputView',imref2d(size(noisyImage)));
  
end
function [correctedImage] = processImage(circleCoordinates, image, filename)
    % Check if the filename contains 'noise'
    if contains(filename, 'noise')
        % Apply denoising
        noiseimage = denoiseImage(image);
        correctedImage = imcrop(noiseimage, [68.5 66.5 349 348]);
    % Check if the filename contains 'proj' or 'rot'
    elseif contains(filename, {'proj', 'rot'})
        % Align the image with noisy image circles
        alignedImage = alignWithNoise(circleCoordinates, image);
        % Now crop the image
        correctedImage = imcrop(alignedImage,[62.5 58.5 345 346]);
        % Display size of the image before and after crop for debuggin
    % Otherwise, return the original image
    else
        correctedImagee = image;
        correctedImage = imcrop(correctedImagee, [68.5 66.5 349 348]);
    end
end

function [denoisedImage] = denoiseImage(image)
    % Define the filter
    filter = fspecial('average', [5 5]); % Create a 5x5 average filter
    
    % Apply the filter to the image
    denoisedImage = imfilter(image, filter);
end

function colours = getColours(image)
     % Convert the image from RGB to Lab color space
     cform = makecform('srgb2lab');
     labImage = applycform(image, cform);
 
     % Split the Lab image into its channels

      a = labImage(:,:,2);
      b = labImage(:,:,3);

     % Define color ranges based on the Lab values
     % The ranges are broad to account for different shades and overlaps
     redRange = [50, 100; 20, 80];     % Extended `b*` range to accommodate the feedback
     greenRange = [-100, -50; 42, 85]; % Broad green range; `a*` is negative, `b*` can vary
     blueRange = [-100, 100; -120, -40];    % Blue range; both `a*` and `b*` are negative
     yellowRange = [-60, 20; 60, 120];   % Yellow range; both `a*` and `b*` are positive
     whiteRange = [-15, 15; -20, 20];   % White range; low absolute values for `a*` and `b*`
 
     % Preallocate a 4x4 cell array to store the color names
     colours = cell(4, 4);
 
     % Calculate the size of each block in the grid
     [rows, cols, ~] = size(image);
     blockRows = rows / 4;
     blockCols = cols / 4;
 
     % Loop over each block in the 4x4 grid
     for i = 1:4
         for j = 1:4
            % Extract the block from the Lab image
             block = labImage(floor((i-1)*blockRows)+1:floor(i*blockRows), floor((j-1)*blockCols)+1:floor(j*blockCols), :);
 
             % Calculate the average color of the block in Lab space
             avgColor = squeeze(mean(mean(block, 1), 2));
             %fprintf('Block (%d,%d) - L: %.2f, a: %.2f, b: %.2f\n', i, j, avgColor(1), avgColor(2), avgColor(3));
             % Determine the color of the block based on the average color in Lab space
             if avgColor(2) >= redRange(1,1) && avgColor(3) >= redRange(2,1) && avgColor(3) <= redRange(2,2)
                 colours{i, j} = 'red';
             elseif avgColor(2) <= greenRange(1,2) && (avgColor(3) >= greenRange(2,1) || avgColor(3) <= greenRange(2,2))
                 colours{i, j} = 'green';
             elseif avgColor(2) <= blueRange(1,2) && avgColor(3) <= blueRange(2,2)
                 colours{i, j} = 'blue';
             elseif avgColor(2) >= yellowRange(1,1) && avgColor(3) >= yellowRange(2,1)
                 colours{i, j} = 'yellow';
             elseif abs(avgColor(2)) <= whiteRange(1,2) && abs(avgColor(3)) <= whiteRange(2,2)
                 colours{i, j} = 'white';
             else
                 colours{i, j} = 'unknown'; % For any color that does not match the above ranges
             end
         end
     end
     return;
 end
% % % % % Main script to execute the functions
% filename = 'images/noise_1.png';
% image = loadImage(filename);
% % % % 
% % %Find circle 
% circleCoordinates = findCircles(image);
% % % % 
% % % % % Process the image
% processedImage = processImage(circleCoordinates, image, filename);
% % % % 
% % % % % Display the cropped image
% figure;
% imshow(processedImage);
% title('Cropped Image');
% % 
% colours = getColours(processedImage);
% disp(colours);

