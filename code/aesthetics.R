# Goal: Standardised plot aesthetics

# Define plot theme
th <- theme(
  # Background and grid
  panel.background = element_blank(),
  plot.background = element_rect(fill = "#0B6F5D", color = "#0B6F5D"),
  panel.grid.major = element_blank(),
  panel.grid.minor = element_blank(),
  axis.line = element_line(size = 0.3, color = "white"),
  
  # Axis titles and labels
  axis.title.x = element_text(size = 12, family = "Helvetica", hjust = 0.5, face = "bold", color = "white"),
  axis.title.y = element_text(size = 12, family = "Helvetica", hjust = 0.5, face = "bold", color = "white"),
  axis.text.y = element_text(size = 10, family = "Helvetica", color = "white"),
  axis.text.x = element_text(size = 10, family = "Helvetica", color = "white"),
  
  # Title, subtitle, and caption
  plot.title = element_text(size = 14, family = "Helvetica", face = "bold", hjust = 0.5, color = "white"),
  plot.subtitle = element_text(size = 12, family = "Helvetica", color = "white"),
  plot.caption = element_text(size = 10, family = "Helvetica", hjust = 1, color = "white"),
  
  # Legend
  legend.position = "bottom",
  legend.text = element_text(size = 12, family = "Helvetica", color = "white"),
  legend.title = element_text(size = 12, family = "Helvetica", face = "bold", color = "white"),
  legend.key = element_blank(),
  legend.background = element_blank(),
  
  # Other
  axis.ticks = element_blank(),
  strip.text = element_text(size = 12, family = "Helvetica", vjust = 1, hjust = 0.5, face = "bold", color = "white"),
  strip.background = element_blank(),
  
  # Global text color
  text = element_text(color = "white", family = "Helvetica")  # Sets global text color to white
)


palette <- c("white", "#ff87aa", "white", "white", "white")
scale <- c("#fb4271","#fe5c85","#ff7298","#ff87aa","#ff9bba","#ffaeca","#ffc0d8","#ffd2e5","#ffe4f0")
