function calker_cal_rank(proj_name, exp_name, ker, events)
	
	calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);
	
	test_db_file = sprintf('database_%s.mat', ker.test_pat);
	
	gt_file = fullfile(calker_exp_dir, 'metadata', test_db_file);
	
	fprintf('Loading database [%s]...\n', test_db_file);
    database = load(gt_file, 'database');
	database = database.database;
	
	scoreDir =  sprintf('%s/scores', calker_exp_dir);
	scorePath = sprintf('%s/scores/%s.scores.mat', calker_exp_dir, ker.name);
	mapPath = sprintf('%s/scores/%s.map.csv', calker_exp_dir, ker.name);
    
	if ~checkFile(scorePath), 
		warning('File not found!! %s \n', scorePath);
		return;
	end
	
	
	scores = load(scorePath);
	
	n_event = length(events);
	
	fprintf('Ranking for feature %s...\n', ker.name);
	
	
	for jj = 1:n_event,
		event_name = events{jj};
		
		
		this_scores = scores.(event_name);
		
		fprintf('-- [%d] Ranking for event [%s]...\n', jj, event_name);
		
		[sorted_scores, sorted_idx] = sort(this_scores, 'descend');
		
		rankFile = sprintf('%s/%s.%s.video.rank', scoreDir, event_name, ker.name);
		
		fh = fopen(rankFile, 'w');
		for kk=1:length(sorted_scores),
			rank_idx = sorted_idx(kk);
			fprintf(fh, '%s %f\n', database.cname{rank_idx}, sorted_scores(kk));
		end
		
		fclose(fh);
	end	
	
end