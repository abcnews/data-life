# These functions assume the correct data all exists in the global environment


abc_theme <- theme_minimal() +
  theme(
    text=element_text(family="ABCSans"),
    strip.text=element_text(hjust=0)
  )

plot_requests_histogram <- function(requests=NA, binwidth=900) {
  if (is.na(requests)) {
    requests <- get_requests_common()
  }
  requests %>% 
    select(timestamp, device) %>%
    ggplot(aes(timestamp)) + 
    abc_theme +
    labs(
      x="",
      y=""
    ) +
    geom_histogram(binwidth=binwidth, boundary=start,fill="#01CFFF")
}

