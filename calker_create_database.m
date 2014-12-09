function calker_create_database(proj_name, exp_name, kf_name, ker)


common_dir = sprintf('/net/per900a/raid0/plsang/%s/metadata/common', proj_name);
calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);
event_file = fullfile(common_dir, [proj_name '.concepts.lst']);
pats = [{'devel'} {'test'}];

% load event list
events = read_file (event_file);
% create db for dev part

skip_exist = 0;

for pat_ = pats,
    pat = pat_{:};
    
    db_file = fullfile(calker_exp_dir, 'metadata', ['database_' pat '.mat']);
	if exist(db_file, 'file'),
		fprintf('File [%s] already exist! skip!\n', db_file);
		continue;
	end
	
    video_file = fullfile(common_dir, [proj_name '.' pat '.lst']);
    segment_dir = sprintf('/net/per900a/raid0/plsang/%s/metadata/%s/%s', proj_name, kf_name, pat);
    
    if skip_exist && exist(db_file,'file')~=0,
        fprintf('Skipped creating db [%s]!!\n', db_file);
    else
        label_files = {};
        for event_ = events,
            event = event_{:};
            label_file = fullfile(common_dir, [event '.' pat '.lst']); 	% label 1
            label_files = [label_files; label_file];
        end
        
        fprintf('creating the database...');

        database = [];

        database.imnum = 0; % total number of segments
        database.cname = {}; % name of each video
        database.label = []; % label of each video
        database.path = {}; % contain the pathes for each image of each class
        database.nclass = 0; % number of videos
        database.video = []; % video index for each segment

        % load video list
        videos = read_file(video_file);

        % load ground-truth
        for ii = 1:length(label_files),
            video_list = read_file(label_files{ii});
            label_videos{ii} = video_list;
        end


        for ii = 1:length(videos),
            video_name = videos{ii};
			if ~mod(ii, 10),
				fprintf('%.2f%% ', 100*ii/length(videos));
			end
            database.nclass = database.nclass + 1;
            %fprintf('Processing [%d/%d] videos...\n', ii, length(videos));
            database.cname{database.nclass} = video_name;

            segment_file = fullfile(segment_dir, [video_name '.prg']);
            segments = read_file(segment_file);
                     
            c_num = length(segments);

            database.imnum = database.imnum + c_num;
            %label = getlabel(subname, videos1, videos2, videos3);
            label = getlabel (video_name, label_videos);

            database.label = [database.label, ones(1, c_num)*label];
            database.video = [database.video, ones(1, c_num)*database.nclass];

            %
            for jj = 1:c_num,               
                c_path = sprintf('%s/%s/feature/%s/%s/%s/%s/%s.mat',...
                    ker.proj_dir, proj_name, kf_name, ker.feat_raw, pat, video_name, segments{jj});                  
                database.path = [database.path, c_path];
            end;    
            
            %c_path = sprintf('/net/per900a/raid0/plsang/%s/feature/%s/%s/%s/%s.%s.tar.gz',...
            %        proj_name, kf_name, ker.feat, pat, video_name, ker.feat);                  
            %database.path = [database.path, c_path];

        end;
        disp('done!');
        
        save(db_file, 'database');
        clear database;
    end
end

end


function label = getlabel(vid, videos)

	label = 0;
	for ii = 1:length(videos),
		%% BUG found when using strfind or findstr which will find the first inclusion string
		% if(size(cell2mat(strfind(videos{ii}, vid))) ~= 0),
		%	label = ii;
		% end
		
		if strmatch(vid, videos{ii}, 'exact'),
			label = ii;
		end
	end
	
	if label == 0,
		label = length(videos) + 1; % background label
	end
end

