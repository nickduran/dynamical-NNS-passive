## The Action Dynamics of Native and Non-native Speakers of English in Processing Active and Passive Sentences (Linguistic Approaches to Bilingualism)

* Step 1: Prepare raw x,y trajectories from MouseTracker for variable extraction. Code written in Python. 
* Step 2: Extract action dynamics variables as reported in paper. Code written in Matlab.
* Step 3: Generate statistical models for replicating results reported in paper. Code written in R.  
* Also included are TOEFL scores for each participant and various R helper functions for generating statistical models. 

### Raw data

    all_mt_files

### Step 1: Prepare raw data to generate DVs

    masterPrepPassives.ipynb

### Step 2: Generate action dynamics DVs

    extractDVs.m

### Step 3: Run statistical models

    activePassive_analysis.Rmd

### Additional files

* TOEFLSCORES.csv

    TOEFL scores for NNS participants

* save_model.R

    Helper functions for reporting analyses
