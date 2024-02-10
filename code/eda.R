# Goal: Gain some insights from the data and modelling

# Import data ----
df <- load_df(path = "data/fraud.csv", standardise = "Y", impute_NA = "Y")

# Data operations ----
df <- df %>% 
  mutate(both_fraud = past_fraud_customer*past_fraud_merchant)

# Calculate the average amount by category
avg_amount <- df %>%
  group_by(category) %>%
  summarise(Average_Amount = mean(amount, na.rm = TRUE)) %>%
  mutate(category = reorder(category, Average_Amount)) # Reorder categories based on Average_Amount

# Calculate the average amount by customer
avg_customer <- df %>%
  group_by(customer) %>%
  summarise(Average_Amount_C = mean(amount, na.rm = TRUE)) %>%
  mutate(customer = reorder(customer, Average_Amount_C))

# Calculate the average amount by merchant
avg_merchant <- df %>%
  group_by(merchant) %>%
  summarise(Average_Amount_M = mean(amount, na.rm = TRUE)) %>%
  mutate(merchant = reorder(merchant, Average_Amount_M))

# Get a smaller dataframe with only those who committed fraud
commit_fraud <- df %>% 
  filter(past_fraud_customer == 1 | past_fraud_merchant == 1) %>% 
  mutate(both_fraud = past_fraud_customer*past_fraud_merchant)

# Add binary variable indicating whether the category is a high value category
df <- df %>%
  left_join(avg_amount, by = "category") %>%
  left_join(avg_customer, by = "customer") %>%
  left_join(avg_merchant, by = "merchant") %>% 
  mutate(value_category = as.factor(ifelse(Average_Amount > 120, 1, 0)), # Big jump from value categories at this threshold
         value_customer = as.factor(ifelse(Average_Amount_C > mean(Average_Amount_C), 1, 0)), # Splitting at the average
         value_merchant = as.factor(ifelse(Average_Amount_M > mean(Average_Amount_M), 1, 0))) %>% 
  select(-Average_Amount, -Average_Amount_C, -Average_Amount_M)

# Scatter plot ----
# Calculate means
means <- df %>%
  group_by(fraud = ifelse(fraud == 1, "Yes", "No")) %>%
  summarise(mean_amount = mean(amount_standardized, na.rm = TRUE))

# Plot
scatter <- df %>%
  mutate(fraud = ifelse(fraud == 1, "Yes", "No")) %>%
  ggplot(aes(x=amount_standardized, y=fraud, color=fraud)) +
  geom_jitter(size=0.3) +
  geom_vline(data=means, aes(xintercept=mean_amount, color=fraud), linetype="dashed") +
  scale_color_manual(values=palette) +
  th +
  labs(x = "Standardised Transaction Amount*",
       y = "Fraudulent Transaction",
       caption = "Standardised by category\nDashed lines indicate average transaction amount for fraudulent and non-fraudulent transactions",
       title = "Transaction Amount and Fraud") +
  theme(legend.position = "none")


# Bar plots ----

# Create the bar plot
avgbar <- avg_amount %>%
  ggplot(aes(x = category, y = Average_Amount)) +
  geom_bar(stat = "identity", fill = "white") +
  labs(x = "", 
       y = "Average Transaction Amount", 
       title = "Average Transaction Amount by Category") +
  th +
  theme(axis.text.x = element_text(hjust = 1),
        legend.position = "none") +
  coord_flip() # Flips the x and y axes for a horizontal bar plot

bar <- df %>%
  group_by(category) %>%
  summarise(Fraud_Count = sum(as.numeric(fraud)), 
            Total_Count = n(), 
            Proportion = Fraud_Count / Total_Count) %>% 
  left_join(avg_amount, by = "category") %>%
  mutate(value_category = as.factor(ifelse(Average_Amount > 120, 1, 0))) %>%
  select(-Average_Amount) %>% 
  mutate(Category = reorder(category, Proportion), # Reorder categories based on Proportion
         Label = paste0(round(Total_Count / 1000, 1), "k")) %>% # Adjust and create a label for the number of observations, rounding to the nearest tenth
  ggplot(aes(x = Category, y = Proportion, fill = value_category)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values=c("white", "#ff87aa")) +
  geom_text(aes(label = Label, y = Proportion + 0.01), # Position labels slightly above the bars
            position = position_dodge(width = 0.9), hjust = 0, color = "white") +
  scale_y_continuous(labels = percent_format()) +
  labs(x = "", 
       y = "Proportion of Fraud Committed", 
       title = "Fraud by Category",
       caption = "Note: Number of observations for each category displayed on the right of each bar\nHigh value categories displayed in pink") +
  th +
  theme(axis.text.x = element_text(hjust = 1),
        legend.position = "none") +
  coord_flip()


