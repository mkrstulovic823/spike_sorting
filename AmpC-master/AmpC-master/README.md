AmpC - Manual spike sorting, post-Kilosort, for tetrode data. 

# INSTRUCTIONS

## Adding dependencies to MATLAB path
1. Add the folder 'funcs' to your path, including subfolders. To do this, use the 
   command addpath(genpath(***)), replacing *** with the folder address. 
2. Add the folder 'main' to your path. 	
3. Check that you have the repository 'npy-matlab' on your path. 

## Changing settings
To find variables that you may need to change, search the file 'AmpC' for the word 'Specify' 
(using Ctrl+F). 

## Starting the programme
1. Change any necessary filenames, settings etc. in AmpC_Setup. 
2. Within MATLAB, change your current directory to one containing:
	a. The *.npy files produced by Kilosort for use by Phy
	b. The file containing the electrophysiological data you want to analyse. 
3. Type in the following at the command line and press Enter:
	AmpC_Setup.m
   (This may take several minutes to complete. Eventually, a message box will appear saying the cluster list 
   has been updated; press OK and it should finish.) 
4. Type in the following at the command line and press Enter:
	g = AmpC_Main(amp, clusters, s)
5. Amp should now load its windows so it covers most of your screen. It is advisable to go back to MATLAB 
and rearrange your panels (Command Window, Editor, Workspace etc.) so that the command window is visible in 
the gap between Amp's windows - any programme errors and warnings will be reported here. 

If you run into any errors, please email pc518@cam.ac.uk, putting 'Amp' in the email header. 

# APPENDIX

Full list of dependencies for AmpC_ programmes when run on my office PC, as of 2020-04-01:
(Enclosing folders will differ from structure used for Github upload.)

'C:\Users\Prannoy\Documents\MATLAB\Folder 10 - AmpNPXlim\get_wdw.m'
'C:\Users\Prannoy\Documents\MATLAB\Folder 10 - AmpNPXlim\inv_tetch.m'
'C:\Users\Prannoy\Documents\MATLAB\Folder 12 - AmpC\AmpC_ClusterUpdate.m'
'C:\Users\Prannoy\Documents\MATLAB\Folder 12 - AmpC\AmpC_Main.m'
'C:\Users\Prannoy\Documents\MATLAB\Folder 12 - AmpC\AmpC_Setup.m'
'C:\Users\Prannoy\Documents\active_scripts\Neuropixel\npy-matlab\constructNPYheader.m'
'C:\Users\Prannoy\Documents\active_scripts\Neuropixel\npy-matlab\readNPY.m'
'C:\Users\Prannoy\Documents\active_scripts\Neuropixel\npy-matlab\readNPYheader.m'
'C:\Users\Prannoy\Documents\active_scripts\Neuropixel\npy-matlab\writeNPY.m'
'Z:\Software\pg_Matlab\LargeEnvo - cut data analysis\customfx\Beeper.m'
'Z:\Software\pg_Matlab\LargeEnvo - cut data analysis\customfx\YX_quickplot.m'
'Z:\Software\pg_Matlab\LargeEnvo - cut data analysis\customfx\colsp.m'
'Z:\Software\pg_Matlab\LargeEnvo - cut data analysis\customfx\figsize.m'	
'Z:\Software\pg_Matlab\LargeEnvo - cut data analysis\customfx\loadperc.m'
'Z:\Software\pg_Matlab\LargeEnvo - cut data analysis\customfx\midstripe.m'