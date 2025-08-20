# Load libraries
packages <- c("ggplot2", "readxl", "dplyr", "tidyr", "svglite")
for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
  library(pkg, character.only = TRUE)
}


# Clear environment
rm(list = ls())

# Set working directory to the project folder
setwd("./projectFolder")

# Load data
data <- read_excel("temp/MapFitsAge.xlsx")
data$sample <- factor(data$sample)

# Define loop variables
y_vars   <- c("other_fit", "self_fit", "SvO_fit")
titles   <- c("Other-RS", "Self-RS", "SvO-RS")
filenames <- c("Age_OtherRS.png", "Age_SelfRS.png", "Age_SvORS.png")

# Loop through each plot variant
for (i in seq_along(y_vars)) {
  
  plot <- ggplot(data, aes(x = ages, y = .data[[y_vars[i]]], color = sample)) +
    geom_point(size = 3) +
    geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 2, aes(group = NULL)) +
    scale_color_manual(values = c("#7df7ad", "#33b366"),
                       labels = c("Study 3", "Study 2")) +
    labs(
      title = titles[i],
      x = "Age",
      y = "Signature Fits",
      color = "Samples"
    ) +
    theme_minimal() +
    theme(
      text = element_text(family = "sans"),
      legend.position = c(.2, .865),
      legend.text = element_text(size = 12),
      panel.grid.minor = element_blank(),
      legend.title = element_text(size = 16, face = "bold"),
      plot.title = element_text(size = 20, face = "bold", hjust = 0.5, margin = margin(b = 10)),
      axis.title.y = element_text(size = 18, vjust = -1, margin = margin(r = 10, unit = "pt"), face = "bold"),
      axis.title.x = element_text(size = 18, vjust = -1, margin = margin(r = 10, unit = "pt"), face = "bold"),
      axis.text.x = element_text(size = 16, color = "black"),
      axis.text.y = element_text(size = 16, color = "black"),
      axis.line = element_line(linewidth = 0.5, color = "black")
    ) +
    scale_x_continuous(breaks = seq(11, 19, by = 1)) +
    scale_y_continuous(breaks = seq(-1, 3, by = 0.5)) +
    coord_cartesian(xlim = c(11, 19), ylim = c(-1, 3))
  
  ggsave(filename = paste0("temp/", filenames[i]),
         plot = plot,
         dpi = 280,
         bg = "white",
         device = "png",
         width = 7, height = 7)
}