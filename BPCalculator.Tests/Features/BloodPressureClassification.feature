Feature: Blood Pressure Classification
    As a healthcare professional
    I want to calculate blood pressure categories
    So that I can assess patient health and provide appropriate guidance

Background:
    Given I have a blood pressure calculator

Scenario: Low blood pressure with low systolic
    Given systolic pressure is 85
    And diastolic pressure is 55
    When I calculate the blood pressure category
    Then the result should be "Low"

Scenario: Low blood pressure with low diastolic
    Given systolic pressure is 100
    And diastolic pressure is 55
    When I calculate the blood pressure category
    Then the result should be "Low"

Scenario: Ideal blood pressure
    Given systolic pressure is 115
    And diastolic pressure is 75
    When I calculate the blood pressure category
    Then the result should be "Ideal"

Scenario: Ideal blood pressure at lower boundary
    Given systolic pressure is 90
    And diastolic pressure is 60
    When I calculate the blood pressure category
    Then the result should be "Ideal"

Scenario: Ideal blood pressure at upper boundary
    Given systolic pressure is 120
    And diastolic pressure is 80
    When I calculate the blood pressure category
    Then the result should be "Ideal"

Scenario: Pre-High blood pressure with elevated systolic
    Given systolic pressure is 130
    And diastolic pressure is 75
    When I calculate the blood pressure category
    Then the result should be "Pre-High"

Scenario: Pre-High blood pressure with elevated diastolic
    Given systolic pressure is 115
    And diastolic pressure is 85
    When I calculate the blood pressure category
    Then the result should be "Pre-High"

Scenario: Pre-High blood pressure at upper boundary
    Given systolic pressure is 140
    And diastolic pressure is 90
    When I calculate the blood pressure category
    Then the result should be "Pre-High"

Scenario: High blood pressure with high systolic
    Given systolic pressure is 150
    And diastolic pressure is 75
    When I calculate the blood pressure category
    Then the result should be "High"

Scenario: High blood pressure with high diastolic
    Given systolic pressure is 115
    And diastolic pressure is 95
    When I calculate the blood pressure category
    Then the result should be "High"

Scenario: High blood pressure with both values high
    Given systolic pressure is 150
    And diastolic pressure is 95
    When I calculate the blood pressure category
    Then the result should be "High"

Scenario: Extremely low blood pressure
    Given systolic pressure is 70
    And diastolic pressure is 40
    When I calculate the blood pressure category
    Then the result should be "Low"

Scenario: Extremely high blood pressure
    Given systolic pressure is 190
    And diastolic pressure is 100
    When I calculate the blood pressure category
    Then the result should be "High"

Scenario Outline: Various blood pressure readings
    Given systolic pressure is <systolic>
    And diastolic pressure is <diastolic>
    When I calculate the blood pressure category
    Then the result should be "<category>"

    Examples:
    | systolic | diastolic | category  |
    | 85       | 55        | Low       |
    | 90       | 60        | Ideal     |
    | 110      | 70        | Ideal     |
    | 120      | 80        | Ideal     |
    | 121      | 75        | Pre-High  |
    | 130      | 85        | Pre-High  |
    | 140      | 90        | Pre-High  |
    | 141      | 85        | High      |
    | 150      | 95        | High      |
    | 180      | 100       | High      |

Scenario: Invalid input - systolic equals diastolic
    Given systolic pressure is 100
    And diastolic pressure is 100
    When I attempt to calculate the blood pressure category
    Then an error should occur indicating invalid relationship

Scenario: Invalid input - systolic less than diastolic
    Given systolic pressure is 80
    And diastolic pressure is 90
    When I attempt to calculate the blood pressure category
    Then an error should occur indicating invalid relationship

Scenario: Ideal blood pressure with explanation text
    Given systolic pressure is 115
    And diastolic pressure is 75
    When I calculate the blood pressure category
    Then the result should be "Ideal"
    And the explanation should contain "ideal and healthy"

Scenario: High blood pressure with explanation text
    Given systolic pressure is 150
    And diastolic pressure is 95
    When I calculate the blood pressure category
    Then the result should be "High"
    And the explanation should contain "consult a healthcare provider"
