using System;
using TechTalk.SpecFlow;
using Xunit;

namespace BPCalculator.Tests.Features
{
    [Binding]
    public class BloodPressureClassificationSteps
    {
        private BloodPressure? _bloodPressure;
        private BPCategory _result;
        private Exception? _exception;

        [Given(@"I have a blood pressure calculator")]
        public void GivenIHaveABloodPressureCalculator()
        {
            // Context setup - calculator is ready
            _bloodPressure = new BloodPressure();
            _exception = null;
        }

        [Given(@"systolic pressure is (.*)")]
        public void GivenSystolicPressureIs(int systolic)
        {
            if (_bloodPressure == null)
            {
                _bloodPressure = new BloodPressure();
            }
            _bloodPressure.Systolic = systolic;
        }

        [Given(@"diastolic pressure is (.*)")]
        public void GivenDiastolicPressureIs(int diastolic)
        {
            if (_bloodPressure == null)
            {
                _bloodPressure = new BloodPressure();
            }
            _bloodPressure.Diastolic = diastolic;
        }

        [When(@"I calculate the blood pressure category")]
        public void WhenICalculateTheBloodPressureCategory()
        {
            if (_bloodPressure == null)
            {
                throw new InvalidOperationException("Blood pressure object not initialized");
            }

            try
            {
                _result = _bloodPressure.Category;
            }
            catch (Exception ex)
            {
                _exception = ex;
                throw; // Re-throw for scenarios expecting success
            }
        }

        [When(@"I attempt to calculate the blood pressure category")]
        public void WhenIAttemptToCalculateTheBloodPressureCategory()
        {
            if (_bloodPressure == null)
            {
                throw new InvalidOperationException("Blood pressure object not initialized");
            }

            try
            {
                _result = _bloodPressure.Category;
            }
            catch (Exception ex)
            {
                _exception = ex;
            }
        }

        [Then(@"the result should be ""(.*)""")]
        public void ThenTheResultShouldBe(string expectedCategory)
        {
            // Map string to enum
            BPCategory expected = expectedCategory switch
            {
                "Low" => BPCategory.Low,
                "Ideal" => BPCategory.Ideal,
                "Pre-High" => BPCategory.PreHigh,
                "High" => BPCategory.High,
                _ => throw new ArgumentException($"Unknown category: {expectedCategory}")
            };

            Assert.Equal(expected, _result);
        }

        [Then(@"an error should occur indicating invalid relationship")]
        public void ThenAnErrorShouldOccurIndicatingInvalidRelationship()
        {
            Assert.NotNull(_exception);
            Assert.IsType<ArgumentException>(_exception);
            Assert.Contains("Systolic pressure must be greater than Diastolic pressure", 
                _exception.Message);
        }
    }
}