# Stacked bar ----

stacked <- commit_fraud %>%
  # Create a combined factor for past fraud by customer and merchant
  mutate(past_fraud_combination = paste("Customer:", past_fraud_customer, "- Merchant:", past_fraud_merchant)) %>%
  # Group by the new combination and fraud status, then summarize
  group_by(past_fraud_combination, fraud) %>%
  summarise(count = n(), .groups = 'drop') %>%
  # Calculate the proportion of each group
  mutate(proportion = count / sum(count)) %>%
  # Adjust the fraud factor for readability
  mutate(fraud = factor(fraud, levels = c(0, 1), labels = c("No Fraud", "Fraud"))) %>%
  # Plotting directly without creating a new dataframe
  ggplot(aes(x = past_fraud_combination, y = proportion, fill = fraud)) +
  geom_bar(stat = "identity", position = "fill") +
  labs(title = "Fraudulent vs. Non-Fraudulent Transactions",
       x = "Has Committed Fraud",
       y = "",
       fill = "Transaction Type",
       caption = "'1' = Entity has committed fraud in the past, '0' = Entity has not committed fraud in the past") +
  th +
  theme(axis.text.x = element_text(hjust = 1)) +
  scale_fill_manual(values = palette) +
  coord_flip() +
  scale_y_continuous(labels = scales::percent)


# Stacked bar v2.0 ----

stacked <- df %>%
  # Create a combined factor for value_customer and value_merchant
  mutate(value_combination = paste("Customer:", value_customer, "- Merchant:", value_merchant)) %>%
  # Group by the new combination and fraud status, then summarize
  group_by(value_combination, fraud) %>%
  summarise(count = n(), .groups = 'drop') %>%
  # Calculate the proportion of each group
  mutate(proportion = count / sum(count)) %>%
  # Adjust the fraud factor for readability
  mutate(fraud = factor(fraud, levels = c(0, 1), labels = c("No Fraud", "Fraud"))) %>%
  ggplot(aes(x = value_combination, y = proportion, fill = fraud)) +
  geom_bar(stat = "identity", position = "fill") +
  labs(title = "Proportion of Fraud by Value Customer or Merchant",
       x = "Value Customer - Merchant Combination",
       y = "Proportion",
       fill = "Transaction Type",
       caption = "'1' = Entity is a value customer/merchant, '0' = Entity is not a value customer/merchant") +
  th +  # Assuming 'th' is a predefined theme
  theme(axis.text.x = element_text(hjust = 1)) +
  scale_fill_manual(values = c("No Fraud" = "white", "Fraud" = "#ff87aa")) +  # Replace with your actual color values
  coord_flip() +
  scale_y_continuous(labels = percent_format())

# Print the stacked bar plot
print(stacked)

# Bubbleplot ----
# Aggregate data to count fraud incidents by category and gender
bubble <- df %>%
  filter(fraud == 1) %>% # Focus on fraud incidents
  group_by(category, gender) %>%
  summarise(fraud_count = n(), .groups = 'drop') %>%
  ggplot(aes(x = category, y = gender, size = fraud_count, color = fraud_count)) +
  geom_point(alpha = 0.7) + # Use geom_point for bubbles, adjust alpha for transparency
  scale_size(range = c(3, 21)) + # Adjust the size range of the bubbles
  scale_color_gradient(low = "#ffe4f0", high = "#fb4271") + # Color gradient
  labs(title = "Bubble Plot of Fraud Incidents\nby Category and Gender",
       x = "Category",
       y = "",
       size = "Fraud Count", # Adjust label for size scale
       color = "Fraud Count",
       caption = "Size and colour intensity of bubbles represent fraud count") +
  th + # Assuming 'th' is your predefined custom theme
  theme(legend.position = "none") +
  coord_flip()

