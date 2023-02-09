#!/bin/bash
set -e
set -u
set -o pipefail

# Testing testing

strat_park="/Volumes/MRI/STRAT-PARK"
sn_r="$HOME/masterproject/SN_R_probatlas27_50.nii"
sn_l="$HOME/masterproject/SN_L_probatlas27_50.nii"
sn="$HOME/masterproject/SN_mask.nii.gz"
lc="$HOME/masterproject/LC_mask.nii.gz"

header=("patient_id SN-STAGE_CROWN_PD_MAP LC-STAGE_CROWN_PD_MAP SN-STAGE_CROWN_R2S LC-STAGE_CROWN_R2S SN-STAGE_CROWN_R2S_A2 LC-STAGE_CROWN_R2S_A2 SN-STAGE_CROWN_T2S LC-STAGE_CROWN_T2S SN-STAGE_CROWN_T2S_A2 LC-STAGE_CROWN_T2S_A2 SN-STAGE_CROWN_TRUE_PD_MAP LC-STAGE_CROWN_TRUE_PD_MAP SN-STAGE_CROWN_TRUE_PD_MAPa LC-STAGE_CROWN_TRUE_PD_MAPa SN-STAGE_HPF_ECHO-3_e3 LC-STAGE_HPF_ECHO-3_e3 SN-STAGE_KMAP LC-STAGE_KMAP SN-STAGE_MRA_e3 LC-STAGE_MRA_e3 SN-STAGE_PD_MAP LC-STAGE_PD_MAP SN-STAGE_R2S_MIP_e3 LC-STAGE_R2S_MIP_e3 SN-STAGE_R2S_e3 LC-STAGE_R2S_e3 SN-STAGE_SWI_ECHO-3_e3 LC-STAGE_SWI_ECHO-3_e3 SN-STAGE_SWI_mIP_ECHO-3_e3 LC-STAGE_SWI_mIP_ECHO-3_e3 SN-STAGE_T1MAP LC-STAGE_T1MAP SN-STAGE_T1WE LC-STAGE_T1WE SN-STAGE_T2S_MIP_e3 LC-STAGE_T2S_MIP_e3 SN-STAGE_T2S_e3 LC-STAGE_T2S_e3 SN-STAGE_TRUE_PD_MAP LC-STAGE_TRUE_PD_MAP SN-STAGE_dSWI_ECHO-3_e3 LC-STAGE_dSWI_ECHO-3_e3 SN-STAGE_dSWI_mIP_ECHO-3_e3 LC-STAGE_dSWI_mIP_ECHO-3_e3 SN-STAGE_meSWIM LC-STAGE_meSWIM SN-STAGE_meSWIM_HPF_ LC-STAGE_meSWIM_HPF_ SN-STAGE_meSWIM_HPF_filled LC-STAGE_meSWIM_HPF_filled SN-STAGE_meSWIM_filled LC-STAGE_meSWIM_filled SN-STAGE_meSWIM_filled_MIP LC-STAGE_meSWIM_filled_MIP SN-STAGE_mpSWIM_ECHO-3_e3 LC-STAGE_mpSWIM_ECHO-3_e3 SN-STAGE_pSWIM_ECHO-3_e3 LC-STAGE_pSWIM_ECHO-3_e3 SN-STAGE_simCSF LC-STAGE_simCSF SN-STAGE_simFLAIR LC-STAGE_simFLAIR SN-STAGE_simGM LC-STAGE_simGM SN-STAGE_simWM LC-STAGE_simWM SN-STAGE_sim_GRE LC-STAGE_sim_GRE SN-STAGE_sim_GREa LC-STAGE_sim_GREa SN-STAGE_tSWI_ECHO-3_e3 LC-STAGE_tSWI_ECHO-3_e3 SN-STAGE_tSWI_mIP_ECHO-3_e3 LC-STAGE_tSWI_mIP_ECHO-3_e3 SN-STAGE_tSWIhpf_ECHO-3_e3 LC-STAGE_tSWIhpf_ECHO-3_e3") 

