D = dir('images/*.png');
score = [];

% Load and process each file in turn
for ind = 1:length(D)
    % Name of PNG file
    filename = fullfile(D(ind).folder, D(ind).name);

    % Name of answer file .mat
    [~, baseFileName, ~] = fileparts(filename);
    mat_filename = fullfile(D(ind).folder, sprintf('%s.mat', baseFileName));

    % Check if the filename contains 'proj_6'
    if contains(filename, 'proj_6')
        score = [score, -1]; % Subtract 1 from the score
        continue; % Skip processing for 'proj_6' file
    end

    % Call the actual findColours function
    res = findColours(filename);

    % Check the answers
    mm = check_answer(res, mat_filename);

    score = [score, mm];
end

% Print out the score
str = repmat('%.2f ', 1, length(score));
fprintf('Score is: ');
fprintf(str, score);
fprintf('\nMean score %f\n', mean(score));
