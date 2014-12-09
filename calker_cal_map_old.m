function calker_cal_map(proj_name, exp_name, ker, events)
	
	calker_exp_dir = sprintf('/net/per900a/raid0/plsang/%s/experiments/%s-calker/%s', proj_name, exp_name, ker.feat);

	db_file = fullfile(calker_exp_dir, 'metadata', 'database_test.mat');

    load(db_file, 'database');
	
	

	% event names
	n_event = length(events);
	
	fprintf('Scoring for feature %s...\n', ker.name);

	
	scorePath = sprintf('%s/scores/%s.scores.mat', calker_exp_dir, ker.name);
	mapPath = sprintf('%s/scores/%s.map.mat', calker_exp_dir, ker.name);
	
	if ~checkFile(scorePath), 
		error('File not found!! %s \n', scorePath);
	end
	scores = load(scorePath);
    
	map = struct;
	m_ap = [];
	for jj = 1:n_event,
		event_name = events{jj};
		this_scores = scores.(event_name);
		fprintf('Scoring for event [%s]...\n', event_name);
		% choose max score of each segment as score of a video
		this_video_scores = arrayfun(@(x)max(this_scores(find(x == database.video))), unique(database.video));
		
		[sorted_scores, idx] = sort(this_video_scores, 'descend');
        gt_idx = find(database.label == jj);
		
		video_idx = unique(database.video(gt_idx));
		
		rank_idx = arrayfun(@(x)find(idx == x), video_idx);
        
        sorted_idx = sort(rank_idx);	
		ap = 0;
		for kk = 1:length(sorted_idx), 
			ap = ap + kk/sorted_idx(kk);
		end
		ap = ap/length(sorted_idx);
		m_ap = [m_ap ap];
		map.(event_name) = ap;
	end	
	
	m_ap
	mean(m_ap)
	map.('all') = mean(m_ap);
	
	save(mapPath, 'map');
end