# EBBcorr
 Demo code to replicate the simuations performed in *A Bayesian beamformer with correlated priors: application to hippocampal source reconstruction* 

## Requirements 
- SPM https://github.com/spm/spm

The code for performing the source reconstruction with the DAiSS Toolbox is all within the SPM repository.

## Usage
The [EBB solver in DAiSS](https://github.com/spm/spm/blob/master/bf_inverse_ebb.m) can be interfaced with in two ways.
#### Using MATLAB Batch
Like most of SPM and its respective toolboxes, DAiSS is typically interfaced with using the MATLAB Batch, an exmple of it can be seen in [here](https://github.com/georgeoneill/EBBcorr/blob/master/run_sims_and_inversions.m#L129) but in short you can call the options using 
```
matlabbatch{JOB}.spm.tools.beamforming.inverse.plugin.ebb.OPTION = VALUE;
```
#### Direct call
It is posible to directly call the function, though its not really advised to in this way. 
```
BF.inverse = bf_inverse_ebb(BF,S);
```
Where `BF` is the stucture DAiSS uses to store all processing and `S` is a structure containing all options.
### Options
DAiSS is comically undocumented, the following options for the EBB code can be called:

**keeplf:** (*default: false*) Keep oriented leadfields.

**corr:** (*default: false*) Uses correlated source priors. If no pairs matrix is suppled in the *pairs* option, then for every source the homolog in the opposite hemisphere is located for pairing.

**pairs:** (*default: empty string*) .mat file containing a triangular matrix (full or sparse) with non-zero elements representing which sources are correlate with each other. For example if sources 3 and 5 are correlated then the matrix element (3,5) or (5,3) should equal 1. To keep a source uncorrelated set its respective diagonal element to 1. (e.g. source 4 is uncorrelated so (4,4) = 1).

**iid:** (*default: false*) Set the prior matrix to an identity matrix, which is the equivalent of a basic minimum-norm inversion.

**noise:** (*default: empty string*) BF.mat file of empty room noise (if an i.i.d noise assumption is not to your liking).

**reml:** (*'strict' | 'loose' [default]*) options for the ReML optimising algorithm, setting to strict will try and balance the weighting of the noise to source matrices with a 1:20 ratio (similar to a 5% regularisation). Loose allows it to freely optimise in the same way as SPM.

## Citation
If you find the correlated prior EBB algorithm useful. Please cite the following.
> O’Neill, G.C., Barry, D.N., Tierney, T.M. _et al._ Testing covariance models for MEG source reconstruction of hippocampal activity. Sci Rep **11**, 17615 (2021). https://www.nature.com/articles/s41598-021-96933-0
