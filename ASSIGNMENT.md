# TU Dublin, Tallaght Campus
**School of Enterprise Computing and Digital Transformation**  
**M.Sc. in Computing in Development Operations (DevOps)**  
**2025/2026**

## Continuous Software Deployment

### CA1 Project
- **Due:** 10/12/2025
- **Value:** 70%
- **Lecturer:** Gary Clynch

---

## CI/CD Pipeline for Blood Pressure Category Calculator

### Blood Pressure Overview

Blood pressure is measured as **'systolic pressure'** over **'diastolic pressure'**, the unit of measure being **mmHg**.

**Example:** A reading of 100 / 80 indicates:
- Systolic pressure: 100
- Diastolic pressure: 80

**Valid Ranges:**
- Systolic: 70 to 190
- Diastolic: 40 to 100
- **Rule:** Systolic pressure is always higher than diastolic pressure

### Blood Pressure Categories

A blood pressure reading can be categorized as:
- Low blood pressure
- Ideal blood pressure
- Pre-high blood pressure
- High blood pressure

**Category Chart Reference:**
![Blood Pressure Chart](bloodbp.JPG)  
`C:\Users\oluwa\Desktop\projects\bp\bloodbp.JPG`

> **Note:** In the figure, consider the lower limits to be **inclusive** in the category.  
> Example: A systolic value of **140 or greater** indicates high blood pressure.

---

## Project Requirements

### Source Code
Public Git repository: https://github.com/gclynch/bp

**Task:** The code is incomplete with respect to the logic to calculate the blood pressure category.
1. Complete this code
2. Add telemetry tracking to the application

---

## CI/CD Pipeline Requirements

### CI (Continuous Integration) Requirements

1. ✅ **Unit Testing**
   - Aim for code coverage of **at least 80%**

2. ✅ **BDD Testing**
   - Include behavior-driven development type testing

3. ✅ **Code Analysis**
   - Static code analysis

4. ✅ **Security Features**
   - Check for dependencies with vulnerabilities

---

### CD (Continuous Deployment) Requirements

1. ✅ **Release Management Strategy**
   - Implement environments (e.g., QA, staging, etc.)

2. ✅ **Deployment Strategy**
   - Implement blue/green or canary deployment

3. ✅ **E2E Testing**
   - Include end-to-end testing

4. ✅ **Performance Testing**
   - Include performance testing

5. ✅ **Security Features**
   - Include penetration testing

6. ✅ **Continuous Telemetry Monitoring**
   - Implement if appropriate

7. ✅ **Authorization Gates**
   - Implement if appropriate

---

### Additional Requirements

- ✅ **Security Tasks:** Include security tasks throughout the entire CI/CD pipeline
- ✅ **Code Quality:** Address any bugs or code quality issues and refactor the code
- ✅ **New Feature:** Add one new feature with appropriate tests
  - Maximum **30 lines of code**
  - Use a branching strategy like **Git Feature Branch workflow**

---

## Deliverables

### 1. Video Demo
- **Duration:** Maximum 15 minutes
- **Content:** Demo of pipeline running / description of pipeline

### 2. Report
Describe the following:

**a. CI/CD Pipeline**
- Pipeline design and implementation
- Tests included
- Design philosophy

**b. New Feature**
- User story format
- Feature description
- Tests implemented

---

## Important Notes

- Use tools and frameworks of your choice
- Ensure all security considerations are addressed
- Document design decisions
- Provide clear evidence of pipeline execution
