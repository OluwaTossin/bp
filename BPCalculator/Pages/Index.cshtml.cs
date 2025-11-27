using System;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Logging;

// page model

namespace BPCalculator.Pages
{
    public class BloodPressureModel : PageModel
    {
        private readonly ILogger<BloodPressureModel> _logger;

        public BloodPressureModel(ILogger<BloodPressureModel> logger)
        {
            _logger = logger;
            // Set logger for BloodPressure class telemetry
            BloodPressure.SetLogger(logger);
        }
        [BindProperty]                              // bound on POST
        public BloodPressure BP { get; set; }

        // setup initial data
        public void OnGet()
        {
            _logger.LogInformation("BP Calculator page accessed");
            BP = new BloodPressure() { Systolic = 100, Diastolic = 60 };
        }

        // POST, validate
        public IActionResult OnPost()
        {
            _logger.LogInformation(
                "BP calculation requested: Systolic={Systolic}, Diastolic={Diastolic}",
                BP.Systolic, BP.Diastolic);

            // extra validation
            if (!(BP.Systolic > BP.Diastolic))
            {
                _logger.LogWarning(
                    "BP validation failed: Systolic={Systolic} not greater than Diastolic={Diastolic}",
                    BP.Systolic, BP.Diastolic);
                ModelState.AddModelError("", "Systolic must be greater than Diastolic");
            }
            else if (ModelState.IsValid)
            {
                try
                {
                    // Access Category to trigger calculation and logging
                    var category = BP.Category;
                    _logger.LogInformation(
                        "BP calculation successful: Result={Category}",
                        category.ToString());
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex,
                        "BP calculation error: Systolic={Systolic}, Diastolic={Diastolic}",
                        BP.Systolic, BP.Diastolic);
                }
            }

            return Page();
        }
    }
}