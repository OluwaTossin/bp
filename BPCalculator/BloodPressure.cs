using System;
using System.ComponentModel.DataAnnotations;
using System.Diagnostics;

namespace BPCalculator
{
    // BP categories
    public enum BPCategory
    {
        [Display(Name="Low Blood Pressure")] Low,
        [Display(Name="Ideal Blood Pressure")]  Ideal,
        [Display(Name="Pre-High Blood Pressure")] PreHigh,
        [Display(Name ="High Blood Pressure")]  High
    };

    public class BloodPressure
    {
        public const int SystolicMin = 70;
        public const int SystolicMax = 190;
        public const int DiastolicMin = 40;
        public const int DiastolicMax = 100;

        [Range(SystolicMin, SystolicMax, ErrorMessage = "Invalid Systolic Value")]
        public int Systolic { get; set; }                       // mmHG

        [Range(DiastolicMin, DiastolicMax, ErrorMessage = "Invalid Diastolic Value")]
        public int Diastolic { get; set; }                      // mmHG

        // calculate BP category
        public BPCategory Category
        {
            get
            {
                // Validation: Systolic must be greater than Diastolic
                if (Systolic <= Diastolic)
                {
                    throw new ArgumentException("Systolic pressure must be greater than Diastolic pressure");
                }

                // Classification based on assignment chart
                // Low: Systolic < 90 OR Diastolic < 60
                if (Systolic < 90 || Diastolic < 60)
                {
                    return BPCategory.Low;
                }
                
                // Ideal: Systolic 90-120 AND Diastolic 60-80
                if (Systolic >= 90 && Systolic <= 120 && Diastolic >= 60 && Diastolic <= 80)
                {
                    return BPCategory.Ideal;
                }
                
                // High: Systolic > 140 OR Diastolic > 90 (check this BEFORE Pre-High)
                if (Systolic > 140 || Diastolic > 90)
                {
                    return BPCategory.High;
                }
                
                // Pre-High: Systolic 121-140 OR Diastolic 81-90
                // This catches everything between Ideal and High
                return BPCategory.PreHigh;
            }
        }
    }
}
