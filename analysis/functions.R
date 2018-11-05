
# Import a json dump file
import_dump <- function(filename) {
  filename %>% 
    file %>% 
    stream_in(flatten=T) %>% 
    as_tibble() %>%
    mutate(request.timestamp_start = as_datetime(request.timestamp_start/1000, tz="Australia/Brisbane"), request.timestamp_end = as_datetime(request.timestamp_end/1000, tz="Australia/Brisbane"))
}

# Make a date time object with the Brisbane timezone.
bne_date_time <- function(data) {
  as_datetime(data/1000, tz="Australia/Brisbane")
}

# Read the log files
read_log <- function(file) {
  read_fwf(here::here('proxydata','increment1',file), fwf_widths(c(30, NA))) %>% filter(str_detect(X2, "TLS passthrough")) %>% bind_cols(list(str_extract(.$X2, "(?<=')[^']*"))) %>% select(timestamp = X1, domain=V1)
}
