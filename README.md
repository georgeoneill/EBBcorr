# EBBcorr
 Demo code to replicate the simuations performed in *A Bayesian beamformer with correlated priors: application to hippocampal source reconstruction* 

## Requirements 
- SPM12 https://www.fil.ion.ucl.ac.uk/spm/software/spm12/
- DAiSS Toolbox: https://github.com/spm/DAiSS. (NOTE the EBB code is in the DAiSS repository [here](https://github.com/spm/DAiSS/blob/master/bf_inverse_ebb.m), this is just an example pipeline which uses it).

If you have SPM already installed you can update it directly from MATLAB 
```
>> spm_update
         A new version of SPM is available.
>> spm_update update
         Download and install in progress...
         Success: xx files have been updated.
```
To install DAiSS copy the repository into the `toolbox` folder in you SPM root folder in MATLAB. 

## Usage
The [EBB solver DAiSS](https://github.com/spm/DAiSS/blob/master/bf_inverse_ebb.m) can be interfaced with in two ways.
#### Using MATLAB Batch
Like most of SPM and its respective toolboxes, DAiSS is typically interfaced with using the MATLAB Batch, an exmple of it can be seen in [here](https://github.com/georgeoneill/EBBcorr/blob/master/run_sims_and_inversions.m#L129) but in short you can call the options using 
```
matlabbatch{JOB}.spm.tools.beamforming.inverse.plugin.ebb.OPTION = VALUE;
```
#### Direct call
It is posible to directly call the function, though its not really advised to this this way normally. 
```
BF.inverse = bf_inverse_ebb(BF,S);
```
Where `BF` is the stucture DAiSS uses to store all processing and `S` is a structure containing all options.
#### Options

## Citation
If you find the correlated prior EBB algorithm useful. Please cite the following.

```
A Bayesian beamformer with correlated priors: application to hippocampal source reconstruction. (Under review).
