using System;
using Xunit;

namespace BPCalculator.Tests
{
    public class BloodPressureTests
    {
        #region Category Tests - Low Blood Pressure

        [Fact]
        public void Category_LowSystolic_ReturnsLow()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 85, Diastolic = 55 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.Low, category);
        }

        [Fact]
        public void Category_LowDiastolic_ReturnsLow()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 100, Diastolic = 55 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.Low, category);
        }

        [Fact]
        public void Category_BothLow_ReturnsLow()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 85, Diastolic = 55 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.Low, category);
        }

        #endregion

        #region Category Tests - Ideal Blood Pressure

        [Fact]
        public void Category_IdealValues_ReturnsIdeal()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 115, Diastolic = 75 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.Ideal, category);
        }

        [Fact]
        public void Category_IdealLowerBound_ReturnsIdeal()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 90, Diastolic = 60 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.Ideal, category);
        }

        [Fact]
        public void Category_IdealUpperBound_ReturnsIdeal()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 120, Diastolic = 80 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.Ideal, category);
        }

        #endregion

        #region Category Tests - Pre-High Blood Pressure

        [Fact]
        public void Category_PreHighSystolic_ReturnsPreHigh()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 130, Diastolic = 75 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.PreHigh, category);
        }

        [Fact]
        public void Category_PreHighDiastolic_ReturnsPreHigh()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 115, Diastolic = 85 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.PreHigh, category);
        }

        [Fact]
        public void Category_PreHighBoth_ReturnsPreHigh()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 130, Diastolic = 85 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.PreHigh, category);
        }

        #endregion

        #region Category Tests - High Blood Pressure

        [Fact]
        public void Category_HighSystolic_ReturnsHigh()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 150, Diastolic = 75 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.High, category);
        }

        [Fact]
        public void Category_HighDiastolic_ReturnsHigh()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 115, Diastolic = 95 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.High, category);
        }

        [Fact]
        public void Category_BothHigh_ReturnsHigh()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 150, Diastolic = 95 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.High, category);
        }

        #endregion

        #region Boundary Value Tests

        [Fact]
        public void Category_Systolic89Diastolic60_ReturnsLow()
        {
            // Test Low/Ideal boundary (Systolic)
            var bp = new BloodPressure { Systolic = 89, Diastolic = 60 };
            Assert.Equal(BPCategory.Low, bp.Category);
        }

        [Fact]
        public void Category_Systolic90Diastolic59_ReturnsLow()
        {
            // Test Low/Ideal boundary (Diastolic)
            var bp = new BloodPressure { Systolic = 90, Diastolic = 59 };
            Assert.Equal(BPCategory.Low, bp.Category);
        }

        [Fact]
        public void Category_Systolic121Diastolic80_ReturnsPreHigh()
        {
            // Test Ideal/PreHigh boundary (Systolic)
            var bp = new BloodPressure { Systolic = 121, Diastolic = 80 };
            Assert.Equal(BPCategory.PreHigh, bp.Category);
        }

        [Fact]
        public void Category_Systolic120Diastolic81_ReturnsPreHigh()
        {
            // Test Ideal/PreHigh boundary (Diastolic)
            var bp = new BloodPressure { Systolic = 120, Diastolic = 81 };
            Assert.Equal(BPCategory.PreHigh, bp.Category);
        }

        [Fact]
        public void Category_Systolic140Diastolic90_ReturnsPreHigh()
        {
            // Test PreHigh upper boundary
            var bp = new BloodPressure { Systolic = 140, Diastolic = 90 };
            Assert.Equal(BPCategory.PreHigh, bp.Category);
        }

        [Fact]
        public void Category_Systolic141Diastolic90_ReturnsHigh()
        {
            // Test PreHigh/High boundary (Systolic)
            var bp = new BloodPressure { Systolic = 141, Diastolic = 90 };
            Assert.Equal(BPCategory.High, bp.Category);
        }

        [Fact]
        public void Category_Systolic140Diastolic91_ReturnsHigh()
        {
            // Test PreHigh/High boundary (Diastolic)
            var bp = new BloodPressure { Systolic = 140, Diastolic = 91 };
            Assert.Equal(BPCategory.High, bp.Category);
        }

        #endregion

        #region Invalid Input Tests

        [Fact]
        public void Category_SystolicEqualsDiastolic_ThrowsArgumentException()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 100, Diastolic = 100 };

            // Act & Assert
            Assert.Throws<ArgumentException>(() => bp.Category);
        }

        [Fact]
        public void Category_SystolicLessThanDiastolic_ThrowsArgumentException()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 80, Diastolic = 90 };

            // Act & Assert
            Assert.Throws<ArgumentException>(() => bp.Category);
        }

        #endregion

        #region Validation Attribute Tests

        [Fact]
        public void Systolic_WithinRange_IsValid()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 120, Diastolic = 80 };

            // Act & Assert - No exception should be thrown
            Assert.InRange(bp.Systolic, BloodPressure.SystolicMin, BloodPressure.SystolicMax);
        }

        [Fact]
        public void Diastolic_WithinRange_IsValid()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 120, Diastolic = 80 };

            // Act & Assert - No exception should be thrown
            Assert.InRange(bp.Diastolic, BloodPressure.DiastolicMin, BloodPressure.DiastolicMax);
        }

        [Fact]
        public void Systolic_MinValue_IsValid()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 70, Diastolic = 50 };

            // Act & Assert
            Assert.Equal(70, bp.Systolic);
            Assert.Equal(BPCategory.Low, bp.Category);
        }

        [Fact]
        public void Systolic_MaxValue_IsValid()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 190, Diastolic = 100 };

            // Act & Assert
            Assert.Equal(190, bp.Systolic);
            Assert.Equal(BPCategory.High, bp.Category);
        }

        [Fact]
        public void Diastolic_MinValue_IsValid()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 100, Diastolic = 40 };

            // Act & Assert
            Assert.Equal(40, bp.Diastolic);
            Assert.Equal(BPCategory.Low, bp.Category);
        }

        [Fact]
        public void Diastolic_MaxValue_IsValid()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 150, Diastolic = 100 };

            // Act & Assert
            Assert.Equal(100, bp.Diastolic);
            Assert.Equal(BPCategory.High, bp.Category);
        }

        #endregion

        #region Additional Edge Cases

        [Fact]
        public void Category_ExtremelyLow_ReturnsLow()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 70, Diastolic = 40 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.Low, category);
        }

        [Fact]
        public void Category_ExtremelyHigh_ReturnsHigh()
        {
            // Arrange
            var bp = new BloodPressure { Systolic = 190, Diastolic = 100 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.High, category);
        }

        [Fact]
        public void Category_JustAboveIdeal_ReturnsPreHigh()
        {
            // Arrange - Testing the transition from Ideal to PreHigh
            var bp = new BloodPressure { Systolic = 121, Diastolic = 75 };

            // Act
            var category = bp.Category;

            // Assert
            Assert.Equal(BPCategory.PreHigh, category);
        }

        #endregion
    }
}