# Prepare data for modelling ----
# Convert character variables to factors
model_df <- df %>%
  mutate_at(vars(age, gender, category, amount_category, both_fraud), as.factor) %>% 
  select(fraud, age, gender, category, amount_standardized, value_category, value_customer, value_merchant)

# Convert fraud from factor/character to binary numeric
model_df$fraud <- as.numeric(model_df$fraud)

# Split the data into training and test sets
set.seed(123) # For reproducibility
index <- createDataPartition(model_df$fraud, p = 0.6, list = FALSE)
train_data <- model_df[index, ]
test_data <- model_df[-index, ]

# Logit model ----

# Fit the logistic regression model using the training set
l_model <- glm(fraud ~ age + category + amount_standardized:value_category, data = train_data, family = "binomial")

# Summarize the model
summary(l_model)

# Predict on test data
l_probabilities <- predict(l_model, test_data, type = "response")
l_predicted_classes <- ifelse(l_probabilities > 0.40, 1, 0)


# Logistic regression model: Results

# Confusion Matrix
l_confusion_matrix <- table(Predicted = l_predicted_classes, Actual = test_data$fraud)
print(l_confusion_matrix)


# Coefficient plot
# Create a dataframe of coefficients
coef_df <- as.data.frame(summary(l_model)$coefficients)
coef_df$predictor <- rownames(coef_df)

# Sort by the absolute value of the Estimate
coef_df$predictor <- factor(coef_df$predictor, levels = coef_df[order(coef_df$Estimate), "predictor"])

# Create a new column for significance in coef_df
coef_df$Significance <- ifelse(coef_df$`Pr(>|z|)` < 0.05, " ", "*") # Ensure there's a space instead of an empty string

# Now plot with shapes indicating the significance
coef <- ggplot(coef_df, aes(x = predictor, y = Estimate)) +
  geom_point(size = 2, aes(shape = Significance), color = "#ff87aa") + # Use shape to represent significance
  scale_shape_manual(values = c("*" = 8, " " = 16)) + # Map asterisk to a shape, 16 is a circle
  th +
  labs(x = "", y = "Coefficient Estimate") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "white") + # Add a vertical dashed line at 0
  theme(legend.position = "none") + # Hide the legend
  coord_flip()

# AUC
# Calculate ROC curve
l_roc_curve <- roc(response = test_data$fraud, predictor = l_probabilities)

# Calculate the area under the curve (AUC)
l_AUC <- auc(l_roc_curve)

# Prepare the data for ggplot
l_roc_data <- data.frame(
  TPR = l_roc_curve$sensitivities,
  FPR = 1 - l_roc_curve$specificities,
  Thresholds = l_roc_curve$thresholds
)

# Plot ROC curve with ggplot2
lroc <- ggplot(l_roc_data, aes(x = FPR, y = TPR)) +
  geom_line(color = "#ff87aa") +
  geom_abline(linetype = "dashed", color = "white") +
  labs(title = "Logit Model ROC Curve",
       x = "False Positive Rate",
       y = "True Positive Rate") +
  annotate("text", x = 0.6, y = 0.3, label = paste("AUC = ", round(l_AUC, 4)), color = "white") +
  th


# Random Forest ----
# Convert specified columns to factors for train_data
train_data <- train_data %>%
  mutate(across(c(fraud, value_category, age, value_customer, value_merchant), as.factor))

# Convert specified columns to factors for test_data
test_data <- test_data %>%
  mutate(across(c(fraud, value_category, age, value_customer, value_merchant), as.factor))

# Train the model
rf_model <- randomForest(fraud ~ age + gender + amount_standardized + value_category + value_customer + value_merchant, data = train_data, 
                              ntree = 300,  # ntree can be adjusted
                              mtry = 3, # mtry can be adjusted
                              importance = TRUE) 

print(rf_model)
varImpPlot(rf_model)
beep(4)

# Variable importance plot
# Assuming rf_model is your randomForest model object
var_imp <- importance(rf_model)

# Convert to a data frame for plotting with ggplot2
var_imp <- as.data.frame(var_imp)
var_imp$Feature = rownames(var_imp)

