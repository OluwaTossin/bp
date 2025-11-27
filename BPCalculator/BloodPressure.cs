using System;
using System.ComponentModel.DataAnnotations;
using System.Diagnostics;
using Microsoft.Extensions.Logging;

namespace BPCalculator
{
    // BP categories
    public enum BPCategory
    {
        [Display(Name = "Low Blood Pressure")] Low,
        [Display(Name = "Ideal Blood Pressure")] Ideal,
        [Display(Name = "Pre-High Blood Pressure")] PreHigh,
        [Display(Name = "High Blood Pressure")] High
    };

    public class BloodPressure
    {
        public const int SystolicMin = 70;
        public const int SystolicMax = 190;
        public const int DiastolicMin = 40;
        public const int DiastolicMax = 100;

        // Logger for telemetry (will be injected where needed)
        private static ILogger _logger;

        [Range(SystolicMin, SystolicMax, ErrorMessage = "Invalid Systolic Value")]
        public int Systolic { get; set; }                       // mmHG

        [Range(DiastolicMin, DiastolicMax, ErrorMessage = "Invalid Diastolic Value")]
        public int Diastolic { get; set; }                      // mmHG

        // Static method to set logger
        public static void SetLogger(ILogger logger)
        {
            _logger = logger;
        }

        // calculate BP category
        public BPCategory Category
        {
            get
            {
                // Validation: Systolic must be greater than Diastolic
                if (Systolic <= Diastolic)
                {
                    _logger?.LogWarning(
                        "Invalid BP calculation attempt: Systolic={Systolic} <= Diastolic={Diastolic}",
                        Systolic, Diastolic);
                    throw new ArgumentException("Systolic pressure must be greater than Diastolic pressure");
                }

                BPCategory result;

                // Classification based on assignment chart
                // Low: Systolic < 90 OR Diastolic < 60
                if (Systolic < 90 || Diastolic < 60)
                {
                    result = BPCategory.Low;
                }
                // Ideal: Systolic 90-120 AND Diastolic 60-80
                else if (Systolic >= 90 && Systolic <= 120 && Diastolic >= 60 && Diastolic <= 80)
                {
                    result = BPCategory.Ideal;
                }
                // High: Systolic > 140 OR Diastolic > 90 (check this BEFORE Pre-High)
                else if (Systolic > 140 || Diastolic > 90)
                {
                    result = BPCategory.High;
                }
                // Pre-High: Systolic 121-140 OR Diastolic 81-90
                // This catches everything between Ideal and High
                else
                {
                    result = BPCategory.PreHigh;
                }

                // Log BP calculation with structured data
                _logger?.LogInformation(
                    "BP calculation: Systolic={Systolic}, Diastolic={Diastolic}, Category={Category}",
                    Systolic, Diastolic, result.ToString());

                return result;
            }
        }

        // Get explanation text for BP category (NEW FEATURE - Phase 6)
        public static string GetCategoryExplanation(BPCategory category)
        {
            return category switch
            {
                BPCategory.Low => "Your blood pressure is low. If you experience dizziness, weakness, or fatigue, consult a healthcare provider.",
                BPCategory.Ideal => "Your blood pressure is ideal and healthy. Maintain your lifestyle with regular exercise and a balanced diet.",
                BPCategory.PreHigh => "Your blood pressure is pre-high (prehypertension). Consider lifestyle changes: reduce salt, exercise regularly, manage stress.",
                BPCategory.High => "Your blood pressure is high. Consult a healthcare provider for evaluation and treatment. Monitor regularly.",
                _ => "Unable to determine category. Please ensure valid input values."
            };
        }
    }
}
