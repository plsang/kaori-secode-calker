function calker_cal_map(proj_name, exp_name, ker, events, videolevel, fusion)
	
	%videolevel: 1 (default): video-based approach, 0: segment-based approach
	
	if ~exist('videolevel', 'var'),
		videolevel = 1;
	end
	
	calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);
	%
	gt_file = fullfile(calker_exp_dir, 'metadata', 'database_test.mat');
	if ~exist(gt_file, 'file'),
		gt_file = sprintf('%s/%s/annotation/calker_groundtruth/database_test.mat', ker.proj_dir, proj_name);
	end

	if ~exist(gt_file, 'file'),
		error('File not found! [%s]', gt_file);
	end
	
    database = load(gt_file, 'database');
	database = database.database;
	
	

	% event names
	n_event = length(events);
	
	fprintf('Scoring for feature %s...\n', ker.name);

	
	scorePath = sprintf('%s/scores/%s.scores.mat', calker_exp_dir, ker.name);
	videoScorePath = sprintf('%s/scores/%s.video.scores.mat', calker_exp_dir, ker.name);
	mapPath = sprintf('%s/scores/%s.map.csv', calker_exp_dir, ker.name);
    
	if ~checkFile(scorePath), 
		error('File not found!! %s \n', scorePath);
	end
	scores = load(scorePath);
			
	m_ap = zeros(1, n_event);

	if videolevel | (~videolevel & exist(videoScorePath, 'file')),	% video-based
	
		if ~videolevel,
			fprintf('Loading video scores path...\n');
			scores = load(videoScorePath);
		end
	
		
		parfor jj = 1:n_event,
			event_name = events{jj};
			this_scores = scores.(event_name);
			
			fprintf('Scoring for event [%s]...\n', event_name);
			
			[~, idx] = sort(this_scores, 'descend');
			gt_idx = find(database.label == jj);
			
			rank_idx = arrayfun(@(x)find(idx == x), gt_idx);
			
			sorted_idx = sort(rank_idx);	
			ap = 0;
			for kk = 1:length(sorted_idx), 
				ap = ap + kk/sorted_idx(kk);
			end
			ap = ap/length(sorted_idx);
			m_ap(jj) = ap;
			%map.(event_name) = ap;
		end	
	else 		% segment-based
		
		videoScorePath = sprintf('%s/scores/%s.video.scores.mat', calker_exp_dir, ker.name);
		fprintf('Calculating scores at video level...\n');
		
		video_scores_ = cell(n_event, 1);
		
		parfor jj = 1:n_event,
			event_name = events{jj};
			this_scores = scores.(event_name);
			
			% choose max score of each segment as score of a video	
			fprintf('Combining scores at video level for event [%s]...\n', event_name);
			this_video_scores = arrayfun(@(x)max(this_scores(find(x == database.video))), unique(database.video));
			video_scores_{jj} = this_video_scores;
			
			fprintf('Scoring for event [%s]...\n', event_name);
			
			[~, idx] = sort(this_video_scores, 'descend');
			gt_idx = find(database.label == jj);
			
			video_idx = unique(database.video(gt_idx));
			
			rank_idx = arrayfun(@(x)find(idx == x), video_idx);
			
			sorted_idx = sort(rank_idx);	
			ap = 0;
			for kk = 1:length(sorted_idx), 
				ap = ap + kk/sorted_idx(kk);
			end
			ap = ap/length(sorted_idx);
			m_ap(jj) = ap;
			%map.(event_name) = ap;
		end	
		
		video_scores = struct;
		for jj = 1:n_event,
			event_name = events{jj};
			video_scores.(event_name) = video_scores_{jj};
		end
		
		ssave(videoScorePath, '-STRUCT', 'video_scores') ;
	end

	m_ap
	mean(m_ap)	
	%save(mapPath, 'map');
	
	fh = fopen(mapPath, 'w');
	for jj = 1:n_event,	
		event_name = events{jj};
		%fprintf(fh, '%s\t%f\n', event_name, m_ap(jj));
		fprintf(fh, '%f\n', m_ap(jj));
	end
	fprintf(fh, '%f\n', mean(m_ap));
	fclose(fh);
end