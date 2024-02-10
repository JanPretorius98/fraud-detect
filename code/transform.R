# Goal: Cleaning scripts for data and transformation into usable format

# Function to impute missing values in data
impute_missing_values <- function(data, method = "Drawn_Distribution", var, group) {
  # Ensure 'var' and 'group' columns exist in the data
  if (!var %in% names(data)) {
    stop("The specified variable column does not exist in the dataframe.")
  }
  
  # Check for missing values in the specified column
  if (!any(is.na(data[[var]]))) {
    message("No missing values in the data.")
    return(data)
  }
  
  if (!group %in% names(data)) {
    stop("The specified group column does not exist in the dataframe.")
  }
  
  if (method == "Average") {
    message("Setting NA values to group averages")
    data <- data %>%
      group_by(.data[[group]]) %>%
      mutate("{var}" := ifelse(is.na(.data[[var]]), mean(.data[[var]], na.rm = TRUE), .data[[var]])) %>%
      ungroup()
  } else if (method == "Drawn_Distribution") {
    message("Imputing NA values from distribution within groups")
    data <- data %>%
      group_by(.data[[group]]) %>%
      mutate("{var}" := ifelse(is.na(.data[[var]]), sample(na.omit(.data[[var]]), 1, replace = TRUE), .data[[var]])) %>%
      ungroup()
  } else if (method == "Zero") {
    warning("Setting NA values to 0; Consider another method")
    data[[var]] <- ifelse(is.na(data[[var]]), 0, data[[var]])
  } else {
    stop("Please provide a valid method. Options include: 'Average', 'Drawn_Distribution', and 'Zero'.")
  }
  
  return(data)
}

# Function to standardise variables
standardise <- function(data, var) {
  # Check if the column exists in the dataframe
  if (!var %in% names(data)) {
    stop("The specified column does not exist in the dataframe.")
  }
  
  # Calculate the mean and standard deviation of the specified column
  column_mean <- mean(data[[var]], na.rm = TRUE)
  column_sd <- sd(data[[var]], na.rm = TRUE)
  
  # Standardize the specified column
  data[[paste0(var, "_standardized")]] <- (data[[var]] - column_mean) / column_sd
  
  # Return the modified dataframe
  message("Numeric columns standardised.")
  return(data)
}


# Import data - use a functional paradigm
load_df <- function(path, standardise = "Y", impute_NA = "Y") {
  
  df <- read.csv(path)
  
# Standardise tables
  
  # Remove `'` characters
  df <- data.frame(lapply(df, function(x) gsub("'", "", x)))
  
  # Remove unknown genders
  df <- df %>% 
    filter(gender != "E" & gender != "U") %>% 
    mutate(gender = ifelse(gender == "F", "Female", "Male"))
  
  # Select necessary columns
  df <- df %>% 
    select(-c(zipcodeOri, zipMerchant))
  
  # Format numeric columns
  df$amount <- as.numeric(df$amount)
  
  
  # Check for missing values in `amount`
  if (impute_NA == "Y") {
    df <- impute_missing_values(data = df, method = "Drawn_Distribution", var = "amount", group = "category")
  } else {
    warning("Did not check for NA values")
  }
 
  # Standardise `amount`
  if (standardise == "Y") {
    df <- standardise(df, "amount")
  } else {
    warning("Numeric columns not standardised")
  }
  
  # Split amount into categories
  df <- df %>%
    mutate(amount_category = cut(amount_standardized,
                                 breaks = 8, # Specifies the number of categories
                                 labels = c("1", "2", "3", "4",
                                            "5", "6", "7", "8"),
                                 include.lowest = TRUE)) # Ensures the lowest value is included in the first interval
  
  # Create a list of unique customers and merchants involved in fraud
  customers_with_fraud <- df %>% filter(fraud == 1) %>% select(customer) %>% distinct() %>% pull(customer)
  merchants_with_fraud <- df %>% filter(fraud == 1) %>% select(merchant) %>% distinct() %>% pull(merchant)
  
  # Assign past_fraud = 1 for rows where the customer or merchant has had fraud in the past
  df <- df %>%
    mutate(past_fraud_customer = ifelse(customer %in% customers_with_fraud, 1, 0),
           past_fraud_merchant = ifelse(merchant %in% merchants_with_fraud, 1, 0),
           past_fraud = ifelse(past_fraud_customer == 1 | past_fraud_merchant == 1, 1, 0))
  
  # Get nicer worded labels for plotting
  better_category_names <- c(
    "es_contents" = "Contents",
    "es_food" = "Food",
    "es_transportation" = "Transportation",
    "es_fashion" = "Fashion",
    "es_barsandrestaurants" = "Bars and Restaurants",
    "es_hyper" = "Hypermarkets",
    "es_wellnessandbeauty" = "Wellness and Beauty",
    "es_tech" = "Tech",
    "es_health" = "Health",
    "es_home" = "Home",
    "es_otherservices" = "Other Services",
    "es_hotelservices" = "Hotel Services",
    "es_sportsandtoys" = "Sports and Toys",
    "es_travel" = "Travel",
    "es_leisure" = "Leisure"
  )
  
  df <- df %>%
    mutate(category = factor(category), # Ensure category is a factor
           category = better_category_names[as.character(category)]) # Map to better names
  
  return(df)
}
