%% Matlab script to simulate realistic smFISH images
%  This script simulates realistc 3D smFISH images with different mRNA 
%  localization patterns. The user can control pattern strength and also
%  the expression level. 
%
%  The following patterns are currently supported
%      'cell3D'  : localization towards the cell_membrane in 3D
%      'cell2D'  : localization towards the cell edge (2D)
%      'nuc3D'  : localization towards the nuclear membrane in 3D
%      'nuc2D'  : localization towards the nuclear edge (2D)
%      'foci'    : localization in mRNA foci
%      'random'  : random localization
%      'polarized' : polarized localization
%      'cellext' : localization to annotated cell extensions
%
%  ==== Required data
%  Script will automatically locate the different data (mainly a library of
%  3 cell shapes) needed to perform these simulations. The distributed 
%  package contains a small test data-set to allow for immediate testing.
%  The complete libary of cell shapes can be downloaded as well. Please 
%  consult the user manual for more information. 
%
%  ==== USAGE
%  1. Change different parameters (e.g. number of simulated cells) 
%     according to your needschange 
%
%  2. Script can be run directly (RUN button from the ribbon "EDITOR".) 
%
%     =====================================================================
%     Copyright (C) 2018  Florian Mueller
%     Email: muellerf.research@gmail.com
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     For a copy a copy of the GNU General Public License
%     see <http://www.gnu.org/licenses/>.
%     =====================================================================

clear param_sim

%% Important parameter describing the simulation

%== How many cells will be simulated per pattern and expression levels
param_sim.n_cell = 20;

%=== mRNA levels - defined as a structure
%   - Defined as a structure, each level is defined as field
%   - Images for each level will be saved in a separate folder
%   - You can define as many different levels as needed
%   - Each level is described by a vector. 
%            First value  - mean expression level. Level for given cell will be caluclated based its cell volume compared to the average cell volume of the entire cell library.
%            Second value - lambda of a Poisson distribution to calculated added noise : lambda  - poissrnd(lambda)
%param_sim.mRNA_level.few      = [50  100];
%param_sim.mRNA_level.low      = [100 100];
param_sim.mRNA_level.moderate = [200 100];
%param_sim.mRNA_level.high     = [400 100];

                
%== Distribution of mRNA amplitudes: defined as a skewed Gaussian 
%    These values can be obtained by fitting experimentally obtained
%    intensity distributions, the corresponding Matlab functions are listed
%    in paranteheis.
param_sim.amp.mu     = 550;    % Mean value (mean)
param_sim.amp.sigma  = 150;    % Standard deviation (std)
param_sim.amp.skew   = 0.9;    % Skewness (skewness) 
param_sim.amp.kurt   = 4;      % Kurtosis (kurtosis)

%== Oversampling of PSF to obtain sub-pixel placement
%  Value is determined by how the PSF used to simulate individual mRNA 
%  molecules has been generated. See locFISH user manual for more details. 
param_sim.factor_binning = 3;


%% Define pattern and their strength for different levels
%  - Each pattern has an unique identifier (as specified above)
%  - Each pattern is defined as a structure. 
%  - For each pattern different pattern strength can be specified (see
%    Supplementary Material for more details)
%  - In order to not simulate a pattern, comment out the correponding
%    lines.

%== RANDOM mRNA localization
param_sim.pattern.random.level.NR = 0;  % Not Relevant
 

%== mRNA localization to the CELL MEMBRANE (3D)
param_sim.pattern.cell3D.th_dist_membrane  = 800;

param_sim.pattern.cell3D.level.weak     = 0.7;        % Percentage of localized mRNAs
param_sim.pattern.cell3D.level.moderate = 0.8;                       
param_sim.pattern.cell3D.level.strong   = 0.9; 

%=== mRNA localization to the CELL MEMBRANE (2D)
param_sim.pattern.cell2D.th_dist_membrane  = 800;

param_sim.pattern.cell2D.level.weak     = 0.4;  % Percentage of localized mRNAs
param_sim.pattern.cell2D.level.moderate = 0.5;
param_sim.pattern.cell2D.level.strong   = 0.6;


%== mRNA localization to the NUCLEAR ENVELOPE (3D)
param_sim.pattern.nuc3D.th_dist_nucleus   = 800; 

param_sim.pattern.nuc3D.level.weak     = 0.7;   % Percentage of localized mRNAs
param_sim.pattern.nuc3D.level.moderate = 0.8;
param_sim.pattern.nuc3D.level.strong   = 0.9;
 

%== mRNA localization to the NUCLEAR ENVELOPE (2D)
param_sim.pattern.nuc2D.th_dist_nucleus = 800;  

param_sim.pattern.nuc2D.level.weak     = 0.5;   % Percentage of localized mRNAs
param_sim.pattern.nuc2D.level.moderate = 0.6;
param_sim.pattern.nuc2D.level.strong   = 0.7;

param_sim.pattern.nuc2D.phi_sigma   = 0.1;
param_sim.pattern.nuc2D.phi_mean    = 0.15;

param_sim.pattern.nuc2D.theta_sigma = 1;


%== mRNA Foci
param_sim.pattern.foci.level.strong    = 1;    % Modulate strength of foci
param_sim.pattern.foci.level.moderate  = 0.75;
param_sim.pattern.foci.level.weak      = 0.5;

%- mRNA foci quantified for DYNC1; the factors above modulate how many foci
%  are in a cell, how many mRNAs are per foci, and the foci diameter. 
param_sim.pattern.foci.n_foci.mu    = 6;
param_sim.pattern.foci.n_foci.sigma = 3;
param_sim.pattern.foci.n_foci.skew  = 1;
param_sim.pattern.foci.n_foci.kurt  = 3.5;

param_sim.pattern.foci.RNA_in_foci.mu    = 11;
param_sim.pattern.foci.RNA_in_foci.sigma = 7;
param_sim.pattern.foci.RNA_in_foci.skew  = 3;
param_sim.pattern.foci.RNA_in_foci.kurt  = 13;

param_sim.pattern.foci.foci_diameter = [500 1000];


%== POLARIZED mRNA localization
param_sim.pattern.polarized.p              = 0.75;  % Percentage of localized mRNAs

param_sim.pattern.polarized.level.weak     = 0.95;  % SD of the polarization angle
param_sim.pattern.polarized.level.moderate = 0.62;
param_sim.pattern.polarized.level.strong   = 0.3;


%== Localization to annotated cellular extensions
param_sim.pattern.cellext.dist_max       = 20;  % Maximum distance from tip of extension where mRNAs will be placed
param_sim.pattern.cellext.level.weak     = 10;  % Enrichment ratio in extensions compared to results of cytoplasm
param_sim.pattern.cellext.level.moderate = 15;
param_sim.pattern.cellext.level.strong   = 20;


%% Simulate images
sim_localization_patterns_v1(param_sim)