# A Pipeline for Verifying and Improving Lipid and Metabolite Annotations 

## Motivation

Lipid/metabolite annotation can be an intensive manual process. It is prone to error and biases and is often not fully reproducible. Besides, different software or versions of the same software introduce additional variations that may affect the final annotation by the end user. These factors result in discordance of the annotation results, which can negatively impact the data interpretation. 

In [PharmacoOmics Laboratory](https://pharmomicslab.site/), two experimenters often conduct the lipid/metabolite annotation separately. Mismatches can be resolved via discussion and consensus. We also develop and validate a simple computational pipeline to compare and/or complement the annotation results. It covers a few typical scenarios, such as results from two software versions, two experimenters, or one experimenter performing the annotation at two different time points.

The ultimate goals of the pipeline are to minimize lipid/metabolite annotation error and maximize annotation coverage for downstream analyses and biological interpretation.

## Showcase

Lipid annotation using two different MS-DIAL versions (5.2 and 4.9) was conducted in this example. For simplicity, we only included the features from the retention time (RT) range of 2 min to 5 min. The spectral intensity from MS-DIAL ver. 4.9 was considered more reliable. However, MS-DIAL ver. 5.2 had a better annotation interface (i.e., available MS/MS from each sample could be examined). We attempted to improve the quality and coverage of the annotated lipid list from MS-DIAL ver. 4.9 using the annotated lipid list from 5.2. Using the fuzzy search method, our in-house script matched the two annotation results, simultaneously using RT and mass-to-charge ratio (*m/z*).

### Step 1: Prepare the input data

The two input data sets were standardized with information related to the retention time (`RT`), the mass-to-charge ratio (`mz`), lipid name (`name`), adduct (`adduct`), percentage of integrated samples among all samples (`fill_perc`), and signal-to-noise ratio (`SN_ratio`). The three latter variables (i.e., `adduct`, `fill_perc`, and `SN_ratio`) are helpful but optional; if the information is unavailable, leave it empty.

- The target data file from MS-DIAL ver. 4.9 contained highly confident annotated lipids, unsettled, unknown, and w/o MS2 peaks. The first 20 rows are shown below.

<p align="center">
  <img src="https://github.com/Pharmaco-OmicsLab/LipMetAnnotCompare/blob/main/README_Figure/Fig1_Data1.png" width="580"/>
</p>
  
- The data file derived by MS-DIAL ver. 5.2 contained only the highly confident annotated lipids. The goal of this data file is to examine the annotation consistency, explore conflicted annotations, and supplement the lipid species not annotated in the data file derived from MS-DIAL ver. 4.9. The first 20 rows are shown below.

<p align="center">
  <img src="https://github.com/Pharmaco-OmicsLab/LipMetAnnotCompare/blob/main/README_Figure/Fig1_Data2.png" width="460"/>
</p>

### Step 2: Match the annotation

This step is conducted through `Rscripts`, which contains three sub-steps with scripts that need to be modified:

#### Step 2.0: Before conducting annotation matching, we need to modify the name of the data to input into R.

```r
# Modify the input name
## Version1 data name. Here it is data from MS-DIAL ver. 4.9
Version1_data_name = "Input_version49.csv"
## Version2 data name. Here it is data from MS-DIAL ver. 5.2
Version2_data_name = "Input_version52.csv"
```

#### Step 2.1: Perform a fuzzy search. A very high distance threshold is set to avoid missing in the matching.

#### Step 2.2: Set the RT and *m/z* cut-offs to avoid redundancy in the matching results.

```r
# Define cut-offs for RT and m/z.
RT_cut_off = 1.5      # %
mz_cut_off = 0.015    # Da
```

In this step, we used cut-offs for RT and *m/z* of 1.5% and 0.015 Da. Defining these cut-off values depends on the used cases. For example, we performed a *priori* manual check of the highly confident annotated lipids between the two versions. We observed that the maximum difference of RT and *m/z* of these highly confident annotated lipids were 1.5% and 0.015 Da. **Note:** Most of the differences were much lower than the maximum values. Otherwise, the software parameterization of the two software versions should be examined.

#### Step 2.3: Export the results.

```r
# Standardize variable name before exporting
Version1_variable_name = "49"
Version2_variable_name = "52"
```

Output data contains two sheets. The first sheet contains the matching results without applying RT and *m/z* cut-off filtering, and the second sheet contains the matching results applying RT and *m/z* cut-off filtering, corresponding to steps 2.1 and 2.2 above.

The first 10 rows of output data are shown below. 

<p align="center">
  <img src="https://github.com/Pharmaco-OmicsLab/LipMetAnnotCompare/blob/main/README_Figure/Fig3_Output.png" width="1200"/>
</p>

- `Annotation_in_Version1Data` indicates whether the lipids were annotated with high confidence or not in the version 1 data. 

-	The `dist` indicates the text-similarity of `mz_RT`.

-	The `mz_diff` and `RT_diff` were absolute differences of `mz` and `RT` in Da and min. The `RT_diff_percentage` was the RT difference in percentage.

### Step 4: Manually examine the results

Eventually, 151 features were matched between the two data sets with cut-offs for RT and *m/z* at 1.5% and 0.015 Da. They were then subjected to manual inspection to ensure the concordance in RT and *m/z*, quality of peak shape, MS/MS pattern, and identification scores. Among 151 matched pairs: 

-	One hundred thirty-five annotated lipids in MS-DIAL ver. 4.9:
    - One hundred thirty-three pairs with identical sum acyl chain: the 6 “unsettled” lipids in ver. 4.9 have their annotation confirmed with results of ver. 5.2. Among 3 lipids with discordant results in acyl chains between two versions, 1 lipid was re-annotated its acyl chains using the ver. 5.2 results because this version provides cleaner and more confident MS/MS.
    - Two pairs with different lipid subclasses: The annotation in ver 4.9 was retained. This was because only 1 sample in MS-DIAL 5.2 was annotated to another lipid species, which led to different annotation results between the two versions. However, after careful examination of the MS/MS of all remaining samples in ver. 5.2, the annotation was in line with what was reported in ver. 4.9.

- Among 16 lipids with no annotation in ver. 4.9:
    - Fifteen of them were annotated with confidence using the results from ver. 5.2.
    - One lipid was not confidently annotated in ver. 5.2 and was eventually removed.
 
<p align="center">
  <img src="https://github.com/Pharmaco-OmicsLab/LipMetAnnotCompare/blob/main/README_Figure/Fig4_AnnotationtSummary.png" width="660"/>
</p>
 
> Overall, by incorporating the annotation results from MS-DIAL ver. 5.2, we increased the confidence in the annotation of 6 lipids, annotated 15 additional lipids, and re-annotated 1 lipid in the results of ver. 4.9.

## Contributors

- Primary developer and GitHub maintainer: Nguyen Tran Nam Tien (current), Nguyen Ky Phat
- Experimenters: Nguyen Ky Anh, Nguyen Quang Thu
- Advisor and PI: Nguyen Phuoc Long, M.D., Ph.D.

## License

This repository is licensed under the [MIT License](LICENSE).

## Citation

Nguyen Tran Nam Tien, Nguyen Ky Phat, Nguyen Quang Thu, Nguyen Ky Anh, Nguyen Phuoc Long. "LipMetAnnotCompare - A Pipeline for Verifying and Improving Lipid and Metabolite Annotations." [https://github.com/Pharmaco-Omics/LipMetAnnotCompare](https://github.com/Pharmaco-OmicsLab/LipMetAnnotCompare).


