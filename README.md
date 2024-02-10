# Fraud Detection by Using Random Forest Classifier
Take-home assessment for Elucidate.

You can find the supplementary presentation [here](final_presentation.pptx).

The main markdown file compiling the results can be found [here](Presentation.Rmd).

## Notes

- **The whole project was completed in R and makes use of the following libraries:**
  - `dplyr`
  - `tidyverse`
  - `ggplot2`
  - `scales`
  - `GGall`
  - `caret`
  - `ModelMetrics`
  -  `pROC`
  - `randomForest`
  - `beepr`
  - `xgboost`
  - `reshape2`
- Zip codes contain no information – all zip codes are 28007 (drop this column)
- Removed unknown values from `age` and `gender`.
- Standardised transaction amount by category to make more meaningful comparisons

----

## Table of Contents
- [Utility Scripts](#utility-scripts)
- [Model Specification](#model-specification)
- [Data Operations](#data-operations)
- [Functions Overview](#functions-overview)
- [Next Steps](#next-steps)
- [Authors](#authors)

---

## Utility Scripts

### `aesthetics.R`

- Defines plot themes and colour palettes for consistent aesthetics

### `eda.R`

- Exploratory data analysis script.
- See [Data Operations](#data-operations) for more information.
- Contains code for the creation of all plot objects and modelling scripts.

### `transform.R`

- Main data transformations script.
- See [Functions Overview](#functions-overview) for more information.
- Transforms data into clean and more user friendly format.

---

## Model Specification

The modeling process in this project involves setting up, training, and evaluating two distinct types of predictive models: Logistic Regression and Random Forest. The Random Forest is the main model of the report, but the Logistic model served as an initial starting point to scrutinise variables and their contributions to the prediction.

Here's a structured overview of the model setup:

### Random Forest Model:

| Aspect                          | Description                                                  |
| ------------------------------- | ------------------------------------------------------------ |
| Feature Conversion              | Converts key features into factors to capture categorical nature within training and testing sets. |
| Model Configuration             | Trains using age, gender, amount_standardized, value_category, value_customer, and value_merchant as predictors. |
| Variable Importance             | Analyzes importance of each feature post-training.           |
| Optimal Threshold Determination | Uses `find_optimal_threshold` function to find the balance between false negatives and positives. |

### Logistic Regression Model:

| Aspect               | Description                                                  |
| -------------------- | ------------------------------------------------------------ |
| Feature Selection    | Includes age, category, and interaction between amount_standardized and value_category as predictors. |
| Model Training       | Uses glm function with a binomial family to fit the model on the training data. |
| Threshold Adjustment | Predictions on test data with a probability threshold of 0.40 to classify transactions. |

### Model Evaluation:

| Metric              | Description                                                  |
| ------------------- | ------------------------------------------------------------ |
| Confusion Matrix    | Generated for each model to evaluate performance based on the optimal threshold identified. |
| ROC Curve Analysis  | Plots ROC curves and calculates AUC to assess differentiation between fraudulent and non-fraudulent transactions (not included in the presentation). |
| Performance Metrics | Calculates accuracy, sensitivity, specificity, and precision. |

-----

## Data Operations

This `eda.R` script is a comprehensive workflow for processing, analyzing, and modeling a dataset for fraud detection. Let's break down the operations carried out on the main dataframe `df` and the setup for training and testing data:

### Data Importing and Initial Processing:
- **load_df**: A custom function is invoked to load the dataset from a CSV file, with options to standardize numeric columns and impute missing values.
- **Data Cleaning**: The loaded `df` undergoes further cleaning to remove unwanted characters and filter out unknown gender values, converting them to a more readable format.

### Feature Engineering and Descriptive Statistics:
- **both_fraud**: A new binary feature is created to indicate transactions involving customers and merchants with a history of fraud.
- **Average Calculations**: The script calculates the average transaction amount by category, customer, and merchant, which may be used later to identify patterns or anomalies in the data.

### Data Augmentation and Categorization:
- **High Value Flags**: `df` is augmented with binary indicators that flag high-value categories, customers, and merchants based on their average transaction amounts, providing additional layers for analysis.

### Preparing Data for Modeling:
- Categorical variables within `df` are converted to factors, setting the stage for the subsequent model training.
- The data is then split into training and testing sets, ensuring a randomized and representative selection for model evaluation.

----

## Functions Overview

----

## Functions from [`transform.R`](code/transform.R)

### `impute_missing_values()`

**Purpose:** This function is designed to address missing values in a dataset, which is a common issue in data preparation. The imputation method can be tailored based on the needs of the analysis.

**Parameters:**

- `data`: The dataframe that contains the data.
- `method`: The method of imputation to use. Options include averaging within a group, drawing from a distribution within a group, or setting missing values to zero.
- `var`: The variable (column) in which to impute missing values.
- `group`: The group by which the imputation should be stratified.

**Intuition:**
- By imputing missing values, we can prevent the loss of data rows that could be critical for analysis.
- Group-based imputation allows for more accurate and representative value assignments compared to global methods, as it respects the inherent structure within the data.

### `standardise()`

**Purpose:** This function standardizes numerical variables, which is a common preprocessing step to normalize data for models that assume data is centered around zero with a standard deviation of one.

**Parameters:**
- `data`: The dataframe containing the data.
- `var`: The variable to be standardized.

**Intuition:**
- Standardization helps in comparing coefficients of variables that are on different scales and is crucial for algorithms that are sensitive to the scale of data, such as k-NN, SVM, and neural networks.

### `load_df()`

**Purpose:** A comprehensive function to load, clean, and prepare the dataset for analysis. It includes steps to standardize the data, impute missing values, and create additional informative variables.

**Parameters:**

- `path`: The file path to the dataset.
- `standardise`: A flag to indicate if the numeric columns should be standardized.
- `impute_NA`: A flag to indicate if missing values should be imputed.

**Intuition:**
- The function encapsulates the entire data cleaning workflow, ensuring that the raw data is converted into a format that is suitable for analysis.
- Removing specific characters and filtering out unknown gender categories help to maintain data quality and consistency.
- The inclusion of categorical splitting and past fraud indicators enriches the dataset, providing more angles for insightful analysis.

---

## Functions from [`eda.R`](code/eda.R)

### `find_optimal_threshold()`

**Purpose:**
This function aims to find the optimal threshold for classifying fraud in a dataset by minimizing the average number of false negatives and false positives. It's a critical step to balance the trade-off between catching as many fraudulent transactions as possible (true positives) and not misclassifying legitimate transactions as fraud (false positives).

**Parameters:**

- `rf_model`: The trained Random Forest model object.
- `test_data`: The test dataset on which the model will make predictions.

**Intuition:**
- The function iterates over a range of threshold values from 0.7 to 0.01, decrementing by 0.01 with each iteration. For each threshold, it:
  - Predicts fraud using the current threshold value.
  - Constructs a confusion matrix based on these predictions.
  - Calculates the number of false negatives (fraudulent transactions predicted as non-fraudulent) and false positives (non-fraudulent transactions predicted as fraudulent).
  - Determines the average of false negatives and false positives for that threshold.
- If the calculated average is lower than what has been observed in previous iterations (stored in `min_average`), it updates `min_average` and sets the `optimal_threshold` to the current threshold value.
- After evaluating all thresholds, it returns the threshold that resulted in the lowest average of false negatives and false positives, thus providing a balanced approach to fraud detection.

**Use Case:**
This function is especially useful when the cost of false negatives (missed fraud) and false positives (legitimate transactions incorrectly flagged as fraudulent) needs to be balanced. It's a fine-tuning step that follows model training to ensure that the model's predictions align well with business objectives and risk management strategies.

----

## Next Steps

### Questions for the bank

1. **Customer Segmentation and Product Usage:**
   - Can you provide insights into the criteria used for customer segmentation within the bank? How are products and services tailored to different segments?

2. **Account and Transaction Types:**
   - Could you explain the range of account types (e.g., savings, checking, loans) and transaction categories (e.g., deposits, withdrawals, transfers) included in the data? How do these account and transaction types relate to the bank's primary revenue streams?

3. **Geographical Influence:**
   - How does the bank's geographical presence affect account distribution and transaction volumes? Are there specific regions that show higher engagement or product uptake?

4. **Customer Retention and Churn Analysis:**
   - What methods are currently employed to track customer retention and churn? Are there identifiable patterns or characteristics of customers who close their accounts or reduce activity?

5. **Digital Banking Trends:**
   - How has the adoption of digital banking services impacted traditional banking operations in terms of account management and transaction processing? Can you identify trends in the data that reflect shifts towards digital platforms?

6. **Fraud Detection and Security Measures:**
   - What types of fraudulent activities are most common, and how are they represented in the data? What preventive measures are in place to detect and mitigate these activities?

7. **Financial Health Indicators:**
   - How does the bank assess the financial health of its customers? Are there specific indicators (e.g., account balance trends, loan repayment behaviors) that are particularly telling?

8. **Product and Service Feedback Loop:**
   - Is there a mechanism in place for collecting and analyzing customer feedback on the bank's products and services? How is this feedback reflected in the dataset?

9. **Regulatory Compliance and Impact:**
   - How do regulatory requirements impact the bank's data management and reporting practices? Are there specific compliance challenges that influence how data is collected or utilized?

### Short-Term Next Steps:

1. **Model Refinement**:
   - Revisit feature selection to include more relevant variables.
   - Optimize hyperparameters for the Random Forest model using cross-validation.

2. **Data Enrichment**:
   - Integrate additional datasets to provide more context for transactions, such as time-series data.
   - Add geospatial data – the zip codes included were unfortunately not helpful.
   - Explore the creation of new features that could capture complex patterns in the data.
   
3. **Model Evaluation**:
   - Conduct thorough error analysis to understand the types of fraud cases that are being missed.
   - Implement model interpretability tools like SHAP values to gain insights into model decisions.

4. **Threshold Tuning**:
   - Apply cost-benefit analysis to refine the fraud detection threshold based on the business impact of false positives and false negatives.
   
   

### Medium-Term Enhancements:

1. **Ensemble Methods**:
   - Combine multiple models through ensemble techniques to improve prediction accuracy.
   - Explore advanced models like Gradient Boosting Machines or Neural Networks.

2. **Deployment Strategy**:
   - Develop a deployment plan for integrating the model into the existing transaction processing system.
   - Set up a monitoring system to track the model's performance over time.

3. **User Feedback Loop**:
   - Implement a system for collecting feedback from the fraud investigation team to continuously improve the model.

4. **Regulatory Compliance**:
   - Ensure that the model complies with all relevant financial regulations and privacy laws.
   
   

### Long-Term Strategic Goals:

1. **Continuous Learning**:
   - Establish a mechanism for the model to learn from new data in real-time or near-real-time.
   - Investigate adaptive learning to allow the model to adjust to emerging fraud tactics.

2. **Customer Experience**:
   - Minimise customer friction by reducing false positives without compromising fraud detection.
   - Develop personalised risk scores for customers to tailor the user experience.

3. **Expansion to New Markets**:
   - Adapt the model for scalability and apply it to new market segments or geographies.

4. **Innovation**:
   - Stay abreast of technological advancements in AI and machine learning for fraud detection.
   - Explore partnerships with fintech companies to leverage new technologies and data sources.

----

## Authors

- Jan-Hendrik Pretorius (MCom Economics, SU)