echo "$header" > $HOME/masterproject/results_0702

export PATH=$PATH:/Applications/MATLAB_R2022b.app/bin

for dir in $strat_park/*
do
    for subject_dir in $dir/DICOM/*
    do
    
        patient_id=$(basename $subject_dir)
        mean=("$patient_id ")
            
        echo "Processing subject with patient_id: $patient_id"
        
        if [ ! -d "$subject_dir/results" ]
        then
            mkdir $subject_dir/results
        fi
        result_dir="$subject_dir/results"
        
        if [ ! -d "$subject_dir/results/STAGE" ]
        then
            mkdir $subject_dir/results/STAGE
        fi
        
        
        # Convert STAGE images from DICOM to NIFTI
        if [ ! -f "$result_dir/STAGE/STAGE_tSWIhpf_ECHO-3_e3.nii" ]
        then
            /Applications/MRIcroGL.app/Contents/Resources/dcm2niix -f %p -o $result_dir/STAGE $subject_dir/STAGE
        fi
        t1we="$result_dir/STAGE/STAGE_T1WE.nii"


        # Convert MPRAGE from DICOM to NIFTI
        if [ ! -f "$result_dir/t1_mprage_sag_p2_iso_PACS.nii" ]
        then
            /Applications/MRIcroGL.app/Contents/Resources/dcm2niix -f %p -o $result_dir $subject_dir/*t1_mprage_sag_p2_iso_PACS
        fi
        mprage="$result_dir/t1_mprage_sag_p2_iso_PACS.nii"


        # Register T1WE to MPRAGE
        if [ ! -f "$result_dir/t1we2mprage.mat" ]
        then
            flirt -in $t1we -ref $mprage -omat $result_dir/t1we2mprage.mat -out $result_dir/t1we_reg_mprage
        fi
        t1we_reg_mni="$result_dir/t1we_reg_mprage.nii.gz"
        

        # Register MPRAGE to MNI
        if [ ! -f "$result_dir/reg_t1_mprage_sag_p2_iso_PACS.nii" ]
        then
            matlab -nodisplay -r "reg_spm('$mprage'),exit";
        fi
        mprage_reg_mni="$result_dir/reg_t1_mprage_sag_p2_iso_PACS.nii"
        
        
        for image in $result_dir/STAGE/STAGE_*.nii
        do
            [ -f "$image" ] || break

            name=$(basename $image .nii)

            echo $name
            
            # Register STAGE images to MPRAGE
            if [ ! -f "$result_dir/${name}_reg_mprage.nii.gz" ]
            then
                flirt -in $image -ref $mprage -out $result_dir/${name}_reg_mprage -init $result_dir/t1we2mprage.mat -applyxfm
            fi
            
            # Register STAGE images to MNI
            if [ ! -f "$result_dir/STAGE/reg_${name}.nii" ]
            then
                matlab -nodisplay -r "write_job('$result_dir/y_t1_mprage_sag_p2_iso_PACS.nii','$image'),exit";
            fi
            
            
            # Make mask of SN
            if [ ! -f "$result_dir/${name}_sn.nii.gz" ]
            then
                fslmaths $result_dir/STAGE/reg_${name} -mas $sn $result_dir/${name}_sn
            fi

            # Make mask of LC
            if [ ! -f "$result_dir/${name}_lc.nii.gz" ]
            then
                fslmaths $result_dir/STAGE/reg_${name} -mas $lc $result_dir/${name}_lc
            fi

            # Mean of mask of SN
            mean+=$(fslstats $result_dir/${name}_sn.nii.gz -M)
            
            # Mean of mask of LC
            mean+=$(fslstats $result_dir/${name}_lc.nii.gz -M)
            
        done

        # Write mean to file
        echo "$mean" >> $HOME/masterproject/results_0702
        
    done
done