# Melt the data frame if you have multiple measures of importance and want to plot them together
var_imp <- melt(var_imp, id.vars = "Feature")

varimp <- var_imp %>% 
  filter(variable != 1 & variable != 0) %>% 
  mutate(variable = ifelse(variable == "MeanDecreaseAccuracy", "Mean Decrease Accuracy", "Mean Decrease Gini")) %>% 
  ggplot(aes(x = reorder(Feature, -value), y = value, color = variable, group = Feature)) +
    geom_point(size = 3) + 
    geom_segment(aes(x=reorder(Feature, -value), xend=reorder(Feature, -value), y=0, yend=value)) +
    scale_color_manual(values = palette) +
    facet_wrap(~variable, scales = "free") + # If you have multiple measures of importance and used melt
    coord_flip() +
    labs(x = "Feature", y = "Importance", title = "Variable Importance") +
    th +
    theme(legend.position = "none")

# Predict on testing data
# Generate class probabilities for the test data

# Function to find optimal threshold ----
find_optimal_threshold <- function(rf_model, test_data) {
  optimal_threshold <- 0.5
  min_average <- Inf  # Initialize with a very high number
  
  # Generate class probabilities for the test data
  rf_probabilities <- predict(rf_model, test_data, type = "prob")
  
  for (threshold in seq(0.7, 0.01, by = -0.01)) {
    # Make predictions based on the current threshold
    rf_predictions <- ifelse(rf_probabilities[,2] > threshold, 1, 0)
    
    # Create a confusion matrix with the new predictions
    rf_confusion_matrix <- table(Predicted = rf_predictions, Actual = test_data$fraud)
    
    # Calculate false negatives and false positives
    false_negatives <- rf_confusion_matrix[2,1]
    false_positives <- rf_confusion_matrix[1,2]
    
    # Calculate average of false negatives and false positives
    average_fn_fp <- (false_negatives + false_positives) / 2
    
    # Check if this is the lowest average we have found so far
    if (average_fn_fp < min_average) {
      min_average <- average_fn_fp
      optimal_threshold <- threshold
    }
  }
  
  return(optimal_threshold)
}

# Use the function to find the optimal threshold
optimal_threshold <- find_optimal_threshold(rf_model, test_data)

rf_probabilities <- predict(rf_model, test_data, type = "prob")

# Make predictions based on the optimal threshold
rf_predictions <- ifelse(rf_probabilities[,2] > optimal_threshold, 1, 0)

# Create a confusion matrix with the new predictions
rf_confusion_matrix <- table(Predicted = rf_predictions, Actual = test_data$fraud)

# Print the confusion matrix
print(rf_confusion_matrix)

# ROC
rf_probabilities <- predict(rf_model, test_data, type = "prob")[,2]
rf_roc_curve <- roc(test_data$fraud, rf_probabilities)
rf_AUC <- auc(rf_roc_curve)

# Prepare the data for ggplot
rf_roc_data <- data.frame(
  TPR = rf_roc_curve$sensitivities,
  FPR = 1 - rf_roc_curve$specificities,
  Thresholds = rf_roc_curve$thresholds
)

# Plot ROC curve with ggplot2
rfroc <- ggplot(rf_roc_data, aes(x = FPR, y = TPR)) +
  geom_line(color = "#ff87aa") +
  geom_abline(linetype = "dashed", color = "white") +
  labs(title = "RF Model ROC Curve",
       x = "False Positive Rate",
       y = "True Positive Rate") +
  annotate("text", x = 0.6, y = 0.3, label = paste0("AUC = ", round(rf_AUC,4)), color = "white") +
  th


# Additional metrics
rf_total_predictions <- sum(rf_confusion_matrix)
rf_accuracy <- sum(diag(rf_confusion_matrix)) / rf_total_predictions
rf_sensitivity <- rf_confusion_matrix[2,2] / sum(rf_confusion_matrix[2, ])
rf_specificity <- rf_confusion_matrix[1,1] / sum(rf_confusion_matrix[1, ])
rf_precision <- rf_confusion_matrix[2,2] / sum(rf_confusion_matrix[, 2])

beep(sound = 3)
